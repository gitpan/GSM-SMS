package GSM::SMS::NBS;

use vars qw($VERSION);

$VERSION = '0.13';

use GSM::SMS::NBS::Message;
use GSM::SMS::NBS::Stack;
use GSM::SMS::OTA::RTTTL;
use GSM::SMS::OTA::CLIicon;
use GSM::SMS::OTA::Operatorlogo;
use GSM::SMS::OTA::VCard;
use GSM::SMS::OTA::Config;
use GSM::SMS::Transport;
use MIME::Base64;


#
# Constructor
#
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless($self, $class);

	$self->{'__CONFIG_FILE__'} = shift;
	return undef unless $self->{'__TRANSPORT__'} = GSM::SMS::Transport->new( $self->{'__CONFIG_FILE__'});
	$self->{'__STACK__'} = GSM::SMS::NBS::Stack->new( -transport => $self->{'__TRANSPORT__'} );	
	return $self;
}

#
# Send  message
#
sub sendto {
	my ($self, $msisdn, $message, $dport, $sport, $dcs ) = @_;
	my $ret;

	my $transport = $self->{'__TRANSPORT__'};

	my $nbs_message = GSM::SMS::NBS::Message->new();
	$nbs_message->create($msisdn, $message, $dport, $sport, $dcs);
	foreach my $frame ( @{$nbs_message->get_frames()} ) {
		# transport->send returns -1 on failure.
		$ret = -1 if $transport->send($msisdn, $frame);
	}
}

#
# send ringing tone 
#
sub sendRTTTL {
	my ($self, $msisdn, $rtttlstring) = @_;

	if ( my $error = OTARTTTL_check($rtttlstring) ) {
		return $error;
	}

	my $music = OTARTTTL_makestream($rtttlstring);
	return $self->sendto( $msisdn, $music, OTARTTTL_PORT);
}

#
# send operator logo
#
sub sendOperatorLogo_b64 {
	my ($self, $msisdn, $country, $operator, $b64, $format) = @_;
	
	my $ol = OTAOperatorlogo_fromb64( $country, $operator, $b64, $format );
	return $self->sendto( $msisdn, $ol, OTAOperatorlogo_PORT);
}

#
# send operator logo
#
sub sendOperatorLogo_file {
	my ($self, $msisdn, $country, $operator, $file ) = @_;

	my $ol = OTAOperatorlogo_fromfile( $country, $operator, $file );
	return $self->sendto($msisdn, $ol, OTAOperatorlogo_PORT);
}

#
# send group graphic
#
sub sendGroupGraphic_b64 {
	my ($self, $msisdn, $b64, $format) = @_;

	my $gg = OTACLIicon_fromb64( $b64, $format );
	return $self->sendto($msisdn, $gg, OTACLIicon_PORT);
}

#
# send group graphic
#
sub sendGroupGraphic_file {
	my ($self, $msisdn, $file) = @_;

	my $gg = OTACLIicon_fromfile( $file );
	
	return $self->sendto($msisdn, $gg, OTACLIicon_PORT);
}

#
# send VCard
#
sub sendVCard {
	my ($self, $msisdn, $lname, $fname, $phone) = @_;

	my $vcard = OTAVcard_makestream( $last, $first, $phone );
	return $self->sendto( $msisdn, $vcard, OTAVcard_PORT);
}

#
# send OTA
#
sub sendConfig {
	my ($self, $msisdn, $bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name) = @_;

	my $ret = -1;
	my $ota = OTAConfig_makestream(  $bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name);
	if ( $ota ) {
		$ret = $self->sendto( $msisdn, $ota, OTAConfig_PORT, 9200);
	}
	return $ret;
}

#
# send SMS text message
#
sub sendSMSTextMessage {
	my ($self, $msisdn, $msg, $multipart) = @_;
	my $cnt = 0;	
	my $ret = 0;
	if ( $multipart ) {
		while (length($msg) > 0) {
			my $xmsg = substr($msg, 0, (length($msg)<160)?length($msg):160 );
			$msg = substr($msg, 160, length($msg) - 160);
			$ret = -1 if $self->sendto( $msisdn, $xmsg, undef, undef, '7bit');
			$cnt++;
		}
	} else {
		$msg = substr($msg, 0, (length($msg)<160)?length($msg):160 );
		$ret = $self->sendto( $msisdn, $msg, undef , undef , '7bit');
	}
	return ($ret==-1)?$ret:$cnt;
}

