#
# $Id: ResponseValues.pl,v 33.11 2012/09/26 16:13:38 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%ResponseValues =
  (
   ActivityRecording =>	       
   {
    DISABLED                   => "Disabled",
    MSG                        => "Msg",
    QUEUE                      => "Queue",
   },

   Disabled =>                  # InhibitGet/InhbitPut have reversed logic
   {
    DISABLED		=> 1,
    ENABLED		=> 0,
   },

   Enabled =>                   # Everyone else with enabled/disabled
   {
    DISABLED		=> 0,
    ENABLED		=> 1,
   },

   Yes =>
   {
    NO			=> 0,
    YES			=> 1,
   },

   OnOff =>
   {
    OFF			=> "Off",
    ON			=> "On",
   },

   AdoptNewMCACheck =>
   {
    ALL			=> "All",
    NETADDR		=> "NetworkAddress",
    NONE		=> "None",
    QMNAME		=> "QMgrName",
   },

   AdoptNewMCAType =>
   {
    ALL			=> "All",
    NO			=> "No",
   },

   Available =>
   {
    UNAVAILABLE		=> 0,
    AVAILABLE		=> 1,
   },

   ChannelDisposition =>
   {
    ALL                 => "All",
    PRIVATE             => "Private",
    SHARED              => "Shared",
    FIXSHARED		=> "Fixshared",
   },

   ChannelEvent =>
   {
    DISABLED           => "Disabled",
    ENABLED            => "Enabled",
    EXCEPTION          => "Exception",
   },

   ChannelMonitoring =>
   {
    HIGH                       => "High",
    LOW			       => "Low",
    MEDIUM		       => "Medium",
    NONE                       => "None",
    OFF			       => "Off",
   },

   ClusterSenderMonitoringDefault =>
   {
    HIGH			=> "High",
    LOW				=> "Low",
    MEDIUM			=> "Medium",
    QMGR                        => "QMgr",
    OFF				=> "Off",
   },

   CLWLUseQ =>
   {
    ANY    		=> "Any",
    LOCAL    		=> "Local",
    QMGR    		=> "QMgr", # Only returned by queue CLWLUseQ
   },

   CommandEvent =>
   {
    DISABLED           => "Disabled",
    ENABLED            => "Enabled",
    NODISPLAY          => "NoDisplay",
   },

   DefInputOpenOption =>
   {
    EXCL    		=> "Exclusive",
    SHARED    		=> "Shared",
   },

   DefinitionType =>
   {
    PREDEFINED 		=> "Predefined",
    PERMDYN	    	=> "Permanent",
    SHAREDYN		=> "Shared",
    TEMPDYN	    	=> "Temporary",
   },

   IGQPutAuthority =>
   {
    ALTIGQ              => "AltIGQ",
    CTX                 => "Context",
    DEF                 => "Default",
    ONLYIGQ             => "OnlyIGQ",
   },

   IPAddressVersion =>
   {
    IPV4		=> "IPv4",
    IPV6		=> "IPv6",
   },

   MonitoringDft =>
   {
    OFF                         => "Off",
    QMGR                        => "QMgr",
    LOW                         => "Low",
    MEDIUM                      => "Medium",
    HIGH                        => "High",
   },

   MsgDeliverySequence =>
   {
    PRIORITY		=> "Priority",
    FIFO		=> "FIFO",
   },

   NonPersistentMsgClass =>
   {
    HIGH		=> "High",
    NORMAL		=> "Normal",
   },

   QMgrAccounting =>	      # QMgr-level QueueAccounting
   {
    NONE                       => "None",
    ON                         => "On",
    OFF                        => "Off",
   },

   QueueAccounting =>
   {
    OFF			=> "Off",
    ON			=> "On",
    QMGR		=> "QMgr",
   },

   QSGDisposition =>
   {
    COPY                => "Copy",
    GROUP               => "Group",
    PRIVATE             => "Private",
    QMGR                => "QMgr",
    SHARED              => "Shared",
   },

   QServiceIntervalEvent =>
   {
    HIGH    		=> "High",
    OK    		=> "OK",
    NONE    		=> "None",
   },

   QType =>
   {
    QALIAS    		=> "Alias",
    QLOCAL    		=> "Local",
    QREMOTE    		=> "Remote",
    QMODEL    		=> "Model",
   },

   ReceiveTimeoutType =>
   {
    ADD    		=> "Add",
    EQUAL    		=> "Equal",
    MULTIPLY   		=> "Multiply",
   },

   Scope =>
   {
    CELL    		=> "Cell",
    QMGR    		=> "QMgr",
   },

   SharedQQmgrName =>
   {
    IGNORE   		=> "Ignore",
    USE   		=> "Use",
   },

   TCPStackType =>
   {
    MULTIPLE   		=> "Multiple",
    SINGLE   		=> "Single",
   },

   TraceRouteRecording =>
   {
    DISABLED   		=> "Disabled",
    MSG   		=> "Msg",
    QUEUE   		=> "Queue",
   },

   TriggerType =>
   {
    NONE    		=> "None",
    EVERY    		=> "Every",
    FIRST    		=> "First",
    DEPTH    		=> "Depth",
   },

   Usage =>
   {
    NORMAL    		=> "Normal",
    XMITQ    		=> "XMITQ",
   },

   # VALUEMAP-CODEREF
   KeepAliveInterval =>
    sub { MQSeries::Command::Base::strinteger(@_, -1, "AUTO"); },

   # VALUEMAP-CODEREF
   MsgMarkBrowseInterval =>
       sub { MQSeries::Command::Base::strinteger(@_, -1, "NOLIMIT"); },

   # VALUEMAP-CODEREF
   MaxPropertiesLength =>
       sub { MQSeries::Command::Base::strinteger(@_, -1, "NOLIMIT"); },

   ChannelStatus =>
   {
    BINDING		=> "Binding",
    INITIALIZING 	=> "Initializing",
    # Special spelling for OS/390 :-(
    INITIALIZI	 	=> "Initializing",
    PAUSED 		=> "Paused",
    REQUESTING 		=> "Requesting",
    RETRYING 		=> "Retrying",
    RUNNING 		=> "Running",
    STARTING		=> "Starting",
    STOPPED 		=> "Stopped",
    STOPPING 		=> "Stopping",
    INACTIVE		=> "Inactive",
   },

   MCAType =>
   {
    PROCESS    		=> "Process",
    THREAD    		=> "Thread",
   },

   MCAStatus =>
   {
    "STOPPED"		=> "Stopped",
    "RUNNING"		=> "Running",
   },

   NonPersistentMsgSpeed =>
   {
    NORMAL    		=> "Normal",
    FAST    		=> "Fast",
   },

   PutAuthority =>
   {
    DEF    		=> "Default",
    CTX    		=> "Context",
    ONLYMCA             => "OnlyMCA",
    ALTMCA              => "AlternateMCA",
   },

   TransportType =>
   {
    DECNET    		=> "DECNET",
    LU62    		=> "LU62",
    NETBIOS    		=> "NetBIOS",
    SPX    		=> "SPX",
    TCP    		=> "TCP",
    UDP    		=> "UDP",
   },

   ApplType =>
   {
    BATCH               => "Batch",
    CHINIT              => "Channel Initiator",
    CICS    		=> "CICS",
    DOS    		=> "DOS",
    IMS 		=> "IMS",
    MVS 		=> "MVS",
    NSK                 => "NSK",
    OS400		=> "OS400",
    OS2 		=> "OS2",
    RRSBATCH            => "RRS-Batch",
    SYSTEM              => "Queue Manager",
    UNIX    		=> "UNIX",
    USER                => "User Application",
    VMS 		=> "VMS",
    WINDOWS    		=> "Win16",
    WINDOWSNT    	=> "Win32",
   },

   ClusterQType =>
   {
    QALIAS 		=> "Alias",
    QLOCAL 		=> "Local",
    QMGR 		=> "QMgrAlias",
    QREMOTE 		=> "Remote",
   },

   DefBind =>
   {
    GROUP		=> "OnGroup",
    OPEN		=> "OnOpen",
    NOTFIXED		=> "NotFixed",
   },

   ChannelType =>
   {
    SDR			=> "Sender",
    SVR			=> "Server",
    RCVR		=> "Receiver",
    RQSTR		=> "Requester",
    SVRCONN		=> "Svrconn",
    CLNTCONN		=> "Clntconn",
    CLUSRCVR		=> "ClusterReceiver",
    CLUSSDR		=> "ClusterSender",
   },

   Compression =>
   {
    NONE		=> "None",
    SYSTEM		=> "System",
   },

   MessageCompression =>
   {
    ANY				=> "Any",
    NONE			=> "None",
    RLE				=> "Rle",
    ZLIBFAST			=> "ZlibFast",
    ZLIBHIGH			=> "ZlibHigh",
   },

   TraceType =>
   {
    GLOBAL		=> "Global",
    STAT		=> "Statistical",
    ACCTG		=> "Accounting",
   },

   QMgrDefinitionType =>
   {
    CLUSSDR		=> "ExplicitClusterSender",
    CLUSSDRA 		=> "AutoClusterSender",
    CLUSSDRB 		=> "AutoExplicitClusterSender",
    CLUSRCVR		=> "ClusterReceiver",
   },

   QMgrType =>
   {
    NORMAL		=> "Normal",
    REPOS               => "Repository",
   },

   IndexType =>
   {
    CORRELID		=> "CorrelId",
    GROUPID             => "GroupId",
    MSGTOKEN		=> "MsgToken",
    MSGID		=> "MsgId",
    NONE		=> "None",
   },

   StatusType =>
   {
    HANDLE              => "Handle",
    QUEUE               => "Queue",
   },

   QStatusInputType =>
   {
    EXCL                => "Exclusive",
    NO                  => "No",
    SHARED              => "Shared",
   },

   SSLClientAuth =>
   {
    OPTIONAL            => "Optional",
    REQUIRED            => "Required",
   },

   AuthInfoType =>
   {
    CRLLDAP             => "CRLLDAP",
    OCSP		=> "OCSP",
    ALL		   	=> "All",
   },

   NamelistType =>
   {
    NONE                => "None",
    QUEUE               => "Queue",
    Q                   => "Queue",
    CLUSTER             => "Cluster",
    AUTHINFO            => "AuthInfo",
   },

   QMgrMonitoring =>
   {
    HIGH			=> "High",
    LOW				=> "Low",
    MEDIUM			=> "Medium",
    NONE                        => "None",
    OFF				=> "Off",
   },

   QueueMonitoring =>
   {
    HIGH			=> "High",
    LOW				=> "Low",
    MEDIUM			=> "Medium",
    QMGR                        => "QMgr",
    OFF				=> "Off",
   },
   SubSate =>	       
   {
    ENDBATCH		=> "EndOfBatch",
    SEND		=> "Sending",
    RECEIVE		=> "Receiving",
    SERIALIZE		=> "Serializing",
    RESYNCH		=> "Resynching",
    HEARTBEAT		=> "Heartbeating",
    SCYEXIT		=> "SecurityExit",
    RCVEXIT		=> "ReceiveExit",
    SENDEXIT		=> "SendExit",
    MSGEXIT		=> "MsgExit",
    MREXIT		=> "MsgRetryExit",
    CHADEXIT		=> "ChannelAutoDefExit",
    NETCONNECT		=> "NetConnecting",
    SSLHANDSHK		=> "SSLHandShaking",
    NAMESERVER		=> "NameServer",
    MQPUT		=> "InMQPut",
    MQGET		=> "InMQGet",
    MQICALL		=> "InMQICall",
    COMPRESS		=> "Compressing",
    OTHER		=> "Other",
    ''			=> "", # Null value
   },

   BaseType => 
   {
    QUEUE			=> "Queue",
    TOPIC			=> "Topic",
   },

   PubSubMode =>
   {
    COMPAT			=> "Compat",
    ENABLED			=> "Enabled",
    DISABLED			=> "Disabled",
   },

   PubSubNPInputMsg =>
   {
    DISCARD			=> "Discard",
    KEEP			=> "Keep",
   },

   PubSubNPResponse =>
   {
    DISCARD			=> "Discard",
    KEEP			=> "Keep",
    NORMAL			=> "Normal",
    SAFE			=> "SAFE",
   },

   PubSubSyncPoint =>
   {
    IFPER			=> "IfPersistent",
    YES				=> "Yes",
   },

   SecurityCase =>
   {
    MIXED			=> "Mixed",
    UPPER			=> "Upper",
   },

   DefReadAhead =>
   {
    DISABLED			=> "Disabled",
    NO				=> "No",
    YES				=> "Yes",
   },

   DefPutResponse =>
   {
    SYNC			=> "Sync",
    ASYNC			=> "Async",
   },

   PropertyControl =>
   {
    ALL				=> "All",
    COMPAT			=> "Compatibility",
    FORCE			=> "ForceRFH2",
    NONE			=> "None",
   },

   ConnectionAffinity =>
   {
    NONE			=> "None",
    PREFERRED			=> "Preferred",
   },

   AsynchronousState => 
   {
    ACTIVE			=> "Active",
    INACTIVE			=> "Inactive",
    STARTED			=> "Started",
    STARTWAIT			=> "StartWait",
    STOPPED			=> "Stopped",
    SUSPENDED			=> "Suspended",
    SUSPTEMP			=> "SuspendedTemporary",
    NONE			=> "None",
   },

   #
   # Added in 1.33 to match what has been done for PCF in 1.33
   #
   DefReconnect =>
   {
    QMGR			=> "QMgr",
    DISABLED			=> "Disabled",
    NO				=> "No",
    YES				=> "Yes",
   },

   ChlAuthType =>
   {
    BLOCKUSER			=> "BlockUser",
    BLOCKADDR			=> "BlockAddress",
    SSLPEERMAP			=> "SSLPeerMap",
    ADDRESSMAP			=> "AddressMap",
    USERMAP			=> "UserMap",
    QMGRMAP			=> "QMgrMap",
   },

   ChlAuthMatch =>
   {
    RUNCHECK			=> "Runcheck",
    EXACT			=> "Exact",
    GENERIC			=> "Generic",
   },

   UserSource =>
   {
    CHANNEL			=> "Channel",
    MAP				=> "Map",
    NOACCESS			=> "NoAccess",
   },

   DSBlock =>
   {
    "0K"				=> "0K",
    "8K"				=> "8K",
    "16K"				=> "16K",
    "32K"				=> "32K",
    "64K"				=> "64K",
    "128K"			=> "128K",
    "256K"			=> "256K",
    "512K"			=> "512K",
    "1M"				=> "1M",
   },

   DSExpand =>
   {
    NO				=> "No",
    YES				=> "Yes",
    DEFAULT			=> "Default",
   },

   Offload =>
   {
    DB2				=> "DB2",
    SMDS			=> "SMDS",
    NONE			=> "None",
   },

   CFConlos =>
   {
    ASQMGR			=> "AsQMgr",
    TERMINATE			=> "Terminate",
    TOLERATE			=> "Tolerate",
   },

   EncryptionPolicySuiteB =>
   {
    NONE			=> "None",
    "128_BIT"			=> "128Bit",
    "192_BIT"			=> "192Bit",
   },

   ChlAuthAction =>
   {
    ADD				=> "Add",
    REPLACE			=> "Replace",
    REMOVE			=> "Remove",
    REMOVEALL			=> "RemoveAll",
   },


 );

#
# These parameter names changed from the guess in MQSeries 1.23 and
# before and the PCF name in 1.24 and later.  Add this for backwards
# compatibility.
#
$ResponseValues{IntraGroupAuthority} = $ResponseValues{IGQPutAuthority};
$ResponseValues{QSharingGroupDisposition} = $ResponseValues{QSGDisposition};

1;
