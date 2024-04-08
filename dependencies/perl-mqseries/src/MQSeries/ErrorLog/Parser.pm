#
# MQSeries::ErrorLog::Parser.pm - Parse error-log files into error-log
#                                 entry objects
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Parser.pm,v 38.2 2012/09/26 16:15:12 jettisu Exp $
#

package MQSeries::ErrorLog::Parser;

use strict;
use Carp;
use Time::Local;

use MQSeries::ErrorLog::Entry;

#
# Load a file with error-descriptions, available as
# the variable 'error_table'.
#
our $error_table;
require "MQSeries/ErrorLog/descriptions.pl";

our $VERSION = '1.34';

#
# Constructor
# Parameters:
# - Class name
# - Hash with optional arguments:
#   - 'default' => default values for Entry object (e.g. QMgr => abc)
#   - 'Carp'    => complaints routine (default: carp)
# Returns:
# - New MQSeries::ErrorLog::Parser object
#
sub new {
    my ($class, %args) = @_;

    my $dfts = $args{'defaults'} || {};
    my $carp = $args{'Carp'} || \&carp;

    my $this = { 'defaults' => $dfts,
                 'Carp' => $carp,
               };
    return bless $this, $class;
}


#
# CLASS METHOD: break a chunk of text into logical entries
#
# Parameters:
# - MQSeries::ErrorLog::Parser object
# - Text from ErrorLog file (with one or more errors)
# Returns:
# - MQSeries::ErrorLog::Entry objects created
#
sub parse_data {
    my ($this, $text) = @_;
    confess "Illegal no of args" unless (@_ == 2 && defined $text);

    my @entries;
    my @chunks = split /\n----+(?: [\w.]+ : \d+ ----+)?\n/, $text;
    #print "Have [" . @chunks . "] chunks\n";
    foreach (@chunks) {
        #
        # Illegally formatted events cause this guy to blow up...
        #
        eval { my $entry = $this->parse_one_chunk($_);
               push @entries, $entry if (defined $entry);
           };

        # DEBUG CODE - this finds ill-formatted entries
        if ($@) {
            $this->{'Carp'}->("Parse error: $@\n");
        };

    }

    return @entries;
}


# DEBUG HELP - issue a warning only once per event type
my %warnings;


