#
# $Id: Statistics.pm,v 37.6 2012/09/26 16:15:17 jettisu Exp $
#
# (c) 2011-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::Statistics;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::Message::System;

require "MQSeries/Message/Statistics.pl";

our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::System);


sub import {
    my ($class) = @_;

    $class->_Register(\&_Translatable);

    return;
}


sub _Translatable {
    my ($self, $header) = @_;

    my $subclass =
        ($header->{"Command"} == MQSeries::MQCMD_STATISTICS_MQI) ?
            "MQSeries::Message::Statistics::QueueManager" :
        ($header->{"Command"} == MQSeries::MQCMD_STATISTICS_Q) ?
            "MQSeries::Message::Statistics::Queue" :
        ($header->{"Command"} == MQSeries::MQCMD_STATISTICS_CHANNEL) ?
            "MQSeries::Message::Statistics::Channel" :
                undef;

    if ($header->{"Type"} == MQSeries::MQCFT_STATISTICS &&
        defined($subclass)) {
        bless $self, $subclass;
        return (\%MQSeries::Message::Statistics::ResponseParameters,
                "%MQSeries::Message::Statistics::ResponseParameters");
    }

    return;
}


package MQSeries::Message::Statistics::QueueManager;
our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::Statistics);


package MQSeries::Message::Statistics::Queue;
our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::Statistics);


package MQSeries::Message::Statistics::Channel;
our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::Statistics);


1;

__END__

=head1 NAME

MQSeries::Message::Statistics -- OO Class for decoding MQSeries statistics messages

=head1 SYNOPSIS

  use MQSeries::Message::Statistics;
  my $message = MQSeries::Message::Statistics::->new();

=head1 DESCRIPTION

This class is a subclass of MQSeries::Message::System which includes a
table for MQSeries::Message::System to use to decode MQSeries
statistics messages.

=head1 METHODS

This class has no methods of its own.  It merely exists as a container
for the translation table that MQSeries::Message::System uses to
decode the statistics PCF messages.