#
# receive SMS message from stack
#
sub receive {
	my ($self, $ref_originatingaddress, $ref_message, $ref_timestamp, $ref_transportname, $ref_port, $blocking) = @_;	

	my $stack = $self->{'__STACK__'};
	return $stack->receive($ref_originatingaddress, $ref_message, $ref_timestamp, $ref_transportname, $ref_port, $blocking);
}

1;

=head1 NAME

GSM::SMS::NBS - API for sending and receiving SMS messages.

=head1 SYNOPSIS

	use GSM::SMS::NBS;

	my $nbs = GSM::SMS::NBS->new( $transportconfigfile );
	
	...	

	$nbs->sendRTTTL( '+32475000000', $rtttl_string );
	$nbs->sendOperatorLogo_b64( $msisdn, $countrycode, $operator, $b64, 'gif' );
	$nbs->sendOperatorLogo_file( $msisdn, $countrycode, $operatorcode, $file );
	$nbs->sendGroupGraphic_b64( $msisdn, $b64, 'png' );
	$nbs->sendGroupGraphic_file( $msisdn, $file );
	$nbs->sendVCard( $msisdn, $lastname, $firstname, $phonenumber );
	$nbs->sendConfig( .... );
	$nbs->sendSMSTextMessage( $msisdn, $message, $multipart );

	...
	
	my $originatingaddress;
	my $message;
	my $timestamp;
	my $transportname;
	my $port;
	my $blocking = 1;

	$nbs->receive(	\$originatingaddress,
					\$message,
					\$timestamp,
					\$transportname,
					\$port,
					$blocking
				);

	print "I got a message from $originatingaddress\n";
		

=head1 DESCRIPTION

This module is the API you would normally use to send and receive sms messages.
It exports all the important  methods and hides some of the more complex things.
It needs a configuration file in it's constructor. The  configuration is transport specific but looks like:

	[transportname]
		name = parameter
	    ...
	[othertransport]
		name = parameter
		...

Look into the transport.cfg files in the examples on how to set it up.

=head1 METHODS

=head2 new

	my $nbs = GSM::SMS::NBS->new( $configfile );

This is the constructor, it expects a file name of a transport configuration as an argument.
All functions return -1 on failure, 0 on success.

=head2 sendSMSTextMessage

	$nbs->sendSMSTextMessage( $msisdn, $msg, $multipart );

Send a text message ( $msg ) to the gsm number ( $msisdn ). If you set $multipart to true (!=0) the message will be split automatically in 160 char blocks. When $multipart is set to false it will be truncated at 160 characters.

=head2 sendRTTTL

	$nbs->sendRTTTL( $msisdn, $rtttlstring );

Send a ringing tone ( $rtttlstring ) to the specified telephone number ( $msisdn ). The RTTTL ( Ringing Tone Tagged Text Language ) format is specified as described in the file rtttlsyntax.txt.

You can find a lot of information about RTTTL ( and a lot of ringing tones ) on the internet. Just point your favourite browser to your favourite searchengine and look for ringing tones.

=head2 sendGroupGraphic_b64

	$nbs->sendGroupGraphic_b64( $msisdn, $b64, $format);

Send a group graphic, also called a Caller Line Identification icon ( CLIicon ),to the recipient indicated by the telephone number $msisdn. It expects a base 64 encoded image and the format the image is in, like 'gif', 'png'. To find out which image formats are supported, look at the superb package Image::Magick. The base 64 encoded image is just a serialisation of an image file, not of the image bitarray. The image is limited in size, it needs to be 71x14 pixels.
The base 64 encoding is used here because you maybe want to build a HTTP (XMLRPC ) gateway to send images. Without the _b64 method you would need to save the image file to disk and use the _file method, this is cumbersome ...
A group graphic is used to visually identify the group the caller belongs to. If you have a friend who calls you and his number is in the group 'friends', you probably would want to picture a pint of beer.

=head2 sendGroupGraphic_file

	$nbs->sendGroupGraphic_file( $msisdn, $file);

Send a group graphic to $msisdn, use the image in file $file. The image must be 71x14 pixels. 

=head2 sendOperatorLogo_b64

	$nbs->sendOperatorLogo_b64( $msisdn, $country, $operator, $b64, $format);

