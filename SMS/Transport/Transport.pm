package GSM::SMS::Transport::Transport;

$VERSION = '0.1';

# Abstract class defines the methods a transport interface must implement
##########################################################################

# constructor
sub new($$) {

    my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {};
	$self->{cfg} = shift;

	bless($self, $class);
	return $self;
}

# abstract method definitions
#

# Send a (PDU encoded) message  
sub send($$)	{};

# Receive a PDU encoded message
#	$ is a ref to a PDU string
# 	return
#   	0 if PDU received
#   	-1 if no message pending  
sub receive($) {};	

# Close
sub close() {};

# A ping command .. just return an informative string on success
sub ping() {};

# get_config_parameters	... return the config parameters I expect here.
sub get_config_parameters() {};

# can we send to the following number?
sub has_valid_route($) {};

1;

=head1 NAME

GSM::SMS::Transport::Transport

Abstract class for the transport modules. Transport modules inherit from this class.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
