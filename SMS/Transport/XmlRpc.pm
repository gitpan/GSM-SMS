package GSM::SMS::Transport::XmlRpc;

#
# HTTP for Remote Serial modem 
#

use GSM::SMS::Transport::Transport;
@ISA = qw(GSM::SMS::Transport::Transport);

$VERSION = '0.1';

# All the parameters I need to run
my @config_vars = qw( 
	name
	match
	spoolout
					);

# Send a (PDU encoded) message  
sub send	{
	my ($self, $msisdn, $pdu) = @_;

	# print "send...";
	$self->_add_to_spool( $msisdn, $pdu, $self->{cfg}->{"spoolout"} );
	# print "\n";
	return 0;
};

# Receive a PDU encoded message
#	$ is a ref to a PDU string
# 	return
#   	0 if PDU received
#   	-1 if no message pending  
sub receive 	{
	my ($self, $pduref) = @_;

	return -1;
};	
 

# Close
sub close	 {
	my ($self) = @_;
}

# A ping command .. just return an informative string on success
sub ping {
	my ($self) = @_;

	return "Pong.. XmlRpc  transport ok";
}


# give out the needed config paramters
sub get_config_parameters {
	my ($self) = @_;

	return @config_vars;
}

# Do we have a valid route for this msisdn
sub has_valid_route {
	my ($self, $msisdn) = @_;
	
	# print "route";

	foreach my $route ( split /,/, $self->{cfg}->{"match"} ) {
		# print "($route)";
		return -1 if $msisdn =~ /$route/;
	}
	return 0;
}

#####################################################################
# transport specific
#####################################################################
sub _add_to_spool {
	my ($self, $msisdn, $pdu, $dir) = @_;
	local (*F);
	
	my $filename = $self->_create_spoolname($msisdn, $pdu);

	# print ">".$dir."/".$filename."\n";
	
	open F, ">".$dir."/".$filename;
	print F $pdu;
	close F;
}


sub _remove_from_spool {
	my ($self, $msisdn, $pdu, $dir) = @_;
	
	my $filename =  $self->_create_spoolname($msisdn, $pdu);
	unlink( $dir."/".$filename );
}

sub _create_spoolname {
	my ($self, $msisdn, $pdu) = @_;
	
	$msisdn =~ s/^\+//;
	my $filename = $msisdn . "_" . $$ . time . substr($pdu,-32);
	return $filename;
}

1;