An operator logo indicates the operator you are connected to for the moment. This is used to have a nice logo on your telephone all of the time. I have also heard the term 'branding' overhere.
You also need to provide a country code and operator code. I have assembled some of these and you can find them in the file codes.txt. These files will move into a seperate package, because you can find the operator and country codes programatically by using the first n numbers of the msisdn.
The method expects a base64 serialised image and the format of the image, 'gif', 'png', next to the receiving telephone number ( $msisdn ) and the country and operator code.
The image needs to be 71x14 pixels.

=head2 sendOperatorLogo_file

	$nbs->sendOperatorLogo_file( $msisdn, $country, $operator, $file );

Send an operator logo to $msisdn, using the image in file $file.

=head2 sendVCard

	$nbs->sendVCard( $msisdn, $lastname, $firstname, $telephone );

A VCard is a small business card, containing information about a person. It is not a GSM only standard, netscape uses vcards to identify the mail sender ( attach vcard option ). You can look at the complete VCard MIME specification in RFC 2425 and RFC 2426.

=head2 sendConfig

	$nbs->sendConfig( $msisdn, $bearer, $connection, $auth, $type, $speed, $proxy, $home, $uid, $pwd, $phone, $name);

Send a WAP configuration to a WAP capable handset. It expects the following parameters:

	The parameters in UPPERCASE are exported constants by the GSM::SMS::OTA::COnfig.

	$msisdn		Phonenumber recipient

	$bearer		OTA_BEARER_CSD | OTA_BEARER_SMS

				The carrier used ( circuit switched data or sms ), WAP is
				independent of the underlying connectivity layer.

	$connection	OTA_CONNECTIONTYPE_TEMPORARY
				OTA_CONNECTIONTYPE_CONTINUOUS

				You have to use continuous for CSD type of calls.

	$auth		OTA_CSD_AUTHTYPE_PAP
				OTA_CSD_AUTHTYPE_CHAP

				Use PAP or CHAP as authentication type. A CSD call is just
				a data call, and as such can use a normal dial-in point.

	$type		OTA_CSD_CALLTYPE_ISDN
				OTA_CSD_CALLTYPE_ANALOGUE
			
	$speed		OTA_CSD_CALLSPEED_9600
				OTA_CSD_CALLSPEED_14400
				OTA_CSD_CALLSPEED_AUTO

	$proxy		IP address of the WAP gateway to use.

	$home		URL of the homepage for this setting. e.g.
				http://wap.domain.com

	$uid		Dial-up userid

	$pwd		Dial-up password

	$phone		Dial-up telephone number

	$name		Nick name for this connection.			
		
	This feature has been tested on a Nokia 7110, but other Nokia
	handsets are also supported.	

=head2 receive

	$nbs->receive(	\$originatingaddress,
					\$message,
					\$timestamp,
					\$transportname,
					\$port,
					$blocking
				);

This method is used for implementing bidirectional SMS. With you can receive incoming messages. The only transport ( for the moment ) that can receive SMS messages is the Serial transport. 

The originatingaddress contains the sender msisdn number. 

The message contains the ( concatenated ) message. A NBS message can be larger than 140 bytes, so a UDP like format is used to send fragements. The lower layers of the GSM::SMS package take care of the SAR ( Segmentation And Reassembly ). 

The timestamp has the following format:

	YYMMDDHHMMSSTZ

	YY	:=	2 digits for the year ( 01 = 2001 )
	MM	:=	2 digits for the month
	DD	:=	2 digits for the day
	HH	:=	2 digits for the hour
	MM	:=	2 ditits for the minutes
	SS	:=	2 digits for the seconds
	TZ	:=  timezone 

Transportname contains the name of the transport as defined in the config file.

Port is the port number used to denote a specified service in the NBS stack.

	my $originatingaddress;
	my $message;
	my $timestamp;
	my $transportname;
	my $port;
	my $blocking = 1;

	$nbs->receive(	\$originatingaddress,
					\$message,
					\$timestamp,
					\$transportname,
					\$port,
					$blocking
				);

	print "I got a message from $originatingaddress\n";
	
=head1 BUGS

Probably a lot. I hope to get some bug reports ...
One odd behaviour is that the CSCA is not always set correctly.
If receiving works, but sending not ( on the serial transport ),
then issue the next command to the modem in e.g. minicom.

	AT+CSCA="+32475161616"
	( For belgian proximus ... look at your operator
	  for correct csca address ).

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
