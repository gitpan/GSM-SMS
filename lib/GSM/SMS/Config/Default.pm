package GSM::SMS::Config::Default;

$Config = {	
	'default' => [
					{
					'router' => 'Simple',
					'spooldir' => '/var/spool/gsmsms',
					'log' => '/var/log/gsmsms',
					'testmsisdn' => '+32475567606'
					}
				 ],

'serial01' => [
			{
			'type' => 'Serial',	
			'name' => 'serial01',
			'pin_code' => '6023',
			'csca' => '+32475161616',
			'serial_port' => '/dev/ttyS0',
			'baud_rate' => '9600',
			'originator' => 'GSM::SMS',
			'match' =>	'.*',
			'memorylimit' => '10'
			}
		   ],

'File' => [
			{
			'type' => 'File',
			'name' => 'File',
			'out_directory' => '/tmp/filetransport',
			'originator' => 'GSM::SMS',
			'match' =>	'.*'
			}
		  ],

	};
1;
