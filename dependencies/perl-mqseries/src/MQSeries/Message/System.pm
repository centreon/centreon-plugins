#
# $Id: System.pm,v 37.4 2012/09/26 16:15:18 jettisu Exp $
#
# (c) 2011-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::System;

use 5.008;

use strict;
use Carp;

use MQSeries::Message::PCF qw(MQDecodePCF);

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::PCF);

my %xlat; # translation table function list


sub PutConvert {
    my $self = shift;
    my $class = ref($self) || $self;
    $self->{"Carp"}->("MQPUTing object of type $class is not supported\n");
    return undef;
}


sub GetConvert {
    my $self = shift;
    my $class = ref($self) || $self;

    #
    # Save the original message in the message buffer.  In case we
    # need it later for something.
    #
    ($self->{Buffer}) = @_;

    #
    # First, translate the raw message to a perly PCF message
    # structure.
    #
    my ($header, $parameters) = MQDecodePCF($self->{Buffer});
    if (!defined($header) || !defined($parameters)) {
        $self->{"Carp"}->("Unable to parse PCF contents from message\n");
        return undef;
    }

    #
    # Second, translate the perly PCF message structure to a much more
    # human-friendly named-structure mess.
    #
    ($self->{"Header"}, $self->{"Parameters"}) =
        $self->_UnTranslatePCF($header, $parameters);
    if (!defined($self->{"Header"}) || !defined($self->{"Parameters"})) {
        $self->{"Carp"}->("Unable to parse $class record from message\n");
        return undef;
    }

    #
    # The message data is useless in a system message -- it all gets
    # parsed into the Header and Parameters, so just feed back
    # something which is true.
    #
    return 1;

}


sub _Register {
    my ($class, $check) = @_;

    #
    # Stringifying the code ref ($check should be a code ref) gives us
    # something that should not get accidentally reused.  Order is not
    # respected here at all, and any conflicts in translation tables
    # are your own problem.
    #
    $xlat{$check} = $check;

    return;
}


sub _Translatable {
    my $self = shift;
    my $class = ref($self) || $self;

    #
    # Check to see if "pre-registered" classes can translate this
    # message.
    #
    foreach my $cref (keys %xlat) {
        my ($rp, $tn) = $xlat{$cref}->($self, @_);
        return ($rp, $tn) if (defined($rp));
    }

    #
    # The derived class, if any, should have overridden this method.
    # Or registered itself, at the very least.
    #
    $self->{"Carp"}->("No translation available for $class message\n");

    return;
}


sub _UnTranslatePCF {
    my $self = shift;
    my $class = ref($self) || $self;
    my ($origheader, $origparams) = @_;

    my ($ResponseParameters, $TableName) = $self->_Translatable($origheader);
    if (!$ResponseParameters) {
        $self->{"Carp"}->("Not a recognized $class message\n");
        return;
    }

    my $header = $origheader;
    my $parameters = {};
    foreach my $origparam (@{$origparams}) {
        my ($key, $value);

        if ($ResponseParameters->{$origparam->{Parameter}}) {
            $key = $ResponseParameters->{$origparam->{Parameter}};
            if (ref($key)) {
                ($key, $value) = @{$key};
            }
        }
        else {
            $self->{"Carp"}->("No such parameter '$origparam->{Parameter}' " .
                              "defined in $TableName\n");
            $key = $origparam->{Parameter};
        }

        #
        # Translate by "type" into the perl version of the message.
        # Unlike _UnTranslatePCF() in MQSeries::Command::Base, which
        # translates by way of the thing it finds for one of the value
        # names it expects.
        #
        if ($origparam->{Type} == MQSeries::MQCFT_STRING) {
            ($parameters->{$key} = $origparam->{"String"}) =~ s/[\s\0]+$//;
        }
        elsif ($origparam->{Type} == MQSeries::MQCFT_INTEGER ||
               $origparam->{Type} == MQSeries::MQCFT_INTEGER64) {
            $parameters->{$key} = $origparam->{"Value"};
        }
        elsif ($origparam->{Type} == MQSeries::MQCFT_BYTE_STRING) {
            $parameters->{$key} = unpack("H*", $origparam->{"ByteString"});
            #$parameters->{$key} = $origparam->{"ByteString"};
        }
        elsif ($origparam->{Type} == MQSeries::MQCFT_INTEGER_LIST ||
               $origparam->{Type} == MQSeries::MQCFT_INTEGER64_LIST) {
            $parameters->{$key} = $origparam->{"Values"};
        }
        elsif ($origparam->{Type} == MQSeries::MQCFT_GROUP) {
            my ($th, $tp) =
              _UnTranslatePCF($self, $origheader, $origparam->{"Group"});
            push(@{$parameters->{$key}}, $tp);
        }
        else {
            $self->{"Carp"}->("Type $origparam->{Type} " .
                              "unknown in _UnTranslatePCF");
            $value = undef; # bypass $value remapping
        }

        #
        # If we're doing value remapping (ie, from MQCA_Q_MGR_NAME to
        # "QMgrName"), and we have something that's not a ref, try to
        # remap it.
        #
        if (ref($value) && !ref($parameters->{$key})) {
            if (exists($value->{$parameters->{$key}})) {
                $parameters->{$key} = $value->{$parameters->{$key}};
            }
            else {
                $self->{"Carp"}->("Value $parameters->{$key} for $key " .
                                  "unknown in $TableName");
            }
        }
    }

    return ($header,$parameters);
}


1;

__END__

=head1 NAME

MQSeries::Message::System -- OO Class for decoding MQSeries v6 system
messages

=head1 SYNOPSIS

This class is a subclass of MQSeries::Message::PCF which provides a
GetConvert() method to decode standard MQSeries events, statistics,
and accounting messages.  It also overrides the standard PutConvert()
method with one that fails as the generation and "putting" of system
messages is not supported.  It is not intended to be used directly,
but rather as the basis of more specific system message objects.

=head1 METHODS

Since this is a subclass of MQSeries::Message::PCF, all of that
class's methods are available, as well as the following.

=head2 PutConvert, GetConvert

Neither of these methods are called by the users application, but are
used internally by MQSeries::Queue::Put() and MQSeries::Queue::Get(),
as well as MQSeries::QueueManager::Put1().

The PutConvert method will cause a failure, since this class is only
to be used for decoding MQSeries system messages, not generating them.
A future release may support the creation of such messages.

The GetConvert method decodes the message contents into the Header and
Parameters hashes, which are available via the methods of the same
name (as inherited from the base class).

=head2 Buffer

Actually, this is one of the MQSeries::Message methods, and not
specific to MQSeries::Message::System or its derivatives.  It is
important, however, to note that this class is one of those that saves
the raw buffer returned by MQGET in the object.  The Buffer method
will return the raw, unconverted PCF data in the original message.

=head2 _Register

Registers a callback function that may be used to check for a
translation table.  Derived classes may wish to call this from a
import() method instead of by overriding the _Translatable method (see
below).

=head2 _Translatable

This method is used internally to see if a derived subclass can
translate the decoded PCF commands to something more useful than the
raw numbers.  All sub-classes should override this method with one
that returns a reference to (and the the name of) a hash specific to
the message format being decoded.

=head2 _UnTranslatePCF

An internally used method that recursively remaps the PCF numbers to
friendly names.  Not meant to be called from applications, but noted
here for people who wonder what it does.

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3),
MQSeries::Message(3), MQSeries::Message::PCF(3)

=cut
