#
# MQSeries::FDC::Parser.pm - Break an FDC log into chunks, then
#                            create FDC::Entry objects from those chunks.
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Parser.pm,v 33.11 2012/09/26 16:15:14 jettisu Exp $
#

package MQSeries::FDC::Parser;

use strict;
use Carp;

use MQSeries::FDC::Entry;

our $VERSION = '1.34';

#
# Constructor
# Parameters:
# - Class name
# - Filename
# Returns:
# - New MQSeries::FDC::Parser object
#
sub new {
    my ($class, $filename) = @_;

    my $this = { 'filename' => $filename, 'data' => '' };
    return bless $this, $class;
}


#
# Break a chunk of text into logical entries
#
# Parameters:
# - MQSeries::FDC::Parser object
# - Text from FDC file (with one or more errors)
# Returns:
# - MQSeries::FDC::Entry objects created
#
sub parse_data {
    my ($this, $text) = @_;

    #
    # We may have residual data from a previous invocation
    # If so, pre-pend it to the text to be parsed this time.
    #
    if ($this->{'data'}) {
        $text = $this->{'data'} . $text;
        $this->{'data'} = '';
    }

    my @entries;
    my @chunks = split /\n(?=\+\-+\+\n.*\n\| (?:MQSeries|WebSphere MQ) First Failure)/, $text;
    #print "Have [" . @chunks . "] FDC chunks\n";

    #
    # We need to be able to tell something going wrong
    # in the last chunk. Hence the unusual array traversal.
    #
    foreach my $idx (0..$#chunks) {
        my $entry = eval { $this->parse_one_chunk( $chunks[$idx] ) };
        if ($@) {
            #carp "Invalid chunk in [$this->{'filename'}]: $@";
        } elsif (defined $entry) {
            push @entries, $entry;
        } elsif ($idx == $#chunks) { # Last chunk, undefined
            $this->{'data'} = $chunks[$idx];
        } else {
            carp "Incomplete data, but not last chunk in [$this->{'filename'}]";
        }
    }

    return @entries;
}


#
# CLASS METHOD: Parse one FDC chunk
#
# Parameters:
# - MQSeries::FDC::Parser object
# - Chunk of FDC data
# Returns:
# - MQSeries::FDC::Entry object
#   - undef if incomplete
#   - confess'es if invalid
#
sub parse_one_chunk {
    my ($this, $data) = @_;

    #
    # To be valid, the data must start with
    # a line of '+-----....----+'
    #
    if ($data !~ m!^\+--+\+\s*\n!) {
        confess "Invalid start in chunk [$data]";
    }

    #
    # We assume the data is complete if we have
    # the start line, the '===' line, some data, and another
    # line with dashes.  If the data is incomplete, we return undef.
    #
    if ($data !~ m!^\+----+\+\s*\n[\w\|\s]+=====+.*\n\+----+\+\s*\n!s) {
        #print "Chunk seems incomplete in [$data]\n";
        return;
    }

    #
    # The chunk of data contains a header with (logical)
    # key/value pairs, where the value may span multiple lines;
    # and a completely arbitrary body.
    #
    if ($data !~ m!======\s*\|(.*)\+-+\+\s+(.*)$!s) {
        confess "Cannot parse chunk [$data]";
    }
    my ($header, $body) = ($1, $2);
    my $fields = {};
    my $end = "\n| end :- ";
    $header .= $end;            # Fake end to make parsing easier
    while ($header =~ m!^\| ([\w\s\-\/]+)\s+:-\s+(.*?)(?=\n\|[\w\-\s]+\s+:- )!msgc) {
        my ($field, $data) = ($1, $2);
        $field =~ s!\s*$!!;
        $data =~ s!\s+\|\s*\n\s*\|\s*! !g;
        $data =~ s![\s\|]*$!!;
        $fields->{$field} = $data;
    }
    if (substr($header, pos($header)) ne $end) {
        confess "Could not parse remainder [" . substr($header, pos($header)) .
          "]";
    }

    return MQSeries::FDC::Entry->new('fields' => $fields, 'body' => $body);
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::FDC::Parser -- Parse a portion of an MQSeries FDC file and return parsed Entry objects.

=head1 SYNOPSIS

  use MQSeries::FDC::Parser;

  my $parser = MQSeries::FDC::Parser->new("AMQ09151.0.FDC");
  open (FDC, '<', "/var/mqm/errors/AMQ09151.0.FDC");
  local $/;
  my @entries = $parser->parse_data(<FDC>);
  close FDC;

=head1 DESCRIPTION

The MQSeries::FDC::Parser class is typically not used directly, but
invoked through the MQSeries::FDC::Tail class.  When used directly, it
can be used to parse a (possibly archived) FDC file and return an
array of neatly-parsed MQSeries::FDC::Entry objects.

This class will try and deal with the vagaries of error-log
processing, chief of which is that the MQSeries FDC is not written to
in an atomic fashion, meaning that some error-log entries may be
incomplete.  In this case, the incomplete part is saved and prefixed
to the data supplied in the next call.  For this reason, you must
create an individual Parser object for each file that is processed.

=head1 METHODS

=head2 new

Create a new MQSeries::ErrorLog::Parser object.  The constructor
takes the filename as its argument; this filename is only
used for error messages.

=head2 parse_data

Parse a chunk of text with one or more FDC entries and
return individual parsed entries.

=head1 SEE ALSO

MQSeries(3), MQSeries::FDC::Tail(3), MQSeries::FDC::Entry(3)

=cut
