#
# $Id: Properties.pm,v 33.11 2012/09/26 16:15:18 jettisu Exp $
#
# (c) 2009-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Properties;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use Params::Validate qw(validate);

our $VERSION = '1.34';

#
# Constructor
#
# Parameters:
# - Carp: warning routine
# - Options: hash reference for MQCMHO
# - QueueManager: MQSeries::QueueManager object
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = validate(@_, { 'Carp'         => 0,
                                'Options'      => 0,
                                'QueueManager' => 1,
                              });

    #
    # Verify Carp parameter
    #
    if (defined $params{Carp} && ref $params{Carp} ne 'CODE') {
        die "Invalid argument: 'Carp' must be a CODE reference";
    } elsif (!defined $params{Carp}) {
        $params{Carp} = \&carp;
    }

    #
    # Verify QueueManager parameter
    #
    unless (ref $params{QueueManager} &&
            $params{QueueManager}->isa("MQSeries::QueueManager")) {
        die "Invalid 'QueueManager' parameter: must be an MQSeries::QueueManager object";
    }

    my $self = bless { 'Carp'         => $params{Carp},
                       'Options'      => $params{Options} || {},
                       'QueueManager' => $params{QueueManager},
                       'CompCode'     => 0,
                       'Reason'       => 0,
                     }, $class;

    #
    # Call MQCRTMH
    #
    my $Hmsg = MQCRTMH($self->{QueueManager}->{Hconn},
                       $self->{Options},
                       $self->{CompCode},
                       $self->{Reason},
                      );
    if ($self->{CompCode} == MQSeries::MQCC_OK) {
        $self->{Hmsg} = $Hmsg;
        return $self;
    } elsif ($self->{CompCode} == MQSeries::MQCC_WARNING ||
             $self->{CompCode} == MQSeries::MQCC_FAILED) {
        $self->{Carp}->("MQCRTMH failed (Reason = $self->{Reason})");
        return;
    }
    $self->{Carp}->("MQCRTMH failed, unrecognized CompCode: '$self->{CompCode}'");
    return;
}


#
# Return matching properties, as name/value pairs in a hash ref
#
# Parameters:
# - Name (may be wildcard)
# - Type
# Returns:
# - Hash reference with (Name -> Value)
#
sub GetProperties {
    my $self = shift;
    my %params = validate(@_, { 'Name' => 0,
                                'Type' => 0,
                              });

    $params{Name} = '' unless (defined $params{Name});
    my $options = { 'Options' => MQSeries::MQIMPO_INQ_FIRST, };
    my $length = 1024;          # FIXME: remember across calls
    my $retval = {};
    while (1) {
        my $type = MQSeries::MQTYPE_AS_SET;
        if (defined $params{Type} &&
            $params{Type} ne MQSeries::MQTYPE_AS_SET) {
            $type = $params{Type};
            $options->{Options} |= MQSeries::MQIMPO_CONVERT_TYPE;
        }
        my $len = $length;
        my $prop_desc = {};
        my $prop = MQINQMP($self->{QueueManager}->{Hconn},
                           $self->{Hmsg},
                           $options,
                           $params{Name},
                           $prop_desc,
                           $type,
                           $len,
                           $self->{CompCode},
                           $self->{Reason});
        if ($self->{CompCode} != MQSeries::MQCC_OK ||
            $self->{Reason} != MQSeries::MQRC_NONE) {
            if ($self->{Reason} == MQSeries::MQRC_PROPERTY_NOT_AVAILABLE) {
                last;
            } elsif ($self->{Reason} == MQSeries::MQRC_PROPERTY_VALUE_TOO_BIG &&
                     $len > $length) {
                #warn "oops - size too small (have $length, need $len) - re-read\n";
                $length = $len;
                $options->{Options} &= ~MQSeries::MQIMPO_INQ_FIRST;
                $options->{Options} &= !MQSeries::MQIMPO_INQ_NEXT;
                $options->{Options} |= MQSeries::MQIMPO_INQ_PROP_UNDER_CURSOR;
                redo;
            } else {
                $self->{Carp}->("MQINQMP failed: (Reason => $self->{Reason}\n");
                last;
            }
        }

        #
        # If a property name is repeated, return only the first one;
        # this matches selector behavior.
        #
        unless (defined $retval->{ $options->{ReturnedName} }) {
            $retval->{ $options->{ReturnedName} } = $prop;
        }
    } continue {
        $options->{Options} &= ~MQSeries::MQIMPO_INQ_FIRST;
        $options->{Options} &= ~MQSeries::MQIMPO_INQ_PROP_UNDER_CURSOR;
        $options->{Options} |= MQSeries::MQIMPO_INQ_NEXT;
    }

    return $retval;
}


