#!/usr/bin/perl -w

use strict;

use Test::More tests => 9;
use DateTime;
use DateTime::Incomplete;

use vars qw( $UNDEF_CHAR $UNDEF2 $UNDEF4 );
$UNDEF_CHAR = $DateTime::Incomplete::UNDEF_CHAR;
$UNDEF4 = $UNDEF_CHAR x 4;   
$UNDEF2 = $UNDEF_CHAR x 2;  

# Test:
# set( day => 31 )->next( $dt ) might break if $dt is on february.

# Test: require "february" 
{
    my $base = DateTime->new( year => 1970 );

    my $dt_19700131 = $base->clone;
    $dt_19700131->set( month => 1, day => 31 );

    my $dti;
    $dti = DateTime::Incomplete->new( 
        month =>  2,
    );

    my $dt1;
    $dt1 = $dti->next( $dt_19700131 );

    is( $dt1->datetime , '1970-02-01T00:00:00', 
        'next - first date in february is ok' );

    TODO: {
        local $TODO = "needs to change invalid day in order to fit in month";
        $dt1->set( month => 3, day => 31 );
        eval { $dt1 = $dti->previous( $dt1 ) };
        ok( $dt1 && ( $dt1->datetime eq '1970-02-28T59:59:59' ),
            'previous - last day in february' );
    }
}

# Test: require day=30
{
    my $base = DateTime->new( year => 1970 );

    my $dt_19700131 = $base->clone;
    $dt_19700131->set( day => 31 );

    my $dt_19700129 = $base->clone;
    $dt_19700129->set( day => 29 );

    my $dt_19700128 = $base->clone;
    $dt_19700128->set( day => 28 );

    my $dti;
    $dti = DateTime::Incomplete->new(
        day =>  30,
    );

    my $dt1;

    { $dt1 = $dti->next( $dt_19700131 ) };
    is( $dt1->datetime , '1970-03-30T00:00:00',
        'next - skips invalid date (01-31)' );

    { $dt1 = $dti->next( $dt_19700129 ) };
    is( $dt1->datetime , '1970-01-30T00:00:00',
        'next - skips invalid date (01-29)' );

    { $dt1 = $dti->next( $dt_19700128 ) };
    is( $dt1->datetime , '1970-01-30T00:00:00',
        'next - skips invalid date (01-28)' );

    SKIP: {
       skip "previous - Would enter infinite recursion", 1
           if 1;

       $dt1->set( month => 3, day => 10 );
       $dt1 = $dti->previous( $dt1 );
       is( $dt1->datetime , '1970-01-30T23:59:59',
            'previous - skips invalid date' );
    }

    TODO: {
        local $TODO = "day 30 is invalid in february";
        my $dt_19700220 = $base->clone;
        $dt_19700220->set( month => 2, day => 20 );
        eval { $dt1 = $dti->next( $dt_19700220 ) };
        is( $dt1->datetime , '1970-03-30T00:00:00',
            'next - skips invalid date (02-20)' );
    }

    TODO: {
        local $TODO = "invalid DT::I should return undef";

        $dti = DateTime::Incomplete->new(
            month => 2, day =>  30,
        );
        eval { $dt1 = $dti->next( $base ) };
        ok( ! defined $dt1 , 
            'next - invalid incomplete datetime (02-30)' );
        warn "#     ".$dt1->datetime if defined $dt1;

        eval { $dt1 = $dti->previous( $base ) };
        ok( ! defined $dt1 ,
            'previous - invalid incomplete datetime (02-30)' );
        warn "#     ".$dt1->datetime if defined $dt1;
    }

}

1;
