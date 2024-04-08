#
# MQSeries::Message::ConfigEvent - Config Event Message
#
# (c) 2002-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: ConfigEvent.pm,v 37.4 2012/09/26 16:15:15 jettisu Exp $
#

package MQSeries::Message::ConfigEvent;

use strict;
use Carp;
use Convert::EBCDIC;

use MQSeries qw(:functions);
use MQSeries::Message;
use MQSeries::Command::Base; # for valuemap translators

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message);

require "MQSeries/Message/ConfigEvent.pl";
require "MQSeries/Command/PCF/ResponseParameters.pl";

#
# Conversion routine on get: decode Config Event message into data
#
sub GetConvert {
    my ($this, $buffer) = @_;

    $this->{Buffer} = $buffer;

    my $offset = 0;
    my $retval = {};

    #
    # The first chunk of the message is the MQCFH (Event Header).
    # We check the length, version and event type.
    #
    my $type    = $this->_readNumber($buffer, 0, 4);
    my $length  = $this->_readNumber($buffer, 4, 4);
    my $version = $this->_readNumber($buffer, 8, 4);
    my $reason  = $this->_readNumber($buffer, 28, 4);
    confess "Invalid type [$type] (not MQCFT_EVENT)"
      unless ($type == MQSeries::MQCFT_EVENT);
    confess "Unexpected version [$version] (not MQCFH_VERSION_2)"
      unless ($version == 2) ; # MQSeries::MQCFH_VERSION_2
    #confess "Unexpected reason code [$reason]"
    #  unless ($reason == MQSeries::MQRC_CONFIG_CHANGE_OBJECT ||
    #          $reason == MQSeries::MQRC_CONFIG_CREATE_OBJECT ||
    #          $reason == MQSeries::MQRC_CONFIG_DELETE_OBJECT ||
    #          $reason == MQSeries::MQRC_CONFIG_REFRESH_OBJECT);
    $retval->{Version} = $version;
    $retval->{Reason} = $reason . " - " . MQReasonToText($reason);
    confess "Unknown reason [$reason]"
      unless (defined MQReasonToText($reason));
    $offset += $length;

    while ($offset < length $buffer) {
        $length = $this->_readNumber($buffer, $offset+4, 4);
        $type = $this->_readNumber($buffer, $offset, 4);
        my $id  = $this->_readNumber($buffer, $offset+8, 4);

        #
        # For QMgr change events, there is a rogue chunk with id 27.
        #
        # This corresponds to MQIA_CPI_LEVEL, an undocumented and
        # unsupported IBM-internal value originally intended to
        # document the MQI level supported by the queue manager.
        #
        # Skip it...
        #
        next if ($id == 27);    # MQIA_CPI_LEVEL

        my $label = $MQSeries::Message::ConfigEvent::ResponseParameters{$id};
        if (!defined $label && defined $retval->{ObjectType}) {
            my $rg = $MQSeries::Command::PCF::ResponseParameters{ $retval->{ObjectType} } || {};
            foreach my $param (keys %$rg) {
                my $macro = $rg->{$param}[0];
                #print "have param [$param] value [$macro]\n";
                if ($macro == $id) {
                    $label = $param;
                    last;
                }
            }
        }

        my $value;

        if ($type == MQSeries::MQCFT_STRING) {
            my $datalen = $this->_readNumber($buffer, $offset+16, 4);
            my $bytes = $this->_readByte($buffer, $offset+20, $datalen);
            $value = Convert::EBCDIC::ebcdic2ascii($bytes);
            $value =~ s!\s+$!!;
        } elsif ($type == MQSeries::MQCFT_STRING_LIST) {
            my $count = $this->_readNumber($buffer, $offset+16, 4);
            confess "Invalid [$label] entry (list with length zero) at offset [$offset]" unless ($count);
            my $data = [];
            my $loff = 20;
            my $str_len = $this->_readNumber($buffer, $loff, 4);
            $loff += 4;
            foreach my $entry (1..$count) {
                my $bytes = $this->_readByte($buffer, $loff, $str_len);
                $loff += $str_len;
                $bytes = Convert::EBCDIC::ebcdic2ascii($bytes);
                $bytes =~ s!\s+$!!;
                push @$data, $bytes;
            }

            $value = $data;
        } elsif ($type == 9) { # MQSeries::MQCFT_BYTE_STRING
            my $datalen = $this->_readNumber($buffer, $offset+12, 4);
            my $bytes = $this->_readByte($buffer, $offset+16, $datalen);
            $bytes =~ s!(.)!sprintf("%02x ", ord($1))!eg;
            $value = $bytes;
        } elsif ($type == MQSeries::MQCFT_INTEGER) {
            $value = $this->_readNumber($buffer, $offset+12, 4);
            my $enum = $MQSeries::Message::ConfigEvent::ResponseEnums{$label};
            my $renum = $MQSeries::Command::PCF::ResponseValues{$label};
            if (defined $enum) {
                if (defined $enum->{$value}) {
                    $value = $enum->{$value};
                } else {
                    $value .= " - <unknown $label>";
                }
            } elsif (ref($renum) eq "CODE") {
                # VALUEMAP-CODEREF
                $value = $renum->(decodepcf => $value);
            } elsif (defined $renum) {
                #print STDERR "Have reverse enum [$label]\n";
                foreach my $key (keys %$renum) {
                    my $rval = $renum->{$key};
                    next unless ($value == $rval);
                    $value = $key;
                    last;
                }
            } else {
                # Value is okay
            }
        } elsif ($type == 5 ) { # MQSeries::MQCFT_INTEGER_LIST)
            my $count = $this->_readNumber($buffer, $offset+12, 4);
            confess "Invalid [$label] entry (list with length zero) at offset [$offset]" unless ($count);
            my $data = [];
            my $loff = 16;
            foreach my $entry (1..$count) {
                my $lvalue = $this->_readNumber($buffer, $offset+$loff, 4);
                $loff += 4;
                my $enum = $MQSeries::Message::ConfigEvent::ResponseEnums{$label};
                my $renum = $MQSeries::Command::PCF::ResponseValues{$label};
                if (defined $enum) {
                    if (defined $enum->{$lvalue}) {
                        $lvalue = $enum->{$lvalue};
                    } else {
                        $lvalue .= " - <unknown $label>";
                    }
                } elsif (ref($renum) eq "CODE") {
                    # VALUEMAP-CODEREF
                    $lvalue = $renum->(decodepcf => $lvalue);
                } elsif (defined $renum) {
                    #print STDERR "Have reverse enum [$label]\n";
                    foreach my $key (keys %$renum) {
                        my $rval = $renum->{$key};
                        next unless ($lvalue == $rval);
                        $lvalue = $key;
                        last;
                    }
                } else {
                    # Value is okay
                }
                push @$data, $lvalue;
            }
            $value = $data;

        } else {
            confess "Unexpected chunk type [$type] for id [$id] [$label] at offset [$offset]";
        }

        unless (defined $label) {
            print STDERR "Unexpected chunk id [$id] with value [$value] at offset [$offset] for object type [$retval->{ObjectType}]\n";
            next;               # See continue block
        }

        #print STDERR "Have [$label] value [$value]\n";
        $retval->{$label} = $value;
    } continue {
        $offset += $length;
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

sub _readNumber {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return unpack "l", pack "L", unpack("N", substr($data,$offset,$length));
}


sub _readByte {
    my $class = shift;
    my ($data,$offset,$length) = @_;
    return substr($data,$offset,$length);
}


1;


__END__

=head1 NAME

MQSeries::Message::ConfigEvent -- Class to decode mainframe WMQ Config Event messages

=head1 SYNOPSIS

  use MQSeries::Message::ConfigEvent;

  #
  # Get a message from a CONFIG.EVENT queue
  #
  my $qmgr_obj = MQSeries::QueueManager->new(QueueManager => 'TEST.QM');
  my $queue = MQSeries::Queue->
    new(QueueManager => $qmgr_obj,
        Queue        => 'SYSTEM.ADMIN.CONFIG.EVENT',
        Mode         => 'input');
  my $msg = MQSeries::Message::ConfigEvent->new();
  $queue->Get(Message => $msg, 'Convert' => 0);
  my $data = $msg->Data(); # Hash-reference

=head1 DESCRIPTION

With WebSphere MQ 5.3 for z/OS, IBM added a new feature called
"configuration events".  If enabled, each object change, create,
delete or refresh in the z/OS queue manager causes an event to be
generated that describes the object.  (A change generates two events -
before and after.)  This is extremely useful, as it leaves an audit
trail of all changes.

However, in all their wisdom, IBM decided I<not> to support this
message type on distributed queue managers (Unix, NT, AS/400).  If you
configure a mainframe queue manager to forward this event to a
distributed queue manager, then try to get the message using the
MQGMO_CONVERT option, a failure occurs and an FDC is generated on the
queue manager.  IBM does not intend to fix this - it is broken as
designed.

Since we I<do> want to keep an audit trail of all changes on a Unix
host, it is necessary to write custom decoding logic, which is
provided in this class.

=head1 METHODS

=head2 GetConvert

This methods is not called by the users application, but is used
internally by MQSeries::Queue::Get().

GetConvert() decodes a configuration event into a hash-reference that
described the event in detail.

=head1 WARNING

When you configure the z/OS queue manager to forward the messages on
the SYSTEM.ADMIN.CONFIG.EVENT queue to a Unix or Windows queue
managers, make sure that the channel used has DataConversion set to
off.

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3), MQSeries::Message(3), Convert::EBCDIC(3)

The "Event Monitoring" manual for WMQ 5.3 (Document Number SC34-6069-00).

=cut

