package GSM::SMS::Transport::Serial;

#
# SMS transport layer for serial GSM modems
#

use GSM::SMS::Transport::Transport;
@ISA = qw(GSM::SMS::Transport::Transport);

$VERSION = '0.1';

use Device::SerialPort;
use GSM::SMS::Log;
use GSM::SMS::Spool;

# All the parameters I need to run ...
my @config_vars = qw( 
	name
	match	
	serial-port
	baud-rate
	heartbeat
	pin-code
	csca
	spoolout
	spoolin
					);

my $__TO = 200;

# constructor
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;

	my $self = {};
	$self->{cfg} = shift;
	
	$self->{'__LOGGER__'} = GSM::SMS::Log->new( $self->{cfg}->{"log"} );
	
	bless($self, $class);
	my $success = $self->init( $self->{cfg} );
	return $self unless $sucess;
	return undef;
} 

# Send a PDU encoded message
sub send {
	my($self, $msisdn, $p) = @_;
	my $logger = $self->{'__LOGGER__'};
	chomp($p);

	# print "MSISDN : $msisdn\n";
	# print "MSG: $p\n";

	# calculate length of message
	my $len =  length($p)/2 - 1;
	$len-=hex( substr($p, 0, 2) );
  
	# $self->_at("ATE0\r", $__TO);
    $self->_at("AT+CMGF=0\r", $__TO);
    $self->_at("AT+CMGS=$len\r", $__TO, ">");
    my $res = $self->_at("$p\cz", $__TO);

	# print "## $res\n"; 
	
	if ($res=~/OK/) {
		$logger->logentry("send [$p]") if $logger;
		return 0;
	} else {
		$logger->logentry("error sending [$p]") if $logger;
		return -1;
	}
}


# Receive a PDU encoded message
# Will return a PDU string in $pduref from the modem IF we have a message pending 
# return
#	0 if PDU received
#	-1 if no message pending
sub receive {
	my ($self, $pduref) = @_;

	my $ar = $self->{MSGARRAY};
	my $msg = shift (@$ar); 	# shift because we want to delete lower index first (problem with modem)
	if (!$msg) {
		
		# Read in pending messages
		my $msgarr = $self->_getSMS();
		foreach my $msg (@$msgarr) {
			push @$ar, $msg;
		}
		$msg = shift (@$ar);	# shift same reason as above
	}
	if ($msg) {
		$$pduref = $msg->{MSG};
		$self->_delete($msg->{ID});
		return 0;
	}
	return -1;
}


# Initialise this transport layer$
#  No init file -> default initfile for transport
sub init {
	my ($self, $config) = @_;

	if ($self->_init($config)) {
		return -1;
	}

	$self->{MSGARRAY} = [];
	
	return 0;
}



# Close the init file
sub close {
	my ($self) =@_;

	my $logger = $self->{'__LOGGER__'};
	
	my $l = $self->{log};
	undef $self->{port};
	$logger->logentry("Serialtransport stopped") if $logger;
}


