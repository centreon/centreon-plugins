#
# MQSeries::Config::Authority.pm - Parse Unix authority files
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Authority.pm,v 33.11 2012/09/26 16:15:10 jettisu Exp $
#

package MQSeries::Config::Authority;

use strict;
use Carp;

our $VERSION = '1.34';

use MQSeries qw(:functions);
use MQSeries::Config::Machine;  # For localqmgrs()

#
# Configuration table to map bits into logical names (setmqaut format)
#
my %auth_bit_to_name =
  (
   #
   # Admin Rights
   #
   MQSeries::MQZAO_CREATE                       => 'crt',
   MQSeries::MQZAO_DELETE                       => 'dlt',
   MQSeries::MQZAO_DISPLAY                      => 'dsp',
   MQSeries::MQZAO_CHANGE                       => 'chg',
   MQSeries::MQZAO_CLEAR                        => 'clr',

   #
   # MQI Rights
   #
   MQSeries::MQZAO_CONNECT                      => 'connect',
   MQSeries::MQZAO_BROWSE                       => 'browse',
   MQSeries::MQZAO_INPUT                        => 'get',
   MQSeries::MQZAO_OUTPUT                       => 'put',
   MQSeries::MQZAO_INQUIRE                      => 'inq',
   MQSeries::MQZAO_SET                          => 'set',
   MQSeries::MQZAO_PASS_IDENTITY_CONTEXT        => 'passid',
   MQSeries::MQZAO_PASS_ALL_CONTEXT             => 'passall',
   MQSeries::MQZAO_SET_IDENTITY_CONTEXT         => 'setid',
   MQSeries::MQZAO_SET_ALL_CONTEXT              => 'setall',
   MQSeries::MQZAO_ALTERNATE_USER_AUTHORITY     => 'altusr',
  );
my %auth_name_to_bit = reverse %auth_bit_to_name;

#
# Configuration table to map bits into PCF codes (our own PCF extensions)
#
my %auth_bit_to_pcf =
  (
   #
   # Admin Rights
   #
   MQSeries::MQZAO_CREATE                       => 'Create',
   MQSeries::MQZAO_DELETE                       => 'Delete',
   MQSeries::MQZAO_DISPLAY                      => 'Display',
   MQSeries::MQZAO_CHANGE                       => 'Change',
   MQSeries::MQZAO_CLEAR                        => 'Clear',

   #
   # MQI Rights
   #
   MQSeries::MQZAO_CONNECT                      => 'Connect',
   MQSeries::MQZAO_BROWSE                       => 'Browse',
   MQSeries::MQZAO_INPUT                        => 'Input',
   MQSeries::MQZAO_OUTPUT                       => 'Output',
   MQSeries::MQZAO_INQUIRE                      => 'Inquire',
   MQSeries::MQZAO_SET                          => 'Set',
   MQSeries::MQZAO_PASS_IDENTITY_CONTEXT        => 'PassId',
   MQSeries::MQZAO_PASS_ALL_CONTEXT             => 'PassAll',
   MQSeries::MQZAO_SET_IDENTITY_CONTEXT         => 'SetId',
   MQSeries::MQZAO_SET_ALL_CONTEXT              => 'SetAll',
   MQSeries::MQZAO_ALTERNATE_USER_AUTHORITY     => 'AlternateUser',
  );

#
# Configuration table to map summary names (all/alladm/allmqi)
# into symbolic names.
#
my %auth_all_to_names =
  (
   'all'    => [ qw(dlt dsp chg clr
                    connect browse get put inq set
                    passid passall setid setall altusr) ],
   'alladm' => [ qw(dlt dsp chg clr) ],
   'allmqi' => [ qw(connect browse get put inq set
                    passid passall setid setall altusr) ],
  );

#
# Configuration table with the valid bits per object type
#
my %object_type_to_names =
  (
   'queue'    => [ qw(browse chg clr crt dlt dsp put
                      inq get passall passid set setall setid) ],
   'process'  => [ qw(chg crt dlt dsp inq set) ],
   'qmgr'     => [ qw(altusr chg connect crt dlt dsp inq set setall setid) ],
   'namelist' => [ qw(chg crt dlt dsp inq) ],
   );

#
# Configuration table with the directory name for each object type
#
my %object_type_to_dir =
  ('queue'    => 'queues',
   'process'  => 'procdef',
   'qmgr'     => 'qmanager',
   'namelist' => 'namelist',
   );

