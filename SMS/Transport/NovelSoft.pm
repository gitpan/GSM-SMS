package GSM::SMS::Transport::NovelSoft;

#
# HTTP access to the NovelSoft (sms-wap.com) SMS center
#

use GSM::SMS::Transport::Transport;
@ISA = qw(GSM::SMS::Transport::Transport);

$VERSION = '0.1';

use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use URI::URL qw(url);
use GSM::SMS::PDU;
use GSM::SMS::Log;
use Data::Dumper;

# All the parameters I need to run
my @config_vars = qw( 
	name
	proxy
	userid
	password
	originator
	smsserver
	backupsmsserver
	match
	spoolout
					);

# constructor
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};
	$self->{cfg} = shift;
	
	$self->{'__LOGGER__'} = GSM::SMS::Log->new( $self->{cfg}->{"log"} );
	
	bless($self, $class);
	return $self;
} 


# Send a (PDU encoded) message  
sub send	{
	my ($self, $msisdn, $pdu) = @_;
	my $logger = $self->{'__LOGGER__'};

	$logger->logentry("send [$pdu]") if $logger;

	$self->_add_to_spool( $msisdn, $pdu, $self->{cfg}->{"spoolout"} );
	if ( $self->_transmit($pdu, $self->{cfg}->{"smsserver"}) ) {
		# trying backup
		if ( $self->_transmit($pdu, $self->{cfg}->{"backupsmsserver"}) ) {    
			$logger->logentry( "Error sending" ) if $logger;	
			return -1;
		}
	}
	$self->_remove_from_spool( $msisdn, $pdu, $self->{cfg}->{"spoolout"} );
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
	my $logger = $self->{'__LOGGER__'};

	$logger->logentry("NovelSoft Transport ended.") if $logger;
}

# A ping command .. just return an informative string on success
sub ping {
	my ($self) = @_;

	return "Pong.. NovelSoft  transport ok";
}


# give out the needed config paramters
sub get_config_parameters {
	my ($self) = @_;

	return @config_vars;
}

# Do we have a valid route for this msisdn
sub has_valid_route {
	my ($self, $msisdn) = @_;

	# print "in route\n";
	# print Dumper $self->{cfg};
	foreach my $route ( split /,/, $self->{cfg}->{"match"} ) {
		# print $route;
		return -1 if $msisdn =~ /$route/;
	}
	return 0;
}

#####################################################################
# transport specific
#####################################################################
sub _transmit {
	my ($self, $pdustr, $server) = @_;

	my $logger = $self->{'__LOGGER__'};

	my $uid = $self->{cfg}->{"userid"};
	my $pwd = $self->{cfg}->{"password"};
	my $originator = $self->{cfg}->{"originator"};
	my $proxy = $self->{cfg}->{"proxy"};
	my $url = url( $server );
	my $msg;
	my $decoder = GSM::SMS::PDU->new();
	my ($da, $pdutype, $dcs, $udh, $payload) = $decoder->SMSSubmit_decode($pdustr); 

	$da=~s/^\+//;

	if (length($udh) > 0) {
		$udh = '01' . sprintf("%02X", int(length($udh)/2)) . $udh;
		$msg="|$udh|$payload";
	} else {
		$msg=$payload;
	}

	my $ua = LWP::UserAgent->new();
	$ua->proxy( 'http', $proxy ) if ( $proxy ne "" );
	my $req = POST "$server",
				[ 
				UID => $uid, 
				PW => $pwd, 
				N => $da, 
				O => $originator,
				M => $msg 
				];

	$req->header( Host => $url->host );

	my $res = $ua->request($req);

	# print "#" x 80 . "\n";
	# print $res->content;
	# print "#" x 80 . "\n";

	if ($res->is_success) {
		my $content = $res->content;
		$logger->logentry( "return: $content" ) if $logger;
		return 0 if ($content=~/01/);
		return -1;
	} else {
		$logger->logentry( "error!" ) if $logger;
		$logger->logentry( $res->error_as_HTML ) if $logger;
		return -1;
	}
}

sub _add_to_spool {
	my ($self, $msisdn, $pdu, $dir) = @_;
	local (*F);
	
	my $filename = $self->_create_spoolname($msisdn, $pdu);
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

=head1 NAME

GSM::SMS::Transport::NovelSoft

=head1 DESCRIPTION

Implements a ( send-only ) transport for the www.sms-wap.com http based sms center. This is a swiss company and they provide a very nice service. A pity that all, but one, GSM operator stopped roaming with Swiss. this way it is not possible anymore for us ( Belgium ) to use this service ... But they have still more then 1 hundred countries served! 

Also can do PDU messages and as such can be used to send NBS messages.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>


