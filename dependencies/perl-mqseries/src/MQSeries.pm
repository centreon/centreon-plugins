#
# $Id: MQSeries.pm,v 33.11 2012/09/26 16:10:13 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#
# This is intended to be a wrapper routine to include either the
# server or client library, based on the machine on which the code is
# running.
#

package MQSeries;

use 5.008;

use strict;
use Carp;

require Exporter;
require DynaLoader;

use MQSeries::Config::Machine;

our @ISA = qw(Exporter DynaLoader);
our $VERSION = '1.34';
our (@EXPORT, %EXPORT_TAGS);

BEGIN {
    my $server;
    if (exists $INC{"MQServer/MQSeries.pm"}) {
        $server = 1;
    } elsif (exists $INC{"MQClient/MQSeries.pm"}) {
        $server = 0;
    } else {
        if ( $^O =~ /Win32/i ) { # Windows: check systemdir
            no strict;

            require "Win32/TieRegistry.pm";
            import Win32::TieRegistry;

            $Registry->Delimiter('/');

            my $CurrentVersion = "LMachine/SOFTWARE/IBM/MQSeries/CurrentVersion/";
            $server = 0;
            my @sdir = ( $Registry->{"$CurrentVersion/FilePath"},
                         $Registry->{"$CurrentVersion/WorkPath"},
                         "C:/Mqm");
            foreach my $try (@sdir) {
                my $systemdir = $try . q{/qmgrs/@SYSTEM};
                if (-d $systemdir) {
                    $server = 1;
                    last;
                }
            }
        } else {                # Unix: check systemdir and mqs.ini
            eval {
                my $mqMachine = MQSeries::Config::Machine->new();
                if (keys %{$mqMachine->localqmgrs}) { # If any local qmgrs...
                    $server = 1;
                } else {
                    $server = 0;
                }
            };
            unless (defined $server) {
                my $systemdir = q{/var/mqm/qmgrs/@SYSTEM};
                if (-d $systemdir) {
                    $server = 1;
                } else {
                    $server = 0;
                }
            }
        }
    }

    if ($server) {
        require "MQServer/MQSeries.pm";
        import MQServer::MQSeries;
        *EXPORT = *MQServer::MQSeries::EXPORT;
        *EXPORT_TAGS = *MQServer::MQSeries::EXPORT_TAGS;
        $MQSeries::Mode = "Server";
    } else {
        require "MQClient/MQSeries.pm";
        import MQClient::MQSeries;
        *EXPORT = *MQClient::MQSeries::EXPORT;
        *EXPORT_TAGS = *MQClient::MQSeries::EXPORT_TAGS;
        $MQSeries::Mode = "Client";
    }
}


1;

__END__

=head1 NAME

MQSeries - Perl extension for MQSeries support

=head1 SYNOPSIS

There are two interfaces provided by the MQSeries modules.  The first
is a straight forward mapping to all of the individual MQI calls, and
the second is a value-added, OO interface, which provides a simpler
interface to a subset of the full MQI functionality.

The straight MQI mapping is:

  use MQSeries;

  $Hconn = MQCONN($Name,$CompCode,$Reason);
  MQDISC($Hconn,$CompCode,$Reason);

  $Hobj = MQOPEN($Hconn,$ObjDesc,$Options,$CompCode,$Reason);
  MQCLOSE($Hconn,$Hobj,$Options,$CompCode,$Reason);

  MQBACK($Hconn,$CompCode,$Reason);
  MQCMIT($Hconn,$CompCode,$Reason);

  $Buffer = MQGET($Hconn,$Hobj,$MsgDesc,$GetMsgOpts,$BufferLength,$CompCode,$Reason);
  MQPUT($Hconn,$Hobj,$MsgDesc,$PutMsgOpts,$Msg,$CompCode,$Reason);
  MQPUT1($Hconn,$ObjDesc,$MsgDesc,$PutMsgOpts,$Msg,$CompCode,$Reason);

  ($Attr1,...) = MQINQ($Hconn,$Hobj,$CompCode,$Reason,$Selector1,...);
  MQSET($Hconn,$Hobj,$CompCode,$Reason,$Selector1,$Attr1,...);

