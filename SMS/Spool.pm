package GSM::SMS::Spool;
use Carp;
# implement spool functions

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw(add_to_spool remove_from_spool create_spoolname read_from_spool);
$VERSION = '0.1';

sub add_to_spool {
	my ($msisdn, $pdu, $dir) = @_;
	local (*F);
	
	my $filename = create_spoolname($msisdn, $pdu);
	open F, ">".$dir."/".$filename;
	print F $pdu;
	close F;
}


sub remove_from_spool {
	my ($file, $dir) = @_;
	
	unlink( $dir."/".$file ) or die $!;
}

sub create_spoolname {
	my ($msisdn, $pdu) = @_;
	
	$msisdn =~ s/^\+//;
	my $filename = $msisdn . "_" . $$ . time . substr($pdu,-32);
	return $filename;
}

sub read_from_spool {
	my	($dir, $n) = @_;
	local (*DIR);
	my ($file, $count, @arr);
	# return array with $n==0:<all>:$n messages from spooldir
	$count = 0;
	opendir(DIR, $dir) or croak "Could not read directory $dir ($!)";
	while ( defined($file = readdir(DIR)) && ( ($n && $count<$n) || !$n) ) {
		next if $file =~ /^\.\.?$/;
		$count++;
		if ($file =~ /(.+?)_.+/) {
			my $msisdn = $1;
			# contents of file
			local (*F);
			open F, $dir . "/" . $file;
			undef $/;
			my $contents = <F>;
			close F;
			my $msg = {};
			$msg->{'msisdn'} = $msisdn;
			$msg->{'pdu'} = $contents;
			$msg->{'file'} = $file;
			push(@arr, $msg);
		}
	}
	closedir(DIR);
	return @arr;
}

1;

=head1 NAME

GSM::SMS::Spool

=head1 DESCRIPTION

Implements a simple filesystem spool mechanism to temporarily store incoming and outgoing SMS messages.

=head1 METHODS

=head2 add_to_spool( $msisdn, $pdu, $dir )

Add a message to the spool dir.

=head2 remove_from_spool( $file, $dir )

Remove a message from a spool dir.

=head2 create_spoolname( $msisdn, $dir )

Create the filename for a spool message. Internal function.

=head2 read_from_spool( $dir, $n )

Read n messages from the spool.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
