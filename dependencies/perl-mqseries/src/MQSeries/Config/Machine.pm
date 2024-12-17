#
# MQSeries::Config::Machine.pm - Machine configuration from mqs.ini
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Machine.pm,v 33.10 2012/09/26 16:18:18 jettisu Exp $
#

package MQSeries::Config::Machine;

use strict;
use Carp;

our $VERSION = '1.34';

#
# Constructor: Read and parse the /var/mqm/mqs.ini file.
#
# Parameters:
# - Class name
# - Optional file name
# Returns:
# - New MQSeries::Config::Machine object
#
sub new {
    my ($class, $filename) = @_;

    $filename ||= '/var/mqm/mqs.ini';

    my $this = bless { 'filename' => $filename }, $class;
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
# - MQSeries::Config::Machine object
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
# Get information on the local queue managers. Will re-parse the file
# if the timestamp has changed.
#
#
# Parameters:
# - MQSeries::Config::Machine object
# Returns:
# - Ref to hash with (qmgrname => data) pairs
#
sub localqmgrs {
    my ($this) = @_;

    my @entries = $this->lookup('QueueManager');
    return { map { ($_->{'Name'}, $_) } @entries };
}


#
# PRIVATE support method: Parse the file
#
# Parameters:
# - MQSeries::Config::Machine object
# Returns:
# - Modified MQSeries::Config::Machine object
sub _parse {
    my ($this) = @_;

    my $filename = $this->{'filename'};

    open (MQSINI, '<', $filename) ||
      confess "Cannot open file [$filename]: $!";
    my $data = {};
    my $stanza;
    my $stanza_data;
    while (<MQSINI>) {
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
    close(MQSINI);

    #
    # Parsing successful - store results
    #
    $this->{'data'} = $data;
    $this->{'mtime'} = (stat $filename)[9];
    return $this;
}


1;                              # End on a positive note


__END__


=head1 NAME

MQSeries::Config::Machine -- Interface to read the machine configuration file

=head1 SYNOPSIS

  use MQSeries::Config::Machine;

  my $conf = MQSeries::Config::Machine->new();

  print "All configuration sections: ", join(', ', $conf->stanzas()), "\n";

  my $default = $conf->lookup('DefaultQueueManager');
  if (defined $default) {
      print "Default queue manager: $default->{'Name'}\n";
  }

  my $local = $conf->localqmgrs();
  print "All local queue managers:\n";
  while (my ($name, $data) = each %$local) {
      print "  $name - $data->{'Directory'}\n";
  }

=head1 DESCRIPTION

The MQSeries::Config::Machine class is an interface to the machine
configuration file, typically /var/mqm/mqs.ini.  This class will parse
the file and allow you to lookup any group of settings in the class.
A utility function based on this will return a full list of
all local queue managers and their base directory name.

An MQSeries::Config::Machine object will cache the parsed
configuration file for efficiency, but will check the timestamp of the
file at every lookup.  Should the file change, it will be re-parsed,
so that up-to-date information is always returned.

=head1 METHODS

=head2 new

Create a new MQSeries::Config::Machine object.  The constructor
takes an optional filename parameter, used when your configuration
file is not at the default location of /var/mqm/mqs.ini.

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

=head2 localqmgrs

A convenience function written on top of C<lookup>.  This function
returns a hash-reference mapping local queue manager names to
configuration settings.

=head1 FILES

/var/mqm/mqs.ini

=head1 SEE ALSO

MQSeries(3), MQSeries::Config::QMgr

=cut