#
# A table of object type to bits, computed on first hit
#
my %object_type_to_bits;

#
# A table of auth-all code to bits, computed on first hit
#
my %auth_all_to_bits;


#
# Constructor
#
# Parameters:
# - Class name
# - Hash with parameters:
#   - QMgrName: queue-manager name
#   - ObjectType: process/queue/qmgr/namelist (or PCF-format,
#                 Process/Queue/QueueManager/QMgr/Namelist)
#   - ObjectName: name of object (ignored for ObjectType=qmgr)
#   - BaseDir: optional base-directory (defaults to /var/mqm)
#   - Carp: Optional reference to routine to log errors
# Returns:
# - New MQSeries::Config::Authority object
#
my $machine;
sub new {
    my ($class, %params) = @_;

    #
    # Compute bit tables
    #
    unless (keys %object_type_to_bits && keys %auth_all_to_bits) {
        _compute_derived_tables();
    }

    #
    # Validate creation parameters
    #
    $params{'Carp'} ||= \&carp;
    my $carp = $params{'Carp'};
    unless (ref $carp eq 'CODE') {
        carp "Invalid 'Carp' parameter: '$carp'";
        return;
    }
    confess "Missing 'QMgrName' parameter"
      unless (defined $params{'QMgrName'});
    confess "Missing or invalid 'ObjectType' parameter"
      unless (defined $params{'ObjectType'} &&
              defined $object_type_to_dir{ $params{'ObjectType'} });
    if ($object_type_to_dir{ $params{'ObjectType'} } eq 'qmanager') {
        $params{'ObjectName'} = 'self';
    }
    $params{'BaseDir'} = '/var/mqm' unless (defined $params{'BaseDir'});
    unless (-d $params{'BaseDir'}) {
        $carp->("Missing base directory '$params{'BaseDir'}'");
        return;
    }

    $machine ||= MQSeries::Config::Machine->new("$params{'BaseDir'}/mqs.ini");
    my $local_qmgrs = $machine->localqmgrs();
    unless (defined $local_qmgrs->{ $params{'QMgrName'} }) {
        $carp->("Unknown queue-manager '$params{'QMgrName'}'");
    }

    my $this = bless \%params, $class;
    $this->{'QMgrDir'} = $params{'BaseDir'} . '/qmgrs/' .
      $local_qmgrs->{ $this->{'QMgrName'} }->{'Directory'};

    #
    # Look and see of the object exists
    #
    my $auth_file = $this->{'ObjectName'};
    $auth_file =~ s/\./!/g;
    $auth_file = "$this->{'QMgrDir'}/auth/$object_type_to_dir{ $this->{'ObjectType'} }/$auth_file";
    unless (-f $auth_file) {
        $carp->("Authority file '$auth_file' not found");
        return;
    }

    #
    # Get settings from @aclass, @class, object
    # Note that _parse_authfile will use caching for @aclass and @class
    #
    $this->_parse_authfile("$this->{'QMgrDir'}/auth/\@aclass",
                           'aclass', undef);
    $this->_parse_authfile("$this->{'QMgrDir'}/auth/$object_type_to_dir{ $this->{'ObjectType'} }/\@class",
                           'class', undef);
    $this->_parse_authfile($auth_file, 'object', $this->{'ObjectType'});

    #
    # Merge the three authorities into one effective set
    #
    foreach my $type (keys %{ $this->{'entities'} }) {
        while (my ($entity, $auth) =
               each %{ $this->{'entities'}{$type} }) {
            $this->{'entities'}{'effective'}{$entity} = 0
              unless (defined $this->{'entities'}{'effective'}{$entity});
            $this->{'entities'}{'effective'}{$entity} |=
              ($auth & $object_type_to_bits{ $this->{'ObjectType'} });
        }
    }

    return $this;
}


#
# Return a list of all entities (groups, principals) for this object
#
# Parameters:
# - MQSeries::Config::Authority object
# Returns:
# - Array of all entities name
#
sub entities {
    my ($this) = @_;

    return sort keys %{ $this->{'entities'}{'effective'} };
}


#
# Return the numeric authority of an entity (group, principal)
#
# Parameters:
# - MQSeries::Config::Authority object
# - Entity name
# Returns:
# - Array of authority names
#
sub numeric_authority {
    confess "Invalid number of params" unless (@_ == 2);
    my ($this, $entity) = @_;

    my $permission = $this->{'entities'}{'effective'}{$entity} || 0;
    return $permission;
}


