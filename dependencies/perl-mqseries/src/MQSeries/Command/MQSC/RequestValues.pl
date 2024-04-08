#
# $Id: RequestValues.pl,v 33.12 2012/09/26 16:13:37 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

%RequestValues =
  (

   Yes				=> [ "NO",		"YES" ],

   Enabled 			=> [ "DISABLED",	"ENABLED" ],

   Disabled 			=> [ "ENABLED",	        "DISABLED" ],

   HardenGetBackout		=> [ "NOHARDENBO",	"HARDENBO" ],

   Purge                        => [ "NOPURGE",         "PURGE" ],

   Shareability			=> [ "NOSHARE",		"SHARE" ],

   TriggerControl		=> [ "NOTRIGGER",	"TRIGGER" ],

   Quiesce			=> [ "FORCE", 		"QUIESCE" ],

   Replace			=> [ "NOREPLACE",	"REPLACE" ],

   #
   # These parameters are used to determine what attributes must be
   # returned by a "display queue manager" command.  The default for
   # an InquireQueueManager() command is "All".
   #
   QMgrAttrs =>
   {
    All				=> "ALL",
    ActivityRecording           => "ACTIVREC",
    AuthorityEvent              => "AUTHOREV",
    AdoptNewMCACheck            => "ADOPTCHK",
    AdoptNewMCAType             => "ADOPTMCA",
    AlterationDate              => "ALTDATE",
    AlterationTime              => "ALTTIME",
    AuthorityEvent		=> "AUTHOREV",
    BridgeEvent                 => "BRIDGEEV",
    CFConlos			=> "CFCONLOS",
    ChannelAutoDef		=> "CHAD",
    ChannelAutoDefEvent		=> "CHADEV",
    ChannelAutoDefExit		=> "CHADEXIT",
    ChannelEvent                => "CHLEV",
    ChannelInitiatorControl     => "SCHINIT",
    ChannelMonitoring           => "MONCHL",
    ChannelStatistics           => "STATCHL",
    ChinitAdapters              => "CHIADAPS",
    ChinitDispatchers           => "CHIDISPS",
    ChinitServiceParm           => "CHISERVP",
    ChinitTraceAutoStart        => "TRAXSTR",
    ChinitTraceTableSize        => "TRAXTBL",
    ChlAuthRecords		=> "CHLAUTH",
    ClusterSenderMonitoringDefault => "MONACLS",
    ClusterSenderStatistics     => "STATACLS",
    ClusterWorkLoadData		=> "CLWLDATA",
    ClusterWorkLoadExit		=> "CLWLEXIT",
    ClusterWorkLoadLength	=> "CLWLLEN",
    ClusterWorkloadMRUChannels  => "CLWLMRUC",
    ClusterWorkloadUseQueue     => "CLWLUSEQ",
    CodedCharSetId		=> "CCSID",
    CommandEvent                => "CMDEV",
    CommandInputQName		=> "COMMANDQ",
    CommandLevel		=> "CMDLEVEL",
    CommandServerControl        => "SCMDSERV",
    ConfigurationEvent          => "CONFIGEV",
    CPILevel			=> "CPILEVEL",
    DeadLetterQName		=> "DEADQ",
    DefXmitQName		=> "DEFXMITQ",
    DistLists			=> "DISTL",
    DNSGroup                    => "DNSGROUP",
    DNSWorkloadMgr              => "DNSWLM",
    EncryptionPolicySuiteB	=> "SUITEB",
    ExpiryInterval              => "EXPRYINT",
    InhibitEvent		=> "INHIBTEV",
    IntraGroupQueuing           => "IGQ",
    IGQPutAuthority         => "IGQAUT",
    IntraGroupUser              => "IGQUSR",
    IPAddressVersion            => "IPADDRV",
    ListenerTimer               => "LSTRTMR",
    LocalEvent			=> "LOCALEV",
    LoggerEvent                 => "LOGGEREV",
    LUGroupName                 => "LUGROUP",
    LUName                      => "LUNAME",
    LU62ARMSuffix               => "LU62ARM",
    LU62Channels                => "LU62CHL",
    MaxActiveChannels           => "ACTCHL",
    MaxChannels                 => "MAXCHL",
    MaxHandles			=> "MAXHANDS",
    MaxMsgLength		=> "MAXMSGL",
    MaxPriority			=> "MAXPRTY",
    MaxPropertiesLength		=> "MAXPROPL",
    MaxUncommittedMsgs		=> "MAXUMSGS",
    MQIAccounting               => "ACCTMQI",
    MQIStatistics               => "STATMQI",
    MsgMarkBrowseInterval	=> "MARKINT",
    OutboundPortMax             => "OPORTMAX",
    OutboundPortMin             => "OPORTMIN",
    Parent			=> "PARENT",
    PerformanceEvent		=> "PERFMEV",
    Platform			=> "PLATFORM",
    PubSubClus			=> "PSCLUS",
    PubSubMaxMsgRetryCount	=> "PSRTYCNT",
    PubSubMode			=> "PSMODE",
    PubSubNPInputMsg		=> "PSNPMSG",
    PubSubNPResponse		=> "PSNPRES",
    PubSubSyncPoint		=> "PSSYNCPT",
    QMgrDesc			=> "DESCR",
    QMgrIdentifier		=> "QMID",
    QMgrName			=> "QMNAME",
    QSGName                     => "",                    # FIXME?
    QueueAccounting             => "ACCTQ",
    QueueMonitoring             => "MONQ",
    QueueStatistics             => "STATQ",
    ReceiveTimeout              => "RCVTIME",
    ReceiveTimeoutMin           => "RCVTMIN",
    ReceiveTimeoutType          => "RCVTTYPE",
    RemoteEvent			=> "REMOTEEV",
    RepositoryName		=> "REPOS",
    RepositoryNamelist		=> "REPOSNL",
    SecurityCase		=> "SCYCASE",
    SharedQQmgrName             => "SQQMNAME",
    SSLCRLNamelist              => "SSLCRLNL",
    SSLEvent                    => "SSLEV",
    SSLFIPSRequired             => "SSLFIPS",
    SSLKeyRepository            => "SSLKEYR",
    SSLKeyResetCount            => "SSLRKEYC",
    SSLTasks                    => "SSLTASKS",
    StartStopEvent		=> "STRSTPEV",
    StatisticsInterval          => "STATINT",
    SyncPoint			=> "SYNCPT",
    TCPChannels                 => "TCPCHL",
    TCPKeepAlive                => "TCPKEEP",
    TCPName                     => "TCPNAME",
    TCPStackType                => "TCPSTACK",
    TraceRouteRecording         => "ROUTEREC",
    TreeLifeTime		=> "TREELIFE",
    TriggerInterval		=> "TRIGINT",
    Version			=> "VERSION",
   },

   QMgrMonitoring =>
   {
    High			=> "HIGH",
    Low				=> "LOW",
    Medium			=> "MEDIUM",
    None                        => "NONE",
    Off				=> "OFF",
   },

   ActivityRecording =>	       
   {
    Disabled                    => "DISABLED",
    Msg                         => "MSG",
    Queue                       => "QUEUE",
   },

   ChannelEvent =>
   {
    Disabled                  => "DISABLED",
    Enabled                   => "ENABLED",
    Exception                 => "EXCEPTION",
   },

   ChannelMonitoring =>
   {
    High                       => "HIGH",
    Low			       => "LOW",
    Medium		       => "MEDIUM",
    None                       => "NONE",
    Off		               => "OFF",
   },

   ClusterSenderMonitoringDefault =>
   {
    High		        => "HIGH",
    Low				=> "LOW",
    Medium			=> "MEDIUM",
    QMgr                        => "QMGR",
    Off				=> "Off",
   },
   
   CLWLUseQ =>
   {
    Any    		        => "ANY",
    Local    		        => "LOCAL",
    QMgr    		        => "QMGR", # Only returned by queue CLWLUseQ
   },

   CommandEvent =>
   {
    Disabled                    => "DISABLED",
    Enabled                     => "ENABLED",
    Nodisplay                   => "NODISPLAY",
   },

   IGQPutAuthority =>
   {
    AltIGQ                      => "ALTIGQ",
    Context                     => "CONTEXT",
    Default                     => "DEFAULT",
    OnlyIGQ                     => "ONLYIGQ",
   },

   
   IPAddressVersion =>
   {
    IPv4		        => "IPV4",
    IPv6		        => "IPV6",
   },
   
   PubSubMode => 
   {
   Compat			=> "COMPAT",
   Enabled			=> "ENABLED",
   Disabled			=> "DISABLED",
   },

   PubSubNPInputMsg =>
   {
   Discard			=> "DISCARD",
   Keep				=> "KEEP",
   },

   PubSubNPResponse =>
   {
   Discard			=> "DISCARD",
   Keep				=> "KEEP",
   Normal			=> "NORMAL",
   SAFE				=> "SAFE",
   },

   PubSubSyncPoint =>
   {
   IfPersistent			=> "IFPER",
   Yes				=> "YES",
   },

   QMgrAccounting =>	      # QMgr-level QueueAccounting
   {
    None                       => "NONE",
    On                         => "ON",
    Off                        => "OFF",
   },

   ReceiveTimeoutType =>
   {
    Add    		       => "ADD",
    Equal    		       => "EQUAL",
    Multiply   		       => "MULTIPLY",
   },

   SecurityCase =>
   {
    Mixed			=> "MIXED",
    Upper			=> "UPPER",
   },

   SharedQQmgrName =>
   {
    Ignore  		       => "IGNORE",
    Use   		       => "USE",
   },

   TCPStackType =>
   {
    Multiple   		       => "MULTIPLE",
    Single   		       => "SINGLE",
   },

   TraceRouteRecording =>
   {
    Disabled   		       => "DISABLED",
    Msg  		       => "MSG",
    Queue   		       => "QUEUE",
   },
   #
   # These parameters are used to determine what attributes must be
   # returned by a "display queue" command.  The default for an
   # InquireQueue() command is "All".
   #
   QAttrs =>
   {
    All				=> "ALL",
    BackoutRequeueName		=> "BOQNAME",
    BackoutThreshold		=> "BOTHRESH",
    BaseQName			=> "TARGQ",
    Cluster                     => "CLUSTER",
    ClusterNameList             => "CLUSNL",
    CLWLQueuePriority           => "CLWLPRTY",
    CLWLQueueRank               => "CLWLRANK",
    CLWLUseQ                    => "CLWLUSEQ",
    CreationDate		=> "CRDATE",
    CreationTime		=> "CRTIME",
    CurrentQDepth		=> "CURDEPTH",
    Custom			=> "CUSTOM",
    DefInputOpenOption		=> "DEFSOPT",
    DefPersistence		=> "DEFPSIST",
    DefPriority			=> "DEFPRTY",
    DefPutResponse		=> "DEFPRESP",
    DefReadAhead		=> "DEFREADA",
    DefinitionType		=> "DEFTYPE",
    DistLists			=> "DISTL",
    HardenGetBackout		=> "HARDENBO",
    IndexType			=> "INDXTYPE",
    InhibitGet			=> "GET",
    InhibitPut			=> "PUT",
    InitiationQName		=> "INITQ",
    MaxMsgLength		=> "MAXMSGL",
    MaxQDepth			=> "MAXDEPTH",
    MsgDeliverySequence		=> "MSGDLVSQ",
    OpenInputCount		=> "IPPROCS",
    OpenOutputCount		=> "OPPROCS",
    NonPersistentMsgClass       => "NPMCLASS",
    PageSetId                   => "PSID",
    ProcessName			=> "PROCESS",
    PropertyControl		=> "PROPCTL",
    QAccounting                 => "ACCTQ",
    QDepthHighEvent		=> "QDPHIEV",
    QDepthHighLimit		=> "QDEPTHHI",
    QDepthLowEvent		=> "QDPLOEV",
    QDepthLowLimit		=> "QDEPTHLO",
    QDepthMaxEvent		=> "QDPMAXEV",
    QDesc			=> "DESCR",
    QMonitoring                 => "MONQ",
    QName                       => "",
    QServiceInterval		=> "QSVCINT",
    QServiceIntervalEvent 	=> "QSVCIEV",
    QSGDisposition              => "QSGDISP",
    QStatistics                 => "STATQ",
    QType			=> "QTYPE",
    RemoteQMgrName		=> "RQMNAME",
    RemoteQName			=> "RNAME",
    RetentionInterval		=> "RETINTVL",
    Scope 			=> "SCOPE",
    Shareability		=> "SHARE",
    StorageClass		=> "STGCLASS",
    TriggerControl		=> "TRIGGER",
    TriggerData			=> "TRIGDATA",
    TriggerDepth		=> "TRIGDPTH",
    TriggerMsgPriority		=> "TRIGMPRI",
    TriggerType			=> "TRIGTYPE",
    Usage			=> "USAGE",
    XmitQName			=> "XMITQ",
   },

   BaseType =>
   {
    Queue			=> "QUEUE",
    Topic			=> "TOPIC",
   },

   DefReadAhead =>
   {
    Disabled			=> "DISABLED",
    No				=> "NO",
    Yes				=> "YES", 
   },
# I couldn't find 'AsParent' equivalent in MQSC
   DefPutResponse =>
   {
    Sync			=> "SYNC",
    Async			=> "ASYNC",
   },

   PropertyControl =>
   {
    All				=> "ALL",
    Compatibility		=> "COMPAT",
    ForceRFH2			=> "FORCE",
    None			=> "None",
   },

   #
   # These parameters are used to determine what attributes must be
   # returned by a "display auth info" command.  The default for an
   # InquireAuthInfo() command is "All".
   #
   AuthInfoAttrs =>
   {
    All				=> "ALL",
    AlterationDate              => "ALTDATE",
    AlterationTime              => "ALTTIME",
    AuthInfoConnName            => "CONNAME",
    AuthInfoDesc                => "DESCR",
    AuthInfoType                => "AUTHTYPE",
    LDAPPassword                => "LDAPPWD",
    LDAPUserName                => "LDAPUSER",
    OCSPResponderURL		=> "OCSPURL",
   },

   AuthInfoType =>
   {
    CRLLDAP                     => "CRLLDAP",
    OCSP			=> "OCSP",
    All				=> "ALL",
   },

   ApplType =>
   {
    AIX				=> "UNIX",
    CICS			=> "CICS",
    DOS				=> "DOS",
    Default			=> "DEF",
    IMS				=> "IMS",
    NSK				=> "NSK",
    MVS				=> "MVS",
    OS2				=> "OS2",
    OS400			=> "OS400",
    UNIX			=> "UNIX",
    VMS				=> "VMS",
    Win16			=> "WINDOWS",
    Win32			=> "WINDOWSNT",
   },

   ProcessAttrs =>
   {
    All				=> "ALL",
    ProcessName			=> "PROCESS",
    ProcessDesc			=> "DESCR",
    ApplType			=> "APPLTYPE",
    ApplId			=> "APPLICID",
    EnvData			=> "ENVRDATA",
    QSGDisposition		=> "QSGDISP",
    UserData			=> "USERDATA",

    AlterationDate		=> "ALTDATE",
    AlterationTime		=> "ALTTIME",
   },

   ChannelDisposition =>
   {
    All                         => "ALL",
    Private                     => "PRIVATE",
    Shared                      => "SHARED",
    Fixshared			=> "FIXSHARED",
   },

   CLWLUseQ =>
   {
    Any    		=> "ANY",
    Local    		=> "LOCAL",
    QMgr    		=> "QMGR", # Only returned by queue CLWLUseQ
   },

   DefInputOpenOption =>
   {
    Exclusive			=> "EXCL",
    Shared			=> "SHARED",
   },

   DefinitionType =>
   {
    Permanent			=> "PERMDYN",
    Shared			=> "SHAREDYN",
    Temporary			=> "TEMPDYN",
   },

   IndexType =>
   {
    CorrelId			=> "CORRELID",
    GroupId                     => "GROUPID",
    MsgToken			=> "MSGTOKEN",
    MsgId			=> "MSGID",
    None			=> "NONE",
   },

   IGQPutAuthority =>
   {
    AltIGQ                      => "ALTIGQ",
    Context                     => "CTX",
    Default                     => "DEF",
    OnlyIGQ                     => "ONLYIGQ",
   },

   MsgDeliverySequence =>
   {
    Priority			=> "PRIORITY",
    FIFO			=> "FIFO",
   },

   NonPersistentMsgClass =>
   {
    High			=> "HIGH",
    Normal			=> "NORMAL",
   },

   QServiceIntervalEvent =>
   {
    High			=> "HIGH",
    None			=> "NONE",
    OK				=> "OK",
   },

   QSGDisposition =>
   {
    All                         => "ALL",
    Copy                        => "COPY",
    Group                       => "GROUP",
    Live                        => "LIVE",
    Private                     => "PRIVATE",
    QMgr                        => "QMGR",
    Shared                      => "SHARED",
   },

   QueueAccounting =>
   {
    Off			        => "OFF",
    On			        => "ON",
    QMgr		        => "QMGR",
   },

   QueueMonitoring =>
   {
    High			=> "HIGH",
    Low				=> "LOW",
    Medium			=> "MEDIUM",
    QMgr                        => "QMGR",
    Off				=> "OFF",
   },

   Scope =>
   {
    QMgr			=> "QMGR",
    Cell			=> "CELL",
   },

   TriggerType =>
   {
    None			=> "NONE",
    Every			=> "EVERY",
    First			=> "FIRST",
    Depth			=> "DEPTH",
   },

   Usage =>
   {
    Normal			=> "NORMAL",
    XMITQ			=> "XMITQ",
   },

   QType =>
   {
    Local			=> "QLOCAL",
    Remote			=> "QREMOTE",
    Alias			=> "QALIAS",
    Model			=> "QMODEL",
   },

   ChannelType =>
   {
    Sender			=> "SDR",
    Server			=> "SVR",
    Receiver			=> "RCVR",
    Requester			=> "RQSTR",
    Svrconn			=> "SVRCONN",
    Clntconn			=> "CLNTCONN",
    ClusterReceiver		=> "CLUSRCVR",
    ClusterSender		=> "CLUSSDR",
    Telemetry			=> "MQTT",
   },

   MCAType =>
   {
    Process			=> "PROCESS",
    Thread			=> "THREAD",
   },

   NonPersistentMsgSpeed =>
   {
    Normal			=> "NORMAL",
    Fast			=> "FAST",
   },

   PutAuthority =>
   {
    Default			=> "DEF",
    Context			=> "CTX",
    AlternateMCA                => "ALTMCA",
    OnlyMCA                     => "ONLYMCA",
   },

   InDoubt =>
   {
    Commit			=> "COMMIT",
    Backout			=> "BACKOUT",
   },

   TransportType =>
   {
    LU62			=> "LU62",
    UDP				=> "UDP",
    TCP				=> "TCP",
    SPX				=> "SPX",
    NetBIOS			=> "NETBIOS",
    DECNET			=> "DECNET",
   },

   ChannelTable =>
   {
    QMgr			=> "QMGRTBL",
    Clntconn			=> "CLNTTBL",
   },

   ChannelInstanceType =>
   {
    Current			=> "CURRENT",
    Saved			=> "SAVED",
   },

   #
   # These parameters are used to determine what attributes must be
   # returned by a "display channel" command.  The default for an
   # InquireChannel() command is "All".
   #
   ChannelAttrs =>
   {
    All				=> "ALL",
    AlterationDate		=> "ALTDATE",
    AlterationTime		=> "ALTTIME",
    BatchDataLimit		=> "BATCHLIM",
    BatchHeartBeat              => "BATCHHB",
    BatchInterval		=> "BATCHINT",
    BatchSize			=> "BATCHSZ",
    Batches			=> "BATCHES",
    BuffersReceived		=> "BUFSRCVD",
    BuffersSent			=> "BUFSSENT",
    BytesReceived		=> "BYTSRCVD",
    BytesSent			=> "BYTSSENT",
    ChannelDesc			=> "DESCR",
    ChannelDisposition		=> "CHLDISP",
    ChannelInstanceType		=> "CHLTYPE",
    ChannelName			=> "",
    ChannelNames		=> "",
    ChannelMonitoring           => "MONCHL",
    ChannelStartDate		=> "CHSTADA",
    ChannelStartTime		=> "CHSTATI",
    ChannelStatus		=> "",
    ChannelType			=> "CHLTYPE",
    ClientChannelWeight		=> "CLNTWGHT",
    ClusterName 		=> "CLUSTER",
    ClusterNamelist		=> "CLUSNL",
    CLWLChannelRank             => "CLWLRANK",
    CLWLChannelPriority         => "CLWLPRTY",
    CLWLChannelWeight           => "CLWLWGHT",
    ConnectionAffinity		=> "AFFINITY",
    ConnectionName		=> "CONNAME",
    CurrentLUWID		=> "CURLUWID",
    CurrentMsgs			=> "CURMSGS",
    CurrentSequenceNumber	=> "CURSEQNO",
    DataConversion		=> "CONVERT",
    DefReconnect		=> "DEFRECON",
    DiscInterval		=> "DISCINT",
    HeaderCompression           => "COMPHDR",
    HeartbeatInterval		=> "HBINT",
    InDoubtStatus		=> "INDOUBT",
    KeepAliveInterval           => "KAINT",
    LastLUWID			=> "LSTLUWID",
    LastMsgDate			=> "LSTMSGDA",
    LastMsgTime			=> "LSTMSGTI",
    LastSequenceNumber		=> "LSTSEQNO",
    LocalAddress                => "LOCLADDR",
    LongRetriesLeft		=> "LONGRTS",
    LongRetryCount		=> "LONGRTY",
    LongRetryInterval		=> "LONGTMR",
    MaxInstances		=> "MAXINST",
    MaxInstancesPerClient	=> "MAXINSTC",
    MCAJobName			=> "JOBNAME",
    MCAName			=> "MCANAME",
    MCAStatus			=> "MCASTAT",
    MCAType			=> "MCATYPE",
    MCAUserIdentifier		=> "MCAUSER",
    MaxMsgLength		=> "MAXMSGL",
    MessageCompression          => "COMPMSG",
    ModeName			=> "MODENAME",
    MsgExit			=> "MSGEXIT",
    MsgRetryCount		=> "MRRTY",
    MsgRetryExit		=> "MREXIT",
    MsgRetryInterval		=> "MRTMR",
    MsgRetryUserData		=> "MRDATA",
    MsgUserData			=> "MSGDATA",
    Msgs			=> "MSGS",
    NonPersistentMsgSpeed	=> "NPMSPEED",
    Password			=> "PASSWORD",
    PropertyControl		=> "PROPCTL",
    PutAuthority		=> "PUTAUT",
    QMgrName			=> "QMNAME",
    QSGDisposition		=> "QSGDISP",
    ReceiveExit			=> "RCVEXIT",
    ReceiveUserData		=> "RCVDATA",
    RemoteQMgrName		=> "RQMNAME",
    RemoteProduct		=> "RPRODUCT",
    RemoteVersion		=> "RVERSION",
    ResetRequested		=> "RESETSEQ",
    SecurityExit		=> "SCYEXIT",
    SecurityUserData		=> "SCYDATA",
    SendExit			=> "SENDEXIT",
    SendUserData		=> "SENDDATA",
    SeqNumberWrap		=> "SEQWRAP",
    ShortRetriesLeft		=> "SHORTRTS",
    ShortRetryCount		=> "SHORTRTY",
    ShortRetryInterval		=> "SHORTTMR",
    SSLCipherSpec               => "SSLCIPH",
    SSLClientAuth               => "SSLCAUTH",
    SSLPeerName                 => "SSLPEER",
    StopRequested		=> "STOPREQ",
    TpName			=> "TPNAME",
    TransportType		=> "TRPTYPE",
    UserIdentifier		=> "USERID",
    XmitQName			=> "XMITQ",
    UseDLQ			=> "USEDLQ",
   },

   ConnectionAffinity =>
   {
    None			=> "NONE",
    Preferred			=> "PREFERRED",
   },

   DefBind =>
   {
    OnGroup			=> "GROUP",
    OnOpen			=> "OPEN",
    NotFixed			=> "NOTFIXED",
   },

   HeaderCompression =>
   {
    None			=> "NONE",
    System			=> "SYSTEM",
   },

   MessageCompression =>
   {
    Any				=> "ANY",
    None			=> "NONE",
    Rle			        => "RLE",
    ZlibFast			=> "ZLIBFAST",
    ZlibHigh			=> "ZLIBHIGH",
   },
  
   # VALUEMAP-CODEREF
   KeepAliveInterval =>
    sub { MQSeries::Command::Base::strinteger(@_, -1, "AUTO", 99999); }, 

   # VALUEMAP-CODEREF
   MsgMarkBrowseInterval =>
       sub { MQSeries::Command::Base::strinteger(@_, -1, "NOLIMIT", 999999999); },
   
# 100MB max
   # VALUEMAP-CODEREF
   MaxPropertiesLength =>
       sub { MQSeries::Command::Base::strinteger(@_, -1, "NOLIMIT", 104857600); },

   NamelistAttrs =>
   {
    All				=> "ALL",
    NamelistName 		=> "NAMELIST",
    NamelistDesc		=> "DESCR",
    NamelistType                => "NLTYPE",
    Names			=> "NAMES",
    AlterationDate		=> "ALTDATE",
    AlterationTime 		=> "ALTTIME",
    NamelistCount		=> "NAMCOUNT",
    QSGDisposition		=> "QSGDISP",
    CommandScope                => "CMDSCOPE",
   },

   SecurityAttrs =>
   {
    Interval			=> "INTERVAL",
    Switches			=> "SWITCHES",
    Timeout			=> "TIMEOUT",
   },

   StorageClassAttrs =>
   {
    All                         => "ALL",
    AlterationDate		=> "ALTDATE",
    AlterationTime 		=> "ALTTIME",
    PageSetId                   => "PSID",
    QSGDisposition		=> "QSGDISP",
    StorageClassDesc		=> "DESCR",	
    XCFGroupName		=> "XCFGNAME",
    XCFMemberName		=> "XCFMNAME",
   },

   TraceType =>
   {
    All				=> '*',
    Global			=> "GLOBAL",
    Statistical			=> "STAT",
    Accounting			=> "ACCTG",
   },

   TraceData =>
   {
    Correlation			=> "CORRELATION",
    Trace			=> "TRACE",
   },

   ClusterQMgrAttrs =>
   {
    All				=> "ALL",
    AlterationDate		=> "ALTDATE",
    AlterationTime		=> "ALTTIME",
    BatchInterval		=> "BATCHINT",
    BatchSize			=> "BATCHSZ",
    ChannelDesc			=> "DESCR",
    ChannelName			=> "CHANNEL",
    ChannelStatus		=> "STATUS",
    ClusterDate			=> "CLUSDATE",
    ClusterName 		=> "CLUSTER",
    ClusterTime			=> "CLUSTIME",
    ConnectionName		=> "CONNAME",
    DataConversion		=> "CONVERT",
    DiscInterval		=> "DISCINT",
    HeartbeatInterval		=> "HBINT",
    LongRetryCount		=> "LONGRTY",
    LongRetryInterval		=> "LONGTMR",
    MCAName			=> "MCANAME",
    MCAType			=> "MCATYPE",
    MCAUserIdentifier		=> "MCAUSER",
    MaxMsgLength		=> "MAXMSGL",
    ModeName			=> "MODENAME",
    MsgExit			=> "MSGEXIT",
    MsgRetryCount		=> "MRRTY",
    MsgRetryExit		=> "MREXIT",
    MsgRetryInterval		=> "MRTMR",
    MsgRetryUserData		=> "MRDATA",
    MsgUserData			=> "MSGDATA",
    NetworkPriority 		=> "NETPRTY",
    NonPersistentMsgSpeed    	=> "NPMSPEED",
    Password			=> "PASSWORD",
    PutAuthority		=> "PUTAUT",
    QMgrDefinitionType		=> "DEFTYPE",
    QMgrIdentifier		=> "QMID",
    QMgrType			=> "QMTYPE",
    ReceiveExit			=> "RCVEXIT",
    ReceiveUserData		=> "RCVDATA",
    SecurityExit		=> "SCYEXIT",
    SecurityUserData		=> "SCYDATA",
    SendExit			=> "SENDEXIT",
    SendUserData		=> "SENDDATA",
    SeqNumberWrap		=> "SEQWRAP",
    ShortRetryCount		=> "SHORTRTY",
    ShortRetryInterval		=> "SHORTTMR",
    Suspend			=> "SUSPEND",
    TpName			=> "TPNAME",
    TransportType		=> "TRPTYPE",
    UserIdentifier		=> "USERID",
   },

   ClusterAction =>
   {
    ForceRemove			=> "FORCEREMOVE",
   },

   TpipeAction =>
   {
    Commit			=> "COMMIT",
    Backout			=> "BACKOUT",
   },

   ThreadType =>
   {
    Active			=> "ACTIVE",
    InDoubt			=> "INDOUBT",
    All				=> '*',
   },

   InDoubtAction =>
   {
    Commit			=> "COMMIT",
    Backout			=> "BACKOUT",
   },

   StatusType =>
   {
    Queue                       => "QUEUE",
    Handle                      => "HANDLE",
   },

   OpenType =>
   {
    All                         => "ALL",
    Input                       => "INPUT",
    Output                      => "OUTPUT",
   },

   SSLClientAuth =>
   {
    Optional                    => "OPTIONAL",
    Required                    => "REQUIRED",
   },

   QStatusAttrs =>
   {
    All                         => "ALL",
    AddressSpaceId              => "ASID",
    ApplTag                     => "APPLTAG",
    ApplType                    => "APPLTYPE",
    AsynchronousState		=> "ASTATE",
    ChannelName                 => "CHANNEL",
    Conname                     => "CONNAME",
    CurrentQDepth               => "CURDEPTH",
    OpenInputCount              => "IPPROCS",
    OpenOutputCount             => "OPPROCS",
    PSBName                     => "PSBNAME",
    PSTId                       => "PSTID",
    QName                       => "QNAME",
    QSGDisposition		=> "QSGDISP",
    TaskNumber                  => "TASKNO",
    TransactionId               => "TRANSID",
    UncommittedMsgs             => "UNCOM",
    URId                        => "URID",
    UserIdentifier              => "USERID",
   },

   #
   # These parameters are used to determine what attributes must be
   # returned by a "display CF Structure" command.  The default for an
   # InquireCFStruc() command is "All".
   #
   CFStrucAttrs =>
   {
    All                         => "ALL",
    AlterationDate		=> "ALTDATE",
    AlterationTime		=> "ALTTIME",
    CFStrucDesc			=> "DESCR",
    CFStrucLevel		=> "CFLEVEL",
    Recovery                    => "RECOVER",
    CFConlos			=> "CFCONLOS",
    DSBlock			=> "DSBLOCK",
    DSBufs			=> "DSBUFS",
    DSExpand			=> "DSEXPAND",
    DSGroup			=> "DSGROUP",
    OFFLD1SZ			=> "OFFLD1SZ",
    OFFLD2SZ			=> "OFFLD2SZ",
    OFFLD3SZ			=> "OFFLD3SZ",
    OFFLD1TH			=> "OFFLD1TH",
    OFFLD2TH			=> "OFFLD2TH",
    OFFLD3TH			=> "OFFLD3TH",
    OFFLOAD			=> "OFFLOAD",
    Recauto			=> "RECAUTO",
   },

   #
   # These parameters are used to determine what attributes must be
   # returned by a "display CF Structure" command.  The default for an
   # InquireCFStruct() command is "All".
   #
   # NOTE: CFStruct is for backwards compatibility with pre-1.24 MQSC
   #       New code should use CFStruc (no final 't')
   #
   CFStructAttrs =>
   {
    All                         => "ALL",
    AlterationDate		=> "ALTDATE",
    AlterationTime		=> "ALTTIME",
    CFStructDesc                => "DESCR",
    CFStructLevel               => "CFLEVEL",
    Recovery                    => "RECOVER",
    CFConlos			=> "CFCONLOS",
    DSBlock			=> "DSBLOCK",
    DSBufs			=> "DSBUFS",
    DSExpand			=> "DSEXPAND",
    DSGroup			=> "DSGROUP",
    OFFLD1SZ			=> "OFFLD1SZ",
    OFFLD2SZ			=> "OFFLD2SZ",
    OFFLD3SZ			=> "OFFLD3SZ",
    OFFLD1TH			=> "OFFLD1TH",
    OFFLD2TH			=> "OFFLD2TH",
    OFFLD3TH			=> "OFFLD3TH",
    OFFLOAD			=> "OFFLOAD",
    Recauto			=> "RECAUTO",
   },

   NamelistType =>
   {
    None                        => "NONE",
    Queue                       => "QUEUE",
    Cluster                     => "CLUSTER",
    AuthInfo                    => "AUTHINFO",
   },

   #
   # Added in 1.33 to match to what is done for PCF in 1.33
   #
   CFConlos =>
   {
    AsQMgr			=> "ASQMGR",
    Terminate			=> "TERMINATE",
    Tolerate			=> "TOLERATE",
   },

   EncryptionPolicySuiteB =>
   {
    None			=> "NONE",
    "128Bit"			=> "128_BIT",
    "192Bit"			=> "192_BIT",
   },

   ChlAuthAction =>
   {
    Add				=> "ADD",
    Replace			=> "REPLACE",
    Remove			=> "REMOVE",
    RemoveAll			=> "REMOVEALL",
   },
   
   ChlAuthAttrs =>
   {
    All				=> "ALL",
    AlterationDate		=> "ALTDATE", 
    AlterationTime		=> "ALTTIME",
    ChlAuth			=> "CHLAUTH",
    ChlAuthDesc			=> "DESCR",
    RemoteQMgrName		=> "QMNAME",
    ClientUserId		=> "CLNTUSER",
    Address			=> "ADDRESS",
    Addrlist			=> "ADDRLIST",
    MCAUserIdentifier		=> "MCAUSER",
    MCAUserIdList		=> "USERLIST",
    SSLPeerName			=> "SSLPEER",
    Custom			=> "CUSTOM",
    ChAuthType			=> "TYPE",
    UserSource			=> "USERSRC",
    Warning			=> "WARN",
   },

   ChlAuthType =>
   {
    BlockUser			=> "BLOCKUSER",
    BlockAddress		=> "BLOCKADDR",
    SSLPeerMap			=> "SSLPEERMAP",
    AddressMap			=> "ADDRESSMAP",
    UserMap			=> "USERMAP",
    QMgrMap			=> "QMGRMAP",
    All				=> "ALL",
   },

   ChlAuthMatch =>
   {
    Runcheck			=> "RUNCHECK",
    Exact			=> "EXACT",
    Generic			=> "GENERIC",
    All				=> "ALL",
   },

   UserSource =>
   {
    Channel			=> "CHANNEL",
    Map				=> "MAP",
    NoAcesss			=> "NOACCESS",
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
    Yes				=> "YES",
    No				=> "NO",
    Default			=> "DEFAULT",
   },

   Offload =>
   {
    DB2				=> "DB2",
    SMDS			=> "SMDS",
    None			=> "NONE",
   },
  
   DefReconnect =>
   {
    QMgr			=> "QMGR",
    Disabled			=> "DISABLED",
    No				=> "NO",
    Yes				=> "YES",
   },

  );

1;
