#
# $Id: RequestParameters.pl,v 33.14 2012/09/26 16:13:37 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%RequestParameters =
  (

   #
   # These parameters are used to update specific queue manager
   # attributes ("ALTER QMGR"), and specify how the values are
   # encoded.  A related list in RequestValues.pl specifies the
   # attributes that can be inquired ("DISPLAY QMGR").
   #
   QueueManager =>
   {
    CFConlos			=> [ "CFCONLOS",	$RequestValues{CFConlos} ],
    ChlAuthRecords		=> [ "CHLAUTH",		$RequestValues{Enabled} ],
    ChildName			=> [ "CHILD",		"string" ],			
    Custom			=> [ "CUSTOM",		"string" ],
    PubSubClus			=> [ "PSCLUS",		$RequestValues{Enabled} ],
    ActivityRecording           => [ "ACTIVREC",        $RequestValues{ActivityRecording} ],
    AuthorityEvent		=> [ "AUTHOREV", 	$RequestValues{Enabled} ],
    ChannelAutoDef		=> [ "CHAD",		$RequestValues{Enabled} ],
    ChannelAutoDefEvent		=> [ "CHADEV",		$RequestValues{Enabled} ],
    ChannelAutoDefExit 		=> [ "CHADEXIT",	"string" ],
    ChannelEvent                => [ "CHLEV",           $RequestValues{ChannelEvent} ],
    ChannelMonitoring           => [ "MONCHL",          $RequestValues{ChannelMonitoring} ],
    ChinitAdapters              => [ "CHIADAPS",        "string" ],
    ChinitDispatchers           => [ "CHIDISPS",        "string" ],
    ChinitTraceAutoStart        => [ "TRAXSTR",         "integer" ],
    ChinitTraceTableSize        => [ "TRAXTBL",         "string" ],
    ClusterSenderMonitoringDefault => [ "MONACLS",      $RequestValues{ClusterSenderMonitoringDefault} ],
    ClusterWorkLoadExit		=> [ "CLWLEXIT",	"string" ],
    ClusterWorkLoadData		=> [ "CLWLDATA",	"string" ],
    ClusterWorkLoadLength	=> [ "CLWLLEN",		"string" ],
    CLWLMRUChannels             => [ "CLWLMRUC",        "string" ],
    CLWLUseQ                    => [ "CLWLUSEQ",        $RequestValues{CLWLUseQ} ],
    CodedCharSetId		=> [ "CCSID",		"integer" ],
    CommandEvent                => [ "CMDEV",           $RequestValues{CommandEvent} ],
    ConfigurationEvent          => [ "CONFIGEV",        $RequestValues{Enabled} ],
    DeadLetterQName		=> [ "DEADQ", 		"string" ],
    DefXmitQName		=> [ "DEFXMITQ",	"string" ],
    EncryptionPolicySuiteB	=> [ "SUITEB",		$RequestValues{EncryptionPolicySuiteB} ],
    ExpiryInterval              => [ "EXPRYINT",        "string" ], # OFF / Number
    Force			=> [ "FORCE" ],
    GroupUR			=> [ "GROUPUR" ,        $RequestValues{Enabled} ],
    IGQPutAuthority             => [ "IGQAUT" ,        $RequestValues{IGQPutAuthority} ],
    InhibitEvent		=> [ "INHIBTEV",	$RequestValues{Enabled} ],
    IGQPutAuthority         => [ "IGQAUT",          $RequestValues{IGQPutAuthority} ],
    IntraGroupQueueing          => [ "IGQ",             $RequestValues{Enabled} ], 
    IGQUserId                    => [ "IGQUSER",         "string" ],
    IPAddressVersion             => [ "IPADDRV",         $RequestValues{IPAddressVersion} ],
    ListenerTimer                => [ "LSTRTMR",         "string" ],
    LocalEvent			=> [ "LOCALEV",		$RequestValues{Enabled} ],
    LU62ARMSuffix               => [ "LU62ARM",         "integer" ],
    LU62Channels                => [ "LU62CHL",         "integer" ],
    LUGroupName                 => [ "LUGROUP",         "string" ],
    LUName                      => [ "LUNAME",          "string" ],
    MaxHandles			=> [ "MAXHANDS", 	"integer" ],
    MaxActiveChannels           => [ "ACTCHL",          "integer" ],
    MaxChannels                 => [ "MAXCHL",          "integer" ],
    MaxMsgLength		=> [ "MAXMSGL",		"integer" ],
    MaxPropertiesLength		=> [ "MAXPROPL",	$RequestValues{MaxPropertiesLength} ],
    MaxUncommittedMsgs		=> [ "MAXUMSGS", 	"integer" ],
    MsgMarkBrowseInterval	=> [ "MARKINT",		$RequestValues{MsgMarkBrowseInterval} ],
    NonPersistentMsgClass       => [ "NPMCLASS",        $RequestValues{NonPersistentMsgClass} ],
    OutboundPortMax             => [ "OPORTMAX",        "integer" ],
    OutboundPortMin             => [ "OPORTMIN",        "integer" ],
    Parent			=> [ "PARENT",		"string" ],
    PerformanceEvent		=> [ "PERFMEV",		$RequestValues{Enabled} ],
    PubSubMaxMsgRetryCount	=> [ "PSRTYCNT",	"integer" ],
    PubSubMode			=> [ "PSMODE",		$RequestValues{PubSubMode} ],
    PubSubNPInputMsg		=> [ "PSNPMSG",		$RequestValues{PubSubNPInputMsg} ],
    PubSubNPResponse		=> [ "PSNPRES",		$RequestValues{PubSubNPResponse} ],
    PubSubSyncPoint		=> [ "PSSYNCPT",	$RequestValues{PubSubSyncPoint} ],
    QMgrDesc			=> [ "DESCR", 		"string" ],
    QMgrAttrs			=> [ "",		$RequestValues{QMgrAttrs} ],
    QueueAccounting             => [ "ACCTQ",           $RequestValues{QMgrAccounting} ],
    QueueMonitoring             => [ "MONQ",            $RequestValues{QMgrMonitoring} ],
    ReceiveTimeout              => [ "RCVTIME",         "integer" ],
    ReceiveTimeoutMin           => [ "RCVTMIN",         "integer" ],
    ReceiveTimeoutType          => [ "RCVTTYPE",        $RequestValues{ReceiveTimeoutType} ],
    RemoteEvent			=> [ "REMOTEEV",	$RequestValues{Enabled} ],
    RepositoryName 		=> [ "REPOS",		"string" ],
    RepositoryNamelist		=> [ "REPOSNL",		"string" ],
    SecurityCase		=> [ "SCYCASE",		$RequestValues{SecurityCase} ],
    SharedQQMgrName             => [ "SQQMNAME",        $RequestValues{SharedQQMgrName} ],
    SSLCRLNamelist              => [ "SSLCRLNL",        "string" ],
    SSLEvent                    => [ "SSLEV",           $RequestValues{Enabled} ],
    SSLKeyRepository            => [ "SSLKEYR",         "string" ],
    SSLKeyResetCount            => [ "SSLRKEYC",        "integer" ],
    SSLTasks                    => [ "SSLTASKS",        "integer" ],
    StartStopEvent		=> [ "STRSTPEV",	$RequestValues{Enabled} ],
    TCPChannels                 => [ "TCPCHL",          "integer" ],
    TCPKeepAlive                => [ "TCPKEEP",         $RequestValues{Yes} ],
    TCPName                     => [ "TCPNAME",         "string" ],
    TCPStackType                => [ "TCPSTACK",        $RequestValues{TCPStackType} ],
    TraceRouteRecording         => [ "ROUTEREC",        $RequestValues{TraceRouteRecording} ],
    TriggerInterval		=> [ "TRIGINT", 	"integer" ],
    TreeLifeTime		=> [ "TREELIFE", 	"integer" ],
    Version			=> [ "VERSION",		"string" ],
    SSLFipsRequired		=> [ "SSLFIPS",		$RequestValues{Yes} ],
   },

   Process =>
   {
    Replace			=> [ "",		$RequestValues{Replace} ],
    ApplId			=> [ "APPLICID",	"string" ],
    ApplType			=> [ "APPLTYPE",	$RequestValues{ApplType} ],
    EnvData			=> [ "ENVRDATA",	"string" ],
    UserData			=> [ "USERDATA",	"string" ],
    ProcessName			=> [ "PROCESS",		"string" ],
    ToProcessName		=> [ "PROCESS",		"string" ],
    FromProcessName		=> [ "LIKE",		"string" ],
    ProcessDesc			=> [ "DESCR",		"string" ],
    ProcessAttrs		=> [ "",		$RequestValues{ProcessAttrs} ],
    QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
   # QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
   },

   InquireQueueNames =>
   {
    QName			=> [ "QUEUE",		"string" ],
    QType			=> [ "TYPE",		$RequestValues{QType} ],
   },

   Queue =>
   {
    Custom			=> [ "CUSTOM",		"string" ],
    Authrec			=> [ "AUTHREC",		$RequestValues{Yes} ],
    BackoutRequeueName		=> [ "BOQNAME",		"string" ],
    BackoutThreshold		=> [ "BOTHRESH", 	"integer" ],
    BaseQName			=> [ "TARGQ", 		"string" ],
    BaseType			=> [ "TARGTYPE",	$RequestValues{BaseType} ],
    CommandScope                => [ "CMDSCOPE",        "string" ],
    # CFStructure is for backwards compatibility with pre-1.24 (new: CFStructure)
    CFStructure                => [ "CFSTRUCT",        "string" ],
    #CFStructure		=> [ "CFSTRUCT",        "string" ],
    ClusterInfo			=> [ "CLUSINFO" ],
    CLWLQueuePriority           => [ "CLWLPRTY" ,      "integer" ],
    CLWLQueueRank               => [ "CLWLRANK",       "integer" ],
    CLWLUseQ                    => [ "CLWLUSEQ",        $RequestValues{CLWLUseQ} ],
    DefInputOpenOption		=> [ "DEFSOPT",		$RequestValues{DefInputOpenOption} ],
    DefPersistence		=> [ "DEFPSIST",	$RequestValues{Yes} ],
    DefPriority			=> [ "DEFPRTY", 	"integer" ],
    DefReadAhead		=> [ "DEFREADA", 	$RequestValues{DefReadAhead} ],
    DefPutResponse		=> [ "DEFPRESP", 	$RequestValues{DefPutResponse} ],
    DefinitionType		=> [ "DEFTYPE", 	$RequestValues{DefinitionType} ],
    DistLists			=> [ "DISTL",		$RequestValues{Yes} ],
    Force			=> [ "FORCE" ],
    FromQName			=> [ "LIKE",		"string" ],
    HardenGetBackout		=> [ "", 		$RequestValues{HardenGetBackout} ],
    InhibitGet			=> [ "GET", 		$RequestValues{Disabled} ],
    InhibitPut			=> [ "PUT",		$RequestValues{Disabled} ],
    InitiationQName		=> [ "INITQ",		"string" ],
    MaxMsgLength		=> [ "MAXMSGL", 	"integer" ],
    MaxQDepth			=> [ "MAXDEPTH",	"integer" ],
    MsgDeliverySequence		=> [ "MSGDLVSQ",	$RequestValues{MsgDeliverySequence} ],
    ProcessName			=> [ "PROCESS",		"string" ],
    PropertyControl		=> [ "PROPCTL",		$RequestValues{PropertyControl} ],
    QDepthHighEvent		=> [ "QDPHIEV",		$RequestValues{Enabled} ],
    QDepthHighLimit		=> [ "QDEPTHHI",	"integer" ],
    QDepthLowEvent		=> [ "QDPLOEV",		$RequestValues{Enabled} ],
    QDepthLowLimit		=> [ "QDEPTHLO", 	"integer" ],
    QDepthMaxEvent		=> [ "QDPMAXEV",	$RequestValues{Enabled} ],
    QDesc			=> [ "DESCR", 		"string" ],
    QName			=> [ "QUEUE",		"string" ],
    QServiceInterval		=> [ "QSVCINT",		"integer" ],
    QServiceIntervalEvent 	=> [ "QSVCIEV",		$RequestValues{QServiceIntervalEvent} ],
   # QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    QType			=> [ "TYPE",		$RequestValues{QType} ],
    QueueAccounting             => [ "ACCTQ",           $RequestValues{QueueAccounting} ],
    QueueMonitoring             => [ "MONQ",            $RequestValues{QueueMonitoring} ],
    RemoteQMgrName		=> [ "RQMNAME", 	"string" ],
    RemoteQName			=> [ "RNAME",		"string" ],
    Replace			=> [ "",		$RequestValues{Replace} ],
    RetentionInterval		=> [ "RETINTVL",	"integer" ],
    Scope 			=> [ "SCOPE", 		$RequestValues{Scope} ],
    Shareability		=> [ "",		$RequestValues{Shareability} ],
    ToQName			=> [ "QUEUE",		"string" ],
 #   TPipeNames                  => [ "TPIPE",           "string"],
    TriggerControl		=> [ "",		$RequestValues{TriggerControl} ],
    TriggerData			=> [ "TRIGDATA",      	"string" ],
    TriggerDepth		=> [ "TRIGDPTH", 	"integer" ],
    TriggerMsgPriority		=> [ "TRIGMPRI",	"integer" ],
    TriggerType			=> [ "TRIGTYPE", 	$RequestValues{TriggerType} ],
    Usage			=> [ "USAGE", 		$RequestValues{Usage} ],
    XmitQName			=> [ "XMITQ", 		"string" ],

    QAttrs			=> [ "",		$RequestValues{QAttrs} ],

    #
    # These are specific to MQSC, and are not part of PCF (yet)
    #
    IndexType			=> [ "INDXTYPE",	$RequestValues{IndexType} ],
    StorageClass		=> [ "STGCLASS",	"string" ],

    ClusterName			=> [ "CLUSTER",		"string" ],
    ClusterNamelist		=> [ "CLUSNL",		"string" ],
    DefBind			=> [ "DEFBIND",		$RequestValues{DefBind} ],
    # ClusInfo is for backwards compatibility with pre-1.24 (new: ClusterInfo)
    ClusInfo			=> [ "CLUSINFO" ],
   },

   InquireChannelNames =>
   {
    ChannelName			=> [ "CHANNEL",		"string" ],
    ChannelType 		=> [ "TYPE",		$RequestValues{ChannelType} ],
   },

   #
   # These parameters are used to defined or update specific channel
   # attributes ("DEFINE CHANNEL", "ALTER CHANNEL"), and specify how
   # the values are encoded.  A related list in RequestValues.pl
   # specifies the attributes that can be inquired ("DISPLAY CHANNEL").
   #
   Channel =>
   {
    BatchDataLimit		=> [ "BATCHLIM",	"integer" ],
    DefReconnect		=> [ "DEFRECON",	$RequestValues{DefReconnect} ],
    ResetRequested		=> [ "RESETSEQ",	"integer" ],
    UseDLQ			=> [ "USEDLQ",		$RequestValues{Yes} ],
    ClientIdentifier		=> [ "CLIENTID",	"string" ],
    AutoStart			=> [ "AUTOSTART",	$RequestValues{Enabled} ],
    BatchHeartBeat              => [ "BATCHHB",         "integer" ],
    BatchInterval		=> [ "BATCHINT",       	"integer" ],
    BatchSize			=> [ "BATCHSZ",		"integer" ],
    ChannelAttrs 		=> [ "",		$RequestValues{ChannelAttrs} ],
    ChannelDesc			=> [ "DESCR",		"string" ],
    ChannelDisposition          => [ "CHLDISP",         $RequestValues{ChannelDisposition} ],
    ChannelInstanceAttrs 	=> [ "",		$RequestValues{ChannelAttrs} ],
    ChannelInstanceType		=> [ "",		$RequestValues{ChannelInstanceType} ],
    ChannelName			=> [ "CHANNEL",		"string" ],
    ChannelMonitoring           => [ "MONCHL",          $RequestValues{QueueMonitoring} ],
    ChannelTable		=> [ "CHLTABLE", 	$RequestValues{ChannelTable} ],
    ChannelType 		=> [ "CHLTYPE",		$RequestValues{ChannelType} ],
    ClientChannelWeight		=> [ "CLNTWGHT",	"integer" ],
    ClusterName			=> [ "CLUSTER",		"string" ],
    ClusterNamelist		=> [ "CLUSNL",		"string" ],
    CLWLChannelRank             => [ "CLWLRANK",        "integer" ],
    CLWLChannelPriority         => [ "CLWLPRTY",        "integer" ],
    CLWLChannelWeight           => [ "CLWLWGHT",        "integer" ],
    CommandScope                => [ "CMDSCOPE",        "string" ],
    ConnectionAffinity		=> [ "AFFINITY",	$RequestValues{ConnectionAffinitity} ],
    ConnectionName		=> [ "CONNAME",		"string" ],
    DataConversion		=> [ "CONVERT",		$RequestValues{Yes} ],
    DataCount			=> [ "DATALEN",		"integer" ],
    DefaultChannelDisposition	=> [ "DEFCDISP",	$RequestValues{ChannelDisposition} ],
    DiscInterval		=> [ "DISCINT",		"integer" ],
    EnvironmentParameters	=> [ "ENVPARM",		"string" ],
    FromChannelName		=> [ "LIKE",		"string" ],
    HeaderCompression           => [ "COMPHDR",         $RequestValues{HeaderCompression} ],
    HeartbeatInterval		=> [ "HBINT",		"integer" ],
    InDoubt 			=> [ "ACTION",		$RequestValues{InDoubt} ],
    InitiationQName 		=> [ "INITQ",		"string" ],
    LongRetryCount		=> [ "LONGRTY",		"integer" ],
    LongRetryInterval		=> [ "LONGTMR",		"integer" ],
    KeepAliveInterval           => [ "KAINT",           $RequestValues{KeepAliveInterval} ],
    LocalAddress                => [ "LOCLADDR",        "string" ],
    LUName			=> [ "LUNAME",		"string" ],
    MaxInstances		=> [ "MAXINST",		"integer" ],
    MaxInstancesPerClient	=> [ "MAXINSTC",	"integer" ],
    MCAName			=> [ "MCANAME",		"string" ],
    MCAType			=> [ "MCATYPE",		$RequestValues{MCAType} ],
    MCAUserIdentifier		=> [ "MCAUSER",		"string" ],
    MaxMsgLength		=> [ "MAXMSGL",		"integer" ],
    MessageCompression          => [ "COMPMSG",         $RequestValues{MessageCompression} ],
    ModeName			=> [ "MODENAME",      	"string" ],
    MsgExit			=> [ "MSGEXIT",		"string" ],
    MsgRetryCount		=> [ "MRRTY",		"integer" ],
    MsgRetryExit		=> [ "MREXIT",		"string" ],
    MsgRetryInterval		=> [ "MRTMR",		"integer" ],
    MsgRetryUserData		=> [ "MRDATA",		"string" ],
    MsgSeqNumber		=> [ "SEQNUM",		"integer" ],
    MsgUserData			=> [ "MSGDATA",		"string" ],
    NetworkPriority 		=> [ "NETPRTY",		"integer" ],
    NonPersistentMsgSpeed	=> [ "NPMSPEED",	$RequestValues{NonPersistentMsgSpeed} ],
    Parameter			=> [ "PARM",		"string" ],
    Password			=> [ "PASSWORD",	"string" ],
    Port			=> [ "PORT",		"integer" ],
    PropertyControl		=> [ "PROPCTL",		$RequestValues{PropertyControl} ],
    PutAuthority		=> [ "PUTAUT",		$RequestValues{PutAuthority} ],
    QMgrName			=> [ "QMNAME",		"string" ],
    QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
   # QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    Quiesce 			=> [ "MODE",		$RequestValues{Quiesce} ],
    ReceiveExit			=> [ "RCVEXIT",		"string" ],
    ReceiveUserData		=> [ "RCVDATA",		"string" ],
    RemoteQMgrName		=> [ "RQMNAME",		"string" ],
    RemoteProduct		=> [ "RPRODUCT",	"string" ],
    RemoteVersion		=> [ "RVERSION",	"string" ],
    Replace			=> [ "",		$RequestValues{Replace} ],
    SecurityExit		=> [ "SCYEXIT",		"string" ],
    SecurityUserData		=> [ "SCYDATA",		"string" ],
    SendExit			=> [ "SENDEXIT",	"string" ],
    SendUserData		=> [ "SENDDATA",	"string" ],
    SeqNumberWrap		=> [ "SEQWRAP",		"integer" ],
    SharingConversations	=> [ "SHARECNV",	"integer" ],
    ShortRetryCount		=> [ "SHORTRTY",	"integer" ],
    ShortRetryInterval		=> [ "SHORTTMR",	"integer" ],
    SSLCipherSpec               => [ "SSLCIPH",         "string" ],
    SSLClientAuth               => [ "SSLCAUTH",        $RequestValues{SSLClientAuth} ],
    SSLPeerName                 => [ "SSLPEER",         "string" ],
    ToChannelName		=> [ "CHANNEL",		"string" ],
    TpName			=> [ "TPNAME",		"string" ],
    TransportType		=> [ "TRPTYPE",		$RequestValues{TransportType} ],
    UserIdentifier		=> [ "USERID",		"string" ],
    XmitQName			=> [ "XMITQ",		"string" ],
   },

   ChlAuthRec =>
   {
    Address			=> [ "ADDRESS",		"string" ],
    Addrlist			=> [ "ADDRLIST",	"string" ],
    ChlAuth			=> [ "CHLAUTH",		"string" ],
    Action			=> [ "ACTION",		$RequestValues{ChlAuthAction} ],
    ChlAuthAttrs		=> [ "",		$RequestValues{ChlAuthAttrs} ],
    ChlAuthDesc			=> [ "DESCR",		"string" ],
    ChlAuthType			=> [ "TYPE",		$RequestValues{ChlAuthType} ],
    ClientUserId		=> [ "CLNTUSER",	"string" ],
    CommandScope		=> [ "CMDSCOPE",	"string" ],
    Custom			=> [ "CUSTOM",		"string" ],
    Match			=> [ "MATCH",		$RequestValues{ChlAuthMatch} ],
    MCAUserIdentifier		=> [ "MCAUSER",		"string" ],
    RemoteQMgrName		=> [ "QMNAME",		"string" ],
    SSLPeerName			=> [ "SSLPEER",		"string" ],
    MCAUserIdList		=> [ "USERLIST",	"string" ],
    UserSource			=> [ "USERSRC",		$RequestValues{UserSource} ],
    Warning			=> [ "WARN",		$RequestValues{Yes} ],
   },


   Namelist =>
   {
    NamelistName 		=> [ "NAMELIST",	"string" ],
    NamelistDesc		=> [ "DESCR",		"string" ],
    NamelistType                => [ "NLTYPE",          $RequestValues{NamelistType} ],
    # XXX - this one may need special support for comma-separated lists
    Names 			=> [ "NAMES",		"string" ],

    Replace			=> [ "",		$RequestValues{Replace} ],
    
    CommandScope                => [ "CMDSCOPE",        "string" ],
    FromNamelistName		=> [ "LIKE",		"string" ],
    QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
   # QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    ToNamelistName 		=> [ "NAMELIST",	"string" ],

    NamelistAttrs		=> [ "",		$RequestValues{NamelistAttrs} ],

   },

   InquireQueueStatus =>
   {
    QName                       => [ "QSTATUS",         "string" ],
    CommandScope                => [ "CMDSCOPE",        "string" ],
    StatusType                  => [ "TYPE",            $RequestValues{StatusType} ],
    OpenType                    => [ "OPENTYPE",        $RequestValues{OpenType} ],
    QStatusAttrs                => [ "",                $RequestValues{QStatusAttrs} ],
   },

   ResetQueueStatistics =>
   {
    QName                       => [ "QSTATS",          "string" ],
   },

   Security =>
   {
    Interval			=> [ "INTERVAL",	"integer" ],
    Timeout			=> [ "TIMEOUT",		"integer" ],
    SecurityAttrs		=> [ "",		$RequestValues{SecurityAttrs} ],

    Admin			=> [ "MQADMIN" ],
    Namelist			=> [ "MQNLIST" ],
    Process			=> [ "MQPROC" ],
    Queue			=> [ "MQQUEUE" ],
    All				=> [ '*' ],

    UserIdentifier		=> [ "",		',' ],

   },

   InquireStorageClassNames =>
   {
    StorageClassName		=> [ "STGCLASS",	"string" ],
   },

   StorageClass =>
   {
    StorageClassName		=> [ "STGCLASS",	"string" ],
    PageSetId			=> [ "PSID",		"integer" ],
    QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    #QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    StorageClassDesc		=> [ "DESCR",		"string" ],
    XCFGroupName		=> [ "XCFGNAME",	"string" ],
    XCFMemberName		=> [ "XCFMNAME",	"string" ],

    FromStorageClassName	=> [ "LIKE",		"string" ],
    ToStorageClassName		=> [ "STGCLASS",	"string" ],

    Replace			=> [ "",		$RequestValues{Replace} ],

    StorageClassAttrs		=> [ "",		$RequestValues{StorageClassAttrs} ],

   },

   #
   # These parameters are used to defined or update specific AuthInfo
   # attributes ("DEFINE AUTHINFO", "ALTER AUTHINFO"), and specify how
   # the values are encoded.  A related list in RequestValues.pl
   # specifies the attributes that can be inquired ("DISPLAY AUTHINFO").
   #
   AuthInfo =>
   {
    AuthInfoConnName            => [ "CONNAME",         "string" ],
    AuthInfoDesc                => [ "DESCR",           "string" ],
    AuthInfoName                => [ "AUTHINFO",        "string" ],
    AuthInfoType                => [ "AUTHTYPE",        $RequestValues{AuthInfoType} ],
    LDAPPassword                => [ "LDAPPWD",         "string" ],
    LDAPUserName                => [ "LDAPUSER",        "string" ],
    OCSPResponderURL		=> [ "OCSPURL",		"string" ],
    QSGDisposition    => [ "QSGDISP",         $RequestValues{QSGDisposition} ],
   # QSGDisposition		=> [ "QSGDISP",         $RequestValues{QSGDisposition} ],
    AuthInfoAttrs               => [ "",                $RequestValues{AuthInfoAttrs} ],
   },

   #
   # These parameters are used to defined or update specific CF Structure
   # attributes ("DEFINE CFSTRUCT", "ALTER CFSTRUCT"), and specify how
   # the values are encoded.  A related list in RequestValues.pl
   # specifies the attributes that can be inquired ("DISPLAY CFSTRUCT").
   #
   CFStruc =>
   {
    CFConlos			=> [ "CFCONLOS",	$RequestValues{CFConlos} ],
    DSBlock			=> [ "DSBLOCK",		$RequestValues{DSBlock} ],
    DSBufs			=> [ "DSBUFS",		"integer" ],
    DSExpand			=> [ "DSEXPAND",	$RequestValues{DSExpand} ],
    DSGroup			=> [ "DSGROUP",		"string" ],
    Offload			=> [ "OFFLOAD",		$RequestValues{Offload} ],
    OFFLD1SZ			=> [ "OFFLD1SZ",	"string" ],
    OFFLD2SZ			=> [ "OFFLD2SZ",	"string" ],
    OFFLD3SZ			=> [ "OFFLD3SZ",	"string" ],
    OFFLD1TH			=> [ "OFFLD1TH",	"integer" ],
    OFFLD2TH			=> [ "OFFLD2TH",	"integer" ],
    OFFLD3TH			=> [ "OFFLD3TH",	"integer" ],
    Recauto			=> [ "RECAUTO",		$RequestValues{Yes} ],
    CFStrucAttrs		=> [ "",                $RequestValues{CFStrucAttrs} ],
    CFLevel			=> [ "CFLEVEL",         "integer" ],
    CFStrucDesc			=> [ "DESCR",           "string", ],
    CFStrucName			=> [ "CFSTRUCT",        "string" ],
    Recovery                    => [ "RECOVER",         $RequestValues{Yes} ],
   },

   #
   # These parameters are used to defined or update specific CF Structure
   # attributes ("DEFINE CFSTRUCT", "ALTER CFSTRUCT"), and specify how
   # the values are encoded.  A related list in RequestValues.pl
   # specifies the attributes that can be inquired ("DISPLAY CFSTRUCT").
   #
   # NOTE: CFStruct is for backwards compatibility with pre-1.24 MQSC
   #       New code should use CFStruc (no final 't')
   #
   CFStruct =>
   {
    CFStructAttrs               => [ "",                $RequestValues{CFStructAttrs} ],

    CFConlos			=> [ "CFCONLOS",	$RequestValues{CFConlos} ],
    DSBlock			=> [ "DSBLOCK",		$RequestValues{DSBlock} ],
    DSBufs			=> [ "DSBUFS",		"integer" ],
    DSExpand			=> [ "DSEXPAND",	$RequestValues{DSExpand} ],
    DSGroup			=> [ "DSGROUP",		"string" ],
    Offload			=> [ "OFFLOAD",		$RequestValues{Offload} ],
    OFFLD1SZ			=> [ "OFFLD1SZ",	"string" ],
    OFFLD2SZ			=> [ "OFFLD2SZ",	"string" ],
    OFFLD3SZ			=> [ "OFFLD3SZ",	"string" ],
    OFFLD1TH			=> [ "OFFLD1TH",	"integer" ],
    OFFLD2TH			=> [ "OFFLD2TH",	"integer" ],
    OFFLD3TH			=> [ "OFFLD3TH",	"integer" ],
    Recauto			=> [ "RECAUTO",		$RequestValues{Yes} ],
    CFStructDesc                => [ "DESCR",           "string", ],
    CFStructLevel               => [ "CFLEVEL",         "integer" ],
    CFStructName                => [ "CFSTRUCT",        "string" ],
    Recovery                    => [ "RECOVER",         $RequestValues{Yes} ],
   },


   Trace =>
   {
    TraceType			=> [ "TRACE",		$RequestValues{TraceType} ],
    TraceNumber			=> [ "TNO",		"integer" ],
    Class			=> [ "CLASS",		"integer" ],
    Comment			=> [ "COMMENT",		"string" ],
    EventId			=> [ "IFCID",		"string" ],
    Destination			=> [ "DEST",		"string" ],
    ResourceMgrId		=> [ "RMID",		"integer" ],
    UserIdentifier		=> [ "USERID",		"string" ],
    TraceData			=> [ "TDATA",		$RequestValues{TraceData} ],
   },

   ArchiveLog =>
   {
    Quiesce 			=> [ "MODE",		$RequestValues{Quiesce} ],
    Time			=> [ "TIME",		"integer" ],
    Wait			=> [ "WAIT",		$RequestValues{Yes} ],
   },

   BufferPool =>
   {
    BufferPool			=> [ "BUFFPOOL",	"integer" ],
    Buffers			=> [ "BUFFERS",		"integer" ],
   },

   PageSetId =>
   {
    PageSetId			=> [ "PSID",		"integer" ],
    BufferPool			=> [ "BUFFPOOL",	"integer" ],
   },

   Cluster =>
   {
    ClusterQMgrName 		=> [ "CLUSQMGR",	"string" ],
    Channel			=> [ "CHANNEL",		"string" ],
    ClusterName			=> [ "CLUSTER", 	"string" ],
    ClusterQMgrAttrs		=> [ "",		$RequestValues{ClusterQMgrAttrs} ],
    ClusterNamelist		=> [ "CLUSNL",		"string" ],
    Quiesce 			=> [ "MODE",		$RequestValues{Quiesce} ],
    QMgrName			=> [ "QMNAME",		"string" ],
    Action			=> [ "ACTION",		$RequestValues{ClusterAction} ],
   },

   Tpipe =>
   {
    TpipeName			=> [ "TPIPE",		"string" ],
    Action			=> [ "ACTION",		$RequestValues{TpipeAction} ],
    SendSequence		=> [ "SENDSEQ",		"integer" ],
    ReceiveSequence		=> [ "RCVSEQ",		"integer" ],
    XCFGroupName		=> [ "XCFGNAME",	"string" ],
   },
   
   InquireThread =>
   {
    ThreadName			=> [ "THREAD",		"string" ],
    ThreadType			=> [ "TYPE",		$RequestValues{ThreadType} ],
   },

   ResolveInDoubt =>
   {
    InDoubt			=> [ "INDOUBT",		"string" ],
    Action			=> [ "ACTION",		$RequestValues{InDoubtAction} ],
    NetworkId			=> [ "NID",		"string" ],
   },

  );

$RequestParameters{CreateQueue} = $RequestParameters{ChangeQueue} =
  {
   %{$RequestParameters{Queue}},
   QName			=> [ $RequestParameterRemap{Queue},	"string" ],
  };

$RequestParameters{CopyQueue} =
  {
   %{$RequestParameters{Queue}},
   ToQName			=> [ $RequestParameterRemap{Queue},	"string" ],
  };

$RequestParameters{ClearQueue} =
  {
   %{$RequestParameters{Queue}},
   QName			=> [ "QLOCAL",		"string" ],
  };

$RequestParameters{DeleteQueue} =
  {
   %{$RequestParameters{Queue}},
   QName			=> [ $RequestParameterRemap{Queue},	"string" ],
   Purge			=> [ "",		$RequestValues{Purge} ],
  };


1;
