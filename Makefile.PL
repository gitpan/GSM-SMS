use ExtUtils::MakeMaker;
use Term::ReadLine;
use File::stat;
use File::Path;

my $term;

WriteMakefile(
    'NAME'			=> 'GSM::SMS',
    'VERSION_FROM'	=> 'SMS/NBS.pm',
	'ABSTRACT'		=> 'Perl Modules For Smart Messaging',
    'PREREQ_PM'		=> {
		'Device::SerialPort'=> 0,
		'Test::More'		=> 0,
		'Log::Agent'		=> 0,
		'MIME::Base64'		=> 0,
		'Data::Dumper'		=> 0,
		'Image::Magick'		=> 0,
		'LWP::UserAgent'	=> 0,
		'File::Temp'		=> 0,
		'HTTP::Request'		=> 0,
		'URI::URL'			=> 0,
		'URI::Escape'		=> 0,
		'LWP::Simple'		=> 0,
		'File::stat'		=> 0,
		'File::Path'		=> 0,
		'Term::ReadLine'	=> 0
	},
	'CONFIGURE'		=> \&configure
);

sub configure {

	$term = new Term::ReadLine 'GSM::SMS configurator';

	print <<EOT;
   
     ____ ____  __  __     ____  __  __ ____
    / ___/ ___||  \\/  |_ _/ ___||  \\/  / ___|
   | |  _\\___ \\| |\\/| (_|_)___ \\| |\\/| \\___ \\
   | |_| |___) | |  | |_ _ ___) | |  | |___) |
    \\____|____/|_|  |_(_|_)____/|_|  |_|____/

        Perl Modules For Smart Messaging


Welcome to the GSM::SMS package! Thanks for using it!

This configuration script gives you the possibility to configure the
default settings of the system. 

All things you configure here can also be overwritten per application, 
by providing an explicit configuration file.


EOT
	my $in;
	$in = $term->readline('Do you want to configurate the package? (y/n) > ');
	return {} if $in =~ /[nN]/;
	print "\nThanks for proceeding!";

	# Configurate system wide settings

	# 1. logfiles
	my $path_default = '/var/log/gsmsms';
	print "\n\n";
	$in = $term->readline("Where do you want the logfile(s)? ($path_default) >");
	my $logdir = $in || $path_default;
	create_directory( $logdir ) unless (stat($logdir));

	# 2. Spool directory
	my $spool_default = '/var/spool/gsmsms';
	$in = $term->readline("Where do you wish to keep the spool directory? ($spool_default) > ");
	my $spooldir = $in || $spool_default;
	create_directory( $spooldir ) unless (stat($spooldir));

	# 3. Test GSM number
	print "\n\n";
	$in = $term->readline( "Mobile phone number to receive the tests on (leave empty for no sending) > " );
	my $testgsm = $in;

	# create config file - generic part
	write_to_config(<<EOT
package GSM::SMS::Config::Default;

\$Config = {	
	'default' => [
					{
					'router' => 'Simple',
					'spooldir' => '$spooldir',
					'log' => '$logdir',
					'testmsisdn' => '$testgsm'
					}
				 ],
EOT
	);
	
	# 3. Transports
	print "\n\nWe're going to configure the transports\n";

	# 3.1 Serial
	print "\n\n";
	$in = $term->readline( "Do you have a serial transport? (y/n) > ");
	if ( $in =~ /y/i ) {
		config_transport_serial();
	}

	# 3.2 NovelSoft
	print "\n\n";
	$in = $term->readline( "Do you have a NovelSoft account? (y/n) > " );
	if ( $in =~ /y/i ) {
		config_transport_novelsoft();
	}

	# 3.3 MCube
	print "\n\n";
	$in = $term->readline( "Do you have an MCube account? (y/n) > " );
	if ( $in =~ /y/i ) {
		config_transport_mcube();
	}

	# 3.4 File
	print "\n\n";
	$in = $term->readline( "Do you want the file test transport activated? (y/n) > " );
	if ( $in =~ /y/i ) {
		config_transport_file();
	}

	append_to_config(<<EOT

	};
1;
EOT
	);

	return {};
}

sub config_transport_serial {
		my ($name, $port, $csca, $pincode, $baus, $originator, $memory, $acl );
		do {
			do {
				$name = $term->readline( "What's the name? (serial01) > " )
						|| "serial01";
				$port = $term->readline( "What's the port? (/dev/ttyS0) > " )
						|| "/dev/ttyS0";
				$csca = $term->readline( "What's the CSCA? (+32475161616) > " )
						|| "+32475161616";
				$pincode = $term->readline( "What's the pincode? (0000) > " )
						|| "0000";
				$baud = $term->readline( "What's the baudrate? (9600) > " )
						|| "9600";
				$originator = $term->readline( "What's the originator? (GSM::SMS)> " )
						|| "GSM::SMS";
				$memory = $term->readline( "How big is the SMS memory? (10) > " )
						|| "10";
				$acl = $term->readline( "What's the access control list regex? (.*) > " )
						|| ".*";

				print <<EOT;
Serial transport summary
------------------------

name:           $name
port:           $port
csca:           $csca
pincode:        $pincode
baudrate:       $baud
originator:     $originator
memory:         $memory
acl:            $acl

EOT
				$in = $term->readline( 'Is this correct? (y/n) > ' );
			} while ( $in =~ /n/i );
	
			append_to_config(<<EOT

'$name' => [
			{
			'type' => 'Serial',	
			'name' => '$name',
			'pin-code' => '$pincode',
			'csca' => '$csca',
			'serial-port' => '$port',
			'baud-rate' => '$baud',
			'originator' => '$originator',
			'match' =>	'$acl',
			'memorylimit' => '$memory'
			}
		   ],
EOT
			);

			print "Serial $name saved\n\n";
			$in = $term->readline( 'Do you want to configure another serial transport? (y/n) > ');
		} while ( $in =~ /y/i );

}


