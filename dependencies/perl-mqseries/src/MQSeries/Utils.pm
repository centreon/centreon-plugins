#
# $Id: Utils.pm,v 33.11 2012/09/26 16:15:20 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Utils;

use 5.008;

use strict;
use Carp;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ConvertUnit);
our $VERSION = '1.34';

#
# Convert a Unit value from a symbolic value to the value
# that MQ expects.
#
# Parameters:
# - Name: 'Wait' / 'Expiry'
# - Value: number / number + 's' for seconds / number + 'm' for minutes
# Returns:
# - Numeric value
#
sub ConvertUnit {
    my ($name, $value) = @_;

    my $numeric_patt = '(?:-?[\d_.]+)';
    if ($name eq 'Wait' || $name eq 'Expiry') {
        #
        # Wait is in milli-seconds, Expiry in tenths of a second
        #
        my $scale = ($name eq 'Wait' ? 1000 : 10);
        if ($value =~ m!^$numeric_patt$!) { 
            # Nothing to be done
        } elsif ($value =~ m!^($numeric_patt)s$!) {
            # Times <scale>
            $value = $1 * $scale;
        } elsif ($value =~ m!^($numeric_patt)m$!) {
            # Times 60 * <scale>
            $value = $1 * 60 * $scale;
        } else {
            die "Invalid '$name' value '$value'";
        }
    } else {
        die "Unsupported unit '$name'";
    }
    return $value;
}


1;


__END__

=head1 NAME

MQSeries::Utils - Internal utility functions

=head1 SYNOPSIS

  use MQSeries::Utils qw(ConvertUnit);

  my $wait_value = ConvertUnit('Wait', '45s');
  my $exp_value = ConvertUnit('Expiry', '1.5m');

=head1 DESCRIPTION

The MQSeries::Utils module contains internal helper functions that are
generally not of interest to users of the MQSeries module.

=head1 FUNCTIONS

=head2 ConvertUnit

This function can convert values for the 'Wait' and 'Expiry' options
from symbolic values into the numeric values required. Symbolic values
are numeric values ending in an 's' for seconds or an 'm' for minutes.

As 'Wait' values are in 1/1000 of a second and 'Expiry' is in 1/10 of
a second, using symbolic values can help avoid mistakes such as
getting the magnitude of these numbers wrong by one or more orders of
magnitude.

=head1 SEE ALSO

MQSeries(3)

=cut
