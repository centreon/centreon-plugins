#
# MQSeries::ErrorLog::Tail.pm - Watch the error-log file in a directory
#                               and return parsed ErrorLog::Entry objects
#                               for any new content added.
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Tail.pm,v 33.11 2012/09/26 16:15:13 jettisu Exp $
#

package MQSeries::ErrorLog::Tail;

use strict;
use Carp;
use IO::File;

use MQSeries::ErrorLog::Parser;

our $VERSION = '1.34';

#
# Constructor
#
# Parameters:
# - Class name
# - Directory to watch
# - Hash with optional parameters for ErrorLog::Parser constructor
# Returns:
# - New MQSeries::ErrorLog::Tail object
#
sub new {
    my ($class, $dirname, @rest) = @_;

    # Paranoia...
    confess "Invalid number of arguments" unless (@_ >= 2);
    confess "Invalid directory [$dirname]" unless (-d $dirname);

    my $parser = new MQSeries::ErrorLog::Parser(@rest);
    my $this = { 'directory' => $dirname,
                 'parser'    => $parser };

    #
    # Establish a baseline for the error-log file
    # (open filehandle, size, inode-number)
    #
    $this->{'filename'} = "$dirname/AMQERR01.LOG";
    if (-f $this->{'filename'}) {
        my $fh = IO::File->new($this->{'filename'}) ||
          confess "Cannot open file [$this->{'filename'}]: $!";
        my ($inode, $size) = (stat _)[1,7];
        $this->{'file'} = { 'inode' => $inode,
                            'fh'    => $fh,
                            'size'  => $size,
                          };
    }

    return bless $this, $class;
}


#
# Detect any change in the error-log file and invoke the
# parser on the changed data.  If this routine is called
# regularly, that data will typically be one error-message;
# however, it may be more.  The MQSeries::ErrorLog::Parser
# class handles these one-or-more message chunks properly.
#
# Parameters:
# - MQSeries::ErrorLog::Tail object
# Returns:
# - List of MQSeries::ErrorLog::Entry objects
#
sub process {
    confess "Invalid no of args" unless (@_ == 1);
    my ($this) = @_;

    #
    # Check and see whether the file has changed.
    # - On inode changes, process the tail-end of the
    #   current file, then the start of the new file
    # - On size changes, just process those updates
    #
    return unless (-f $this->{'filename'});
    my ($inode, $size) = (stat _)[1,7];

    my @entries;
    if (defined $this->{'file'}) { # Have seen it before
        if ($this->{'file'}{'inode'} != $inode ||
            $this->{'file'}{'size'} != $size) {
            #print "Detect ErrLog change, size now at [$size]\n";
            #
            # Inode or file-size change:
            # - Seek back to the end of the old fh (to re-set eof flag)
            # - Process new data (if any, which may fail for inode change)
            #
            my $fh = $this->{'file'}{'fh'};
            seek($fh, $this->{'file'}{'size'}, 0);
            local $/;
            my $new_data = <$fh>;
            if (defined $new_data && length $new_data) {
                push @entries, $this->{'parser'}->parse_data($new_data);
            }
            $this->{'file'}{'size'} = $size;

            #
            # For file-size changes, return.
            # For inode-changes, fall through to the
            # open-new-file logic below.
            #
            if ($this->{'file'}{'inode'} == $inode) {
                return @entries;
            }
            #print "This was the tail end - now on to the new beginning\n";
        } else {
            #print "No change detected to [$this->{'filename'}]\n";
            # No detectable change
            return;
        }
    }

    #
    # Open new file
    #
    my $fh = IO::File->new($this->{'filename'}) ||
      confess "Cannot open file [$this->{'filename'}]: $!";
    $this->{'file'} = { 'inode' => $inode,
                        'fh'    => $fh,
                        'size'  => $size,
                      };
    local $/;
    my $new_data = <$fh>;
    if (defined $new_data && length $new_data) {
        push @entries, $this->{'parser'}->parse_data($new_data);
    }

    return @entries;
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::ErrorLog::Tail -- Watch MQSeries error-log files

=head1 SYNOPSIS

  use MQSeries::ErrorLog::Tail;

  my $err_log = new MQSeries::ErrorLog::Tail("/var/mqm/errors");
  while (1) {
      my @entries = $err_log->process();
      process_errorlog_entries(@entries) if (@entries);
      sleep(10) unless (@entries);
  }

  sub process_errorlog_entries {
      my (@errlog_entries) = @_;

      foreach my $entry (@errlog_entries) {
          # Send off to syslog or whatever
      }
  }

=head1 DESCRIPTION

The MQSeries::ErrorLog::Tail class provides a mechanism to watch
the MQSeries errorlog (AMQERR01.LOG), which is generally written
to whenever an MQSeries error occurs, or when certain events happen.

Every time the process() method is invoked, it will return a
(possibly empty) array of MQSeries::ErrorLog::Entry objects,
which can in turn be analyzed and shipped off to syslog or other
monitoring tools.

The MQSeries::ErrorLog::Tail class will notice file roll-overs
(where the old AMQERR01.LOG is renamed AMQERR02.LOG and a new
file AMQERR01.LOG is created).  In such cases, it will first
process the tail-end of the old file, then switch over to the
new file.

=head1 METHODS

=head2 new

Create a new MQSeries::ErrorLog::Tail object. The argument is the
directory to watch (/var/mqm/errors for a typical installation's
system-wide global error log, /var/mqm/qmgrs/XYZ/errors for a
typical installation's queue-manager specific error log).

=head2 process

Process any changes since the previous invocation (or the constructor).
Read any data found, parse it and return the MQSeries::ErrorLog::Entry
objects that were read.

=head1 SEE ALSO

MQSeries(3), MQSeries::ErrorLog::Parser(3), MQSeries::ErrorLog::Entry(3),
MQSeries::FDC::Tail(3)

=cut