#
# Return a list of all the authority names that an entity holds
# (with names in setmqaut format, not using all/alladm/allmqi,
#  oer in PCF macro name format)
#
# Parameters:
# - MQSeries::Config::Authority object
# - Entity name
# - Format: Optional output format (setmqaut/PCF, default setmqaut)
# Returns:
# - Array of authority names
#
sub authorities {
    confess "Invalid number of params" unless (@_ == 2 || @_ == 3);
    my ($this, $entity, $format) = @_;
    $format ||= 'setmqaut';

    my $permission = $this->{'entities'}{'effective'}{$entity};
    return unless (defined $permission);
    my @retval;
    my $table = ($format eq 'setmqaut' ? \%auth_bit_to_name : \%auth_bit_to_pcf);

    while (my ($bit, $name) = each %$table) {
        next unless (($permission & $bit) == $bit);
        push @retval, $name;
    }
    return sort @retval;
}


#
# Indicate whether an entity has a specific authority
#
# Parameters:
# - MQSeries::Config::Authority object
# - Entity name
# - Authority (including 'all', 'allmqi', 'alladm'
# Returns:
# - Boolean
#
sub has_authority {
    confess "Invalid number of params" unless (@_ == 3);
    my ($this, $entity, $authority) = @_;

    my $bits = $auth_name_to_bit{$authority} || $auth_all_to_bits{$authority};
    unless (defined $bits) {
        $this->{'Carp'}->("Invalid authority '$authority'");
        return 0;
    }

    #
    # Limit the bits to those set for this object type
    #
    $bits = $bits & $object_type_to_bits{ $this->{'ObjectType'} };

    my $permission = $this->{'entities'}{'effective'}{$entity} || 0;

    return (($bits & $permission) == $bits ? 1 : 0);
}


#
# List the authorities of an entity in long format, that can be plugged
# into an setmqaut command.
#
# Parameters:
# - MQSeries::Config::Authority object
# - Entity
# Returns:
# - String like "+alladm +dsp -chg"
#
sub authority_command {
    confess "Invalid parameters" unless (@_ == 2);
    my ($this, $entity) = @_;

    my $permission = $this->{'entities'}{'effective'}{$entity} || 0;

    #
    # NOTE: 'crt' is not part of 'all', 'alladm' or 'allmqi', so needs
    #       special handling.
    #
    if ($permission == 0) {
        return '-all -crt';
    }

    my @elements;
    if ($this->has_authority($entity, 'crt')) {
        push @elements, "+crt";
    } else {
        push @elements, "-crt";
    }

    if ($this->has_authority($entity, 'all')) {
        push @elements, "+all";
    } else {
        foreach my $group (qw(alladm allmqi)) {
            if ($this->has_authority($entity, $group)) {
                push @elements, "+$group";
                next;
            }
            my @elems;
            my $any_set = 0;
            foreach my $name (@{ $auth_all_to_names{$group} }) {
                my $bit = $auth_name_to_bit{$name};
                next unless ($object_type_to_bits{ $this->{'ObjectType'} } & $bit);
                if ($this->has_authority($entity, $name)) {
                    push @elems, "+$name";
                    $any_set = 1;
                } else {
                    push @elems, "-$name";
                }
            }
            if ($any_set) {
                push @elements, @elems;
            } else {
                push @elements, "-$group";
            }
        }
    }
    return "@elements";
}