sub config_transport_novelsoft {
	my ($user, $password, $proxy, $acl, $originator);
	do {
		$user = $term->readline( "What's your account name? > " );
		$password = $term->readline( "What's your account password? > " );
		$proxy = $term->readline( "Give url of http proxy, if any. > " );
		$originator = $term->readline( "What's the originator? (GSM::SMS) > " )
						|| "GSM::SMS";
		$acl = $term->readline( "What's the access control list regex? (.*) > " )
						|| ".*";


		print <<EOT;
Novelsoft summary
-----------------

user:         $user
password:     $password
proxy:        $proxy
originator:   $originator
acl:          $acl
		
EOT

		$in = $term->readline( 'Is this correct? (y/n) > ' );
	} while ( $in =~ /n/i );
	append_to_config(<<EOT
'NovelSoft' => [
				{
				'type' => 'NovelSoft',
				'name' => 'NovelSoft',
				'proxy' =>	'$proxy',
				'userid' => '$user',
				'password' => '$password',
				'originator' => '$originator',
				'smsserver' =>	'http://clients.sms-wap.com:80/cgi/csend.cgi',
				'backupsmsserver' => 'http://clients.sms-wap.com:80/cgi/csend.cgi',
				'match' =>	'$acl'
				}
			   ],

EOT
	);
	print "Novelsoft config saved.\n";
}


sub config_transport_mcube {
	my ($user, $password, $proxy, $acl, $originator);
	do {
		$user = $term->readline( "What's your account name? > " );
		$password = $term->readline( "What's your account password? > " );
		$proxy = $term->readline( "Give url of http proxy, if any. > " );
		$originator = $term->readline( "What's the originator? (GSM::SMS) > " )
						|| "GSM::SMS";
		$acl = $term->readline( "What's the access control list regex? (.*) > " )
						|| ".*";

		print <<EOT;
MCube summary
-------------

user:         $user
password:     $password
proxy:        $proxy
originator:   $originator
acl:          $acl
		
EOT

		$in = $term->readline( 'Is this correct? (y/n) > ' );
	} while ( $in =~ /n/i );
	append_to_config(<<EOT

'MCube' => [
			{
			'type' => 'MCube',
			'name' => 'MCube',
			'proxy' =>	'$proxy',
			'userid' => '$user',
			'password' =>	'$password',
			'originator' => '$originator',
			'smsserver' =>	'http://www.m3.be/scripts/httpgate1.cfm',
			'match' =>	'$acl'
			}
		   ],
EOT
	);
	print "MCube config saved.\n\n";
}


sub config_transport_file {
	my ($acl, $originator, $directory);

	do {
		$directory = $term->readline( "Directory to put the files (/tmp/filetransport) > " )
				|| "/tmp/filetransport";
		create_directory( $directory ) unless (stat($directory));

		$originator = $term->readline( "What's the originator? (GSM::SMS) > " )
				|| "GSM::SMS";
		$acl = $term->readline( "What's the access control list regex? (.*) > " )
				|| ".*";

		print <<EOT;
File transport summary
----------------------

out directory: $directory
originator:    $originator
acl:           $acl
		
EOT

		$in = $term->readline( 'Is this correct? (y/n) > ' );
	} while ( $in =~ /n/i );
	append_to_config(<<EOT

'File' => [
			{
			'type' => 'File',
			'name' => 'File',
			'out_directory' => '$directory',
			'originator' => '$originator',
			'match' =>	'$acl'
			}
		  ],
EOT
	);
	print "File transport config saved.\n\n";
}

sub append_to_config {
	my ($cfg) = @_;

	local (*F);
	open F, '>>./SMS/Config/Default.pm';
	print F $cfg;	
	close F;
}

sub write_to_config {
	my ($cfg) = @_;

	local (*F);
	open F, '>./SMS/Config/Default.pm';
	print F $cfg;	
	close F;
}
sub create_directory {
	my ($dir) = @_;
	
	print "The directory <$dir> does not exist.\n";
	my $yn;
	do {
		$yn = $term->readline( "Do you want to create it? (y/n) > ");
	} while ( $yn !~ /[nNyY]/ );
	mkpath( $dir, 1, 0777) if ( $yn =~ /y/i );	
}
