package GSM::SMS::Config;
# Test for config
# ------------------------------------------------------------------------

#  Config format:
#	^#		:= comment
#	^[.+]$ 	:= start block
#	^.+=.+$	:= var, value pair
#	$_preferences->{$blockname}->{$var}=$value
#	$blockname = ( 'default', <blocknames> }

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw( &read_config &get_config);
$VERSION = '0.1';

sub read_config {
	my ($filename) = @_;
	my $config = {};
	
	# prepare default config
	my $hook = {};
	$config->{'default'} = [];
	push(@{$config->{'default'}}, $hook);
	
	# open config file
	local(*F);
	open F, $filename or return undef;
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
	close F;

	return $config;
}

sub get_config {
	my ($config, $name) = @_;
	
	return ${$config->{$name}}[0];
}
1; 

=head1 NAME

GSM::SMS::Config

=head1 DESCRIPTION

Implements a simple configuration format. Used mainly for the transports config file.

=head1 AUTHOR

Johan Van den Brande johan@vandenbrande.com>