#
# CLASS METHOD: Parse one ErrorLog chunk
#
# Parameters:
# - MQSeries::ErrorLog::Parser object
# - Chunk of ErrorLog data
# Returns:
# - MQSeries::ErrorLog::Entry object
#
sub parse_one_chunk {
    my ($this, $chunk) = @_;

    #
    # Deal with catastrophic errors - if MQSeries cannot
    # write the message due to missing message catalog files,
    # don't bother to try and parse it.
    #
    if ($chunk =~ /MQSeries was unable to open a message catalog to display an error message for/) {
        return;
    }

    #
    # Apparently, MQSeries doesn't always do proper atomic writes
    # of entire error-log entries.  Try and look for the most
    # common errors and don't try and parse the chunk if there are
    # obvious errors.
    #
    if ($chunk =~ m!^\d\d/\d\d/\d\d\s+\d\d/\d\d/\d\d\s+\d\d:\d\d:\d\d\s!s ||
        $chunk =~ m!\nACTION:?\n.*\nACTION:?\n!s ||
        $chunk =~ m!\nEXPLANATION:?\n.*\nEXPLANATION:?\n!s ||
        $chunk =~ m!\nAMQ\d\d\d\d.*\nAMQ\d\d\d\d!s ||
        $chunk =~ m!^(.+\n)(?=\d\d/\d\d/\d\d\s+\d\d:\d\d:\d\d\s*AMQ)!s) {
        #carp "Invalid chunk: $chunk\n";
        $this->{'invalid'}++;
        return;
    }

    #
    # Break the chunk into:
    # - timestamp
    # - event code
    # - summary
    # - explanation
    # - action
    # - set of parsed fields (initialized fron class defaults)
    #
    my $data = { };

    #
    # Handle timestamp
    #
    # NOTE: Depending on the MQSeries release, the text of the
    #       error code & summary may or may not start on the next line.
    #
    # Thanks to Mike Carr [mcarr@qualcomm.com] for pointing this out.
    # Added support for multiple time stamp formats - depending on LOCALE settings.
    # Also to handle WMQ6.0 errorlog format.
    #
    #                1 2      3      4           5      6      7         8
    if ($chunk =~ m!^((\d\d)/(\d\d)/(\d{2,4})\s+(\d\d):(\d\d):(\d\d))\s+([AaPp][Mm]|)([\w\-\(\)\.\s]*)(?=\n|AMQ)!g) {
        $data->{'timestamp'} = $1;
        my $hour = $5;
        if ($8 ne '') {
           my $am_pm = $8;
           if ($am_pm =~ m!AM!i && $hour eq "12") {
              $hour = 0;
           } elsif ($am_pm =~ m!PM!i && $hour ne "12") {
              $hour += 12;
           }
        }
        $data->{'ctime'} = timelocal($7, $6, $hour, $3, $2-1, $4);
    } else {
        confess "Cannot parse timestamp in [$chunk]";
    }

    # Handle error code and summary
    if ($chunk =~ m!\G\s*(AMQ\d+):\s+(.*?)\s*\n\s*\n(?=EXPLANATION:?\s+)!gs) {
        $data->{'error_code'} = $1;
        $data->{'summary'} = $2;
        $data->{'summary'} =~ s!\s+! !g;
    } else {
        confess "Cannot parse summary in [$chunk]";
    }

    #
    # Get explanation
    # NOTE: Depending on the MQSeries release, the
    #       explanation text may or may not start on the next line.
    #
    if ($chunk =~ m!\GEXPLANATION:?\s+(.*?)\n(?=ACTION:?\s+)!gs) {
        $data->{'explanation'} = $1;
        $data->{'explanation'} =~ s!\s+! !g;
    } else {
        confess "Cannot parse explanation in [$chunk]";
    }

    #
    # Get action
    # NOTE: Depending on the MQSeries release, the
    #       action text may or may not start on the next line.
    #
    if ($chunk =~ m!\GACTION:?\s+(.*)$!gs) {
        $data->{'action'} = $1;
        $data->{'action'} =~ s!\s+! !g;
    } else {
        confess "Cannot parse action in [$chunk]; next is [" .
          substr($chunk, pos($chunk), 50) . "]";
    }

    #
    # Every description in the error-table is basically
    # a string with a regexp, plus a list of field-names
    # for the first, second, etc parenthesis-group in the regexp.
    #
    my $desc = $error_table->{ $data->{'error_code'} };

    if ($desc) {
        $chunk =~ s!\s+! !g; # Normalize to undo line-wrapping
        my $match = 0;
        my $fields = $data->{'fields'} = { %{ $this->{'defaults'} } };
        #
        # Thanks to Michael Fowler <michael@shoebox.net> for a comment
        # that the regular expression should be evualated in an array
        # context.  Earlier code was using a for-loop and symbolic
        # references for $1, $2, $3, ...
        #
        if (my @entries = ($chunk =~ m!$desc->[0]!)) {
            foreach my $fld (@{$desc}[1..$#$desc]) {
                my $val = shift @entries;
                $fields->{$fld} = $val if (defined $val);
            }

            #
            # For TCP/IP errors, split 'Host' field into either:
            # - 'HostName', 'IPAddress' and 'IPPort'
            # - 'HostName' and 'IPAddress'
            # - 'IPAddress' and 'IPPort'
            # - 'IPAddress'
            # depending on how much is available
            #
            if (defined $fields->{'Host'}) {
                if ($fields->{'Host'} =~ m!^(\S+)\s+\((\d+\.\d+\.\d+\.\d+)\)\s+\((\d+)\)$!) {
                    $fields->{'HostName'} = $1;
                    $fields->{'IPAddress'} = $2;
                    $fields->{'IPPort'} = $3;
                } elsif ($fields->{'Host'} =~ m!^(\d+\.\d+\.\d+\.\d+)\s+\((\d+)\)$!) {
                    $fields->{'IPAddress'} = $1;
                    $fields->{'IPPort'} = $2;
                } elsif ($fields->{'Host'} =~ m!^(\S+)\s+\((\d+\.\d+\.\d+\.\d+)\)$!) {
                    $fields->{'HostName'} = $1;
                    $fields->{'IPAddress'} = $2;
                } elsif ($fields->{'Host'} =~ m!^(\d+\.\d+\.\d+\.\d+)$!) {
                    $fields->{'IPAddress'} = $1;
                } else {
                    confess "Cannot parse field 'Host' ($fields->{'Host'})";
                }
                delete $fields->{'Host'};
            }
        } else {
            unless ($warnings{ $data->{'error_code'} }++) {
                $this->{'Carp'}->("Cannot match for event [$data->{'error_code'}] and text [$chunk] with available error description [$desc->[0]]");
            }
        }
    }

    my $entry = MQSeries::ErrorLog::Entry->new(%$data);

    #
    # Issue a warning if the event code is not known (no detailed view) -
    # using the event class' own methods
    #
    unless (defined $desc) {
        unless ($warnings{ $data->{'error_code'} }++) {
            $this->{'Carp'}->("WARNING: Unknown error " .
                              $entry->display_raw() . "\n");
        }
    }

    return $entry;
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::ErrorLog::Parser -- Parse a portion of an MQSeries error log and return parsed Entry objects.

=head1 SYNOPSIS

  use MQSeries::ErrorLog::Parser;

  my $qmgr = 'foo';   # Queue Manager we are processing
  my $parser = MQSeries::ErrorLog::Parser->
    new('defaults' => { 'QMgr' => $qmgr });
  open (ERRORS, '<', "/var/mqm/qmgrs/$qmgr/errors/AMQERR01.LOG");
  local $/;
  my @entries = $parser->parse_data(<ERRORS>);
  close ERRORS;

=head1 DESCRIPTION

The MQSeries::ErrorLog::Parser class is typically not used directly,
but invoked through the MQSeries::ErrorLog::Tail class.  When used
directly, it can be used to parse a (possibly archived) error-log file
and return an array of neatly-parsed MQSeries::ErrorLog::Entry
objects.

This class will try and deal with the vagaries of error-log
processing, chief of which is that the MQSeries error-log is not
written to in an atomic fashion, meaning that some error-log entries
may be interleaved and hence un-parseable.

All error-log entries can be parsed to some extent (summary, action,
timestamp); however, most common error messages are also parsed in
detail to give access to embedded fields such as 'QMgr', 'Channel',
'Queue', etc.

=head1 METHODS

=head2 new

Create a new MQSeries::ErrorLog::Parser object.  The constructor
take the following optional parameters:

=over 4

=item Carp

A reference to an error-handling routine.  This defaults
to 'carp', but can be changed to your own error-handling routine.

In order to avoid overloading the system with error messages,
message format errors are not logged and errors for specific
error-log messages are generated only once for each message code.

=item defaults

A reference to a hash with default parameters that will be used
to initialize the MQSeries::ErrorLog::Entry object created.
A typical default parameter is 'QMgr', which should be specified
whenever you are parsing error-log messages for a specific
queue manager.

=back

=head2 parse_data

Parse a chunk of text with one or more error messages and
return individual parsed entries.

=head1 FILES

The file 'descriptions.pl' contains a list of all error messages
supported, in the form of regular expressions and a set of field
names extracted from these expressions.  Additions and corrections
are welcome.

=head1 SEE ALSO

MQSeries(3), MQSeries::ErrorLog::Tail(3), MQSeries::ErrorLog::Entry(3)

=cut
