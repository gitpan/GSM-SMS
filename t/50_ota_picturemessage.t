use strict;
use Test::More tests => 3;

BEGIN {
	use_ok( 'GSM::SMS::OTA::PictureMessage' );
}

my $text = 'Just a test';

# 1. test the 'fromfile'
my $stream = GSM::SMS::OTA::PictureMessage::OTAPictureMessage_fromfile( $text, "t/test_72x28.gif" );

my $test_stream = "3000000B4A757374206120746573740200FF00481C01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00060007F81FC0007C30C30783F1C1C3183CF9F38FE3E3F18F1F3DF9F98FF9E7F99F1FBFF9FD8FFDC7FCBF1F9FF9FF8FBFC3FFFF1FFFF9FF8F3FE1FFFF1FFFF9FF8F3FF01FFF1FFFF9FF803FF803FF1FFFF9FF8F3FFF00FF1FFFF9FF8F3FFFF07F1FFFF9FF8FBFFFFC7F1FFFF9FF8FFEDFFC7F1FFFF9FF8FFCCFFC7F1FFFF9FF8FF9CFFC7F1FFFF9FF8FF1C7F8FF1FFFF0FF8FC1E1F1FF1FFFC03E0003EC03FC03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

my $test_stream_inv = "3000000B4A757374206120746573740200FF00481C010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001FFF9FFF807E03FFF83CF3CF87C0E3E3CE7C3060C701C1C0E70E0C206067006180660E04006027002380340E060060070403C0000E000060070C01E0000E000060070C00FE000E00006007FC007FC00E000060070C000FF00E000060070C0000F80E00006007040000380E00006007001200380E00006007003300380E00006007006300380E0000600700E380700E0000F00703E1E0E00E0003FC1FFFC13FC03FC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

ok( $stream eq $test_stream || $stream eq $test_stream_inv, "Compare 'fromfile' to test stream" );

# 2. test the 'fromb64'
my $b64image = <<EOT;
R0lGODlhSAAcAIAAAP///wAAACwAAAAASAAcAAACs4yPqcvtD6OctNqLs968ewiE4jga5Cky
54K2SRnAMmzSR1rjMc7b4QsA3n4KXa5INBp3iKDwuWw6ayoncTi9Pa7NY2MaHcaQWeq3DCyj
c+stV/JOS89xd9tRx87pNrolz0Zit+JXAbiTdShFSPZ3h7hHIdho+Lj0iFcX5paJaWXHohja
mWlWtbZZWjhqGooqikTqqjdbO9G3SMbVl5qqy9vCaBK46fJxjJysvMzc7PwMHVEAADs=
EOT

$stream = GSM::SMS::OTA::PictureMessage::OTAPictureMessage_fromb64( $text, $b64image, 'gif' );

ok( $stream eq $test_stream || $stream eq $test_stream_inv, "Compare 'fromb64' to test stream" );