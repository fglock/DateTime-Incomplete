#!/usr/bin/perl -w

use strict;

use Test::More tests => 10;
use DateTime;
use DateTime::Incomplete;

use vars qw( $UNDEF_CHAR $UNDEF2 $UNDEF4 );
$UNDEF_CHAR = 'x';
$UNDEF4 = $UNDEF_CHAR x 4;   # xxxx
$UNDEF2 = $UNDEF_CHAR x 2;   # xx

{
    # Tests for new(), set(), datetime()

    my $dti;
    my $dt = DateTime->new( year => 2003 );
    my $str = $dt->datetime;
    my $dti_clone;
    my $str_clone;

    $dti = DateTime::Incomplete->new( 
        year =>   $dt->year,
        month =>  $dt->month,
        day =>    $dt->day,
        hour =>   $dt->hour,
        minute => $dt->minute,
        second => $dt->second,
        nanosecond => $dt->nanosecond,
    );
    is( $dti->datetime , $dt->datetime, 
        'new() matches DT->new' );

    $dti->set( year => undef );
    $str =~ s/^2003/$UNDEF4/;
    is( $dti->datetime , $str,
        'undef year' );

    $dti->set( month => undef );
    $str =~ s/-01-/-$UNDEF2-/;
    is( $dti->datetime , $str,
        'undef month' );

    # Tests clone()

    $dti_clone = $dti->clone;
    $str_clone = $str;

    $dti->set( day => undef );
    $str =~ s/-01/-$UNDEF2/;
    is( $dti->datetime , $str,
        'undef day' );

    is( $dti_clone->datetime , $str_clone,
        'clone has day' );

    # end: Tests clone()

    $dti->set( hour => undef );
    $str =~ s/00:/$UNDEF2:/;
    is( $dti->datetime , $str,
        'undef hour' );

    $dti->set( minute => undef );
    $str =~ s/:00:/:$UNDEF2:/;
    is( $dti->datetime , $str,
        'undef minute' );

    $dti->set( second => undef );
    $str =~ s/:00/:$UNDEF2/;
    is( $dti->datetime , $str,
        'undef second' );

    is( $dti->nanosecond , $dt->nanosecond,
        'def nanosecond' );
    $dti->set( nanosecond => undef );
    ok( ! defined( $dti->nanosecond ),
        'undef nanosecond' );

    # TESTS TODO:
    # set_time_zone, time_zone
    # year, month, day, hour, minute, second

}

1;

