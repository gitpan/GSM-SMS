package GSM::SMS::Config;
use strict;
use vars qw( $VERSION );

use Carp;
use Log::Agent;

$VERSION = '0.3';

=head1 NAME

GSM::SMS::Config - Implements a simple .ini style config.

=head1 DESCRIPTION

Implements a simple configuration format. Used mainly for the transports 
config file.

The configuration format is defined as follows

  ^#         := comment
  ^[.+]$     := start block
  ^.+=.+$    := var, value pair
  
The structure allows attribute (configuration) access as follows

  $_preferences->{$blockname}->{$var}=$value
  $blockname = ( 'default', <blocknames> }

=head1 METHODS

=over 4

=item B<new> - The constructor

  my $cfg = GSM::SMS::Config->new(
               -file => $config_file, # Optional otherwise take default config
			   -check => 1            # Optional, does a sanity check
			);

=cut

sub new {
	my ($proto, %arg) = @_;

	my $class = ref($proto) || $proto;

	my $self = {
			_config_file => $arg{-file},
			_check => $arg{-check}
	};

	bless $self, $class;

	$self->read_config( $self->{_config_file}, $self->{_check} );

	return $self;
}

=item B<read_config> - read a configuration file

=cut

sub read_config {
	my ($self, $filename, $check) = @_;
	my $config = {};
	
	# prepare default config
	my $hook = {};
	$config->{'default'} = [];
	push(@{$config->{'default'}}, $hook);
	
	# open config file
	local(*F);
	
	if ( $filename ) {
		
		logdbg "debug", "Reading config from a specific file ($filename)";
		
		open F, $filename or do 
							 { 
								logcroak "Could not open config file $filename ($!)"; 
								return undef 
							 };

		while (<F>) {
			chomp;					# loose trailing newline
			s/#.*//;				# loose comments
			s/^\s+//;				# loose leading white
			s/\s+$//;				# loose trailing white;
			next unless length;		# did we loose everything?
			
			# recon block or var/value pair ...
			if ( /\[(.+?)\]/ ) {
				$hook =  {} ;
				$config->{$1} = [];
				push( @{$config->{$1}}, $hook );
			} else {
				my ($var, $value) = split(/\s*=\s*/, $_, 2);
				$hook->{$var} = $value;
			}
		}
		close F if $filename;

	} else {

		logdbg "debug", "Getting default configuration.";
	
		require GSM::SMS::Config::Default;
		$config = $GSM::SMS::Config::Default::Config;
	}
	$self->{_config} = $config;

	return undef unless $check && $self->is_sane();

	return $config;
}

=item B<is_sane> - check if a configuration complies with some rules

=cut

sub is_sane {
	my ($self) = @_;

	my $config = $self->{_config};

	# we need a spool_dir for the transports ...
	unless (defined $self->get_value( undef, 'spooldir' ))
	{
		logcroak "insane config: 'spooldir' is mandatory in config file";
		return undef;
	}

	# we need a router object for the transports
	unless (defined $self->get_value( undef, 'router' ))
	{
		logcroak "insane config: 'router' is mandatory in config file";
		return undef;
	}

	# we also need to know here we want the logfiles ... although this can be
	# application specific
	unless (defined $self->get_value( undef, 'log' ))
	{
		logcroak "insane config: 'log' is mandatory in config file";
		return undef;
	}
	
	# we need at least one defined transport ...
	if (keys(%{$config}) <= 1)
	{ 
		logcroak "insane config: We need at least one defined transport";
		return undef;
	}

	return 1;
}

=item B<get_section_names> - Get an array of all the section names

=cut

sub get_section_names {
	my ($self) = @_;

	return keys %{$self->{_config}};
}


=item B<get_config> - get a specific config file section

  $config->get_config( 'default' );
  $config->get_config( 'Serial01' );

=cut

sub get_config {
	my ($self, $name) = @_;
	
	return ${$self->{_config}->{$name}}[0];
}

=item B<get_value> - get the config value for that section

  $value = $config->get_value($section, $name);

=cut

sub get_value {
	my ($self, $section, $name) = @_;

	$section = $section || 'default';

	return ${$self->{_config}->{$section}}[0]->{$name};
}

1; 

=head1 AUTHOR

Johan Van den Brande johan@vandenbrande.com>

=cut
