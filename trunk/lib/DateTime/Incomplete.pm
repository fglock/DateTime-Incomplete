package DateTime::Incomplete;

use strict;
use vars qw($VERSION);

use vars qw( $UNDEF_CHAR $UNDEF2 $UNDEF4 );
use vars qw( $CAN_RECURRENCE $RECURRENCE_MODULE );

BEGIN
{
    $VERSION = '0.00_02';

    $UNDEF_CHAR = 'x';
    $UNDEF4 = $UNDEF_CHAR x 4;   # xxxx
    $UNDEF2 = $UNDEF_CHAR x 2;   # xx

    # to_recurrence() method requires a recurrence module.
    # otherwise, it is not necessary.
    $RECURRENCE_MODULE = 'DateTime::Event::Recurrence';
    $CAN_RECURRENCE = 0;
    eval "
        use $RECURRENCE_MODULE;
        \$CAN_RECURRENCE = 1;
    ";
}

# DATETIME-LIKE METHODS


sub new 
{
    # There is not much parameter checking, because we don't know in advance
    # which Calendar will be used. But this may change later.
    my $class = shift;
    my %param = @_;

    # There is no point in accepting 'language', because there is no
    # set_language() method in DateTime (yet)
    die "Parameter 'language' is not supported" if exists $param{language};

    # That's all it takes
    my $self = bless { %param }, $class;
    return $self;
}

sub set
{
    # There is not much parameter checking, because we don't know in advance
    # which Calendar will be used. But this may change later.
    die "set() requires a field name and a value" unless $#_ == 2;
    $_[0]->{ $_[1] } = $_[2];
}

sub set_time_zone
{
    die "set() requires a time_zone value" unless $#_ == 1;
    $_[0]->{time_zone} = $_[1];
}

sub clone { bless { %{ $_[0] } }, ref $_[0] }

sub year       { $_[0]->{year} }
sub month      { $_[0]->{month} }
sub day        { $_[0]->{day} }
sub hour       { $_[0]->{hour} }
sub minute     { $_[0]->{minute} }
sub second     { $_[0]->{second} }
sub nanosecond { $_[0]->{nanosecond} }
sub time_zone  { $_[0]->{time_zone} }


# Internal stringification methods.
# some of these methods are not used, but they are defined just in case.
sub _year       { defined $_[0]->year   ? sprintf( "%0.4d", $_[0]->year )   : $UNDEF4 }
sub _month      { defined $_[0]->month  ? sprintf( "%0.2d", $_[0]->month )  : $UNDEF2 }
sub _day        { defined $_[0]->day    ? sprintf( "%0.2d", $_[0]->day )    : $UNDEF2 }
sub _hour       { defined $_[0]->hour   ? sprintf( "%0.2d", $_[0]->hour )   : $UNDEF2 }
sub _minute     { defined $_[0]->minute ? sprintf( "%0.2d", $_[0]->minute ) : $UNDEF2 }
sub _second     { defined $_[0]->second ? sprintf( "%0.2d", $_[0]->second ) : $UNDEF2 }
sub _nanosecond { defined $_[0]->nanosecond ? sprintf( "%0.9d", $_[0]->nanosecond ) : $UNDEF_CHAR x 9 }

sub ymd
{
    my ( $self, $sep ) = @_;
    $sep = '-' unless defined $sep;
    return $self->_year . $sep. $self->_month . $sep . $self->_day;
}
*date = \&ymd;

sub hms
{
    my ( $self, $sep ) = @_;
    $sep = ':' unless defined $sep;
    return $self->_hour . $sep. $self->_minute . $sep . $self->_second;
}
# don't want to override CORE::time()
*DateTime::Incomplete::time = \&hms;

sub iso8601 { join 'T', $_[0]->ymd('-'), $_[0]->hms(':') }
*datetime = \&iso8601;


# DATETIME::INCOMPLETE METHODS


