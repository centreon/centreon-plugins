#
# MQSeries::ErrorLog::Entry.pm - One entry from the ErrorLog
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Entry.pm,v 33.11 2012/09/26 16:15:12 jettisu Exp $
#

package MQSeries::ErrorLog::Entry;

use strict;
use Carp;

use overload ('""'  => 'as_string',
              'cmp' => 'compare',
              '<=>' => 'compare');

our $VERSION = '1.34';

#
# ErrorLog::Entry constructor
#
# Parameters:
# - Class name
# - Hash with structure fields, including optional 'data' hash ref
# Returns:
# - MQSeries::ErrorLog::Entry object
#
sub new {
  my ($class, %data) = @_;

  my $this = \%data;

  #
  # Sometimes we get non-ASCII values in the fields we parse.
  # Typically, this indicates some bad client code handed MQSeries
  # bad data, and IBM faithfully reproduces it in the error-log.
  #
  # However, it screws up our displays - so sanitize it...
  #
  while (my ($fld, $val) = each %{ $this->{'fields'} }) {
      if ($val =~ s/([^\w\s\-\:\.\!\/\(\)])/sprintf("\\0x%02x", ord $1)/eg) {
          #print "Escape field [$fld] from [$this->{'fields'}{$fld}] to [$val]\n";
          $this->{'fields'}{$fld} = $val;
      }
  }

  return bless $this, $class;
}


#
# Get the error-code from the entry
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - Error code (AMQxxxx)
#
sub error_code {
    my ($this) = @_;

    return $this->{'error_code'};
}


#
# Get the original timestamp (in Unix time format) from the entry
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - Timestamp (Unix time format)
#
sub timestamp {
    my ($this) = @_;

    return $this->{'ctime'};
}


#
# Get the summary string from the entry
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - Summary string (no embedded newlines)
#
sub summary {
    my ($this) = @_;

    return $this->{'summary'};
}


#
# Get the contents of a data field (parsed from the contents
# of the ErrorLog entry).
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# - Field name ('Channel', 'Pid', ...)
# - Optional new/replacement value
# Returns:
# - Field value / undef
#
sub field {
    my ($this, $fld, $val) = @_;

    $this->{'fields'}{$fld} = $val if (defined $val);

    return $this->{'fields'}{$fld};
}


#
# Get the list of all fields in the object
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - List of fields
#
sub fields {
    my ($this) = @_;

    return keys %{ $this->{'fields'} };
}


#
# Display parsed entry
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - Descriptive string (multi-lines)
#
sub as_string {
  my ($this) = @_;

  return "Error [$this->{'error_code'}] [$this->{'summary'}] at [" .
    localtime($this->{'ctime'}) . "]\n" .
    join("", map { "\t$_: $this->{'fields'}{$_}\n"
                 } sort keys %{$this->{'fields'}});

}


#
# Debug support method: display raw error details
#
# Parameters:
# - MQSeries::ErrorLog::Entry object
# Returns:
# - Descriptive string (multi-lines)
#
sub display_raw {
  my ($this) = @_;

  return "Error with code [$this->{'error_code'}] and timestamp [" .
    localtime($this->{'ctime'}) . "]\n" .
    "\tSummary: $this->{'summary'}\n" .
    "\tExplanation: $this->{'explanation'}\n" .
    "\tAction: $this->{'action'}\n" .
    "\tFields: " . join(', ', sort keys %{ $this->{'fields'} });
}


#
# Comparison routine - most useful for duplicate filters.
# This compares ErrorLog entries based on their message code
# and the contents of any fields; it does not look at the
# timestamp.
#
# Parameters:
# - MQSeries::ErrorLog::Entry object (a)
# - MQSeries::ErrorLog::Entry object (b)
# Returns:
# - Comparison value (0 if equal, -1/1 if non-equal)
#
sub compare {
    my ($a, $b) = @_;

    #
    # Compare error codes
    #
    my $cmp = ( $a->error_code() cmp $b->error_code() );
    return $cmp if ($cmp);

    #
    # Compare fields in alphabetic order
    # (Required to make any (ill-advised) sort stable)
    #
    foreach my $fld (sort keys %{ $a->{'fields'} }) {
        return 1 unless (defined $b->{'fields'}{$fld});
        $cmp = ($a->{'fields'}{$fld} cmp $b->{'fields'}{$fld});
        return $cmp if ($cmp);
    }
    foreach my $fld (keys %{ $a->{'fields'} }) {
        return 1 unless (defined $a->{'fields'}{$fld});
    }

    #
    # If we get here, consider the entries equal
    #
    return 0;
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::ErrorLog::Entry -- One entry in an MQSeries error-log file

=head1 SYNOPIS

  #
  # Assuming we get an array of parsed MQSeries::ErrorLog::Entry
  # objects from somewhere, here's how we dump them to syslog.
  #
  use Sys::Syslog;
  openlog($0, 'pid', 'daemon');

  sub process_errorlog_entries {
      foreach my $entry (@_) {
          syslog('info', "$entry"); # Overloaded operator-""
      }
  }


=head1 DESCRIPTION

The MQSeries::ErrorLog::Entry class is not used directly, but invoked
through the MQSeries::ErrorLog::Parser class.

When the MQSeries::ErrorLog::Tail or MQSeries::ErrorLog::Parser
classes return an array of entries, these can be queried for their
error-codes, summary, parsed fields, etc.

This class has overloaded the '""' (to-string) operator, which means
that printing an object results in reasonable results.

=head1 METHODS

=head2 new

Create a new MQSeries::ErrorLog::Entry object.  The parameters are not
documented; use the MQSeries::ErrorLog::Parser class to create these.

=head2 error_code

Return the error code (e.g., AMQ9001)

=head2 timestamp

Return the original time-stamp from the entry, in Unix time() format

=head2 summary

Return the original summary

=head2 field

Get (one parameter) or set (two parameters) detailed parsed fields,
such as 'QMgr', 'Channel', 'Host', etc.  See the 'descriptions.pl'
files used by the MQSeries::ErrorLog::Parser class for a list of
supported messages and the fields parsed.

=head2 fields

Get a list of all field names supported by this entry.

=head2 as_string

Return a string with the details of this entry; also invoked by the
overloaded operator-"".

=head1 FILES

The file 'descriptions.pl' contains a list of all error messages
supported, in the form of regular expressions and a set of field
names extracted from these expressions.  Additions and corrections
are welcome.

=head1 SEE ALSO

MQSeries(3), MQSeries::ErrorLog::Tail(3), MQSeries::ErrorLog::Parser(3)

=cut
