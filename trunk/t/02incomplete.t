#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;
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
    my $dti_half;

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


    # Tests is_undef, false

    is( $dti->is_undef , 0,
        'not undef' );

    $dti_half = $dti->clone;   # a half-defined datetime
    my $dt2 = $dti_half->to_datetime( base => $dt );
    is( $dt->datetime , $dt2->datetime,
        'to_datetime' );


    # Tests contains

    is( $dti->contains( $dt2 ), 1,
        'contains' );
    $dt2->add( hours => 1 );
    is( $dti->contains( $dt2 ), 0,
        'does not contain' );


    # undef time

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

    # Tests is_undef, true

    is( $dti->is_undef , 1,
        'is undef' );

    # TESTS TODO:
    # set_time_zone, time_zone
    #   -- together with contains() and to_datetime()

}

1;

