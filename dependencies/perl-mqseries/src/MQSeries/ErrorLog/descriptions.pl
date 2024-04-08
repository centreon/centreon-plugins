#
# descriptions.pl - Include file for MQSeries::ErrorLog::Parser
#                   that describes all known error types.
#
# (c) 2000-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# $Id: descriptions.pl,v 38.3 2012/09/26 16:15:13 jettisu Exp $
#

#
# For more info on all these messages, see the
# IBM MQSeries Messages manual, GC33-1876.
#

package MQSeries::ErrorLog::Parser;

use strict;


#
# Define a set of helper-patterns
#
my $broker_patt = '(?:message|Publish\/Subscribe) broker';
my $channel_patt = '[\w\.\%\/]+';
my $code_patt = '-?\d+';
my $exit_patt = '[\w\.\/\-\(\)]+';
my $hex_patt = '[A-F\d]+';
my $hostname_patt = '\w[\w\-\.]*';
my $ip_patt = '\d+\.\d+\.\d+\.\d+';
my $host_patt = "$hostname_patt \\($ip_patt\\) \\(\\d+\\)|$hostname_patt \\($ip_patt\\)|$ip_patt \\(\\d+\\)|$ip_patt";
my $logfile_patt = 'S\d+\.LOG';
my $pid_patt = '\d+';
my $product_patt = '(?:MQSeries|WebSphere MQ)';
my $qmgr_patt = '[\w\.!%\/]+';
my $qname_patt = '[\w\.\%\/]+';
my $rc_patt = '\d+';
my $reason_patt = '\d+: \(.*?\)|\d+:\w+|\d+\w+|\d+:?';
my $resourcemgr_patt = '\w+\s+\w+';
my $seqno_patt = '\d+';
my $server_patt = '[A-Z]+';
my $xa_operation_patt = 'xa_\w+';

