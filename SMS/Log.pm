package GSM::SMS::Log;
use Time::localtime;

# Very simple logger
# 

use Exporter;
@ISA = ('Exporter');
@EXPORT = qw( logentry );
$VERSION = '0.1';

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	$self->{'__LOGFILE__'} = shift;
	bless($self, $class);
	return $self;
}

sub logentry {
	my ( $self, $text ) = @_;
	local (*F);

	my $LOGFILE = $self->{'__LOGFILE__'};
	if ( $LOGFILE ne "" ) {
		
		open F, ">>$LOGFILE";
		my $tm = localtime(time);
		print F sprintf("[%02d/%02d/%02d %02d:%02d:%02d]\t%s\n", 
						$tm->mday, 
						$tm->mon+1,
						$tm->year+1900,
						$tm->hour,
						$tm->min,
						$tm->sec,
						$text
					   );
		close F;

	}
}

1;

=head1 NAME

GSM::SMS::Log

=head1 DESCRIPTION

Implements a simple logger.

=head1 AUTHOR

Johan Van den Brande <johan@vandenbrande.com>
