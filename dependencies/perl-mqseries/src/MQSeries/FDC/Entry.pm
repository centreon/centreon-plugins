# MQSeries::FDC::Entry.pm - One entry from an FDC log.
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Entry.pm,v 33.11 2012/09/26 16:15:14 jettisu Exp $
#

package MQSeries::FDC::Entry;

use strict;
use Carp;

use overload ('""'  => 'as_string',
              'cmp' => 'compare',
              '<=>' => 'compare');

our $VERSION = '1.34';

#
# Constructor
#
# Parameters:
# - Class name
# - 'fields' => ref to hash with (field, value) pairs
# - 'body'   => (long) body text
# Returns:
# - MQSeries::FDC::Entry object
#
sub new {
    my ($class, %args) = @_;

    confess "Illegal arguments"
      unless (keys %args == 2 &&
              defined $args{'fields'} && defined $args{'body'});

    my $this = bless \%args, $class;

    # Normalize numeric fields
    foreach my $fld (qw(Process Thread)) {
        next unless (defined $this->{'fields'}{$fld});
        $this->{'fields'}{$fld} += 0;
    }

    #
    # The 'Userid' field, which looks like '012345 (name)',
    # will also be available through 'uid' and 'userid'
    #
    if (defined $this->{'fields'}{'UserID'} &&
        $this->{'fields'}{'UserID'} =~ /^0*(\d+) \((\w+)\)$/) {
        $this->{'fields'}{'uid'} = $1;
        $this->{'fields'}{'userid'} = $2;
    }

    #
    # The event code will be made available from the
    # first bit of the 'Probe Description' field
    #
    if (defined $this->{'fields'}{'Probe Description'} &&
        $this->{'fields'}{'Probe Description'} =~ /^([A-Z][A-Z\d]+):/) {
        $this->{'fields'}{'event_code'} = $1;
    }

    return $this;
}


#
# Access method for header fields.
#
# IBM-defined fields are directly taken from the FDC header,
# and therefore start with a capital letter; derived fields
# are all lower-case.
#
# Parameters:
# - MQSeries::FDC::Entry object
# - Field name
# Returns:
# - Field value
#
sub get_header {
    my ($this, $field) = @_;

    return $this->{'fields'}{$field};
}


#
# Access method for the body (long details from the FDC entry)
#
# Parameters:
# - MQSeries::FDC::Entry object
# Returns:
# - Body text
#
sub get_body {
    my ($this) = @_;

    return $this->{'body'};
}


#
# Display parsed FDC entry
#
# Parameters:
# - MQSeries::FDC::Entry object
# Returns:
# - Descriptive string (multi-lines)
#
sub as_string {
  my ($this) = @_;

  my $retval = "FDC Entry at [" . $this->get_header('Date/Time') . "] with fields:\n";
  #print "All fields: [", join(',', sort keys %{ $this->{'fields'} }), "]\n";
  foreach my $field ('Host Name', 'QueueManager',
                     'Process', 'userid',
                     'Program Name', 'Major Errorcode',
                     'event_code') {
      my $value = $this->get_header($field);
      next unless (defined $value);
      $retval .= "\t$field: $value\n";
  }
  return $retval;
}


#
# Comparison routine - most useful for duplicate filters.
# This compares FDC entries based on the contents of
# the most important; it does not look at the  timestamp.
#
# Parameters:
# - MQSeries::FDC::Entry object (a)
# - MQSeries::FDC::Entry object (b)
# Returns:
# - Comparison value (0 if equal, -1/1 if non-equal)
#
sub compare {
    my ($a, $b) = @_;

    #
    # Compare the most important fields
    #
    foreach my $field ('Host Name', 'QueueManager',
                       'userid', 'Program Name',
                       'Major Errorcode', 'event_code') {
        my $cmp = (($a->get_header($field) || 'unknown') cmp
                   ($b->get_header($field) || 'unknown'));
        return $cmp if ($cmp);
    }

    #
    # If we get here, consider the entries equal
    #
    return 0;
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::FDC::Entry -- One entry in an MQSeries FDC file

=head1 SYNOPIS

  #
  # Assuming we get an array of parsed MQSeries::FDC::Entry
  # objects from somewhere, here's how we dump them to syslog.
  #
  use Sys::Syslog;
  openlog($0, 'pid', 'daemon');

  sub process_fdc_entries {
      foreach my $entry (@_) {
          syslog('info', "$entry"); # Overloaded operator-""
      }
  }


=head1 DESCRIPTION

The MQSeries::FDC::Entry class is not used directly, but invoked
through the MQSeries::FDC::Parser class.

When the MQSeries::FDC::Tail or MQSeries::FDC::Parser
classes return an array of entries, these can be queried for their
parsed fields.

This class has overloaded the '""' (to-string) operator, which means
that printing an object results in reasonable results.

=head1 METHODS

=head2 new

Create a new MQSeries::FDC::Entry object.  The parameters are not
documented; use the MQSeries::FDC::Parser class to create these.

=head2 get_header

Return a field parsed from the header.  Any field from the
header is available directly; in addition, a number of
parsed fields are derived.  Most FDC entries have following
standard fields:

   Date/Time
   Host Name
   QueueManager (sometimes missing)
   PIDS
   LVLS
   Product Long Name
   Vendor
   Probe Id
   Application Name
   Component
   Build Date
   UserID
   Program Name
   Process
   Thread
   Major Errorcode
   Minor Errorcode
   Probe Type
   Probe Severity
   Probe Description
   Comment1

In addition, the following parsed fields are available (these
have all lower-case names):

   uid        (numerical userid from UserID field, if available)
   userid     (text userid from UserID field, if available)
   event_code (event code from Probe Description, if available)

=head2 get_body

Return the body with all details from the FDC entry

=head2 as_string

Return a string with the details of this entry; also invoked by the
overloaded operator-"".

=head1 SEE ALSO

MQSeries(3), MQSeries::FDC::Tail(3), MQSeries::FDC::Parser(3)
