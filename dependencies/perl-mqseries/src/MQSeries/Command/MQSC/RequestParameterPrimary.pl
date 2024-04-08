#
# $Id: RequestParameterPrimary.pl,v 33.6 2012/09/26 16:10:15 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%RequestParameterPrimary =
  (

   #
   # Process commands
   #
   ChangeProcess		=> "ProcessName",
   CopyProcess			=> "ProcessName",
   CreateProcess		=> "ProcessName",
   DeleteProcess		=> "ProcessName",
   InquireProcess		=> "ProcessName",

   #
   # Queue commands
   #
   ChangeQueue			=> "QName",
   ClearQueue			=> "QName",
   CopyQueue			=> "ToQName",
   CreateQueue			=> "QName",
   DeleteQueue			=> "QName",
   InquireQueue			=> "QName",
   InquireQueueStatus           => "QName",
   ResetQueueStatistics         => "QName",

   #
   # Channel commands
   #
   ChangeChannel		=> "ChannelName",
   CopyChannel			=> "ChannelName",
   CreateChannel		=> "ChannelName",
   DeleteChannel		=> "ChannelName",
   InquireChannel		=> "ChannelName",
   InquireChannelStatus		=> "ChannelName",

   #
   # StorageClass commands
   #
   ChangeStorageClass		=> "StorageClassName",
   #CopyStorageClass		=> "StorageClassName",
   CreateStorageClass		=> "StorageClassName",
   DeleteStorageClass		=> "StorageClassName",
   InquireStorageClass		=> "StorageClassName",

   #
   # AuthInfo commands
   #
   ChangeAuthInfo		=> "AuthInfoName",
   CopyAuthInfo			=> "AuthInfoName",
   CreateAuthInfo		=> "AuthInfoName",
   DeleteAuthInfo		=> "AuthInfoName",
   InquireAuthInfo		=> "AuthInfoName",

   #
   # Coupling Facility Structure commands
   #
   ChangeCFStruc		=> "CFStrucName",
   CopyCFStruc			=> "CFStrucName",
   CreateCFStruc		=> "CFStrucName",
   DeleteCFStruc		=> "CFStrucName",
   InquireCFStruc		=> "CFStrucName",

   #
   # Coupling Facility Structure commands
   #
   # NOTE: CFStruct is for backwards compatibility with pre-1.24 MQSC
   #       New code should use CFStruc (no final 't')
   #
   ChangeCFStruct		=> "CFStructName",
   CopyCFStruct			=> "CFStructName",
   CreateCFStruct		=> "CFStructName",
   DeleteCFStruct		=> "CFStructName",
   InquireCFStruct		=> "CFStructName",

   # 
   # ChannelAuthRecords commands
   #
   InquireChlAuthRecs		=> "ChlAuth",
   SetChlAuthRec		=> "ChlAuth",

  );

1;