#
# Return matching properties, in detail in an array
#
# Parameters:
# - Name (may be wildcard)
# - Type
# Returns:
# - Array with ({ details })
#
sub GetDetailedProperties {
    my $self = shift;
    my %params = validate(@_, { 'Name' => 0,
                                'Type' => 0,
                              });

    $params{Name} = '' unless (defined $params{Name});
    my $options = { 'Options' => MQSeries::MQIMPO_INQ_FIRST, };
    my $length = 1024;          # FIXME: remember across calls
    my @retval;
    while (1) {
        my $type = MQSeries::MQTYPE_AS_SET;
        if (defined $params{Type} &&
            $params{Type} ne MQSeries::MQTYPE_AS_SET) {
            $type = $params{Type};
            $options->{Options} |= MQSeries::MQIMPO_CONVERT_TYPE;
        }
        my $len = $length;
        my $prop_desc = {};
        my $prop = MQINQMP($self->{QueueManager}->{Hconn},
                           $self->{Hmsg},
                           $options,
                           $params{Name},
                           $prop_desc,
                           $type,
                           $len,
                           $self->{CompCode},
                           $self->{Reason});
        if ($self->{CompCode} != MQSeries::MQCC_OK ||
            $self->{Reason} != MQSeries::MQRC_NONE) {
            if ($self->{Reason} == MQSeries::MQRC_PROPERTY_NOT_AVAILABLE) {
                last;
            } elsif ($self->{Reason} == MQSeries::MQRC_PROPERTY_VALUE_TOO_BIG &&
                     $len > $length) {
                #warn "oops - size too small (have $length, need $len) - re-read\n";
                $length = $len;
                $options->{Options} &= ~MQSeries::MQIMPO_INQ_FIRST;
                $options->{Options} &= !MQSeries::MQIMPO_INQ_NEXT;
                $options->{Options} |= MQSeries::MQIMPO_INQ_PROP_UNDER_CURSOR;
                redo;
            } else {
                $self->{Carp}->("MQINQMP failed: (Reason => $self->{Reason}\n");
                last;
            }
        }
        # FIXME: what prop_desc fields to add?
        my $entry = { Name     => $options->{ReturnedName},
                      Type     => $type,
                      Value    => $prop,
                      Encoding => $options->{ReturnedEncoding},
                    };
        if ($type == MQSeries::MQTYPE_STRING) {
            $entry->{CCSID} = $options->{ReturnedCCSID};
        }
        push @retval, $entry;
    } continue {
        $options->{Options} &= ~MQSeries::MQIMPO_INQ_FIRST;
        $options->{Options} &= ~MQSeries::MQIMPO_INQ_PROP_UNDER_CURSOR;
        $options->{Options} |= MQSeries::MQIMPO_INQ_NEXT;
    }

    return @retval;
}


#
# Set a single property, overwriting an existing property with the
# same name (use the low-level API for duplicate property values).
#
# As properties are all client-side, there's no set-multiple call -
# it doesn't improve performance and would complicate the API.
#
# Parameters:
# - Name
# - Value (may be undef)
# - Type (optional, default is MQTYPE_STRING)
# FIXME: if necessary, add below, or selected fields from below
# - SetPropsOpts (optional, hashref: encoding, ...)
# - PropDesc (optional, hash-ref)
# Returns: boolean
#
sub SetProperty {
    my $self = shift;
    my %params = validate(@_, { 'Name'  => 1,
                                'Value' => 1,  # May be undef
                                'Type'  => 0,
                              });
    unless (defined $params{Type}) {
        $params{Type} = MQSeries::MQTYPE_STRING;
    }
    MQSETMP($self->{QueueManager}->{Hconn},
            $self->{Hmsg},
            {},                 # SetPropOpts
            $params{Name},
            {},                 # PropDesc
            $params{Type},
            $params{Value},
            $self->{CompCode},
            $self->{Reason});
    if ($self->{CompCode} != MQSeries::MQCC_OK ||
        $self->{Reason} != MQSeries::MQRC_NONE) {
        $self->{Carp}->("MQSETMP failed: (Reason => $self->{Reason}\n");
        return;
    }
    return 1;
}