# A ping command .. just return an informative string on success
sub ping {
	my ($self) = @_;

	return $self->_getSQ();
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

sub get_name {
	my ($self) = @_;

	return $self->{cfg}->{name};
}

###############################################################################
# Transport layer specific functions
#
sub _init {
	my ($self, $cfg) = @_;

	my $logger = $self->{'__LOGGER__'};
	
	# print Dumper $cfg;


	# Start of log ...
	$logger->logentry('Starting Serial Transport for '.$cfg->{"name"}) if $logger;
	
	# Get configuration from config file

	

	$self->{cfg} = $cfg;

	my $port = $cfg->{"serial-port"}	||	return -1;
	my $br   = $cfg->{"baud-rate"}		|| 	return -1;
	my $pc   = $cfg->{"pin-code"}		|| 	return -1;
	my $csca = $cfg->{"csca"}		|| 	return -1;
	my $modem = $cfg->{"name"};
	
	# Start up serial port
	$self->{port} = Device::SerialPort->new ($port);
    	$self->{port}->baudrate($br);
    	$self->{port}->parity("none");
    	$self->{port}->databits(8);
    	$self->{port}->stopbits(1);

	# Try to communicate to the port
	$self->_at("ATE0\r", $__TO);
	my $res = $self->_at("AT\r", $__TO);
	my $res = $self->_at("AT\r", $__TO);

	unless ($res =~/OK/is) {
		$logger->logentry('Could not communicate to '.$port.'.') if $logger;
		return -1;
	}

	# Check the modem status (PIN, CSCA and network connection)
	return -1 unless ( $self->_register );

	$logger->logentry("Modem is alive! (SQ=".$self->_getSQ()."dBm)") if $logger;
	return 0;
}



sub _getSMS {
	my ($self) = @_;
	my $result = [];
	my $msgcount=0;

	# to pdu mode
	$self->_at("AT+CMGF=0\r", $__TO);

	# loop from 1 to 10 to get messages
	for (my $i=1; $i<=10; $i++) {
		my $res = $self->_at( "AT+CMGR=$i\r", $__TO );

		next if ($res=~/ERROR/ig);

		# find +CMGR: ..,..,..
		my $cmgr_start 	= index( $res, "+CMGR:" );
		my $cmgr_stop	= index( $res, "\r", $cmgr_start );
		my $cmgr = substr($res, $cmgr_start, $cmgr_stop - $cmgr_start);

		# find PDU string
		my $pdu_start	= $cmgr_stop + 2;
		my $pdu_stop	= index( $res, "\r", $pdu_start );
		my $pdu  = substr($res, $pdu_start, $pdu_stop - $pdu_start);

		# message settings
		$cmgr=~/\+CMGR:\s+(\d*),(\d*),(\d*)/;

		my $msg = $result->[$msgcount++] = {};
		$msg->{'ID'} = $i;
		$msg->{'STAT'} = $1;
		$msg->{'LENGTH'} = $3;
		$msg->{'MSG'}.=$pdu;
	}
	return $result;
}


sub _delete {
	my ($self, $id) = @_;
	
	my $l=$self->{log};

	$self->_at("AT+CMGF=1\r", $__TO);
	my $res = $self->_at("AT+CMGD=".$id."\r", $__TO);
	# my $res="OK";	

	# print "DELETE $res\n";

	if ($res=~/OK/) {
	} else {
		exit(0);
	}
}


sub _at {
    my ($self, $at, $timeout, $expect) = @_;
 
	my $ob = $self->{port};

    $ob->purge_all;
    $ob->write("$at");
    $ob->write_drain;
 
    my $in = "";
    my $max = 500;
    my $count = 0;
    my $found = 0;
    my $to_read;
    my $readcount;
    my $input;
    my $counter=0;

	# print "$at\n";
 
    do {
        select(undef,undef,undef, 0.1);
        $to_read = $max - $count;
 
        ($readcount, $input) = $ob->read($to_read);
        $in.=$input;
        $count+=$readcount;
 
        if ( ($in=~/OK\r\n/) || ($in=~/ERROR\r\n/) ) {
            $found=1;
        }
 
        if ( $expect ne "" ) {
            if ( index($in, $expect) > -1 ) {
                $found=1;
            }
        }
        $counter++;
 
 
    } while ( ($found==0) && ($counter<$timeout) );
 
    select(undef,undef,undef, 0.1);
 
    $to_read=$max-$count;
    ($readcount, $input) = $ob->read($to_read);
 
    $in.=$input;

	# print "# $in #\n";

    return $in;
}                                                                                          

sub _getSQ {
	my ($self) = @_;
	my $res = $self->_at("AT+CSQ\r", $__TO);
	$res=~/\+CSQ:\s+(\d+),(\d+)/igs;
	$res=$1;
	
	my $dbm;

	# transform into dBm
	$dbm = -113 if ($res == 0);
	$dbm = -111 if ($res == 1);
	$dbm = -109 + 2*($res-2) if (($res >= 2) && ($res <=30));
	$dbm = 0 if ($res == 99); 

	return $dbm;
}

# Register modem: PIN, CSCA, Wait for network connectivity for a certain period
sub _register {
	my ($self) = @_;
	my $res;

	my $logger = $self->{'__LOGGER__'};
	
	my $cfg = $self->{cfg};

	my $pc   = $cfg->{"pin-code"};
	my $csca = $cfg->{"csca"};	
	
    	$logger->logentry( "Checking if modem ready .." ) if $logger;    
	
	# 1. Do we need to give in the PIN ?
	$res = $self->_at("AT+CPIN?\r", $__TO, "+CPIN:");

	if ( $res=~/\+CPIN: SIM PIN/i ) {
		# Put PIN
		$logger->logentry("Modem needs PIN ...") if $logger;	
		$self->_at("AT+CPIN=\"$pc\"\r", $__TO);
		 
		# Check PIN
		$res = $self->_at("AT+CPIN?\r", $__TO , "+CPIN:");
		if( $res!~/\+CPIN: READY/i ) {
			# somethings wrong here!
			$logger->logentry("Modem did not accept PIN!") if $logger;
			return 0;
		}
	}

	# 2. Set the CSCA
	$res = $self->_at("AT+CSCA=\"$csca\"\r", $__TO);
	$res = $self->_at("AT+CSCA=\"$csca\"\r", $__TO);

	# 3. Wait for registration on network
	my $registered = 0;
	my $stime = time;
	do {
		$res = $self->_at("AT+CREG?\r", $__TO , "+CREG");
		if ( $res=~/1/i ) {
			$registered++;
		}
	}
	until ( $registered || ((time - $stime) > 10 ) );

	if( $registered==0 ) {
		$logger->logentry("Modem could not register on network!") if $logger;
		return 0;
	}

	# All went fine!

	return -1;
}
1;

=head1 NAME

GSM::SMS::Transport::Serial

=head1 DESCRIPTION

This class implements a serial transport. It uses Device::SerialPort to communicate to the modem. At the moment the modem that I recommend is the WAVECOM modem. This module is in fact the root of the complete package, as the project started as a simple perl script that talked to a Nokia6110 connected via a software modem ( as that model did not implement standard AT ) on a WINNT machine, using Win32::SerialPort and Activestate perl. Also tested with the M20 modem module from SIEMENS. 

I first used the Nokia6110, then moved to the Falcom A1 GSM modem, then moved to the SIEMENS M20 and then moved to the WAVECOM series. Both M20 and WAVECOM worked best, but I could crash the firmware in the M20 by sending some fake PDU messages.

=head1 ISSUES

The Device::SerialPort puts a big load on your system (active polling).

The initialisation does not always work well and sometimes you have to
initialize your modem manually using minicom or something like that.

	>minicom -s
	AT
	AT+CPIN?
	AT+CPIN="nnn"
	AT+CSCA?
	AT+CSCA="+32475161616"

+CPIN puts the pin-code in the modem; Be carefull, only 3 tries and then you have to provide the PUK code etc ...

+CSCA sets the service center address

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
