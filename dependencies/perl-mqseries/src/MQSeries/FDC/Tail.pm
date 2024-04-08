#
# MQSeries::FDC::Tail.pm - Watch multiple FDC in a directory
#                          and return parsed FDC::Entry objects for
#                          any new content added.
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Tail.pm,v 33.11 2012/09/26 16:15:14 jettisu Exp $
#

package MQSeries::FDC::Tail;

use strict;
use Carp;
use IO::File;

use MQSeries::FDC::Parser;

our $VERSION = '1.34';

#
# The FDC logs are watched based on the following assumptions:
# - The initial data in the FDC files is of no interest (just updates)
# - Files may grow
# - New files can be added at any time
# - Log-management scripts may truncate FDC files down to zero bytes
#   at any time
# - If a file inode changes, the previous file is of no interest
#

#
# Constructor
#
# Parameters:
# - Class name
# - Directory to watch
# - Max # of files this is allowed to open at any one time
#   (defaults to 200)
# Returns:
# - New MQSeries::FDC::Tail object
#
sub new {
    my ($class, $dirname, $maxfiles) = @_;

    # Paranoia...
    $maxfiles = 200 if (!defined $maxfiles);
    confess "Invalid number of arguments" unless (@_ == 2 || @_ == 3);
    confess "Invalid directory [$dirname]" unless (-d $dirname);
    confess "Maxfiles must be at least 20" unless ($maxfiles >= 20);

    my $this = bless { 'directory' => $dirname,
                       'files'     => {},
                       'maxfiles'  => $maxfiles,
                     }, $class;

    # Establish a base-line of known state
    $this->scan();

    return $this;
}


#
# Establish a baseline of all known files and sizes.  Later 'process'
# calls will only see updates relative to this.
#
# Parameters:
# - MQSeries::FDC::Tail object
#
sub scan {
    my ($this) = @_;

    #
    # Find all matching and readable files in the directory; the
    # 'files' attribute is indexed by name and stores hashes with
    # inode and size entries.
    #
    opendir(WATCHDIR, $this->{'directory'}) ||
      confess "Cannot open directory [$this->{'directory'}]: $!";
    my $entries = {};
    while (defined (my $entry = readdir WATCHDIR)) {
        next unless ($entry =~ m!^AMQ\d+.*\.FDC$!);
        next unless (-f "$this->{'directory'}/$entry" && -r _);

        # Get stats - but re-use results from -f filetest
        my ($inode, $size) = (stat _)[1,7];
        $entries->{$entry} = { 'inode'   => $inode,
                               'size'   => $size,
                               'parser' => MQSeries::FDC::Parser->new($entry),
                             };
    }
    closedir WATCHDIR;
    $this->{'files'} = $entries;
    return $this;
}


#
# Process all changed files and invoke the parser on the changed
# data. If this routine is called regularly, that data will typically
# be one error-message; however, it may be more.  The
# MQSeries::FDC::Parser class handles these one-or-more message chunks
# properly.
#
# Parameters:
# - MQSeries::FDC::Tail object
# Returns:
# - List of MQSeries::FDC::Entry objects
#
sub process {
    confess "Invalid no of args" unless (@_ == 1);
    my ($this) = @_;

    #
    # Find all matching files in the directory;
    # the 'files' attribute is indexed by name and stores
    # hashes with inode, size and (lazily populated) fh entries.
    #
    opendir(WATCHDIR, $this->{'directory'}) ||
      confess "Cannot open directory [$this->{'directory'}]: $!";
    my %found;
    my @entries;
    while (defined (my $entry = readdir WATCHDIR)) {
        next unless ($entry =~ m!^AMQ\d+.*\.FDC$!);
        next unless (-f "$this->{'directory'}/$entry" && -r _);

        # Get stats - but re-use results from -f filetest
        my ($inode, $size, $mtime) = (stat _)[1,7,9];
        $found{$entry} = 1;

        #
        # Existing-file logic
        # - Inode changed (treat as new file)
        # - File size change (read updates)
        #
        if (defined $this->{'files'}{$entry}) {
            if ($this->{'files'}{$entry}{'inode'} != $inode) {
                #
                # If the inode has changed, delete the entry from the
                # table - the new-file logic will cause the file to be
                # processed from the start.
                #
                delete $this->{'files'}{$entry};
                # Fall-through
            } elsif ($this->{'files'}{$entry}{'size'} != $size) {
                #
                # If the size has changed, cater for:
                # - growth (just read new data)
                # - truncation, then growth (read from start)
                #
                my $fh = $this->{'files'}{$entry}{'fh'};
                unless (defined $fh) {
                    $this->_check_maxfiles();
                    $fh = $this->{'files'}{$entry}{'fh'} =
                      IO::File->new("$this->{'directory'}/$entry") ||
                        confess "Cannot open file [$this->{'directory'}/$entry]: $!";
                }
                if ($this->{'files'}{$entry}{'size'} < $size) { # Growth
                    #print "FDC File grown to [$size]\n";
                    seek($fh, $this->{'files'}{$entry}{'size'}, 0);
                } else {        # Truncation: seek back to beginning
                    #print "FDC File truncated\n";
                    seek($fh, 0, 0);
                }
                push @entries, $this->process_updates($fh, $this->{'files'}{$entry}{'parser'});
                $this->{'files'}{$entry}{'size'} = $size;
                $this->{'files'}{$entry}{'mtime'} = $mtime;
                next;
            } else {            # Size unchanged
                next;
            }
        }

        #
        # New file (not seen before or inode changed)
        #
        $this->{'files'}{$entry} =
          { 'inode'  => $inode,
            'mtime'  => $mtime,
            'size'   => $size,
            'parser' => MQSeries::FDC::Parser->new($entry),
          };
        $this->_check_maxfiles();
        my $fh = $this->{'files'}{$entry}{'fh'} =
          IO::File->new("$this->{'directory'}/$entry") ||
            confess "Cannot open file [$this->{'directory'}/$entry]: $!";
        push @entries, $this->process_updates($fh, $this->{'files'}{$entry}{'parser'});
    }                           # End while: all entries in directory
    closedir(WATCHDIR);

    #
    # Now get rid of all files we have open, that no longer are in the
    # directory - useful for a long-running daemon
    #
    foreach my $file (keys %{ $this->{'files'} }) {
        next if (defined $found{$file});
        #print "Getting rid of entry [$file]\n";
        delete $this->{'files'}{$file};
    }

    # We're done!
    return @entries;
}