If the perl5 API is compiled with the version 5 headers and libraries,
then the following MQI calls are also available:

  MQBEGIN($Hconn,$BeginOpts,$CompCode,$Reason);
  $Hconn = MQCONNX($Name,$ConnectOpts,$CompCode,$Reason);

There are also some additional utility routines provided which
are not part of the MQI, but specific to the perl5 API:

  ($ReasonText,$ReasonMacro) = MQReasonToStrings($Reason);
  ($ReasonText) = MQReasonToText($Reason);
  ($ReasonMacro) = MQReasonToMacro($Reason);

The OO interface is provided in several optional modules.  Three of
these make up the core OO interface:

  MQSeries::QueueManager
  MQSeries::Queue
  MQSeries::Message

There are several subclasses of MQSeries::Message which handle special
message formats:

  MQSeries::Message::Storable
  MQSeries::Message::Event
  MQSeries::Message::PCF
  MQSeries::Message::DeadLetter

There is also a module which provides an interface to the command
server PCF messages for MQSeries administration:

  MQSeries::Command

There are two sets of classes that help you follow (tail C<-f> style) and
parse the two kinds of log-files written by MQSeries: the FDC files
and the error-logs.  These classes allow you to write a log monitoring
daemon that feeds into syslog or your system management tools.

  MQSeries::ErrorLog::Tail
  MQSeries::ErrorLog::Parser
  MQSeries::ErrorLog::Entry
  MQSeries::FDC::Tail
  MQSeries::FDC::Parser
  MQSeries::FDC::Entry

