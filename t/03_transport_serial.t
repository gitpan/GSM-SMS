use strict;
use Test::More tests => 5;

# Testing the Serial support.

BEGIN { 
	use_ok( 'GSM::SMS::Transport::Serial' );
	use_ok( 'GSM::SMS::NBS' );
	use_ok( 'GSM::SMS::Config' );
}

# can we correctly instantiate ... problem here is we've a init that
# will actually talk to the serial port ... so we'll skip it for this
# transport ...
=for comments
my $t = GSM::SMS::Transport::Serial->new(
					-name 		=> 'serial',
					-match		=> 'match',
					-originator => 'GSM::SMS',
					-pin_code	=> '0000'
				);
isa_ok( $t, 'GSM::SMS::Transport::Serial' );
=cut

my $cfg;
# Now we can try to actually send a message ... if configured for serial
SKIP: {
	eval {
		$cfg = GSM::SMS::Config->new( -check => 1 );
	};
	skip( "Config hinders test: $@", 2 ) if ($@);

	my $msisdn = $cfg->get_value( 'default', 'testmsisdn' );
	skip( 'No test msisdn', 2 ) unless $msisdn;
	
	my $cfg = GSM::SMS::Config->new( -check => 1 );
	skip( 'Serial not configured', 2 ) unless $cfg->get_config('serial01');

	my $nbs = GSM::SMS::NBS->new( -transport => 'serial01' );
	
	ok( $nbs, 'NBS stack' );
	ok( $nbs->sendSMSTextMessage( $msisdn, 'Hello World from GSM::SMS (serial)' ) != 0, 'Sending a text message');
}