#
# Handle the updates of one file.  This is a separate method to allow
# sub-classes to provide a different read mechanism (e.g.,
# line-by-line or chunk-by-chunk instead of everything).
#
# Parameters:
# - MQSeries::FDC::Tail object
# - Filehandle
# - MQSeries::FDC::Parser object for this file
# Returns:
# - List of MQSeries::FDC::Entry objects
#
sub process_updates {
    confess "Illegal no of args" unless (@_ == 3);
    my ($this, $fh, $parser) = @_;

    local $/;
    my $new_data = <$fh>;
    return unless (defined $new_data && length $new_data);
    return $parser->parse_data($new_data);
}


#
# PRIVATE help functions: check and see that we do not have too many
# files open.  This is invoked just before we open any file-handle.
#
# NOTE: The main reason this is required is that 32-bit Solaris has a
#       limit of max 255 files open at any one time using stdio (which
#       perl does), even though the file-descriptor limit can be quite
#       a bit higher.  And, of course, MQ likes to write FDC errors
#       on hundreds of files at once :-)
#
# Parameters:
# - MQSeries::FDC::Tail object
#
sub _check_maxfiles {
    my ($this) = @_;

    my $files = $this->{'files'};
    return unless (scalar(keys %$files) >= $this->{'maxfiles'});

    #print "Checking max # of open files\n";
    #
    # Collect the enties that have an open file, and their mtime.
    #
    my %open_entries;
    foreach my $entry (keys %$files) {
        next unless (defined $files->{$entry}{'fh'});
        $open_entries{$entry} = $files->{$entry}{'mtime'};
    }
    return unless (scalar(keys %open_entries) >= $this->{'maxfiles'});

    #
    # Sort the files by age
    #
    my @oldest = sort { $open_entries{$a} <=> $open_entries{$b}
                      } keys %open_entries;
    #print "Oldest file is [" .
    #  ($open_entries{ $oldest[-1] } - $open_entries{ $oldest[0] }),
    #  "] seconds older than the latest\n";

    foreach my $entry (@oldest[0,9]) {
        $files->{$entry}{'fh'}->close();
        delete $files->{$entry}{'fh'};
    }
}


1;                              # End on a positive note


__END__

=head1 NAME

MQSeries::FDC::Tail -- Watch MQSeries FDC error files

=head1 SYNOPSIS

  use MQSeries::FDC::Tail;

  my $fdc_log = new MQSeries::FDC::Tail("/var/mqm/errors");
  while (1) {
      my @entries = $fdc_log->process();
      process_fdc_entries(@entries) if (@entries);
      sleep(10) unless (@entries);
  }

  sub process_fdc_entries {
      my (@fdc_entries) = @_;

      foreach my $entry (@fdc_entries) {
          # Send off to syslog or whatever
      }
  }

=head1 DESCRIPTION

The MQSeries::FDC::Tail class provides a mechanism to watch the FDC
logs, which are generally written to if a fatal MQSeries error, or
internal MQSeries error, occurs.

Every time the process() method is invoked, it will return a (possibly
empty) array of MQSeries::FDC::Entry objects, which can in turn be
analyzed and shipped off to syslog or other monitoring tools.

The MQSeries::FDC::Tail class will notice new FDC files appearing;
files being truncated (e.g. by housekeeping jobs) or files being
removed.

=head1 METHODS

=head2 new

Create a new MQSeries::FDC::Tail object. The argument is the directory
to watch (/var/mqm/errors for a typical installation).  An optional
second argument specifies the maximum number of files that may be open
at the same time; the default is 200, well under the default limit of
255 open files imposed by the stdio libraries of many vendors.

=head2 process

Process any changes since the previous invocation (or the
constructor).  Read any data found, parse it and return the
MQSeries::FDC::Entry objects that were read.

=head1 SEE ALSO

MQSeries(3), MQSeries::FDC::Parser(3), MQSeries::FDC::Entry(3), MQSeries::ErrorLog::Tail(3)
