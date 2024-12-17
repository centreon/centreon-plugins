#
# $Id: Responses.pl,v 33.6 2012/09/26 16:13:39 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%Responses =
  (
   ChangeQueueManager 		=> $ResponseParameters{QueueManager},
   InquireQueueManager 		=> $ResponseParameters{QueueManager},
   PingQueueManager 		=> $ResponseParameters{QueueManager},

   ChangeProcess 		=> $ResponseParameters{Process},
   CopyProcess 			=> $ResponseParameters{Process},
   CreateProcess 		=> $ResponseParameters{Process},
   DeleteProcess 		=> $ResponseParameters{Process},
   InquireProcess 		=> $ResponseParameters{Process},
   InquireProcessNames 		=> $ResponseParameters{Process},

   ChangeQueue 			=> $ResponseParameters{Queue},
   ClearQueue 			=> $ResponseParameters{Queue},
   CopyQueue 			=> $ResponseParameters{Queue},
   CreateQueue 			=> $ResponseParameters{Queue},
   DeleteQueue 			=> $ResponseParameters{Queue},
   InquireQueue 		=> $ResponseParameters{Queue},
   InquireQueueNames 		=> $ResponseParameters{Queue},
   InquireQueueStatus 		=> $ResponseParameters{QueueStatus},
   ResetQueueStatistics 	=> $ResponseParameters{Queue},

   ChangeChannel 		=> $ResponseParameters{Channel},
   CopyChannel 			=> $ResponseParameters{Channel},
   CreateChannel 		=> $ResponseParameters{Channel},
   DeleteChannel 		=> $ResponseParameters{Channel},
   InquireChannel 		=> $ResponseParameters{Channel},
   InquireChannelNames 		=> $ResponseParameters{Channel},
   InquireChannelStatus 	=> $ResponseParameters{Channel},
   PingChannel 			=> $ResponseParameters{Channel},
   ResetChannel 		=> $ResponseParameters{Channel},
   ResolveChannel 		=> $ResponseParameters{Channel},
   StartChannel 		=> $ResponseParameters{Channel},
   StartChannelInitiator 	=> $ResponseParameters{Channel},
   StartChannelListener 	=> $ResponseParameters{Channel},
   StopChannel 			=> $ResponseParameters{Channel},

   ChangeNamelist		=> $ResponseParameters{Namelist},
   CreateNamelist		=> $ResponseParameters{Namelist},
   DeleteNamelist		=> $ResponseParameters{Namelist},
   InquireNamelist		=> $ResponseParameters{Namelist},
   InquireNamelistNames		=> $ResponseParameters{Namelist},

   ChangeAuthInfo		=> $ResponseParameters{AuthInfo},
   CreateAuthInfo		=> $ResponseParameters{AuthInfo},
   DeleteAuthInfo		=> $ResponseParameters{AuthInfo},
   InquireAuthInfo		=> $ResponseParameters{AuthInfo},
   InquireAuthInfoNames		=> $ResponseParameters{AuthInfo},

   ChangeCFStruc		=> $ResponseParameters{CFStruc},
   CreateCFStruc		=> $ResponseParameters{CFStruc},
   DeleteCFStruc		=> $ResponseParameters{CFStruc},
   InquireCFStruc		=> $ResponseParameters{CFStruc},
   InquireCFStrucNames		=> $ResponseParameters{CFStruc},

   #
   # NOTE: CFStruct is for backwards compatibility with pre-1.24 MQSC
   #       New code should use CFStruc (no final 't')
   #
   ChangeCFStruct		=> $ResponseParameters{CFStruct},
   CreateCFStruct		=> $ResponseParameters{CFStruct},
   DeleteCFStruct		=> $ResponseParameters{CFStruct},
   InquireCFStruct		=> $ResponseParameters{CFStruct},
   InquireCFStructNames		=> $ResponseParameters{CFStruct},

   InquireStorageClass		=> $ResponseParameters{StorageClass},
   InquireStorageClassNames	=> $ResponseParameters{StorageClass},

   InquireTrace			=> $ResponseParameters{Trace},

   InquireClusterQueueManager	=> $ResponseParameters{Cluster},

   InquireChlAuthRecs		=> $ResponseParameters{ChlAuthRec},
   SetChlAuthRec		=> $ResponseParameters{ChlAuthRec},
  );

#
# This is used to determine how to map multiple MQSC responses into
# one MQSeries::Command response.  All the 'old_key' fields of the
# individual MQSC responses are collected into one 'new_key' field of
# the MQSeries::Command response.
#
# Format: CommandName => [ old_key, new_key ]
#
%ResponseList =
  (
   InquireProcessNames		=> [ qw(ProcessName ProcessNames) ],
   InquireQueueNames		=> [ qw(QName QNames) ],
   InquireChannelNames		=> [ qw(ChannelName ChannelNames) ],
   InquireNamelistNames		=> [ qw(NamelistName NamelistNames) ],
   InquireStorageClassNames	=> [ qw(StorageClassName StorageClassNames) ],
   InquireAuthInfoNames		=> [ qw(AuthInfoName AuthInfoNames) ],
   InquireCFStrucNames		=> [ qw(CFStrucName CFStrucNames) ],
  );

1;
