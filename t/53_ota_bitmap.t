use strict;
use Test::More tests => 11;

BEGIN {
	use_ok( 'GSM::SMS::OTA::Bitmap' );
}

my $correct_7214 = "480E0107800000000001F0001FE00000000007FC003FF0000000000FFE007FF8000000000CCE007FC0000000000D5600FF00000000000EEE00FC06318C6318CFFE63FC06318C6318CFFE63FF00000000000FFE007FC0000000000EAE007FF8000000000D56003FF0000000000FFE001FE0000000000CE600078000000000084200";

my $correct_7214_inv = "480E01F87FFFFFFFFFFE0FFFE01FFFFFFFFFF803FFC00FFFFFFFFFF001FF8007FFFFFFFFF331FF803FFFFFFFFFF2A9FF00FFFFFFFFFFF111FF03F9CE739CE730019C03F9CE739CE730019C00FFFFFFFFFFF001FF803FFFFFFFFFF151FF8007FFFFFFFFF2A9FFC00FFFFFFFFFF001FFE01FFFFFFFFFF319FFF87FFFFFFFFFF7BDFF";

my $correct_7228 = "481C01FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE00060007F81FC0007C30C30783F1C1C3183CF9F38FE3E3F18F1F3DF9F98FF9E7F99F1FBFF9FD8FFDC7FCBF1F9FF9FF8FBFC3FFFF1FFFF9FF8F3FE1FFFF1FFFF9FF8F3FF01FFF1FFFF9FF803FF803FF1FFFF9FF8F3FFF00FF1FFFF9FF8F3FFFF07F1FFFF9FF8FBFFFFC7F1FFFF9FF8FFEDFFC7F1FFFF9FF8FFCCFFC7F1FFFF9FF8FF9CFFC7F1FFFF9FF8FF1C7F8FF1FFFF0FF8FC1E1F1FF1FFFC03E0003EC03FC03FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";

my $correct_7228_inv = "481C010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001FFF9FFF807E03FFF83CF3CF87C0E3E3CE7C3060C701C1C0E70E0C206067006180660E04006027002380340E060060070403C0000E000060070C01E0000E000060070C00FE000E00006007FC007FC00E000060070C000FF00E000060070C0000F80E00006007040000380E00006007001200380E00006007003300380E00006007006300380E0000600700E380700E0000F00703E1E0E00E0003FC1FFFC13FC03FC0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

my $b64image_7214 = <<EOT;
R0lGODlhSAAOAIAAAP///wAAACwAAAAASAAOAAACZYQdGcftDyNTSTZKrd4OZ+t93BiF4mOe
5IosQPXCUMrW14K/cRna/qGI4WQdDMq1awGRsibTlYI5PcelVYlNaqXRbPfniyKPPTArmAvy
vuZNJa2d0docscZEH3GhY4kqDzIhCFEAADs=
EOT

my $b64image_7228 = <<EOT;
R0lGODlhSAAcAIAAAP///wAAACwAAAAASAAcAAACs4yPqcvtD6OctNqLs968ewiE4jga5Cky
54K2SRnAMmzSR1rjMc7b4QsA3n4KXa5INBp3iKDwuWw6ayoncTi9Pa7NY2MaHcaQWeq3DCyj
c+stV/JOS89xd9tRx87pNrolz0Zit+JXAbiTdShFSPZ3h7hHIdho+Lj0iFcX5paJaWXHohja
mWlWtbZZWjhqGooqikTqqjdbO9G3SMbVl5qqy9vCaBK46fJxjJysvMzc7PwMHVEAADs=
EOT

my ($ref1, $w1, $h1) = GSM::SMS::OTA::Bitmap::OTABitmap_fromfile( "t/test_72x14.gif" );
is( $w1, 72, "Image width should be 72, got $w1" );
is( $h1, 14, "Image height should be 14, got $h1" );

my ($ref2, $w2, $h2) = GSM::SMS::OTA::Bitmap::OTABitmap_fromfile( "t/test_72x28.gif" );
is( $w2, 72, "Image width should be 72, got $w2" );
is( $h2, 28, "Image height should be 28, got $h2" );

my ($ref3, $w3, $h3) = GSM::SMS::OTA::Bitmap::OTABitmap_fromb64( $b64image_7214, 'gif' );
is( $w3, 72, "Image width should be 72, got $w3" );
is( $h3, 14, "Image height should be 14, got $h3" );

my ($ref4, $w4, $h4) = GSM::SMS::OTA::Bitmap::OTABitmap_fromb64( $b64image_7228, 'gif' );
is( $w4, 72, "Image width should be 72, got $w4" );
is( $h4, 28, "Image height should be 28, got $h4" );

my $stream = GSM::SMS::OTA::Bitmap::OTABitmap_makestream( 72, 14, 1, $ref1 );
ok( $stream eq $correct_7214 || $stream eq $correct_7214_inv, "makestream for 72x14" );

$stream = GSM::SMS::OTA::Bitmap::OTABitmap_makestream( 72, 28, 1, $ref2 );
ok( $stream eq $correct_7228 || $stream eq $correct_7228_inv, "makestream for 72x28" );