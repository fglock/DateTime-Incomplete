use Test::More;
use DateTime;
use DateTime::Incomplete;
use strict;

use vars qw( $UNDEF_CHAR );
$UNDEF_CHAR = 'x';
$UNDEF4 = $UNDEF_CHAR x 4;   # xxxx
$UNDEF2 = $UNDEF_CHAR x 2;   # xx

{
    my $dti;
    $dt = DateTime->new( year => 2003 );
    $str = $dt->datetime;

    $dti = DateTime::Incomplete->new( year => 2003 );
    is( $dti->datetime eq $dt->datetime, 
        'new() matches DT->new' );

    $dti->set( year => undef );
    $str =~ s/^2003/$UNDEF4/;
    is( $dti->datetime eq $str,
        'undef year' );

    $dti->set( month => undef );
    $str =~ s/-01-/-$UNDEF2-/;
    is( $dti->datetime eq $str,
        'undef month' );

    $dti->set( day => undef );
    $str =~ s/-01/-$UNDEF2/;
    is( $dti->datetime eq $str,
        'undef day' );

    $dti->set( hour => undef );
    $str =~ s/01:/$UNDEF2:/;
    is( $dti->datetime eq $str,
        'undef hour' );

    $dti->set( minute => undef );
    $str =~ s/:01:/:$UNDEF2:/;
    is( $dti->datetime eq $str,
        'undef minute' );

    $dti->set( second => undef );
    $str =~ s/:01/:$UNDEF2/;
    is( $dti->datetime eq $str,
        'undef second' );
}

1;