#
# PRIVATE helper method: parse an authority file
#
# Parameters:
# - MQSeries::Config::Authority object
# - File name
# - Key
# - Object type/undef (will cache non-object specific)
# Returns:
# - Boolean
#
my $cache;                      # File -> { mtime, inode, data }
sub _parse_authfile {
    confess "Invalid no of params" unless (@_ == 4);
    my ($this, $authfile, $key, $type) = @_;

    unless (-f $authfile) {
        $this->{'Carp'}->("Undefined authfile [$authfile]");
        return 0;
    }

    #
    # Check cache, when applicable
    #
    if (! defined $type && defined $cache->{$authfile}) {
        my ($inode, $mtime) = (stat $authfile)[1,9];
        if ($cache->{$authfile}{'inode'} == $inode &&
            $cache->{$authfile}{'mtime'} == $mtime) {
            #
            # Cache hit
            #
            $this->{'entities'}{$key} = $cache->{$authfile}{'data'};
            return 1;
        }
    }

    unless (open(AUTHFILE, '<', $authfile)) {
        carp "Unable to open $authfile: $!";
        return 0;
    }

    #
    # The authentication file contains stanzas like
    #   mqm:
    #      Authority=0x00000000
    # where 'mqm' is an entity (e.g. Unix group) and 'Authority'
    # is a hexadecimal number representing an authority bit-pattern,
    # with every bit represented by an MQZAO_xxx macro.
    #
    my $entities;
    while (<AUTHFILE>) {
        #
        # Extract the entity from the first line in a pair
        #
        unless (/^(\S+):$/) {
            $this->{'Carp'}->("Invalid entity line in [$authfile]: $_");
            return 0;
        }
        my $entity = $1;
        #
        # If an entity occurs multiple times in the same file
        # (which the IBM OAM never does, typically the result of manual
        #  editing), the permissions are effectively ORed.
        #
        if (defined $entities->{$entity}) {
            $this->{'Carp'}->("Entity [$entity] occurs twice in [$authfile], ORing access");
        }

        #
        # Extract the authority fron the second line in a pair
        $_ = <AUTHFILE>;
        unless (defined $_) {
            $this->{'Carp'}->("Unexpected end of file - incomplete file [$authfile]");
            return 0;
        }
        unless (/^\s+Authority=(0x[A-Fa-f0-9]{8})$/) {
            $this->{'Carp'}->("Invalid authority line in [$authfile]: $_");
            return 0;
        }
        my $permission = hex $1;
        next if ($permission == 0);

        #
        # Store the permission number for the entity (to be queried later),
        # taking care to perform the logical OR for duplicate entities.
        #
        $entities->{$entity} ||= 0;
        $entities->{$entity} |= $permission;
        my $used = 0;
        while (my ($bit, $name) = each %auth_bit_to_name) {
            if (($permission & $bit) == $bit) {
                $used |= $bit;
            }
        }
        if ($permission != $used) {
            my $bitvalue = sprintf("0x%08x", $permission & ~$used);
            $this->{'Carp'}->("Unknown permission [$bitvalue] for [$entity] in [$authfile]");
            return 0;
        }

        #
        # FIXME: For NT, also parse an 'SID=' line
        #
    }
    close(AUTHFILE);

    $this->{'entities'}{$key} = $entities;

    #
    # Fill cache, if appropriate
    #
    unless (defined $type) {
        my ($inode, $mtime) = (stat $authfile)[1,9];
        $cache->{$authfile}{'inode'} = $inode;
        $cache->{$authfile}{'mtime'} = $mtime;
        $cache->{$authfile}{'data'} = $entities;
    }

    return 1;                   # Success
}


#
# Helper function: compute configuration tables that are
# derived from others.
#
# No parameters or return values.
#
sub _compute_derived_tables {
    #
    # Compute object_type_to_bits
    #
    while (my ($type, $namelist) = each %object_type_to_names) {
        $object_type_to_bits{$type} = 0;
        foreach my $name (@$namelist) {
            my $bit = $auth_name_to_bit{$name};
            confess "Unknown name [$name] for type [$type]"
              unless (defined $bit);
            $object_type_to_bits{$type} |= $bit;
        }
    }

    #
    # Compute auth_all_to_bits
    #
    while (my ($type, $namelist) = each %auth_all_to_names) {
        $auth_all_to_bits{$type} = 0;
        foreach my $name (@$namelist) {
            my $bit = $auth_name_to_bit{$name};
            confess "Unknown name [$name] for type [$type]"
              unless (defined $bit);
            $auth_all_to_bits{$type} |= $bit;
        }
    }

    #
    # For all 'object type to XXX' tables, support the
    # object type names as used by setmqaut as well as the
    # names used by PCF.  This allows the user to ask
    # for 'QueueManager' objects as well as 'qmgr' objects.
    #
    my %type_aliases = ('QueueManager' => 'qmgr',
                        'QMgr'         => 'qmgr',
                        'Process'      => 'process',
                        'Queue'        => 'queue',
                        'Namelist'     => 'namelist',
                       );
    foreach my $table (\%object_type_to_names,
                       \%object_type_to_bits,
                       \%object_type_to_dir) {
        while (my ($new, $old) = each %type_aliases) {
            $table->{$new} = $table->{$old};
        }
    }
}


