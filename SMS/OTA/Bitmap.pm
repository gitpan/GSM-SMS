package GSM::SMS::OTA::Bitmap;
# Generic package for OTA bitmaps

require Exporter;
@ISA = qw(Exporter);

@EXPORT = qw( BITMAP_WIDTH BITMAP_HEIGHT OTABitmap_makestream OTABitmap_fromfile OTABitmap_fromb64 );

$VERSION = '0.1';

use constant BITMAP_WIDTH  => 72;
use constant BITMAP_HEIGHT => 14;

use MIME::Base64;
use Image::Magick;


sub OTABitmap_makestream {
	my ($width, $height, $depth, $ref_bytearray) = @_;


	my $stream='';

	$stream.= sprintf("%02X", $width);
	$stream.= sprintf("%02X", $height);
	$stream.= sprintf("%02X", $depth);
	foreach my $byte (@$ref_bytearray) {
		$stream.= uc unpack ('H2' , $byte);
	}
	return $stream;
}

sub OTABitmap_fromfile {
	my ($filename) = @_;

	my $image = Image::Magick->new( );
	return -1 unless $image; 

	$image->Read( $filename );

	# check image size
	return -1 unless ( $image->Get('columns') == BITMAP_WIDTH && $image->Get('height') == BITMAP_HEIGHT );

	# convert to monochrome
	$image->Set(magick => 'mono');
	my $monochrome = $image->ImageToBlob( );

	# reverse bitorder
	my @ba;
	foreach my $b ( split //, $monochrome ) {
		my $byte =  reverse(unpack("B8", $b));
		push(@ba, pack("B8", $byte));
	}
	undef $image;	
	return (\@ba);
}

sub OTABitmap_fromb64 {
	my ($b64image, $format) = @_;

	my $blob = decode_base64( $b64image );

	my $image = Image::Magick->new( magick => $format );
	return -1 unless $image; # wrong format ;-)

	$image->BlobToImage( $blob );

	# check image size
	return -1 unless ( $image->Get('columns') == BITMAP_WIDTH && $image->Get('height') == BITMAP_HEIGHT );

	# convert to monochrome
	$image->Set(magick => 'mono');
	my $monochrome = $image->ImageToBlob( );

	# reverse bitorder
	my @ba;
	foreach my $b ( split //, $monochrome ) {
		my $byte =  reverse(unpack("B8", $b));
		push(@ba, pack("B8", $byte));
	}
	undef $image;	
	return (\@ba);
}
1;

=head1 NAME

GSM::SMS::OTA::Bitmap

=head1 DESCRIPTION

Used to create a ota bitmap to use in CLI and OPERATOR logo's. We use the perlinterface to ImageMagick instead of the 'convert' command from the same package.

=head1 METHODS

=head2 OTABitmap_fromb64

	$ref_bitmaparray = OTABitmap_fromb64($bitmap_image_b64, $format_of_image);

Expects a bitmap in base64 format and the format of the image (e.g. 'gif', 'png'). The base64 method is here to be able to use the function in a webcentric way. This way you can e.g. use xmlrpc calls to exchange images for sending via SMS.

=head2 OTABitmap_fromfile

	$ref_bitmaparray = OTABitmap_fromfile($image_file);

Create a bitmap array from a file.

=head2 OTABitmap_makestream

	$stream = OTABitmap_makestream( $width, $height, $depth, $ref_bitmaparray );

Create a OTA Bitmap. Width is 72 and height is 14 pixels, you can find those back in the constants BITMAP_WIDTH and BITMAP_HEIGHT.	

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