#
# Delete a property.  If a wildcard is specified, deletes
# the first matching property.
#
# Parameters:
# - Name (no wildcard allowed)
# FIXME: maybe DltPropOpts
# Returns: boolean
#
sub DeleteProperty {
    my $self = shift;
    my %params = validate(@_, { 'Name' => 1, });

    MQDLTMP($self->{QueueManager}->{Hconn},
            $self->{Hmsg},
            {},                 # DltPropOpts
            $params{Name},
            $self->{CompCode},
            $self->{Reason});
    if ($self->{CompCode} != MQSeries::MQCC_OK ||
        $self->{Reason} != MQSeries::MQRC_NONE) {
        $self->{Carp}->("MQDLTMP failed: (Reason => $self->{Reason}\n");
        return;
    }
    return 1;
}


#
# Destructor
#
sub DESTROY {
    my $self = shift;

    MQDLTMH($self->{QueueManager}->{Hconn},
            $self->{Hmsg},
            {},
            $self->{CompCode},
            $self->{Reason});
    if ($self->{CompCode} != MQSeries::MQCC_OK ||
        $self->{Reason} != MQSeries::MQRC_NONE ) {
        $self->{Carp}->("MQDLTMH failed: (Reason => $self->{Reason}\n");
    }
}


#
# Return the completion code from the most recent operation
#
sub CompCode {
    my $self = shift;
    return $self->{CompCode};
}


#
# Return the reason code from the most recent operation
#
sub Reason {
    my $self = shift;
    return $self->{Reason};
}


1;

__END__

=head1 NAME

MQSeries::Properties -- OO interface to MQSeries message properties

