#
# MQSeries::Config::QMgr.pm - Queue manager configuration from qm.ini
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: QMgr.pm,v 33.11 2012/09/26 16:15:11 jettisu Exp $
#

package MQSeries::Config::QMgr;

use strict;
use Carp;

use MQSeries::Config::Machine;

our $VERSION = '1.34';

#
# Constructor: Read and parse the /var/mqm/qmgrs/XYYZY/qm.ini file.
#
# Parameters:
# - Class name
# - Queue manager name
# - Optional base directory, if not /var/mqm
# Returns:
# - New MQSeries::Config::QMgr object
#
sub new {
    my ($class, $qmgr, $basename) = @_;

    $basename ||= '/var/mqm';

    my $this = bless { 'qmgr'     => $qmgr,
                       'basename' => $basename,
                     }, $class;
    $this->_parse();
    return $this;
}


#
# Return the names of all stanzas. Will re-parse the file
# if the timestamp has changed.
#
# Parameters:
# - MQSeries::Config::QMgr object
# Returns:
# - Array of stanza names
#
sub stanzas {
    my ($this) = @_;

    #
    # If the disk modification time has changed, re-parse
    #
    if ((stat $this->{'filename'})[9] != $this->{'mtime'}) {
        $this->_parse();
    }

    return keys %{ $this->{'data'} };
}


#
# Get information for a particular stanza. Will re-parse the file
# if the timestamp has changed.
#
# Parameters:
# - MQSeries::Config::QMgr object
# - Stanza name
# Returns:
# - Array with hash-references of (key -> value) pairs
#   for that stanza
#
sub lookup {
    my ($this, $stanza) = @_;

    #
    # If the disk modification time has changed, re-parse
    #
    if ((stat $this->{'filename'})[9] != $this->{'mtime'}) {
        $this->_parse();
    }

    return unless (defined $this->{'data'}{$stanza});
    if (wantarray) {            # Return all
        return @{ $this->{'data'}{$stanza} };
    } else {                    # Return the last
        return $this->{'data'}{$stanza}[-1];
    }
}


#
# PRIVATE support method: Parse the file
#
# Parameters:
# - MQSeries::Config::Machine object
# Returns:
# - Modified MQSeries::Conifg::Machine object
sub _parse {
    my ($this) = @_;

    #
    # Get the directory name for this queue manager -
    # by asking the machine configuration for it.
    #
    $this->{'machine'} ||=
      MQSeries::Config::Machine->new($this->{'basename'} . '/mqs.ini');
    my $local = $this->{'machine'}->localqmgrs();
    unless (defined $local->{ $this->{'qmgr'} }) {
        confess "Unknown queue manager [$this->{'qmgr'}]";
    }

    my $filename = $this->{'basename'} . '/qmgrs/' .
      $local->{ $this->{'qmgr'} }->{'Directory'} . '/qm.ini';

    open (QMINI, '<', $filename) ||
      confess "Cannot open file [$filename]: $!";
    my $data = {};
    my $stanza;
    my $stanza_data;
    while (<QMINI>) {
        next if (/^\#/ || /^\s*$/); # Skip comments, blank lines

        #
        # A stanza line introduces the beginning of a new section
        # and looks like 'QueueManager:'
        #
        if ( /^(\w+):/ ) {
            $stanza = $1;
            $stanza_data = {};
            $data->{$stanza} = [] unless (defined $data->{$stanza});
            push @{ $data->{$stanza} }, $stanza_data;
            next;
        }

        #
        # A data line belongs to a stanza and looks like 'Prefix=/var/mqm'
        #
        if (/^\s*(\S+)=(\S+)/) {
            my ($key, $value) = ($1, $2);
            confess "Have data line before first stanza in [$filename]: $_"
              unless (defined $stanza);

            if (defined $stanza_data->{$key}) {
                carp "Duplicate key [$key] in stanza [$stanza] of [$filename]";
            }
            $stanza_data->{$key} = $value;
        }
    }
    close(QMINI);

    #
    # Parsing successful - store results
    #
    $this->{'data'} = $data;
    $this->{'filename'} = $filename;
    $this->{'mtime'} = (stat $filename)[9];
    return $this;
}


1;                              # End on a positive note


__END__


=head1 NAME

MQSeries::Config::QMgr -- Interface to read the queue manager configuration file

=head1 SYNOPSIS

  use MQSeries::Config::QMgr;

  my $conf = MQSeries::Config::QMgr->new('your.queue.manager');

  print "All configuration sections: ", join(', ', $conf->stanzas()), "\n";

  my $tuning = $conf->lookup('TuningParameters');
  if (defined $tuning) {
      print "Tuning parameters:\n";
      foreach my $param (sort keys %$tuning) {
          print "\t$param: $tuning->{$param}\n";
      }
  }

=head1 DESCRIPTION

The MQSeries::Config::QMgr class is an interface to a queue manager
configuration file, typically /var/mqm/qmgrs/XXX/qm.ini for queue
manager 'XXX'.  This class will parse the file and allow you to lookup
any group of settings in the class.

An MQSeries::Config::QMgr object will cache the parsed configuration
file for efficiency, but will check the timestamp of the file at every
lookup.  Should the file change, it will be re-parsed, so that
up-to-date information is always returned.

=head1 METHODS

=head2 new

Create a new MQSeries::Config::QMgr object. The constructor takes one
required and one optional parameter:

=over 4

=item The name of the queue manager

=item The name of the base directory, if not /var/mqm

=back

The constructor will use the machine configuration file (by default
/var/mqm/mqs.ini) to map the queue manager name to the appropriate
directory name.

=head2 stanzas

Return an array with all stanza names.  These can then be used as
a parameter to C<lookup>.

=head2 lookup

Lookup a stanza in the configuration file.  Depending on the context,
this returns either an array with one entry for each instance of the
stanza found, or the latest stanza with that name. Each entry is a
hash-reference with key-value pairs.  For example, using
C<$conf->lookup('QueueManager')> returns an array with one
hash-reference for each locally-defined queue manager; each
hash-reference will contain a 'Name' and 'Directory' field and
whatever other fields the configuration file will contain.

=head1 FILES

/var/mqm/mqs.ini
/var/mqm/qmgrs/*/qm.ini

=head1 SEE ALSO

MQSeries(3), MQSeries::Config::Machine

=cut
