use strict;
use Test::More tests => 2;

BEGIN {
	use_ok( 'GSM::SMS::OTA::RTTTL' );
}

my $rtttl = "AxelF:d=4,o=5,b=125:32p,8g,8p,16a#.,8p,16g,16p,16g,8c6,8g,8f,8g,8p,16d.6,8p,16g,16p,16g,8d#6,8d6,8a#,8g,8d6,8g6,16g,16f,16p,16f,8d,8a#,2g,p,16f6,8d6,8c6,8a#,g,8a#.,16g,16p,16g,8c6,8g,8f,g,8d.6,16g,16p,16g,8d#6,8d6,8a#,8g,8d6,8g6,16g,16f,16p,16f,8d,8a#,2g";

my $correct = "024A3A5505E195B1180400A698E490A1861061B8906188108188288B12618598618418A271490618810818828A309B126D8618A26C30C49881681081681361B618210428B409B08B126D86106DA620420620A22C4986166184289B52620420620A28C26C49B6186289B0C3126205A04205A04D86D8608000";

my ($stream, $count) = GSM::SMS::OTA::RTTTL::OTARTTTL_makestream( $rtttl );

is( $stream, $correct, "Compare makestream to valid stream" );