sub is_undef 
{
    for ( values %{$_[0]} )
    {
        return 0 if defined $_;
    }
    return 1;
}


sub to_datetime
{
    my $self = shift;
    my %param = @_;
    die "no base datetime" unless exists $param{base} && 
                                  UNIVERSAL::can( $param{base}, 'utc_rd_values' );

    my $result = $param{base}->clone;
    my ($key, $value);
    while (($key, $value) = each %$self ) {
        next unless defined $value;
        if ( $key eq 'time_zone' )
        {
            $result->set_time_zone( $value );
            next;
        }        
        $result->set( $key => $value );
    }
    return $result;
}


sub contains
{
    my $self = shift;
    my $dt = shift;
    die "no datetime" unless defined $dt && 
                             UNIVERSAL::can( $dt, 'utc_rd_values' );

    my ($key, $value);
    while (($key, $value) = each %$self ) {
        next unless defined $value;
        if ( $key eq 'time_zone' )
        {
            # TODO! - time_zone is ignored.
            next;
        }        
        return 0 unless $dt->$key == $value;
    }
    return 1;
}


sub to_recurrence
{
    die "to_recurrence() is not available because ".
        $RECURRENCE_MODULE . " is not installed" unless $CAN_RECURRENCE;

    my $self = shift;
    my %param;

    my $freq = '';
    my $year;
    for ( qw( second minute hour day month year ) )
    {
        my $by = $_ . 's';  # months, hours
        if ( exists $self->{$_} && defined $self->{$_} )
        {
            if ( $_ eq 'year' ) 
            {
                $year = $self->{$_};
                next;
            }
            $param{$by} = [ $self->{$_} ];
            next;
        }
        $freq = $_ unless $freq;
        # TODO: use a hash
        $param{$by} = [ 1 .. 12 ] if $_ eq 'month';
        $param{$by} = [ 1 .. 31 ] if $_ eq 'day';
        $param{$by} = [ 0 .. 23 ] if $_ eq 'hour';
        $param{$by} = [ 0 .. 59 ] if $_ eq 'minute';
        $param{$by} = [ 0 .. 59 ] if $_ eq 'second';
    }
    if ( $freq eq '' )
    {
        # it is a single date
        my $dt = DateTime->new( %$self );
        return DateTime::Set->from_datetimes( dates => [ $dt ] );
    }

    # for ( keys %param ) { print STDERR " param $_ = @{$param{$_}} \n"; }

    my $r = yearly $RECURRENCE_MODULE ( %param );
    if ( defined $year ) {
        my $span = DateTime::Span->from_datetimes( 
                       start => DateTime->new( year => $year ),
                       before => DateTime->new( year => $year + 1 ) );
        $r = $r->intersection( $span );
    }
    return $r;
}


1;

__END__

=head1 NAME

DateTime::Incomplete - The partial date & time thing


=head1 SYNOPSIS

  my $dti = DateTime::Incomplete->new( year => 2003 );
  # 2003-xx-xx
  $dti->set( month => 12 );
  # 2003-12-xx
  $dt = $dti->to_datetime( base => DateTime->now );
  # 2003-12-19T16:54:33


=head1 DESCRIPTION

DateTime::Incomplete is a class for representing partial
date and times.

Such values are generated by expressions like '10:30',
'2003', and 'dec-14'.


=head1 DATETIME-LIKE METHODS

=over 4

=item * new()

Creates a new incomplete date:

  my $dti = DateTime::Incomplete->new( year => 2003 );
  # 2003-xx-xx

This class method accepts parameters for each date and
time component: "year", "month", "day", "hour",
"minute", "second", "nanosecond".  Additionally, it
accepts a "time_zone" parameter.

Note: There is no "language" parameter.

C<new> without parameters creates a completely undefined datetime:

  my $dti = DateTime::Incomplete->new();

