#
# $Id: Event.pm,v 33.15 2012/09/26 16:15:16 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::Event;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::Message::System;

require "MQSeries/Message/Event.pl";

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::System);


sub import {
    my ($class) = @_;

    $class->_Register(\&_Translatable);

    return;
}


sub _Translatable {
    my ($self, $header) = @_;

    if ($header->{"Type"} == MQSeries::MQCFT_EVENT &&
       ($header->{"Command"} == MQSeries::MQCMD_Q_MGR_EVENT ||
        $header->{"Command"} == MQSeries::MQCMD_PERFM_EVENT ||
        $header->{"Command"} == MQSeries::MQCMD_CHANNEL_EVENT)) {
       return (\%MQSeries::Message::Event::ResponseParameters,
               "%MQSeries::Message::Event::ResponseParameters");
    }

    return;
}


sub EventHeader {
    my $self = shift;

    return $self->Header(@_);
}


sub EventData {
    my $self = shift;

    return $self->Parameters(@_);
}

1;

__END__

=head1 NAME

MQSeries::Message::Event -- OO Class for decoding MQSeries event messages

=head1 SYNOPSIS

  use MQSeries::Message::Event;
  my $message = MQSeries::Message::Event->new;

=head1 DESCRIPTION

This class is a subclass of MQSeries::Message::System which includes a
table for MQSeries::Message::System to use to decode standard MQSeries
Event messages.

=head1 METHODS

=head2 EventHeader

This method can be used to query the Header data structure.  If no
argument is given, then the entire Header hash is returned.  If a
single argument is given, then this is interpreted as a specific key,
and the value of that key in the Header hash is returned.

The keys in the Header hash are the fields from the MQCFH structure.
See the "MQSeries Programmable System Management" documentation.

=head2 EventData

This method can be used to query the Parameters data structure.  If no
argument is given, then the entire Parameters hash is returned.  If a
single argument is given, then this is interpreted as a specific key,
and the value of that key in the Parameters hash is returned.

The keys in the Parameters hash vary, depending on the specific event.
In general, these are the strings shown in the documentation for each
individual event described in the "MQSeries Programmable System
Management" documentation.  The data structures in the eventdata in
the original event are identified with macros, such as
"MQCA_Q_MGR_NAME".  Rather than use these (in some cases very cryptic)
macros, the strings shown in the IBM MQSeries documentation are used
instead.  In this case, "QMgrName".

The macros are mapped to strings as follows:

   Macro                                Key
   =====                                ===
   MQCACF_APPL_NAME                     ApplName
   MQCACF_AUX_ERROR_DATA_STR_1          AuxErrorDataStr1
   MQCACF_AUX_ERROR_DATA_STR_2          AuxErrorDataStr2
   MQCACF_AUX_ERROR_DATA_STR_3          AuxErrorDataStr3
   MQCACF_BRIDGE_NAME                   BridgeName
   MQCACF_OBJECT_Q_MGR_NAME             ObjectQMgrName
   MQCACF_USER_IDENTIFIER               UserIdentifier
   MQCACH_CHANNEL_NAME                  ChannelName
   MQCACH_CONNECTION_NAME               ConnectionName
   MQCACH_FORMAT_NAME                   Format
   MQCACH_SSL_HANDSHAKE_STAGE           SSLHandshakeStage
   MQCACH_SSL_PEER_NAME                 SSLPeerName
   MQCACH_XMIT_Q_NAME                   XmitQName
   MQCA_BASE_Q_NAME                     BaseQName
   MQCA_PROCESS_NAME                    ProcessName
   MQCA_Q_MGR_NAME                      QMgrName
   MQCA_Q_NAME                          QName
   MQCA_XMIT_Q_NAME                     XmitQName
   MQIACF_AUX_ERROR_DATA_INT_1          AuxErrorDataInt1
   MQIACF_AUX_ERROR_DATA_INT_2          AuxErrorDataInt2
   MQIACF_BRIDGE_TYPE                   BridgeType
   MQIACF_COMMAND                       Command
   MQIACF_CONV_REASON_CODE              ConversionReasonCode
   MQIACF_ERROR_IDENTIFIER              ErrorIdentifier
   MQIACF_OPEN_OPTIONS                  Options
   MQIACF_REASON_QUALIFIER              ReasonQualifier
   MQIACH_CHANNEL_TYPE                  ChannelType
   MQIACH_SSL_RETURN_CODE               SSLReturnCode
   MQIA_APPL_TYPE                       ApplType
   MQIA_HIGH_Q_DEPTH                    HighQDepth
   MQIA_MSG_DEQ_COUNT                   MsgDeqCount
   MQIA_MSG_ENQ_COUNT                   MsgEnqCount
   MQIA_Q_TYPE                          QType
   MQIA_TIME_SINCE_RESET                TimeSinceReset

These functions are simply wrappers around the Header and Parameters
methods in MQSeries::Message::PCF and are provided for backwards
compatibility with the previous implementation.

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3),
MQSeries::Message(3), MQSeries::Message::PCF(3),
MQSeries::Message::System(3)

=cut
