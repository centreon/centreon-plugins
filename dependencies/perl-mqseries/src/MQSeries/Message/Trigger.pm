#
# MQSeries::Message::Trigger - Trigger Message
#
# (c) 2003-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: Trigger.pm,v 33.11 2012/09/26 16:15:18 jettisu Exp $
#

package MQSeries::Message::Trigger;

use strict;
use Carp;

use MQSeries::Message;

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message);

require "MQSeries/Command/PCF/ResponseValues.pl"; # For ApplType
my %ApplType =
  reverse %{ $MQSeries::Command::PCF::ResponseValues{'ApplType'} };

#
# Conversion routine on get: decode TriggerMonitor message into data
#
sub GetConvert {
    my ($this, $buffer) = @_;

    $this->{Buffer} = $buffer;

    my $offset = 0;
    my $retval = {};

    #
    # The message is in MQTM format.  We check the structure id and
    # version.  Depending on the queue manager platform, we need to
    # read numbers in big-endian format (Solaris) or little-endian
    # format (Linux/Intel).
    #
    my $type = $this->_readByte($buffer, 0, 4);
    my $little_endian = ord($this->_readByte($buffer, 4, 1));
    my $version = ($little_endian ?
                   $this->_readLENumber($buffer, 4, 4) :
                   $this->_readBENumber($buffer, 4, 4));
    confess "Invalid type [$type] (not MQTM_STRUC_ID_ARRAY)"
      unless ($type eq 'TM  ');
    confess "Unexpected version [$version] (not MQTM_VERSION_1)"
      unless ($version == 1) ; # MQSeries::MQTM_VERSION_1
    $retval->{Version} = $version;
    $offset += 8;

    #
    # Read QName (48), ProcessName (48), TriggerData (64)
    #
    foreach my $pair ( [ qw(QName 48) ],
                       [ qw(ProcessName 48) ],
                       [ qw(TriggerData 64) ] ) {
        my ($field, $size) = @$pair;
        my $bytes = $this->_readByte($buffer, $offset, $size);
        $offset += $size;
        $bytes =~ s!\s+$!!;
        next if ($bytes eq '');
        $retval->{$field} = $bytes;
    }

    #
    # Read and convert ApplType
    #
    {
        my $appl_type = ($little_endian ?
                         $this->_readLENumber($buffer, $offset, 4) :
                         $this->_readBENumber($buffer, $offset, 4));
        $retval->{ApplType} = $ApplType{$appl_type} ||
          "<unknown ApplType value $appl_type>";
        $offset += 4;
    }

    #
    # Read ApplId (256), EnvData (128), UserData (128)
    #
    foreach my $pair ( [ qw(ApplId 256) ],
                       [ qw(EnvData 128) ],
                       [ qw(UserData 128) ] ) {
        my ($field, $size) = @$pair;
        my $bytes = $this->_readByte($buffer, $offset, $size);
        $offset += $size;
        $bytes =~ s!\s+$!!;
        next if ($bytes eq '');
        $retval->{$field} = $bytes;
    }

    return $retval;
}


#
# We do not support generating Config Event messages
#
sub PutConvert {
    confess "Creating / Putting Config Event messages is not supported";
}


# ------------------------------------------------------------------------

#
# Read number in Big-Endian format (Network order, e.g. Solaris)
#
sub _readBENumber {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack("N", substr($data,$offset,$length));
}

#
# Read number in Little-Endian format (VAX order, e.g. Linux/Intel)
#
sub _readLENumber {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack("V", substr($data,$offset,$length));
}


sub _readByte {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return substr($data,$offset,$length);
}


1;


__END__

=head1 NAME

MQSeries::Message::Trigger -- Class to decode trigger messages

=head1 SYNOPSIS

  use MQSeries::Message::Trigger;

  #
  # Get a message from an initiation queue
  #
  my $qmgr_obj = MQSeries::QueueManager->new(QueueManager => 'TEST.QM');
  my $queue = MQSeries::Queue->
    new(QueueManager => $qmgr_obj,
        Queue        => 'APPGROUP.APPNAME.INITQ',
        Mode         => 'input');
  my $msg = MQSeries::Message::Trigger->new();
  $queue->Get(Message => $msg, 'Convert' => 0);
  my $data = $msg->Data(); # Hash-reference

=head1 DESCRIPTION

This class is used for a trigger monitor written in perl.  It can
decode a trigger message and break it into structure fields.

=head1 METHODS

=head2 GetConvert

This methods is not called by the users application, but is used
internally by MQSeries::Queue::Get().

GetConvert() decodes a trigger message into a hash-reference that
described the triggerevent in detail.

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3), MQSeries::Message(3)

The "Application Programming Guide".

=cut