#
# NOTE: Keep this table in alphabetical order for ease of maintenance
#
our $error_table =
  {

   #
   # Messages AMQ3500-3999 are MQSeries for Windows.
   # So far, we don't support them.
   #

   #
   # Messages AMQ4000-4999 are MQSeries for Windows NT
   # user-interface messages.  We don't support these.
   #

   #
   # Messages AMQ5000-5999 are Installable Services Messages
   #

   'AMQ5008' => [ "An essential $product_patt process ($pid_patt) (?:\\(.*\\)|) cannot be found and is assumed to be terminated\\.",
                  "Pid" ],

   'AMQ5009' => [ "$product_patt agent process ($pid_patt) has terminated unexpectedly\\.",
                  "Pid" ],

   'AMQ5022' => [ "The Channel Initiator has started\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Pid" ],

   'AMQ5023' => [ "The Channel Initiator has ended\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Pid" ],

   'AMQ5024' => [ "The Command Server has started\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Pid" ],

   'AMQ5025' => [ "The Command Server has ended\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Pid" ],

   'AMQ5026' => [ "The Listener '($server_patt)' has started\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Listener", "Pid" ],

   'AMQ5027' => [ "The Listener '($server_patt)' has ended\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Listener", "Pid" ],

   'AMQ5028' => [ "The Server '($server_patt)' has started\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Server", "Pid" ],

   'AMQ5029' => [ "The Server '($server_patt)' has ended\\. ProcessId\\s?\\(($pid_patt)\\)\\.",
                  "Server", "Pid" ],

   'AMQ5032' => [ "Error (.*?) accessing file '(.*?)'\\.",
                  "Error", "Filename" ],

   'AMQ5037' => [ "The Queue Manager task (.*?) has started\\.",
                  "Task" ],

   'AMQ5041' => [ "The Queue Manager task (.*?) has ended\\.",
                  "Task" ],

   'AMQ5042' => [ "The request to start the process (.*?) failed\\.",
                  "Process" ],

   'AMQ5511' => [ "Installable service component '(.*?)' returned 'CompCode = ($rc_patt), Reason = ($rc_patt)'\\.",
                  "Component", "Code", "Reason" ],

   'AMQ5520' => [ "The system could not load the module '(.*?)' for the installable service '(.*?)' component '(.*?)'\\. The system return code was ($rc_patt)\\. The Queue Manager is continuing without this component\\.",
                  "Module", "Service", "Component", "Code" ],

   'AMQ5806' => [ "$product_patt $broker_patt started for queue manager ($qmgr_patt)\\.",
                  "QMgr" ],

   'AMQ5807' => [ "$product_patt $broker_patt for queue manager ($qmgr_patt) ended\\.",
                  "QMgr" ],

   'AMQ5817' => [ "An invalid stream queue \\(($qname_patt)\\s*\\) has been detected by the $product_patt $broker_patt\\.",
                  "Stream" ],

   # NOTE: Have encountered this guy without an actual broker name...
   'AMQ5818' => [ "Unable to open $product_patt $broker_patt stream queue \\((.*?)\\s*\\) for reason (\\d+,\\d+)\." ],

   'AMQ5819' => [ "$product_patt $broker_patt stream \\(($qname_patt)\\s*\\) has ended abnormally for reason ($reason_patt)\\.",
                  "Stream", "Reason" ],

   'AMQ5820' => [ "$product_patt $broker_patt stream \\(\\s*($qname_patt)\\s*\\) restarted.",
                  "Stream" ],

   'AMQ5821' => [ "$product_patt $broker_patt unable to contact parent broker \\(($qmgr_patt) \\) for reason ($reason_patt)\\.",
                  "Broker", "Reason" ],

   'AMQ5822' => [ "$product_patt $broker_patt failed to register as a child of broker \\(($qmgr_patt) \\) for reason ($reason_patt)\\. .* The problem is likely to be caused by the parent broker not yet existing, or a problem with the ($qname_patt) queue at the parent broker\\.",
                  "Broker", "Reason", "QName" ],

   'AMQ5826' => [ "$product_patt $broker_patt failed to propagate subscription to stream \\(($qname_patt) \\) at broker \\(($qmgr_patt) \\)\\. Reason codes ($reason_patt) and ($reason_patt)\\.",
                  "Stream", "Broker", "Reason1", "Reason2" ],

   'AMQ5832' => [ "$product_patt $broker_patt failed to publish configuration information on ($qname_patt)\\.",
                  "QName" ],

   'AMQ5833' => [ "A loop has been detected in the $product_patt $broker_patt hierarchy\\." ],

   'AMQ5834' => [ "Conflicting queue manager names in the $product_patt $broker_patt hierarchy\\..* The names of the queue managers \\(($qmgr_patt)\\s*\\) and \\(($qmgr_patt)\\s*\\) in the $product_patt $broker_patt hierarchy both start with the same 12 characters\\." ],

   'AMQ5838' => [ "$product_patt $broker_patt cannot be deleted as child \\(($qmgr_patt)\\s*\\) is still registered\\.",
                  "Child" ],

   # FIXME: So far, encountered this guy without an actual broker name...
   'AMQ5839' => [ "$product_patt $broker_patt received (?:an )?unexpected inter-broker communication" ],

   'AMQ5840' => [ "$product_patt $broker_patt (?unable to delete|failed to delete the) queue \\(($qname_patt)\\s*\\) for reason ($reason_patt)\\.",
                  "QName", "Reason" ],

   'AMQ5841' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) deleted.",
                  "Broker" ],

   'AMQ5842' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) cannot be deleted for reason '($reason_patt)'\\.",
                  "Broker", "Reason" ],

   'AMQ5843' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) cannot be started as it is partially deleted\\.",
                  "Broker" ],

   # NOTE: This guy often has blank relation names, cannot be parsed reliably
   'AMQ5844' => [ "$product_patt $broker_patt relation \\(.*\\) is unknown to broker \\(($qmgr_patt)\\)\\.",
                  "Broker" ],

   'AMQ5847' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) has removed knowledge of relation \\(($qmgr_patt)\\)\\.",
                  "Broker", "Relation" ],

   # FIXME: So far, enountered this guy without an actual relation name...
   'AMQ5848' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) has failed to remove references to relation \\(\\) for reason '($reason_patt)'\\.",
                  "Broker", "Reason" ],

   'AMQ5849' => [ "$product_patt $broker_patt \\(($qmgr_patt) \\) may not change parent from \\(($qmgr_patt) \\) to \\(($qmgr_patt) \\)\\.",
                  "Broker", "OldParent", "NewParent" ],

   # NOTE: The 'related broker' can be a queue manager name or
   #       'unknown relation', so be generous in accepting that pattern
   'AMQ5852' => [ "$product_patt $broker_patt failed to propagate delete publication command for stream \\(($qname_patt)\\s*\\) to related broker \\(.*?\\s*\\) for reason ($reason_patt)\\.",
                  "Stream", "Related", "Reason" ],

   'AMQ5855' => [ "$product_patt $broker_patt \\(($qmgr_patt)\\) (?:but the broker has )?ended for reason '($reason_patt)'\\.",
                  "Broker", "Reason" ],

   'AMQ5856' => [ "Broker publish command message cannot be processed\\. Reason code ($reason_patt)\\..* The $product_patt broker failed to process a publish message for stream \\(($qname_patt)\\s*\\)\\.",
                  "Reason", "Stream" ],

   'AMQ5857' => [ "Broker control command message cannot be processed\\. Reason code ($reason_patt)\\..*The $product_patt broker failed to process a command message on the ($qname_patt)\\.",
                  "Reason", "Stream" ],

   'AMQ5864' => [ "Broker reply message could not be sent to queue \\(($qname_patt)\\s*\\) at queue manager \\(($qmgr_patt)\\s*\\) for reason ($reason_patt)\\.",
                  "Stream", "QMgr", "Reason" ],

   'AMQ5866' => [ "Broker command message has been discarded\\. Reason code ($reason_patt)\\.",
                  "Reason" ],

   'AMQ5867' => [ " $product_patt $broker_patt stream \\(($qname_patt)\\s*\\) has ended abnormally for reason ($reason_patt)\\.",
                  "Stream", "Reason" ],

   'AMQ5869' => [ "$product_patt $broker_patt is checkpointing registrations\\..*registrations of stream \\(($qname_patt)\\s*\\)\\.",
                  "Stream" ],

   # NOTE: The queue-manager name is missing here
   'AMQ5876' => [ "A parent conflict has been detected in the $product_patt $broker_patt hierarchy\\." ],

   'AMQ5878' => [ "$product_patt $broker_patt recovery failure detected\\." ],

   # NOTE: The 'Stream' field here may look like 'uncreated stream',
   #       hence not match the qname_pattern normally used.
   'AMQ5882' => [ "The $product_patt $broker_patt has written a message to the dead-letter queue \\(($qname_patt)\\s*\\) for reason '($reason_patt)'.*for stream \\((.*?)\\s*\\)",
                   "DeadletterQueue", "Reason", "Stream" ],

   #
   # Messages AMQ6000-6999 are Common Services Messages
   # Many of these (all?) should have a corresponding entry in the FDC logs.
   #
   'AMQ6004' => [ "An error occurred during $product_patt initialization or ending\\." ],

   'AMQ6026' => [ "A resource shortage prevented the creation of an $product_patt process\\." ],

   'AMQ6035' => [ "$product_patt failed, no storage available\\." ],

   'AMQ6037' => [ "$product_patt was unable to obtain enough storage\\." ],

   'AMQ6047' => [ "$product_patt is unable to convert string data tagged in CCSID \\d+ to data in CCSID \\d+\\." ],

   'AMQ6048' => [ "$product_patt is unable to convert string data due to a DBCS error\." ],

   'AMQ6050' => [ "$product_patt is unable to convert string data in CCSID \\d+ to data in CCSID \\d+\\." ],

   'AMQ6053' => [ "$product_patt is unable to convert string data in CCSID \\d+ to data in CCSID -?\\d+\\." ],

   'AMQ6090' => [ "$product_patt was unable to display an error message" ],

   'AMQ6091' => [ "An internal $product_patt error has occurred\\." ],

   'AMQ6109' => [ "An internal $product_patt error has occurred\\." ],

   'AMQ6110' => [ "An internal $product_patt error has occurred\\." ],

   'AMQ6118' => [ "An internal $product_patt error has occurred" ],

   'AMQ6119' => [ "An internal $product_patt error has occurred" ],

   'AMQ6122' => [ "An internal $product_patt error has occurred\\." ],

   'AMQ6125' => [ "An internal error has occurred with identifier ($hex_patt)\\.",
                  "Id" ],

   'AMQ6150' => [ "$product_patt semaphore is busy\\." ],

   'AMQ6162' => [ "An error has occurred reading an INI file\\." ],

   'AMQ6165' => [ "Access to the MQS.INI file or a queue manager QM.INI file is denied\\." ],

   'AMQ6166' => [ "The MQS.INI file or a queue manager QM.INI file is missing\\." ],

   'AMQ6174' => [ "The library ($exit_patt) was not found\\.",
                  "Exit" ],

   'AMQ6175' => [ "The system could not dynamically load the library ($exit_patt)\. The error message",
                  "Exit" ],

   'AMQ6183' => [ "The failing process is process ($pid_patt)\\.",
                  "Pid" ],

   'AMQ6188' => [ "The system could not dynamically load the shared library '($exit_patt)' due to a problem with the library",
                  "Exit" ],

   'AMQ6184' => [ "An internal $product_patt error has occurred on queue manager ($qmgr_patt)\\..*The failing process is process ($pid_patt)\\.",
                  "QMgr", "Pid" ],

   'AMQ6209' => [ "An unexpected asynchronous signal \\((\\d+)(?: : [A-Z\\d]+)?\\) has been received and ignored\\..* Process ($pid_patt) received an unexpected asynchronous signal and ignored it\\.",
                  "Signal", "Pid" ],

   'AMQ6254' => [ "The system could not dynamically load the shared library '(\\S+)', library '(\\S+)' has been used instead.",
                  "BadLibrary", "GoodLibrary" ],

   'AMQ6255' => [ "The system could not dynamically load the shared library '(\\S+)'. The queue manager will continue without this module.",
                  "BadLibrary" ],

   # NOTE: So far, encountered this error without a location.
   'AMQ6708' => [ "A disk full condition was encountered when formatting a new log file in location (.*?)\\.",
                  "Location" ],

   'AMQ6709' => [ "The log for the Queue manager is full\\." ],

   #
   # Messages AMQ7000-7999 are MQSeries Product Messages
   #

   'AMQ7006' => [ "The (\\S+) stanza starting on line (\\d+) of configuration file (\\S+) is missing the required (\\S+) attribute\\.",
                  "Stanza", "Line", "File", "Attribute" ],

   # AMQ7030 changed between MQ 5.0/5.1 and 5.2
   'AMQ7030' => [ "(?:Request to quiesce the queue manager accepted\\.|Quiesce request accepted\\.)" ],

   'AMQ7075' => [ "Unknown attribute (\\S+) on line (\\d+) of ini file (\\S+)\\.",
                  "Attribute", "Line", "File" ],

   'AMQ7076' => [ "Line (\\d+) of the configuration file (\\S+) contained value (.*?)\\s*that is not valid for the attribute (\\S+)\\.",
                  "Line", "File", "Value", "Attribute" ],

   # NOTE: Not sure whether the mode is variable or not
   'AMQ7126' => [ "This copy of $product_patt is now running in Production mode\\." ],

   # NOTE: Not sure whether the filename and dirname are variable or not
   'AMQ7153' => [ "A Production, Beta or Trial Period license could not be installed for this copy of $product_patt\\. This is because the 'nodelock' file in the 'qmgrs/\@SYSTEM' directory could not be created or updated\\." ],

   'AMQ7159' => [ "A FASTPATH application has ended unexpectedly" ],

   'AMQ7191' => [ "There are (\\d+) days left in the beta test period for this copy of $product_patt\\.",
                  "Days" ],

   'AMQ7199' => [ "The purchased processor allowance for this installation has been set to (-?\\d+) using the MQ setmqcap command\\.",
                  "Capacity" ],

   'AMQ7203' => [ "The purchased processor allowance for this installation has not been set\\." ],

   'AMQ7214' => [ "The module '(\\S+)' for A[Pp][Ii] Exit '(\\w+)' could not be loaded for reason (\\S+)\\.",
                  "Module", "Exit", "Reason" ],

   'AMQ7216' => [ "The A[Pp][Ii] Exit '(\\w+)' function '(\\w+)' in the module '(\\S+)' returned CompCode ($code_patt) and ReasonCode ($rc_patt)",

                  "Exit", "Function", "Module", "Code", "Reason" ],

   # NOTE: This was found with empty strings, rather useless...
   'AMQ7217' => [ "The A[Pp][Ii] Exit '' module '' function'' returned a response code '($code_patt)' that is not valid in the ExitResponse field of the Api Exit parameters \\(MQAXP\\)\\.",
                  "Reason" ],

   'AMQ7310' => [ "The attempt to put a report message on queue ($qname_patt) on queue manager ($qmgr_patt) failed with reason code ($reason_patt)\\. The message will be put on the dead-letter queue\\.",
                  "QName", "QMgr", "Reason" ],

   'AMQ7229' => [ "(\\d+) log records accessed on queue manager '($qmgr_patt)' during the log replay phase\\.",
		  "LogRecords", "QMgr" ],

   'AMQ7230' => [ "Log replay for queue manager '($qmgr_patt)' complete\\.",
		  "QMgr" ],

   'AMQ7231' => [ "(\\d+) log records accessed on queue manager '($qmgr_patt)' during the recovery phase\\.",
		  "LogRecords", "QMgr" ],

   'AMQ7232' => [ "Transaction manager state recovered for queue manager '($qmgr_patt)'\\.",
		  "QMgr" ],

   'AMQ7233' => [ "(\\d+) out of (\\d+) in-flight transactions resolved for queue manager '($qmgr_patt)'\\.",
		  "Resolved", "Total", "QMgr" ],

   'AMQ7463' => [ "The log for queue manager ($qmgr_patt) is full\\.",
                  "QMgr" ],

   'AMQ7466' => [ "The log for queue manager ($qmgr_patt) is too small to support the current data rate\\.",
                  "QMgr" ],

   'AMQ7467' => [ "The oldest log file required to start queue manager ($qmgr_patt) is ($logfile_patt)\\.",
                  "QMgr", "LogFile" ],

   'AMQ7468' => [ "The oldest log file required to perform media recovery of queue manager ($qmgr_patt) is ($logfile_patt)\\.",
                  "QMgr", "LogFile" ],

   'AMQ7469' => [ "Transactions rolled back to release log space\\." ],

   'AMQ7472' => [ "Object ($qname_patt), type (\\w+) damaged\\.",
                  "Object", "Type" ],

   'AMQ7604' => [ "The XA resource manager '($resourcemgr_patt)' was not available when called for ($xa_operation_patt)\\.",
                  "ResourceMgr", "Operation" ],

   'AMQ7605' => [ "The XA resource manager ($resourcemgr_patt) has returned an unexpected return code ($code_patt), when called for ($xa_operation_patt)\\.",
                  "ResourceMgr", "Code", "Operation" ],

   'AMQ7622' => [ "$product_patt could not load the XA switch load file for resource manager '($resourcemgr_patt)'\\..*?An error has occurred loading XA switch file (.*?)\\. If the error",
                  "ResourceMgr", "File" ],

   'AMQ7624' => [ "An exception occurred during an ($xa_operation_patt) call to XA resource manager '($resourcemgr_patt)'\\.",
                  "Operation", "ResourceMgr" ],

   'AMQ7625' => [ "The XA resource manager '($resourcemgr_patt)' has become available again\\.",
                  "ResourceMgr" ],

   'AMQ7924' => [ "Bad length in the PCF header \\(length = \\d+\\)\\." ],

   'AMQ7925' => [ "Message version (\\d+) is not supported",
                  "MessageVersion" ],

   # FIXME: If encountered again, determine CCSID pattern
   'AMQ7935' => [ "Bad CCSID in message header \\(CCSID = 0\\)" ],

   #
   # Messages AMQ8000-8999 are MQSeries Administration Messages
   #

   'AMQ8003' => [ "$product_patt queue manager '?($qmgr_patt)'? started\\.",
                  "QMgr" ],

   'AMQ8004' => [ "$product_patt queue manager '?($qmgr_patt)'? ended\\.",
                  "QMgr" ],

   'AMQ8024' => [ "$product_patt channel initiator started\\." ],

   # FIXME: Are the number of objects of interest?
   'AMQ8048' => [ "Default objects statistics :" ],

   'AMQ8049' => [ "While creating or replacing the default object ($qname_patt) for $product_patt queue manager ($qmgr_patt) an error occurred\\. The error was due to improper authorization\\. The reason code is ($reason_patt)\\.",
                  "ObjectName", "QMgr", "Reason" ],

   'AMQ8053' => [ "While creating or replacing the default object ($qname_patt) for $product_patt queue manager ($qmgr_patt) an error occurred\\. The error was due to a broken connection. The reason code is ($reason_patt)\\.",
                  "ObjectName", "QMgr", "Reason" ],

   'AMQ8059' => [ "While creating or replacing the default object ($qname_patt) for $product_patt queue manager ($qmgr_patt) an error occurred\\. The error was due to an unexpected error, error code ($reason_patt) ",
                  "ObjectName", "QMgr", "Reason" ],

   'AMQ8101' => [ "An unexpected reason code with hexadecimal value ($reason_patt) was received from the $product_patt queue manager during command processing\\.",
                  "Reason" ],

   'AMQ8214' => [ "CONNAME parameter required with channel types SDR, RQSTR, CLNTCONN, CLUSSDR and CLUSRCVR\\." ],

   'AMQ8226' => [ "$product_patt channel ($channel_patt) cannot be created",
                  "Channel" ],


   'AMQ8424' => [ "Error detected in a name keyword\\." ],

   'AMQ8504' => [ "An MQINQ request by the command server, for the $product_patt queue ($qname_patt), failed with reason code ($reason_patt)\\.",
                  "QName", "Reason" ],

   'AMQ8506' => [ "An MQGET request by the command server, for the $product_patt queue ($qname_patt), failed with reason code ($reason_patt)\\.",
                  "QName", "Reason" ],

   'AMQ8507' => [ "failed with reason code ($reason_patt)\\. The MQDLH reason code was ($reason_patt)\\.",
                  "Mqput1Code", "MqdlhCode" ],

   'AMQ8508' => [ "A request by the command server to delete a queue manager object list failed with return code ($reason_patt)\\.",
		  "Reason" ],

   'AMQ8509' => [ "Command server MQCLOSE reply-to queue failed with reason code ($reason_patt)\\.",
		  "Reason" ],

   'AMQ8708' => [ "Dead-letter queue handler started to process INPUTQ\\(($qname_patt)\\)\\.",
		  "QName" ],

   #
   # Messages AMQ9000-9999 are Remote Messages
   #
   'AMQ9001' => [  "Channel '($channel_patt)' ended normally",
                   "Channel" ],

   'AMQ9002' => [  "Channel '($channel_patt)' is starting",
                   "Channel" ],

   'AMQ9184' => [ "The user exit '(\\S+)' returned an address '0' for the exit buffer that is not valid",
                  "Exit" ],

   # FIXME: Nasty, we also encounter this message in a completely
   #        different format.
   'AMQ9202' => [  "Remote host '($host_patt)' not available.*from TCP/IP is ($rc_patt) \\(X'",
                  'Host', 'IPCode' ],

   # FIXME: Encountered this without a host name, check...
   'AMQ9203' => [ "A configuration error for TCP/IP occurred" ],

   'AMQ9206' => [  "over TCP/IP to '?($host_patt)'?.*from (?:the )?TCP/IP(?:\\(write\\) call was| is) ($rc_patt) X\\('",
                  'Host', 'IPCode' ],

   'AMQ9207' => [ "Incorrect data format received from host '($host_patt)' over TCP/IP",
                  'Host' ],

   'AMQ9208' => [ "receiving data from '?($host_patt)'?.*return code (?:from the TCP/IP \\((.*?)\\) call was )?($rc_patt) \\(X'",
                  'Host', 'Operation', 'IPCode' ],

   'AMQ9209' => [ "An error occurred receiving data from '($host_patt)' over TCP/IP\\.",
                  'Host' ],

   'AMQ9213' => [ "The return code from the (.*?) call was ($rc_patt) \\(X'",
                  "Operation", "IPCode" ],

   'AMQ9218' => [ "The TCP/IP listener program could not bind to port number (\\d+)\\.",
                  "Port" ],

   'AMQ9220' => [ "The attempt to load the TCP/IP library or procedure '(.*?)' failed with error code ($rc_patt)\\.",
                  "Library", "Reason" ],

   'AMQ9221' => [ " The specified value of '(.*?)' was not recognized as one of the protocols supported\\.",
                  "Protocol" ],

   'AMQ9228' => [ "The TCP/IP responder program could not be started\\." ],

   'AMQ9243' => [ "The queue manager '($qmgr_patt)' does not exist\\.",
                  "QMgr" ],

   'AMQ9244' => [ "The default queue manager does not exist\\." ],

   'AMQ9245' => [ "$product_patt was unable to obtain the account details for MCA user ID '(\\w+)'\\. This user ID was the MCA user ID for channel '($channel_patt)' on queue manager '($qmgr_patt)' and may have been defined in the channel definition, or supplied either by a channel exit or by a client\\.",
                  "Userid", "Channel", "QMgr" ],

   'AMQ9255' => [ "Listener already running\\." ],

   'AMQ9409' => [ "The repository manager ended abnormally\\." ],

   'AMQ9410' => [ "The repository manager started successfully\\." ],

   'AMQ9411' => [ "The repository manager (?:ended|stopped) normally\\." ],
   'AMQ9418' => [ "Only one repository for cluster (\\S+)\\.",
                  "Cluster" ],

   'AMQ9420' => [ "No repositories for cluster (\\S+)\\.",
                  "Cluster" ],

   'AMQ9422' => [ "Repository manager error, RC=(\\d+)",
                  "Reason" ],

   'AMQ9431' => [ "CLUSSDR channel ($channel_patt) is altered so that it can no longer be used to access queue manager \\S+ within cluster (\\S+)\\.",
                  "Channel", "Cluster" ],

   'AMQ9437' => [ "Unable to commit repository changes\\." ],

   'AMQ9442' => [ "The Refresh Cluster\\((\\S+)\\) command caused \\d+ objects to be refreshed and \\d+ objects to be republished\\.",
                  "Cluster" ],

   'AMQ9447' => [ "Following an error, the repository manager tried to backout some updates to the repository, but was unsuccessful\\. The repository manager terminates\\." ],

   'AMQ9457' => [ "Repository available, cluster (\\S+), channel ($channel_patt), sender (\\S+)\\.",
                  "Cluster", "Channel", "Sender" ],

   'AMQ9496' => [ "Channel program '($channel_patt)' was ended because the channel exit at the remote end requested it\\.",
                  "Channel" ],

   'AMQ9502' => [ "Type of channel not suitable for action requested\\..*The operation requested cannot be performed on channel '($channel_patt)'\\.",
                  "Channel" ],


   # NOTE: At time, this gets invalid channel names (eg, from bad clients),
   #       so we use a non-standard pattern
   'AMQ9503' => [ "Channel '(.*?)' between this machine and the remote machine could not be established",
                  "Channel" ],

   # NOTE: At time, this gets invalid channel names (eg, from bad clients),
   #       so we use a non-standard pattern
   'AMQ9504' => [ "A protocol error was detected for channel '(.*?)'\\.",
                  "Channel" ],

   'AMQ9506' => [ "Channel '($channel_patt)' has ended because the remote queue manager did not accept the last batch of messages.",
                  "Channel" ],

   'AMQ9507' => [ "Channel '($channel_patt)' is currently in-doubt\\. .* The requested operation cannot complete because the channel is in-doubt with host '(.*?)'\\.",
                  "Channel", "Host" ],

   # NOTE: At times, this gets empty queue manager names (probably
   #       a client error), so we use a non-standard pattern
   'AMQ9508' => [ "The connection attempt to queue manager '(.*?)' failed with reason code ($reason_patt)\\.",
                  "QMgr", "Reason" ],

   'AMQ9509' => [ "The attempt to open either the queue or queue manager object '(.*?)' on queue manager '($qmgr_patt)' failed with reason code ($reason_patt)\\.",
                  "Object", "QMgr", "Reason" ],

   'AMQ9510' => [ "The attempt to get messages from queue '($qname_patt)' on queue manager '($qmgr_patt)' failed with reason code ($reason_patt)\\.",
                  "QName", "QMgr", "Reason" ],

   'AMQ9511' => [ "The attempt to put messages to queue '($qname_patt)' on queue manager '($qmgr_patt)' failed with reason code ($reason_patt)\\.",
                  "QName", "QMgr", "Reason" ],

   'AMQ9514' => [ "Channel '($channel_patt)' is in use",
                  "Channel" ],

   'AMQ9516' => [ "The filesystem returned error code ($code_patt) for file '(.*?)'\\.",
                  "Code", "Filename" ],

   'AMQ9518' => [ "File '($exit_patt)' not found",
                  "Exit" ],

   # NOTE: At times, this gets invalid channel names (eg, from bad clients),
   #       so we use a non-standard pattern
   'AMQ9519' => [ "The requested operation failed because the program could not find a definition of channel '(.*?)'\\.",
                   "Channel" ],

   'AMQ9520' => [ "There is no definition of channel '($channel_patt)' at the remote location\\.",
                   "Channel" ],

   'AMQ9522' => [ "The program could not access the channel status table\\." ],

   'AMQ9523' => [ "During communications through channel '($channel_patt)', the remote queue manager channel program detected a protocol error\\.",
                  "Channel" ],

   'AMQ9524' => [ "Channel '($channel_patt)' cannot start because the remote queue manager is not currently available\\.",
                  "Channel" ],

   'AMQ9525' => [ "Channel '($channel_patt)' is closing",
                  "Channel" ],

   'AMQ9526' => [ "error for channel '($channel_patt)'.*A message with sequence number ($seqno_patt) has been sent when sequence number ($seqno_patt) was",
                  "Channel", "sent_seqno", "expected_seqno" ],

   'AMQ9527' => [ "Cannot send message through channel '($channel_patt)'\\.",
                  "Channel" ],

   'AMQ9528' => [ "User requested closure of channel '($channel_patt)'\\.",
                  "Channel" ],

   'AMQ9530' => [ "The attempt to inquire the attributes of queue '($qname_patt)' on queue manager '($qmgr_patt)' failed with reason code ($reason_patt)\\.",
                  "QName", "QMgr", "Reason" ],

   'AMQ9531' => [ "Queue '($qname_patt)' identified as a transmission queue in the channel definition '($channel_patt)' is not a transmission queue\\.",
                  "QName", "Channel" ],

   'AMQ9533' => [ "Channel '($channel_patt)' is not currently active\\.",
                  "Channel" ],

   'AMQ9534' => [ "Channel '($channel_patt)' is currently",
                  "Channel" ],

   'AMQ9535' => [ "Channel program '($channel_patt)' ended because user exit '(.*?)' is not valid\\.",
                  "Channel", "Exit" ],

   'AMQ9536' => [ "Channel program '($channel_patt)' was ended by exit '($exit_patt)'",
                  "Channel", "Exit" ],

   'AMQ9540' => [ "The program ended because return code ($code_patt) was received when an attempt was made to commit change to the resource managers. The commit ID was '(.*?)'\\.",
                  "Reason", "CommitId" ],

   'AMQ9542' => [ "Queue manager is ending\\." ],

   'AMQ9544' => [ "During the processing of channel '($channel_patt)' one or more.*The program identifier \\(PID\\) of the processing program was '($pid_patt)'\\.",
                  "Channel", "Pid" ],

   'AMQ9545' => [ "Channel '($channel_patt)' closed because",
                  "Channel" ],

   'AMQ9546' => [ "The program has ended because return code ($code_patt) was returned from an internal function\\.",
                  "Code" ],

   'AMQ9547' => [ "The operation requested cannot be performed because channel '($channel_patt)' on the remote machine is not of a suitable type\\.",
                  "Channel" ],

   'AMQ9549' => [ "Transmission Queue '($qname_patt)' inhibited for MQGET\\.",
                  "QName" ],

   'AMQ9553' => [ "The function (.*?) attempted is not currently supported on this platform\\.",
                  "Function" ],

   'AMQ9558' => [ "The channel program ended because the channel '($channel_patt)' is not currently available on the remote system\\.",
                  "Channel" ],

   'AMQ9588' => [ "Program cannot update queue manager object\\..*The attempt to update object '(.*?)' on queue manager '($qmgr_patt)' failed with reason code ($reason_patt)\\.",
                  "Object", "QMgr", "Reason" ],

   # NOTE: Found this with an empty user id
   'AMQ9599' => [ "The attempt to open either the queue or queue manager object '($qname_patt)' on queue manager '($qmgr_patt)' by user '.*?' failed with reason code ($reason_patt)\\.",
                  "QName", "QMgr", "Reason" ],

   # NOTE: At times, this gets invalid channel names (eg, from bad clients),
   #       so we use a non-standard pattern
   'AMQ9999' => [ "Channel program '(.*?)' ended abnormally\\.",
                  "Channel" ],

  };

1;                              # End on a positive note
