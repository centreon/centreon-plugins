#
# $Id: Requests.pl,v 33.6 2012/09/26 16:13:38 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%Requests =
  (


   #
   # QueueManager commands
   #
   ChangeQueueManager		=> [ "ALTER QMGR",     	$RequestParameters{QueueManager} ],
   InquireQueueManager		=> [ "DISPLAY QMGR",   	$RequestParameters{QueueManager},
				     $RequestArgs{QueueManager}, ],
   PingQueueManager		=> [ "PING QMGR",		{} ],


   #
   # Process commands
   #
   ChangeProcess		=> [ "ALTER",     	$RequestParameters{Process} ],
   CopyProcess			=> [ "DEFINE",     	$RequestParameters{Process} ],
   CreateProcess		=> [ "DEFINE", 	     	$RequestParameters{Process} ],
   DeleteProcess		=> [ "DELETE",     	$RequestParameters{Process} ],
   InquireProcess		=> [ "DISPLAY",      	$RequestParameters{Process},
				     $RequestArgs{Process}, ],
   InquireProcessNames		=> [ "DISPLAY",      	$RequestParameters{Process} ],


   #
   # Queue commands
   #
   ChangeQueue			=> [ "ALTER",      	$RequestParameters{ChangeQueue} ],
   ClearQueue			=> [ "CLEAR",      	$RequestParameters{ClearQueue} ],
   CopyQueue			=> [ "DEFINE",     	$RequestParameters{CopyQueue} ],
   CreateQueue			=> [ "DEFINE",      	$RequestParameters{CreateQueue} ],
   DeleteQueue			=> [ "DELETE",      	$RequestParameters{DeleteQueue} ],
   InquireQueue			=> [ "DISPLAY",      	$RequestParameters{Queue},
				     $RequestArgs{Queue}, ],
   InquireQueueNames		=> [ "DISPLAY",      	$RequestParameters{InquireQueueNames} ],

   #
   # Available from release 5.2 on MVS, not before
   #
   InquireQueueStatus           => [ "DISPLAY",         $RequestParameters{InquireQueueStatus} ],
   ResetQueueStatistics		=> [ "RESET",           $RequestParameters{ResetQueueStatistics} ],

   #
   # Channel commands
   #
   ChangeChannel		=> [ "ALTER",      	$RequestParameters{Channel} ],
   CopyChannel			=> [ "DEFINE",    	$RequestParameters{Channel} ],
   CreateChannel		=> [ "DEFINE",     	$RequestParameters{Channel} ],
   DeleteChannel		=> [ "DELETE",     	$RequestParameters{Channel} ],
   #
   # We have to override the key word used for ChannelType.  For most
   # of the channel commands, its CHLTYPE, but for DISPLAY, it is
   # TYPE.  Inconsistent, and annoying, but that is part of why PCF
   # exists in the first place...
   #
   InquireChannel		=> [
				    "DISPLAY", 
				    {
				     %{$RequestParameters{Channel}},
				     ChannelType =>
				     [
				      "TYPE",
				      $RequestValues{ChannelType}
				     ],
				    },
				    $RequestArgs{Channel},
				   ],
   #
   # Similarly, ChannelName maps to CHSTATUS, not CHANNEL, for this
   # command.
   #
   InquireChannelStatus		=> [
				    "DISPLAY",
				    {
				     %{$RequestParameters{Channel}},
				     ChannelName => [ "CHSTATUS", "string" ],
				    },
				    $RequestArgs{ChannelStatus},
				   ],

   InquireChannelNames		=> [ "DISPLAY",      	$RequestParameters{InquireChannelNames} ],
   PingChannel			=> [ "PING",      	$RequestParameters{Channel} ],
   ResetChannel			=> [ "RESET",     	$RequestParameters{Channel} ],
   ResolveChannel		=> [ "RESOLVE",     	$RequestParameters{Channel} ],
   StartChannel			=> [ "START",     	$RequestParameters{Channel} ],
   StartChannelInitiator	=> [ "START CHINIT",	$RequestParameters{Channel} ],
   StartChannelListener		=> [ "START LISTENER",	$RequestParameters{Channel} ],
   StopChannel			=> [ "STOP",      	$RequestParameters{Channel} ],

   # ChannelAuthorityRecord commands
   InquireChlAuthRecs		=> [ "DISPLAY",		$RequestParameters{ChlAuthRec} ],
   SetChlAuthRec		=> [ "SET",		$RequestParameters{ChlAuthRec} ],

   #
   # Namelist commands
   #
   ChangeNamelist		=> [ "ALTER",		$RequestParameters{Namelist} ],
   CreateNamelist		=> [ "DEFINE",		$RequestParameters{Namelist} ],
   DeleteNamelist		=> [ "DELETE",		$RequestParameters{Namelist} ],
   InquireNamelist		=> [ "DISPLAY",		$RequestParameters{Namelist} ],
   InquireNamelistNames		=> [ "DISPLAY",		$RequestParameters{Namelist} ],

   #
   # Cluster commands
   #
   InquireClusterQueueManager	=> [ "DISPLAY",		$RequestParameters{Cluster} ],
   ResumeQueueManagerCluster	=> [ "RESUME QMGR",	$RequestParameters{Cluster} ],
   SuspendQueueManagerCluster	=> [ "SUSPEND QMGR",	$RequestParameters{Cluster} ],
   RefreshCluster		=> [ "REFRESH",		$RequestParameters{Cluster} ],
   ResetCluster			=> [ "RESET",		$RequestParameters{Cluster} ],

   #
   # Security commands
   #
   ChangeSecurity		=> [
				    "CHANGE SECURITY",	
				    $RequestParameters{Security},
				   ],
   InquireSecurity		=> [ 
				    "DISPLAY SECURITY",
				    $RequestParameters{Security},
				   ],
   RefreshSecurity		=> [ 
				    "REFRESH SECURITY",
				    $RequestParameters{Security},
				   ],
   ReverifySecurity		=> [
				    "RVERIFY SECURITY",
				    $RequestParameters{Security},
				   ],

   #
   # Storage Class Commands
   #
   ChangeStorageClass		=> [ "ALTER",		$RequestParameters{StorageClass} ],
   CreateStorageClass		=> [ "DEFINE",		$RequestParameters{StorageClass} ],
   DeleteStorageClass		=> [ "DELETE",		$RequestParameters{StorageClass} ],
   InquireStorageClass		=> [ "DISPLAY",		$RequestParameters{StorageClass} ],
   InquireStorageClassNames	=> [ "DISPLAY",      	$RequestParameters{InquireStorageClassNames} ],

   ChangeTrace			=> [ "ALTER",		$RequestParameters{Trace} ],
   InquireTrace			=> [ "DISPLAY",		$RequestParameters{Trace} ],
   StartTrace			=> [ "START",		$RequestParameters{Trace} ],
   StopTrace			=> [ "STOP",		$RequestParameters{Trace} ],

   ArchiveLog			=> [ "ARCHIVE LOG",	$RequestParameters{ArchiveLog} ],

   CreateBufferPool		=> [ "DEFINE",		$RequestParameters{BufferPool} ],

   CreatePageSetId		=> [ "DEFINE",		$RequestParameters{PageSetId} ],

   RecoverBootStrapDataSet	=> [ "RECOVER BSDS",	{} ],

   ResetTpipe			=> [ "RESET",		$RequestParameters{Tpipe} ],

   # XXX everything above this line has been sanity checked for 2.1/5.1
   
   InquireThread		=> [ "DISPLAY",		$RequestParameters{InquireThread} ],
   ResolveInDoubt		=> [ "RESOLVE",		$RequestParameters{ResolveInDoubt}],

   #
   # AuthInfo Commands
   #
   ChangeAuthInfo		=> [ "ALTER",     	$RequestParameters{AuthInfo} ],
   CopyAuthInfo			=> [ "DEFINE",     	$RequestParameters{AuthInfo} ],
   CreateAuthInfo		=> [ "DEFINE", 	     	$RequestParameters{AuthInfo} ],
   DeleteAuthInfo		=> [ "DELETE",     	$RequestParameters{AuthInfo} ],
   InquireAuthInfo		=> [ "DISPLAY",      	$RequestParameters{AuthInfo},
				     $RequestArgs{AuthInfo}, ],
   InquireAuthInfoNames		=> [ "DISPLAY",      	$RequestParameters{AuthInfo} ],

   #
   # CFStruc Commands
   #
   ChangeCFStruc		=> [ "ALTER",     	$RequestParameters{CFStruc} ],
   CreateCFStruc		=> [ "DEFINE", 	     	$RequestParameters{CFStruc} ],
   DeleteCFStruc		=> [ "DELETE",     	$RequestParameters{CFStruc} ],
   InquireCFStruc		=> [ "DISPLAY",      	$RequestParameters{CFStruc},
				     $RequestArgs{CFStruc}, ],
   InquireCFStrucNames		=> [ "DISPLAY",      	$RequestParameters{CFStruc} ],

   #
   # CFStruct Commands
   #
   # NOTE: CFStruct is for backwards compatibility with pre-1.24 MQSC
   #       New code should use CFStruc (no final 't')
   #
   ChangeCFStruct		=> [ "ALTER",     	$RequestParameters{CFStruct} ],
   CreateCFStruct		=> [ "DEFINE", 	     	$RequestParameters{CFStruct} ],
   DeleteCFStruct		=> [ "DELETE",     	$RequestParameters{CFStruct} ],
   InquireCFStruct		=> [ "DISPLAY",      	$RequestParameters{CFStruct},
				     $RequestArgs{CFStruct}, ],
   InquireCFStructNames		=> [ "DISPLAY",      	$RequestParameters{CFStruct} ],

  );

1;
