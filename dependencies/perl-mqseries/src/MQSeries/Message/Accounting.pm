#
# $Id: Accounting.pm,v 1.14 2012/09/26 16:15:15 jettisu Exp $
#
# (c) 2011-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Message::Accounting;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::Message::System;

require "MQSeries/Message/Accounting.pl";

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
        ($header->{"Command"} == MQSeries::MQCMD_ACCOUNTING_MQI) ?
            "MQSeries::Message::Accounting::QueueManager" :
        ($header->{"Command"} == MQSeries::MQCMD_ACCOUNTING_Q) ?
            "MQSeries::Message::Accounting::Queue" :
                undef;

    if ($header->{"Type"} == MQSeries::MQCFT_ACCOUNTING &&
        defined($subclass)) {
        bless $self, $subclass;
        return (\%MQSeries::Message::Accounting::ResponseParameters,
                "%MQSeries::Message::Accounting::ResponseParameters");
    }

    return;
}


package MQSeries::Message::Accounting::QueueManager;
our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::Accounting);


package MQSeries::Message::Accounting::Queue;
our $VERSION = '1.34';
our @ISA = qw(MQSeries::Message::Accounting);


1;

__END__

=head1 NAME

MQSeries::Message::Accounting -- OO Class for decoding MQSeries accounting messages

=head1 SYNOPSIS

  use MQSeries::Message::Accounting;
  my $message = MQSeries::Message::Accounting::->new();

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
   MQBACF_CONNECTION_ID                 ConnectionId
   MQCACF_APPL_NAME                     ApplicationName
   MQCACF_USER_IDENTIFIER               UserId
   MQCACH_CHANNEL_NAME                  ChannelName
   MQCACH_CONNECTION_NAME               ConnectionName
   MQCAMO_CLOSE_DATE                    CloseDate
   MQCAMO_CLOSE_TIME                    CloseTime
   MQCAMO_CONN_DATE                     ConnDate
   MQCAMO_CONN_TIME                     ConnTime
   MQCAMO_DISC_DATE                     DiscDate
   MQCAMO_DISC_TIME                     DiscTime
   MQCAMO_END_DATE                      IntervalEndDate
   MQCAMO_END_TIME                      IntervalEndTime
   MQCAMO_OPEN_DATE                     OpenDate
   MQCAMO_OPEN_TIME                     OpenTime
   MQCAMO_START_DATE                    IntervalStartDate
   MQCAMO_START_TIME                    IntervalStartTime
   MQCA_CREATION_DATE                   CreateDate
   MQCA_CREATION_TIME                   CreateTime
   MQCA_Q_MGR_NAME                      QueueManager
   MQCA_Q_NAME                          QName
   MQGACF_Q_ACCOUNTING_DATA             QAccountingData
   MQIACF_PROCESS_ID                    ApplicationPid
   MQIACF_SEQUENCE_NUMBER               SeqNumber
   MQIACF_THREAD_ID                     ApplicationTid
   MQIAMO64_BROWSE_BYTES                BrowseBytes
   MQIAMO64_GET_BYTES                   GetBytes
   MQIAMO64_PUT_BYTES                   PutBytes
   MQIAMO64_TOPIC_PUT_BYTES             PutTopicBytes
   MQIAMO_BACKOUTS                      BackCount
   MQIAMO_BROWSES                       BrowseCount
   MQIAMO_BROWSES_FAILED                BrowseFailCount
   MQIAMO_BROWSE_MAX_BYTES              BrowseMaxBytes
   MQIAMO_BROWSE_MIN_BYTES              BrowseMinBytes
   MQIAMO_CBS                           CBCount
   MQIAMO_CBS_FAILED                    CBFailCount
   MQIAMO_CLOSES                        CloseCount
   MQIAMO_CLOSES_FAILED                 CloseFailCount
   MQIAMO_COMMITS                       CommitCount
   MQIAMO_COMMITS_FAILED                CommitFailCount
   MQIAMO_CTLS                          CtlCount
   MQIAMO_CTLS_FAILED                   CtlFailCount
   MQIAMO_DISC_TYPE                     DiscType
   MQIAMO_GETS                          GetCount
   MQIAMO_GETS_FAILED                   GetFailCount
   MQIAMO_GET_MAX_BYTES                 GetMaxBytes
   MQIAMO_GET_MIN_BYTES                 GetMinBytes
   MQIAMO_INQS                          InqCount
   MQIAMO_INQS_FAILED                   InqFailCount
   MQIAMO_OBJECT_COUNT                  ObjectCount
   MQIAMO_OPENS                         OpenCount
   MQIAMO_OPENS_FAILED                  OpenFailCount
   MQIAMO_PUT1S                         Put1Count
   MQIAMO_PUT1S_FAILED                  Put1FailCount
   MQIAMO_PUTS                          PutCount
   MQIAMO_PUTS_FAILED                   PutFailCount
   MQIAMO_PUT_MAX_BYTES                 PutMaxBytes
   MQIAMO_PUT_MIN_BYTES                 PutMinBytes
   MQIAMO_Q_TIME_AVG                    TimeOnQAvg
   MQIAMO_Q_TIME_MAX                    TimeOnQMax
   MQIAMO_Q_TIME_MIN                    TimeOnQMin
   MQIAMO_SETS                          SetCount
   MQIAMO_SETS_FAILED                   SetFailCount
   MQIAMO_STATS                         StatCount
   MQIAMO_STATS_FAILED                  StatFailCount
   MQIAMO_SUBRQS                        SubRqCount
   MQIAMO_SUBRQS_FAILED                 SubRqFailCount
   MQIAMO_SUBS_DUR                      SubCountDur
   MQIAMO_SUBS_FAILED                   SubFailCount
   MQIAMO_SUBS_NDUR                     SubCountNDur
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