There is a set of classes that parses configuration and authority
files (/var/mqm/mqs.ini, /var/mqm/qmgrs/*/qm.ini,
/var/mqm/qmgrs/*/auth/*/*).

  MQSeries::Config::Authority
  MQSeries::Config::Machine
  MQSeries::Config::QMgr

Some internal helper functions are stored in the module:

  MQSeries::Utils

See the documentation for each of these individual modules for more
information.

=head1 DESCRIPTION

This module provides a perl language interface to MQSeries
functions. It uses the standard MQSeries interface except where a perl
convention is required or just more useful.

Where data structures are required, this interface uses a hash
reference. The keys in the hash are structure element names. If an
element is not specified in the hash, a default value will be
used. Output elements are updated in the hash as necessary.

=head2 Basic Module Usage

By default, this module will export all functions and MQSeries
constants into the caller's namespace.  This may bloat that module's
memory usage by some 400 Kbyte.  For that reason, you can also request
to only export the functions.  To use macros, you would then either
import them individually or refer to them using the MQSeries:: prefix.

This leads to the following C<use> statements:

=over 4

=item use MQSeries;

The default: export functions and constants.

=item use MQSeries qw(:functions);

Export just the functions.  This should be the way most modules
import MQSeries, as it saves 400Kbyte per module importing MQSeries.
In order to use a macro, e.g. C<MQCC_FAILED>, you could either add it to the
list on the C<use> statement, or refer to C<MQSeries::MQCC_FAILED>.

=item use MQSeries qw(:constants);

Export just the constants; not very useful.

=item use MQSeries qw(:all);

The same as the default: export functions and constants.

=back

=head2 Server vs. Client API

Compiled MQSeries applications, such as those written in C or C++,
have to decide at compile/link time which of the two API styles to
use: server (shared memory, same host) or client (TCP/IP, same or
remote host).  Perl applications can make this decision at runtime,
dynamically.

By default, the MQSeries module will try to dynamically determine
whether or not the localhost has any queue managers installed, and if
so, use the "server" API, otherwise, it will use the "client" API.

This will Do The Right Thing (tm) for most applications, unless you
want to connect directly to a remote queue manager from a host which
is running other queue managers locally.  Since the existence of
locally installed queue managers will result in the use of the
"server" API, attempts to connect to the remote queue managers will
fail with a Reason Code of 2058.

To workaround this problem, you can force the use of either the server
or client API explictly by using one of the following use statements.

=over 4

=item use MQClient::MQSeries;

This will force the use of the client API, regardless of whether or
not there are queue managers on the localhost.

=item use MQServer::MQSeries;

This will force the use of the server API, and thus only allow
connections only to queue managers on the same machine.  This normally
is not necessary, since the API should detect existence of local queue
manager and default to this flavor of access.

The author uses this in one and only one special case: the automated
script that installs a queue manager, and then customizes it.  When
the script first runs, there is usually no local queue manager, but it
will need to connect to it using the server API once it is created.

=back

Of course, you can combine the various import options, for example the
following is perfectly valid:

  use MQClient::MQSeries qw(:functions);

B<NOTE>: The perl API, when compiled and installed, will normally
build both the server and client extensions, but on some platforms one
or the other is not available.  For example, we currently only support
the client API on IRIX, and only the server API on OS/390.  Whether or
not the server and/or client options are even available depends on how
the MQSeries perl API was compiled and installed.  Consult your
administrator (or whoever built this extension) for such details.

=head1 SUBROUTINES

For complete details on each of the following subroutines, please
consult the "MQSeries Application Programming Guide" and "MQSeries
Application Programming Reference".  This documentation will merely
document how the perl API and the underlying C API calling and return
code conventions vary.

One way in which all of these calls are identical to the C API is in
the use of the '$CompCode' and '$Reason' conventions.  All of the API
calls take these as positional arguments, and the completion code and
reason code are written to those variables, respecitively.

In general, all of the C data structures used to pass or return values
to each API call are passed or returned as a perl hash reference,
specified as a positional argument in the relavent API call.

=head2 MQCONN

  $Hconn = MQCONN($Name,$CompCode,$Reason);

This call returns the Hconn value, to be used in subsequent MQI calls.
The C API took the $Hconn as a positional parameter, whereas the perl
API returns it.

=head2 MQCONNX

  $Hconn = MQCONNX($Name,$ConnectOpts,$CompCode,$Reason);

NOTE: This MQI call is only available if the perl5 API is compiled
against MQSeries version 5 headers and libraries.

This call returns the Hconn value, to be used in subsequent MQI calls.
The C API took the $Hconn as a positional parameter, whereas the perl
API returns it.

The $ConnectOpts value is a hash reference, with keys corresponding to
the fields of the MQCO structure.  This is an input value only.

With the $ConnectOpts, two interior data structures can be provided:
C<ClientConn> and C<SSLConfig>.  These provide access to the C<MQCNO>
and C<MQSCO> options.  The two data structures can be used
independently; and example of them used in combination is shown below:

  $coption = { 'ChannelName'    => 'Some.Channel.Name',
               'TransportType'  => 'TCP',
               'ConnectionName' => 'hostname(port)',
             };
  $ssl_option = { 'KeyRepository' => '/var/mqm/ssl/key' };
  $Hconn = MQCONNX($qmgr_name, { 'ClientConn' => $coption,
                                 'SSLConfig'  => $ssl_option,
                               }, $cc, $re);

See the application programming reference for details on the
additional fields available in the C<ClientConn> data structure.

=head2 MQDISC

  MQDISC($Hconn,$CompCode,$Reason);

The calling convention of this subroutine is identical to the C API.

=head2 MQOPEN

  $Hobj = MQOPEN($Hconn,$ObjDesc,$Options,$CompCode,$Reason);

In the same way that MQCONN loses one positional parameter, and
returns it to the caller, so does MQOPEN remove the $Hobj parameter
from the argument list and returns the value.

The $ObjDesc parameter should be a hash reference, for example:

  $ObjDesc = {
              ObjectName        => 'SOME.MODEL.QUEUE',
              DynamicQName      => 'FOOBAR*',
             };

The $Options parameter should be a set of ORed options, for example:

  $Options = MQOO_INPUT_AS_Q_DEF | MQOO_FAIL_IF_QUIESCING;

If a distribution list is being opened, then the list of queues can be
specified in one of three ways.  The list is given via a new key
"ObjectRecs", used to identify the list.  This is different from the
C-centric approach in the C API, namely to specify the list using the
RecsPresent, ObjectRecPtr, etc.

The first method is to specify an array of plain queue names:

  $ObjDesc = {
              ObjectRecs        => [qw( QUEUE1 QUEUE2 QUEUE3 )],
             };

The second method is to specify an array or array references, each
giving the QName and QMgrName:

  $ObjDesc = {
              ObjectRecs        => [
                                    [qw( QUEUE1 QM1 )],
                                    [qw( QUEUE2 QM2 )],
                                    [qw( QUEUE3 QM3 )],
                                   ],
             };

Finally, an array of hash references can be specified, each giving the
QName and QMgrName via specific keys:

  $ObjDesc = {
              ObjectRecs        => [
                                    {
                                     ObjectName         => 'QUEUE1',
                                     ObjectQMgrName     => 'QM1',
                                    },
                                    {
                                     ObjectName         => 'QUEUE2',
                                     ObjectQMgrName     => 'QM2',
                                    },
                                    {
                                     ObjectName         => 'QUEUE3',
                                     ObjectQMgrName     => 'QM3',
                                    },
                                   ],
             };

In the second and third cases, the queue manager names are always
optional.  Which method to use is largely a matter of style.

When the Reason Code returned by the API is MQRC_MULTIPLE_REASONS,
then these are encoded into an array of hash references, and that
array is returned as a new key in the ObjDesc hash, "ResponseRecs".
The order of the CompCode/Reason pair in the array corresponds to the
order of the queues listed in the ObjectRecs array.

This is best explained in an example.  In this case, we used the
first, simple list of queue names for our distribution list.

  if ( $Reason == MQRC_MULTIPLE_REASONS ) {
      for ( $index = 0 ; $index <= scalar @{$ObjDesc->{ObjectRecs}} ; $index++ ) {
          next if $ObjDesc->{ResponseRecs}->[$index]->{Reason} == MQRC_NONE;
          print "QName: " . $ObjDesc->{ObjectRecs}->[$index] . "\n";
          print "Reason: " . $ObjDesc->{ResponseRecs}->[$index]->{Reason} . "\n";
          print "CompCode: " . $ObjDesc->{ResponseRecs}->[$index]->{CompCode} . "\n";
      }
  }

=head2 MQCLOSE

  MQCLOSE($Hconn,$Hobj,$Options,$CompCode,$Reason);

The calling convention of this subroutine is identical to the C API.

The $Options value is a set of ORed options, for example:

  $Options = MQCO_DELETE_PURGE;

=head2 MQBEGIN

  MQBEGIN($Hconn,$BeginOpts,$CompCode,$Reason)

NOTE: This MQI call is only available if the perl5 API is compiled
against MQSeries version 5 headers and libraries.

The calling convention of this subroutine is identical to the C API.

The $BeginOpts value is a hash reference, with keys corresponding to
the fields of the MQBO structure.  This is both an input and output value.

=head2 MQBACK

  MQBACK($Hconn,$CompCode,$Reason);

The calling convention of this subroutine is identical to the C API.

=head2 MQCMIT

  MQCMIT($Hconn,$CompCode,$Reason);

The calling convention of this subroutine is identical to the C API.

=head2 MQGET

  $Buffer = MQGET($Hconn,$Hobj,$MsgDesc,$GetMsgOpts,$BufferLength,$CompCode,$Reason);

One positional parameter, the $Buffer, is removed from the argument
list.  This is the return value of this subroutine.  The $MsgDesc and
$GetMsgOpts values are hash references.  The $MsgDesc will be
populated with the MQMD structure returned by the MQGET call.  This is
also an input value, and the $MsgDesc data can be populated, for
example, with a specific 'CorrelId'.

  $MsgDesc = {
              CorrelId => $correlid,
             };

The $GetMsgOpts hash reference contains the MQGMO data structure
fields, for example:

  $GetMsgOpts = {
                 Options => MQGMO_FAIL_IF_QUIESCING | MQGMO_SYNCPOINT | MQGMO_WAIT,
                 WaitInterval => MQWI_UNLIMITED,
                };

=head2 MQPUT, MQPUT1

  MQPUT($Hconn,$Hobj,$MsgDesc,$PutMsgOpts,$Msg,$CompCode,$Reason);
  MQPUT1($Hconn,$ObjDesc,$MsgDesc,$PutMsgOpts,$Msg,$CompCode,$Reason);

Both of these calls differ from the C API in the same way as MQGET.
Likewise, the $MsgDesc and $PutMsgOpts values are hash references for
the appropriate data structures.

If MQPUT1() is being used to put a message to a distribution list,
then the $ObjDesc is used in the same way as documented above for
MQOPEN().  In addition, there is a special key to the $PutMsgOpts hash
which can be specified, and the rest of this discussion applies
equally to both MQPUT() and MQPUT1().

The $PutMsgOpts->{PutMsgRecs} value must be an array of hash
references, one for each queue opened in the distribution list,
interpreted in the same order.  Each individual hash reference is
interpreted as a single put message record.  The keys of each record
can be any of:

  MsgId
  CorrelId
  GroupId
  Feedback
  AccountingToken

For example, the following sets the CorrelId the same across all of
the messages in a distribution list of three queues.

  $PutMsgOpts = {
                 PutMsgRecs => [
                                {
                                 MsgId          => MQPMO_NEW_MSG_ID,
                                 CorrelId       => $SomeCorrelId,
                                },
                                {
                                 MsgId          => MQPMO_NEW_MSG_ID,
                                 CorrelId       => $SomeCorrelId,
                                },
                                {
                                 MsgId          => MQPMO_NEW_MSG_ID,
                                 CorrelId       => $SomeCorrelId,
                                },
                               ],
                };

Note that the following fields of the $PutMsgOpts hash do not need to
be specified:

  PutMsgRecFields (calculated automatically)
  PutMsgRecOffset
  PutMsgRecPtr
  ResponseRecPtr
  ResponseRecOffset

For the MQPUT() call, if the Reason code returned is
MQRC_MULTIPLE_REASONS, then these are returned as part of the
$PutMsgOpts hash, in the key ResponseRecs.  For the MQPUT1() call,
these are returned as part of the $ObjDesc hash.

See the MQOPEN() documentation above for the format of this value.

=head2 MQINQ

  ($Attr1,...) = MQINQ($Hconn,$Hobj,$CompCode,$Reason,$Selector1,...);

This call differs from the C API significantly.  Rather than passing a
list of pairs of selectors and attributes, only a list of selectors is
passed.  The return value is a list of attributed.  The C API
convention was simply to pass the address for each answer in the
arguments, but in perl, it makes more sense to return this as a list.

=head2 MQSET

  MQSET($Hconn,$Hobj,$CompCode,$Reason,$Selector1,$Attr1,...);

This call also differs from the C API significantly.  The C API took a
pointer to an array of selectors, with an argument indicating the
length of the array, and a similar pair of values for the attribute
values themselves.  The perl convention is to list the selectors and
attributes in pairs, rather than by passing in an array reference.

=head2 MQCRTMH

  $Hmsg = MQCRTMH($Hconn,$CrtMsgHOpts,$CompCode,$Reason);

This call is only available if the module has been compiled with MQ
v7.  It creates a message handle, which can be used to get/set message
properties.

The $CrtMsgHOpts parameter is a MQCMHO data structure, which for MQ v7
only contains an 'Options' field.

  $CrtMsgHOpts = { Options => ( MQSeries::MQCMHO_VALIDATE ) };

The default (listed above) is generally sufficient.

=head2 MQDLTMH

  MQDLTMH($Hconn,$Hmsg,$DltMsgHOpts,$CompCode,$Reason)

This call is only available if the module has been compiled with MQ
v7.  It deletes a message handle previously created with MQCRTMH.

The $DltMsgHOpts parameter is a MQDMHO data structure, which for MQ v7
only contains an 'Options' field, with no options defined.  For MQ v7,
just specify an empty hash reference.

=head2 MQDLTMP

  MQDLTMP($Hconn,$Hmsg,$DltPropOpts,$Name,$CompCode,$Reason)

This call is only available if the module has been compiled with MQ
v7.  it deletes a message property.

The $DltPropOpts parameter is a MQDMPO parameter, which only contains
an 'Options' field.

  $DltPropOpts = { Options => ( MQSeries::MQDMPO_DEL_FIRST ) };

The default (listed above) is generally sufficient.

The $Name parameter is a fully qualified property name.

=head2 MQINQMP

  $PropertyValue = MQINQMP($Hconn,$Hmsg,$InqPropOpts,$Name,$PropDesc,$Type,$Length,$CompCode,$Reason)

This call is only available if the module has been compiled with MQ
v7.  It retrieves a message property.  The return value is the value
of the property retrieved.

The $InqPropOpts parameter is an MQIMPO data structure.

The $Name parameter is a property name, which may contain a wildcard.

The $PropDesc parameter is an MQPD data structure.

The $Type parameter determines the return type if the option
MQSeries::MQIMPO_CONVERT_TYPE is specified as part of the $InqPropOpts
parameter.  In either case, it is also an output parameter that
specifies the returned type of the proeprty,
e.g. MQSeries::MQTYPE_STRING.

The $Length parameter is the maximum length of the property value to
return.  It is also an output parameter that specifies the length of
the returned value.

=head2 MQSETMP

  MQSETMP($Hconn,$Hmsg,$SetPropOpts,$Name,$PropDesc,$Type,$Value,$CompCode,$Reason)

This call is only available if the module has been compiled with MQ
v7.  It sets or updates a message property.

The $SetPropOpts parameter is a MQHMSG data structur, which for MQ v7
only contains an 'Options' field.

  $SetPropOpts = { Options => ( MQSeries::MQSMPO_SET_FIRST ) };

The default (listed above) is generally sufficient.

The $Name parameter is the property name.

The $PropDesc parameter is an MQPD data structure.

The $Type parameter specifies the data type of the property,
e.g. MQSeries::MQTYPE_STRING or MQSeries::MQTYPE_FLOAT64.

The $Value parameter is the actual proeprty value.  It may be C<undef>
for string and byte string properties.

=head2 MQSTAT

  MQSTAT($Hconn,$StatType,$Stat,$CompCode,$Reason)

This call is only available if the module has been compiled with MQ
v7.  It returns queue manager asynchronous put status information.

The $StatType parameter must always be
MQSeries::MQSTAT_TYPE_ASYNC_ERROR.

The $Stat parameter is a MQSTS data structure must be specified as a
hash reference.  On output, it includes the MQSTS fields documented in
the Application Programming Reference for MQ v7.

=head2 MQReasonToStrings

  ($ReasonText,$ReasonMacro) = MQReasonToStrings($Reason);

This subroutine is specific to the perl API, although similar
functionality is desperately needed in the other programming languages
as well.  This takes an MQSeries Reason code, and returns the English
language text explaining the reason code, and the macro name.  These
strings are compiled into the perl module, encoded in the XS routines,
after having been extracted from the IBM HTML documentation.

For example, a reason code of 2009 (MQRC_CONNECTION_BROKEN) will return:

  "Connection to queue manager lost."

which looks a lot better in error logs and alerts than 2009.

The macro name itself is also returned as a string, so one could use
"MQRC_CONNECTION_BROKEN" in logs, error messages, etc.

In this release, only English language text is returned, but in a
future release, these messages will be locale specific.  This will
almost certainly be implemented with locale-specific DBM files, but
you probably do not need to know this just yet....

=head2 MQReasonToText

  ($ReasonText) = MQReasonToText($Reason);

This is nothing more than a trivial interface to MQReasonToStrings,
returning just the one value (the reason text).

=head2 MQReasonToMacro

  ($ReasonMacro) = MQReasonToMacro($Reason);

This is nothing more than a trivial interface to MQReasonToStrings,
returning just the one value (the MQRC_* macro as a string).

=cut