The macros are mapped to strings as follows:

   Macro                                Key
   =====                                ===
   MQCACH_CHANNEL_NAME                  ChannelName
   MQCACH_CONNECTION_NAME               ConnectionName
   MQCAMO_END_DATE                      IntervalEndDate
   MQCAMO_END_TIME                      IntervalEndTime
   MQCAMO_START_DATE                    IntervalStartDate
   MQCAMO_START_TIME                    IntervalStartTime
   MQCA_CREATION_DATE                   CreateDate
   MQCA_CREATION_TIME                   CreateTime
   MQCA_Q_MGR_NAME                      QueueManager
   MQCA_Q_NAME                          QName
   MQCA_REMOTE_Q_MGR_NAME               RemoteQMgrName
   MQGACF_CHL_STATISTICS_DATA           ChlStatisticsData
   MQGACF_Q_STATISTICS_DATA             QStatisticsData
   MQIACH_CHANNEL_TYPE                  ChannelType
   MQIAMO64_BROWSE_BYTES                BrowseBytes
   MQIAMO64_BYTES                       TotalBytes
   MQIAMO64_GET_BYTES                   GetBytes
   MQIAMO64_PUBLISH_MSG_BYTES           PublishMsgBytes
   MQIAMO64_PUT_BYTES                   PutBytes
   MQIAMO64_TOPIC_PUT_BYTES             PutTopicBytes
   MQIAMO_AVG_BATCH_SIZE                AverageBatchSize
   MQIAMO_AVG_Q_TIME                    AvgTimeOnQ
   MQIAMO_BACKOUTS                      BackCount
   MQIAMO_BROWSES                       BrowseCount
   MQIAMO_BROWSES_FAILED                BrowseFailCount
   MQIAMO_CBS                           CBCount
   MQIAMO_CBS_FAILED                    CBFailCount
   MQIAMO_CLOSES                        CloseCount
   MQIAMO_CLOSES_FAILED                 CloseFailCount
   MQIAMO_COMMITS                       CommitCount
   MQIAMO_COMMITS_FAILED                CommitFailCount
   MQIAMO_CONNS                         ConnCount
   MQIAMO_CONNS_FAILED                  ConnFailCount
   MQIAMO_CONNS_MAX                     ConnsMax
   MQIAMO_CTLS                          CtlCount
   MQIAMO_CTLS_FAILED                   CtlFailCount
   MQIAMO_DISCS                         DiscCount
   MQIAMO_EXIT_TIME_AVG                 ExitTimeAvg
   MQIAMO_EXIT_TIME_MAX                 ExitTimeMax
   MQIAMO_EXIT_TIME_MIN                 ExitTimeMin
   MQIAMO_FULL_BATCHES                  FullBatchCount
   MQIAMO_GENERATED_MSGS                GeneratedMsgs
   MQIAMO_GETS                          GetCount
   MQIAMO_GETS_FAILED                   GetFailCount
   MQIAMO_INCOMPLETE_BATCHES            IncmplBatchCount
   MQIAMO_INQS                          InqCount
   MQIAMO_INQS_FAILED                   InqFailCount
   MQIAMO_MSGS                          MsgCount
   MQIAMO_MSGS_EXPIRED                  ExpiredMsgCount
   MQIAMO_MSGS_NOT_QUEUED               NonQueuedMsgCount
   MQIAMO_MSGS_PURGED                   PurgeCount
   MQIAMO_NET_TIME_AVG                  NetTimeAvg
   MQIAMO_NET_TIME_MAX                  NetTimeMax
   MQIAMO_NET_TIME_MIN                  NetTimeMin
   MQIAMO_OBJECT_COUNT                  ObjectCount
   MQIAMO_OPENS                         OpenCount
   MQIAMO_OPENS_FAILED                  OpenFailCount
   MQIAMO_PUBLISH_MSG_COUNT             PublishMsgCount
   MQIAMO_PUT1S                         Put1Count
   MQIAMO_PUT1S_FAILED                  Put1FailCount
   MQIAMO_PUTS                          PutCount
   MQIAMO_PUTS_FAILED                   PutFailCount
   MQIAMO_PUT_RETRIES                   PutRetryCount
   MQIAMO_Q_MAX_DEPTH                   QMaxDepth
   MQIAMO_Q_MIN_DEPTH                   QMinDepth
   MQIAMO_SETS                          SetCount
   MQIAMO_SETS_FAILED                   SetFailCount
   MQIAMO_STATS                         StatCount
   MQIAMO_STATS_FAILED                  StatFailCount
   MQIAMO_SUBRQS                        SubRqCount
   MQIAMO_SUBRQS_FAILED                 SubRqFailCount
   MQIAMO_SUBS_DUR                      SubCountDur
   MQIAMO_SUBS_FAILED                   SubFailCount
   MQIAMO_SUBS_NDUR                     SubCountNDur
   MQIAMO_SUB_DUR_HIGHWATER             SubCountDurHighWater
   MQIAMO_SUB_DUR_LOWWATER              SubCountDurLowWater
   MQIAMO_SUB_NDUR_HIGHWATER            SubCountNDurHighWater
   MQIAMO_SUB_NDUR_LOWWATER             SubCountNDurLowWater
   MQIAMO_TOPIC_PUT1S                   Put1TopicCount
   MQIAMO_TOPIC_PUT1S_FAILED            Put1TopicFailCount
   MQIAMO_TOPIC_PUTS                    PutTopicCount
   MQIAMO_TOPIC_PUTS_FAILED             PutTopicFailCount
   MQIAMO_UNSUBS_DUR                    UnsubCountDur
   MQIAMO_UNSUBS_FAILED                 UnsubFailCount
   MQIAMO_UNSUBS_NDUR                   UnsubCountNDur
   MQIA_COMMAND_LEVEL                   CommandLevel
   MQIA_DEFINITION_TYPE                 DefinitionType
   MQIA_Q_TYPE                          QType

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Queue(3),
MQSeries::Message(3), MQSeries::Message::PCF(3),
MQSeries::Message::System(3)

=cut