1;                              # End on a positive note


__END__


=head1 NAME

MQSeries::Config::Authority -- Interface to parse authority files

=head1 SYNOPSIS

  use MQSeries::Config::Authority;

  my $authobj = new MQSeries::Config::Authority('QMgrName'   => 'TEST',
                                                'ObjectType' => 'queue',
                                                'ObjectName' => 'FOO.BAR');
  print "All entities for queue: ", join(', ', $authobj->entities()), "\n";
  print "Entity 'mqm' has authorities: ",
      join(', ', $authobj->authorities('mqm')), "\n";

  if ($authobj->has_authority('allcmd', 'mqops')) {
      print "Entity 'mqops' has 'allcmd' authority\n";
  }

  print "The command to recreate authority for user 'nobody' is:\n\t",
      "setmqaut -m TEST -t queue -n FOO.BAR -g nobody ",
      $authobj->authority_command(), "\n";


=head1 DESCRIPTION

The MQSeries::Config::Authority class is an interface to the authority
files in /var/mqm/qmgrs/XYZ/auth/, for MQSeries versions 5.0 and 5.1
on Unix.  It will not work with MQSeries 5.2 and higher, as those
store the authority information in a queue.

This class will parse authority files for specific objects and take
into account the @aclass and @class files.  Objects created then
provide access to the entities (Unix groups or principals) that have
access to the object, allow you to query whether an entity has
specific access levels, or to create command input that will allow you
to recreate the access settings at a later date.

The MQSeries::Config::Authority class will cache the parsed @aclass
and @class authority files across multiple authority files for
efficiency, but will check the timestamp of these files at every
lookup.  Should the files change, they will be re-parsed, so that
up-to-date information is always returned.

=head1 METHODS

=head2 new

Create a new MQSeries::Config::Authority object.  The constructor
takes named parameters, of which two are required and three are
optional, depending on the type and your environment:

=over 4

=item QMgrName

The name of the queue manager containing the object.  The Authority
class will query the mqs.ini file for the queue-manager directory name,
using the MQseries::Config::Machine class.

=item ObjectType

This must be either 'qmgr', 'queue', 'process' or 'namelist'.  The
aliases 'QMgr', 'QueueManager', 'Queue', 'Process' and 'Namelist'
or also supported.

=item ObjectName

The name of the object to be read, if the object type is not 'qmgr'.

=item BaseDir

An optional parameter specifying the base directory, if not /var/mqm.

=item Carp

A reference to a routine used to issue warnings.  Will default to C<carp>.

=back

=head2 entities

Returns an array with all entities (Unix groups or principals).  These
can then be used in further method calls.  As the authority file has a
flat namespace, it is not indicated whether an entity name is that of
a Unix group of that of a principal.

=head2 numeric_authority

This method requires one parameter, an entity name, and will return
the numeric authority value for that entity.  The numeric authority
is normally not of interest, but can be used when generating authority
files directly.

=head2 authorities

This method has one parameter, an entity name, and one optional
parameter, the format ('setmqaut' or 'PCF').  It returns a
list of all authority names for this entity.

If the format parameter is 'setmquat' or is not specified, the
authority names returned correspond to the values as specified in
C<setmqaut>, e.g. 'connect', 'inq', 'get', etc.  If a user has all
authorities, the full list of names is returned, not 'all'.

If the format parameter is 'PCF', the PCF macros as defined by the
MQSeries::Command module are returned.

=head2 has_authority

This method requires two parameters: an entity name and an authority
name.  It returns a boolean value indicating whether the user has the
indicated authority or not.  Apart from the indidivual authority
names, this method also supports the combined authority names 'all',
'allcmd' and 'allmqi'.

=head2 authority_command

This method requires one parameter, an entity name, and returns a
string with authorities suitable for use in a C<setmqaut> command.  If
the entity holds 'connect' authority, the string includes '+connect',
otherwise it will include '-connect'.  In order to keep the string
short, the combined authority values 'all', 'allcmd' and 'allmqi' will
be used when appropriate.

=head1 BUGS

This module only works with MQSeries versions 5.0 and 5.1 on Unix.
Version 5.2 is not supported.

=head1 SEE ALSO

MQSeries(3), MQSeries::Config::Authority(3)

=cut
