#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use DateTime;
use DateTime::Incomplete;

{
    my $dti;
    my $dt = DateTime->new( year => 2003 );
    my $error;

    $dti = DateTime::Incomplete->new( 
        year =>   $dt->year,
        month =>  $dt->month,
        day =>    $dt->day,
        hour =>   $dt->hour,
        minute => $dt->minute,
        second => $dt->second,
        nanosecond => $dt->nanosecond,
    );

    is( $dti->day_name , $dt->day_name, 
        'DTI->day_name matches DT->day_name' );

    $dti->set( year => undef );
    ok( ! defined $dti->day_name ,
        'day_name checks for valid parameter' );

    is( $dti->offset , $dt->offset,
        'DTI->offset matches DT->offset' );

    $dt->set_time_zone( 'America/Chicago' );
    $dti->set_time_zone( 'America/Chicago' );
    is( $dti->offset , $dt->offset,
        'DTI->offset matches DT->offset' );

    $dti->set( year => undef );
    ok( ! defined $dti->is_leap_year ,
        'is_leap_year checks for valid parameter' );
}

1;