The parameters can be explicitly undefined:

  my $dti = DateTime::Incomplete->new( year => 2003, day => undef );


=item * set

Use this to define or undefine a datetime field:

  $dti->set( month => 12 );
  $dti->set( day => 24 );
  $dti->set( day => undef );

=item * set_time_zone

This method accepts either a time zone object or a string that can be
passed as the "name" parameter to C<< DateTime::TimeZone->new() >>.

Incomplete dates don't know the "local time" concept:
If the new time zone's offset is different from the old time zone,
no local time adjust is made.


=item * clone

Creates a new object with the same datetime.

=item * year, month, day, hour, minute, second, nanosecond

Return the field value, or C<undef>.

=item * time_zone

This returns the C<DateTime::TimeZone> object for the datetime object,
or C<undef>.

=item * datetime, ymd, date, hms, time, iso8601

These are equivalent to DateTime stringification methods with the same name, 
except that undefined fields are replaced by 'xx' or 'xxxx'.


=back

=head1 DATETIME::INCOMPLETE METHODS

=over 4

=item * is_undef

Returns true if the datetime is completely undefined.

=item * to_datetime

  $dt = $dti->to_datetime( base => DateTime->now );

Returns a "complete" datetime.

The resulting datetime is in the same Calendar as C<base>. 

The following example creates a Julian Calendar date, within
year 1534:

  $dtj = DateTime::Calendar::Julian->new( ... );
  $dti = DateTime::Incomplete->new( year => 1534 );
  $dtj2 = $dti->to_datetime( base => $dtj );
 
The resulting datetime can be either before of after the
C<base> datetime. No adjustments are made, besides setting
the missing fields.

This method may C<die> if it results in a datetime that
doesn't exist.


=item * to_recurrence

  $dti = DateTime::Incomplete->new( month => 12, day => 24 );
  $dtset= $dti->to_recurrence;   # Christmas day recurrence

This method generates the set of all possible datetimes
that fit into an incomplete datetime definition.

Those recurrences are DateTime::Set objects:

  $dt_next_xmas = $dti->to_recurrence->next( DateTime->today );

Recurrence generation has only been tested with
Gregorian dates so far.

This method will die if the
C<DateTime::Event::Recurrence> package is not installed.

Incomplete dates that have the I<year> defined will
generate finite sets. This kind of sets can take a lot of 
resources (RAM and CPU). 
The following datetime would generate the set of all seconds in 2003:

  2003-xx-xxTxx:xx:xx


=item * contains

  $bool = $dti->contains( $dt );

Returns a true value if the incomplete datetime range 
I<contains> a given datetime value.

Note: the incomplete-datetime time-zone value is ignored,
that is, the value of "local time" is compared.
This may lead to unexpected results if the time zone field is set.

For example:

  2003-xx-xx contains 2003-12-24
  2003-xx-xx does not contain 1999-12-14

=back

=head1 TODO - "MAY-BE-USEFUL" METHODS

These are some ideas for new methods, that are not implemented.
Let us know if any of these might be useful for you,
at <datetime@perl.org>.

=over 4

=item * add_datetime

Just like to_datetime, but adds the field values.

=item * compare

or is that simply not defined?

=item * to_spanset

=item * to_span

=item * other C<DateTime> methods

=item * other C<DateTime::Set> methods (next/previous/...)

=item * set_week

$dti->set( week => 10 )


=back


=head1 AUTHORS

Flavio S. Glock <fglock[at]cpan.org>

With Ben Bennett <fiji[at]ayup.limey.net>, 
Eugene Van Der Pijll <pijll[at]gmx.net>,
and the DateTime team.

Some code was just copied from Dave Rolsky C<DateTime> module.

=head1 COPYRIGHT

Copyright (c) 2003 Flavio S. Glock.  All rights reserved.
This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE
file included with this module.

=head1 SEE ALSO

datetime@perl.org mailing list

http://datetime.perl.org/

=cut