=head1 SYNOPSIS

  use MQSeries qw(:functions);
  use MQSeries::Queue;
  use MQSeries::Message;

  #
  # Open a queue for output, and write a message with properties
  #
  my $qmgr_obj = MQSeries::QueueManager->
    new('QueueManager' => 'some.queue.manager');
  my $queue = MQSeries::Queue->new(QueueManager => $qmgr_obj,
                                   Queue        => 'SOME.QUEUE',
                                   Mode         => 'output')
    or die("Unable to open queue.\n");

  my $msg = MQSeries::Message->new(Data => "Example message data');

  $queue->Put(Message    => $msg,
              Properties => { 'perl.MQSeries.example' => 'property value', },
             );

  #
  # Alternative: perform a Put1 with properties
  #
  my $qmgr_obj = MQSeries::QueueManager->
    new('QueueManager' => 'some.queue.manager');
  my $msg = MQSeries::Message->new(Data => "Example message data');

  $qmgr_obj->Put1(Queue   =  > 'SOME.QUEUE',
                  Message    => $msg,
                  Properties => { 'perl.MQSeries.example' => 'property value', },
                 );

  #
  # Open a queue for input, read a message, and then list the properties
  #
  my $queue = MQSeries::Queue->new(QueueManager => $qmgr_obj,
                                   Queue        => 'SOME.QUEUE',
                                   Mode         => 'input')
    or die("Unable to open queue.\n");

  my $msg = MQSeries::Message->new();
  $queue->Get(Message    => $msg)
    or die("Unable to get message");

  my $props_hashref = $msg->Properties()->GetProperties();

  #
  # Create a properties object and manipulate it directly.  It can
  # then be passed to a $queue->Put() operation as the Properties
  # parameter.
  #
  my $props = MQSeries::Properties->new('QueueManager' => $qmgr_obj);
  $props->SetProperty(Name  => 'perl.MQSeries.demo.int',
                      Value => 42,
                      Type  => MQSeries::MQTYPE_INT32);
  $props->SetProperty(Name  => 'perl.MQSeries.demo.float',
                      Value => 3.141265,
                      Type  => MQSeries::MQTYPE_FLOAT64);
  my $prop_hashref = $props->GetProperties('Name' => 'perl.MQSeries.%');
  $props->DeletePropery(Name => 'perl.MQSeries.demo.float');

=head1 DESCRIPTION

The C<MQSeries::Properties> class is used to work with message
properties, a new feature of MQ v7.  Message properties are attached
to a message and can be used for compatibility with JMS applications,
for selectors (see the C<SelectionString> parameter on the
C<MQSeries:Queue> class), and for publish and subscribe.

Message properties are only available if the MQSeries module has been
compiled against MQ v7 headers and libraries, and if the queue manager
connected to runs MQ v7 or above.

The C<MQseries::Properties> class represents a message handle (Hmsg)
and the implementation uses the message-handle related MQI calls.
Properties can be specified when messages are put and are implicitly
retrieved when messages are read.

At the MQ level, message properties are typed; data types like text
strings, byte strings, integers, floats and booleans are supported.
The property type can be relevant for selector strings.  At the perl
level, properties are assumed to be strings unless otherwise
specified, though the full range of types is supported.

=head1 METHODS

=head2 new

The property class constructor.  This method is normally not invoked
directly; instead, it is invoked by Put/Put1/Get operations when
necessary.  It can be invoked directly when a properties object is
created to be used across multiple Put or Put1 calls.

The constructor takes one named parameter:

=over 4

=item QueueManager

An C<MQSeries::QueueManager> object

=back

=head2 GetProperties

This method returns the property as a hash reference, i.e. key/value
pairs.  If a property has multiple values (this is technically
possible but not recommended), it returns the first value.  This
matches the behavior of selectors.

This method has two optional named parameters:

=over 4

=item Name

The name of the properties to be retrieved.  This may contain a
wildcard, e.g. 'perl.MQSeries.%'.

=item Type

The property type to be returned.  This is not a selection mechanism,
but performs data conversion at the MQ level.  For example, if the
type specified is C<MQSeries::MQTYPE_FLOAT64>, the properties will be
converted to 64-bit floating point numbers by MQ before being
returned; an error will be retrurned if the data cannot be converted.
Given the flexibility of perl when dealing with scalar values, this
parameter is rarely required.

=back

=head2 GetDetailedProperties

This method returns all the properties in detail, in the order they
are specified and including duplicate values.  This method has two
optional named parameters:

=over 4

=item Name

The name of the properties to be retrieved.  This may contain a
wildcard, e.g. 'perl.MQSeries.%'.

=item Type

The property type to be returned.  This is not a selection mechanism,
but performs data conversion at the MQ level.  For example, if the
type specified is C<MQSeries::MQTYPE_FLOAT64>, the properties will be
converted to 64-bit floating point numbers by MQ before being
returned; an error will be retrurned if the data cannot be converted.
Given the flexibility of perl when dealing with scalar values, this
parameter is rarely required.

=back

It returns an array of hash references, with one hash reference per
property value.  Each hash reference can contain the following keys:

=over 4

=item Name

The property name

=item Value

The property value (this can be C<undef>)

=item Type

The property type, as an integer matching one of the
C<MQSeries::MQTYPE_xxx> constants.  For example, strings are returrned
as C<MQSeries::MQTYPE_STRING>.

=item Encoding

The returned encoding

=item CCSID

The returned character set id (when the type is
C<MQSeries::MQTYPE_STRING>).

=back

=head2 DeletyProperty

This method deletes a property.  It has one required named parameter:

=over 4

=item Name

The name of the property to be deleted.  This may not contain
wildcards.

=back

=head2 SetProperty

This method adds or updates a property.  It has the following named
parameters:

=over 4

=item Name

The name of the property to be added or updated.  This may not contain
wildcards.  This paramater is required.

=item Value

The property value.  This can be C<undef> for string / bytestring
properties.  This paramater is required.

=item Type

The property type, as an integer matching one of the
C<MQSeries::MQTYPE_xxx> constants.  For example, strings are specified
as C<MQSeries::MQTYPE_STRING> and 32-bit integers as
C<MQSeries::MQTYPE_INT32>.

This parameter is optional.  When not specified, the default is the
string type.

=back

The property type can be relevant when selectors are used.  For
example, if a queue is opened like this, only integer properties will
match, and string proeprties will be ignored:

  my $queue_obj = MQSeries::Queue->
    new(QueueManager    => $qmgr_obj,
        Queue           => 'SOME.QUEUE',
        Mode            => 'input',
        SelectionString => 'perl.MQSeries.test.value=5',
       );

To put a message that matches the selector, use:

  $queue_obj->Put(Message    => $msg,
                  Properties => { 'perl.MQSeries.test.value' =>
                                  { Value => 5,
                                    Type  => MQSeries::MQTYPE_INT32,
                                  }
                                },
                 );

=head2 CompCode

The completion code from the most recent low-level MQI call for the
message handle

=head2 Reason

The reason code from the most recent low-level MQI call for the
message handle

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSerie::Queue(3), MQSeries::Message(3)

=cut
