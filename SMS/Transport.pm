package GSM::SMS::Transport;
use Carp;
use GSM::SMS::Config;
use Data::Dumper;

$VERSION = '0.1';

# Constructor
##########################################################################
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};	
	bless($self, $class);	

	# process constructor parameters
	$self->{"__CONFIG_FILE__"} = shift;
	
	# initialize class parameters
	#	anonymous array to transports
	$self->{"__TRANSPORTS__"} = [];
	
	# read config file
	unless ( $self->{"__CONFIG__"} = read_config( $self->{"__CONFIG_FILE__"} )) {
		croak("Could not load config file : " . $self->{"__CONFIG_FILE__"} . "!");
	}

	# print Dumper $self->{'__CONFIG__'};

	# initialise transport
	$self->_init( $self->{"__CONFIG__"} );
	
		return $self;
}

# Send
##########################################################################
sub send {
	my ($self, $msisdn, $pdu) = @_;

	my $transport = $self->_route($msisdn);
	if ( $transport ) {
		if ( my $result = $transport->send($msisdn, $pdu) ) {
			# print  "error !\n";
			return 0;
		}
	}
	return -1;
}

# Receive
##########################################################################
sub receive {
	my ($self) = @_;
	my $pdu;

	foreach my $transporter ( @{$self->get_transports()} ) {
		if (!$transporter->receive(\$pdu)) {
			return $pdu;
		}
	}
	return $pdu;
}

# Get an array containing the transports
##########################################################################
sub get_transports {
	my $self = shift;
	return $self->{"__TRANSPORTS__"};
}

# Close
#	Clean up ...
##########################################################################
sub close {
	my $self = shift;
	
	foreach my $transport ( @{$self->{"__TRANSPORTS__"}} ) {
		$transport->close();
	}
}

##########################################################################
# P R I V A T E
##########################################################################

# Route
#	Give us the handle to the correct transport to use
#	Implements the routing.
#	Routing is now only done by the 'prefix' config parameter
sub _route {
	my ($self, $msisdn) = @_;
	
	# print "route... ";
	foreach my $transport ( @{$self->{"__TRANSPORTS__"}} ) {
		# print "--> $transport\n";
		if ( $transport->has_valid_route($msisdn) ) {
			# print "found ($transport)\n";
			return $transport;
		}
	}
	# print "END\n";
	return undef;
}

# Init
#	Create the actual transports and initialize them
sub _init {
	my ($self, $conf) = @_;

	 # print Dumper $conf;

	foreach my $transport ( keys %$conf ) {
		next if $transport =~ /default/;

		 #print "T: $transport ... ";

		# load transport class, using the preferences
		my $transport_config = get_config($conf, $transport);
		my $transport_type = $transport_config->{"type"};

		 # print Dumper $transport_config;
	
		 # print "starting up $transport_type..\n";
	
		my $transport_instance = eval(
			"use GSM::SMS::Transport::$transport_type; my \$n = GSM::SMS::Transport::$transport_type->new(\$transport_config); return \$n;"
									 );

		 # print $@;

		# print "use Tektonica::iSMS::Transport::$transport_type; my \$n = Tektonica::iSMS::Transport::$transport->new(\$transport_config); return \$n;";

		# add to list, if succeed
		if ( $transport_instance ) {
			# print "ok";
		 	push( @{$self->{"__TRANSPORTS__"}}, $transport_instance );
		}
		# print "\n";
	}
}

1;

=head1 NAME

GSM::SMS::Transport

=head1 DESCRIPTION

This can be best seen as a factory for the transports defined in the GSM::SMS::Transport::* modules.
When given a config file, it dynamically loads the transports defined in that config file, and initializes them.
 
=head1 METHODS

=head2 new( $configfile )

Create a new transport layer with the settings as in the config file. Please look in the example config file for the transport specific configuration settings.

=head2 send( $msisdn, $pdu )

Send a PDU message to the the msisdn. The transport layer will choose a transport according to the regular expression defined in the config file. This regexp matches against the msisdn.

=head2 $pdu = $t->receive()

Receive a pdu message from the transport layer. Undef when no new message available.

=head2 close()

Shut down transport layer, calls the transport specific close method.


=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
