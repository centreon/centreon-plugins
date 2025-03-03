#
# $Id: DeadLetter.pm,v 33.11 2012/09/26 16:10:09 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::DeadLetter;

use strict;
use Carp;

use DynaLoader;
use Exporter;

use MQSeries qw(:functions);
use MQSeries::Message;

our $VERSION = '1.34';
our @ISA = qw( MQSeries::Message Exporter DynaLoader );
our @EXPORT_OK = qw(MQDecodeDeadLetter MQEncodeDeadLetter);

bootstrap MQSeries::Message::DeadLetter;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;

    my %MsgDesc =
      (
       Format   => MQSeries::MQFMT_DEAD_LETTER_HEADER,
      );

    #
    # This is a bit wierd.  The MQSeries::Message->new() constructor
    # will deal with the Carp argument, however, we have to error
    # check the MsgDesc argument, and would like to use the
    # user-supplied Carp argument for consistent error handling.
    # Thus, this snippet looks very different from the other
    # classes...
    #
    if ( $args{Carp} ) {
        if ( ref $args{Carp} ne "CODE" ) {
            carp "Invalid argument: 'Carp' must be a CODE reference\n";
            return;
        }
    } else {
        $args{Carp} = \&carp;
    }

    if ( exists $args{MsgDesc} ) {
        unless ( ref $args{MsgDesc} eq "HASH" ) {
            $args{Carp}->("Invalid argument: 'MsgDesc' must be a HASH reference.\n");
            return;
        }
        foreach my $key ( keys %{$args{MsgDesc}} ) {
            $MsgDesc{$key} = $args{MsgDesc}->{$key};
        }
    }

    $args{MsgDesc} = {%MsgDesc};

    my $self = MQSeries::Message->new(%args) || return;

    if ( $args{Header} ) {
        $self->{Header} = $args{Header};
    } else {
        $self->{Header} = {};
    }

    bless ($self, $class);

    return $self;
}


sub Header {
    my $self = shift;

    if ( $_[0] ) {
        exists $self->{Header}->{$_[0]} ? return $self->{Header}->{$_[0]} : return;
    } else {
        return $self->{Header};
    }
}


sub GetConvert {
    my $self = shift;
    ($self->{Buffer}) = @_;
    my $data = "";

    unless ( ($self->{"Header"},$data) =
             MQDecodeDeadLetter($self->{Buffer},length($self->{Buffer})) ) {
        $self->{Carp}->("Unable to decode MQSeries Dead Letter Message\n");
        return undef;
    }

    return $data;
}


sub PutConvert {
    my $self = shift;
    my ($data) = @_;

    my $buffer = MQEncodeDeadLetter($self->{"Header"},$data,length($data));

    if ( $buffer ) {
        return $buffer;
    } else {
        $self->{Carp}->("Unable to encode MQSeries Dead Letter Message\n");
        return undef;
    }
}

1;

__END__

=head1 NAME

MQSeries::Message::DeadLetter -- OO interface to the Dead Letter message type

=head1 SYNOPSIS

  use MQSeries;
  use MQSeries::Message::DeadLetter;

=head1 DESCRIPTION

The MQSeries::Message::DeadLetter class is an interface to the Dead
Letter messages delivered to the dead letter queue (usually
SYSTEM.DEAD.LETTER.QUEUE) by the queue manager.

=head1 METHODS

Since this class is a subclass of MQSeries::Message, all of the
latters methods are availables as well as the following:

=head2 new

The constructor takes all of the same key/value pairs as the
MQSeries::Message constructor, as well as the following additional keys:

  Key                   Value
  ===                   =====
  Header                HASH reference

NOTE: The MsgDesc->Format string defaults to MQFMT_DEAD_LETTER_HEADER
automatically, and should not be specified.  If it is overridden, and
you are using this class to put messages to the dead letter queue,
then in all likelyhood you may experience problems with the
applications that process the DLQ.

=over 4

=item Header

The value of this key is a HASH reference representing the MQDLH
header structure.  See the docs for method of the same name below for
more information.

=back

=head2 Header

This method returns the HASH reference representing the MQDLH
structure prepended to the original message body.

=head1 SEE ALSO

MQSeries::Message(3)

=cut
