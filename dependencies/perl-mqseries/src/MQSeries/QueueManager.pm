#
# $Id: QueueManager.pm,v 38.6 2012/09/26 16:15:19 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::QueueManager;

use 5.008;

use strict;
use Carp;

#
# We're going to use this to validate signal names
#
use Config;

use MQSeries qw(:functions);
use MQSeries::Properties;
use MQSeries::Message;
use Params::Validate qw(validate);

#
# Well, now that we're using the same constants for the Inquire/Set
# interface, they no longer are really part of the Command/PCF
# hierarchy.  We may or may not address this namespace asymmetry in a
# future release.
#
use MQSeries::Command::PCF;
use MQSeries::Command::Base;

our $VERSION = '1.34';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = validate(@_, { 'QueueManager'         => 0,
                              'Carp'                 => 0,
                              'CompCode'             => 0,
                              'Reason'               => 0,
                              'GetConvert'           => 0,
                              'PutConvert'           => 0,
                              'RetryCount'           => 0,
                              'RetrySleep'           => 0,
                              'RetryReasons'         => 0,
                              'ConnectTimeout'       => 0,
                              'ConnectTimeoutSignal' => 0,
                              'ClientConn'           => 0,
                              'SSLConfig'            => 0,
                              'SecurityParms'        => 0,
                              'AutoCommit'           => 0,
                              'AutoConnect'          => 0,
                            });

    my $self =
      {

       Carp                     => \&carp,
       RetryCount               => 0,
       RetrySleep               => 60,
       RetryReasons             => {
                                    map { $_ => 1 }
                                    (
                                     MQSeries::MQRC_CONNECTION_BROKEN,
                                     MQSeries::MQRC_Q_MGR_NOT_AVAILABLE,
                                     MQSeries::MQRC_Q_MGR_QUIESCING,
                                     MQSeries::MQRC_Q_MGR_STOPPING,
                                     MQSeries::MQRC_CHANNEL_NOT_AVAILABLE,
                                     MQSeries::MQRC_HOST_NOT_AVAILABLE,
                                    )
                                   },
       ConnectTimeoutSignal     => 'USR1',
       ConnectTimeout           => 0,
       ConnectArgs              => {},
       AutoCommit               => 0,

      };
    bless ($self, $class);

    #
    # First thing -- override the Carp routine if given.
    #
    if ( $args{Carp} ) {
        if ( ref $args{Carp} ne "CODE" ) {
            carp "Invalid argument: 'Carp' must be a CODE reference";
            return;
        } else {
            $self->{Carp} = $args{Carp};
        }
    }

    #
    # Minimally, the QueueManager is a required option.
    #
    # Uh, well, if you are using the "default" queue manager, we have
    # to allow this to be optional.
    #
    if ( $args{QueueManager} ) {
        if ( ref $args{QueueManager} && $args{QueueManager}->isa("MQSeries::QueueManager") ) {
            $self->{QueueManager} = $args{QueueManager}->{QueueManager};
        } else {
            $self->{QueueManager} = $args{QueueManager};
        }
    } else {
        $self->{QueueManager} = "";
    }

    #
    # Sanity check the data conversion CODE snippets.
    #
    foreach my $key ( qw( PutConvert GetConvert ) ) {
        if ( $args{$key} ) {
            if ( ref $args{$key} ne "CODE" ) {
                $self->{Carp}->("Invalid argument: '$key' must be a CODE reference");
                return;
            } else {
                $self->{$key} = $args{$key};
            }
        }
    }

    #
    # Sanity check the other optional attributes.  Anything else in
    # the arguments is ignored.  Developer beware.  RTFM.  Yada yada
    # yada.
    #
    foreach my $connectarg ( qw( RetryCount RetrySleep RetryReasons
                                 ConnectTimeout ConnectTimeoutSignal
                                 ClientConn SSLConfig SecurityParms) ) {
        next unless exists $args{$connectarg};
        $self->{ConnectArgs}->{$connectarg} = $args{$connectarg};
    }


    #
    # Has AutoCommit behavior been specified?  If not, we make a note
    # of it.
    #
    if ( exists $args{AutoCommit} ) {
        $self->{AutoCommit} = $args{AutoCommit};
    }

    #
    # By default, we connect during the constructor.  This can be
    # turned off (for more detailed error handling) by passing
    # AutoConnect as 0.
    #
    # On failure, we don't return an object, so there's nothing to
    # call CompCode or Reason on.  Scalar references can eb passed to
    # get access to the completion code and reason.
    #
    unless (exists $args{'AutoConnect'} && $args{'AutoConnect'} == 0) {
        my $result = $self->Connect();
        foreach my $code ( qw( CompCode Reason )) {
            if ( ref $args{$code} eq "SCALAR" ) {
                ${ $args{$code} } = $self->{$code};
            }
        }
        return unless $result;
    }

    return $self;
}


sub Open {
    my $self = shift;
    my %args = validate(@_, { 'Options' => 0,
                              'ObjDesc' => 0,
                            });

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    #
    # If the options are given, we assume you know what you're doing.
    #
    if ( exists $args{Options} ) {
        $self->{Options} = $args{Options};
    } else {
        $self->{Options} = MQSeries::MQOO_INQUIRE |
          MQSeries::MQOO_FAIL_IF_QUIESCING;
    }

    #
    # Same for the ObjDesc
    #
    if ( exists $args{ObjDesc} ) {
        if ( ref $args{ObjDesc} eq "HASH" ) {
            $self->{ObjDescPtr} = $args{ObjDesc};
        } else {
            $self->{Carp}->("Invalid argument: 'ObjDesc' must be a HASH reference");
            return;
        }
    } else {
        $self->{ObjDescPtr} =
          {
           ObjectType           => MQSeries::MQOT_Q_MGR,
          };
    }

    #
    # Open the Queue
    #
    $self->{Hobj} = MQOPEN(
                           $self->{Hconn},
                           $self->{ObjDescPtr},
                           $self->{Options},
                           $self->{CompCode},
                           $self->{Reason},
                          );

    if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
        return 1;
    } elsif ( $self->{CompCode} == MQSeries::MQCC_FAILED ) {
        $self->{Carp}->(qq/MQOPEN failed (Reason = $self->{Reason})/);
        return;
    } else {
        $self->{Carp}->(qq/MQOPEN failed, unrecognized CompCode: '$self->{CompCode}'/);
        return;
    }
}


sub Close {
    my $self = shift;

    return 1 unless $self->{Hobj};

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    MQCLOSE(
            $self->{Hconn},
            $self->{Hobj},
            MQSeries::MQCO_NONE,
            $self->{CompCode},
            $self->{Reason},
           );
    if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
        delete $self->{Hobj};
        return 1;
    } elsif ( $self->{Reason} == MQSeries::MQRC_HCONN_ERROR ) {
        delete $self->{Hobj};
        return 1;
    } else {
        $self->{Carp}->("MQCLOSE of $self->{ObjDescPtr}->{ObjectName} on " .
                        qq/$self->{QueueManager} failed (Reason = $self->{Reason})/);
        return;
    }
}


sub ObjDesc {
    my $self = shift;

    if ( $_[0] ) {
        if ( exists $self->{ObjDescPtr}->{$_[0]} ) {
            return $self->{ObjDescPtr}->{$_[0]};
        } else {
            $self->{Carp}->("No such ObjDescPtr field: $_[0]");
            return;
        }
    } else {
        return $self->{ObjDescPtr};
    }
}


sub CompCode {
    my $self = shift;
    return $self->{CompCode};
}


sub PutConvertReason {
    my $self = shift;
    return $self->{"PutConvertReason"};
}


sub Reason {
    my $self = shift;
    return $self->{Reason};
}


sub Reasons {
    my $self = shift;
    return $self->{ObjDescPtr}->{ResponseRecs};
}


sub Inquire {
    my $self = shift;
    my (@args) = @_;

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my (@keys) = ();

    my $ForwardMap = $MQSeries::Command::PCF::RequestValues{QueueManager};
    my $ReverseMap = $MQSeries::Command::PCF::_Responses{MQSeries::MQCMD_INQUIRE_Q_MGR}->[1];

    foreach my $key ( @args ) {

        unless ( exists $ForwardMap->{$key} ) {
            $self->{Carp}->("Unrecognized Queue attribute: '$key'");
            return;
        }

        push(@keys,$ForwardMap->{$key});

    }

    my (@values) = MQINQ(
                         $self->{Hconn},
                         $self->{Hobj},
                         $self->{CompCode},
                         $self->{Reason},
                         @keys,
                        );

    unless ( $self->{CompCode} == MQSeries::MQCC_OK &&
             $self->{Reason} == MQSeries::MQRC_NONE ) {
        $self->{Carp}->("MQINQ call failed. " .
                        qq/CompCode => '$self->{CompCode}', / .
                        qq/Reason   => '$self->{Reason}'\n/);
        return;
    }

    # In case the data parsing fails...
    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my (%values) = ();

    for ( my $index = 0 ; $index <= $#keys ; $index++ ) {

        my ($key,$value) = ($keys[$index],$values[$index]);

        my ($newkey,$ValueMap) = @{$ReverseMap->{$key}};

        if (!$ValueMap) {
            $values{$newkey} = $value;
        }
        elsif (ref($ValueMap) eq "CODE" && # VALUEMAP-CODEREF
               defined($ValueMap = $ValueMap->(decodepcf => $value))) {
            $values{$newkey} = $ValueMap;
        }
        elsif (ref($ValueMap) eq "HASH" &&
               exists($ValueMap->{$value})) {
            $values{$newkey} = $ValueMap->{$value}; # maybe not defined?
        }
        else {
            $self->{Carp}->("Unrecognized value '$value' for key '$newkey'\n");
            return;
        }

    }

    $self->{CompCode} = MQSeries::MQCC_OK;
    $self->{Reason} = MQSeries::MQRC_NONE;

    return %values;

}


sub Disconnect {
    my $self = shift;

    return 1 unless $self->{Hconn};

    #
    # This should protect us from disconnecting from a queue manager
    # when this object is destroyed in a forked child process.
    #
    return 1 unless exists $MQSeries::QueueManager::Pid2Hconn{$$};

    #
    # This should protect us from disconnecting when a given Hconn has
    # been reused by more than one object.  The order the objects are
    # created or destroyed shouldnot matter.
    #
    return 1 if $MQSeries::QueueManager::Pid2Hconn{$$}->{$self->{Hconn}}-- > 1;

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    if ( $self->{_Pending} && $self->{AutoCommit} == 0 ) {
        $self->Backout() || do {
            my $putcnt = $self->{_Pending}->{Put} || 0;
            my $getcnt = $self->{_Pending}->{Get} || 0;
            $self->{Carp}->("Unable to backout pending transaction before disconnect\n" .
                            "Currently $putcnt puts and $getcnt gets pending\n" .
                            "Reason => " . MQReasonToText($self->Reason()) . "\n");
            return;
        };
    }

    MQDISC(
           $self->{Hconn},
           $self->{CompCode},
           $self->{Reason},
          );
    if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
        delete $self->{Hconn};
        return 1;

    } else {
        $self->{Carp}->(qq/MQDISC of $self->{QueueManager} failed (Reason = $self->{Reason})/);
        return;
    }
}


sub DESTROY {
    my $self = shift;
    $self->Close();
    $self->Disconnect();
}


sub Backout {
    my $self = shift;
    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    MQBACK(
           $self->{Hconn},
           $self->{CompCode},
           $self->{Reason},
          );
    if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
        delete $self->{_Pending};
        return 1;
    } else {
        $self->{Carp}->(qq/MQBACK of $self->{QueueManager} failed (Reason = $self->{Reason})/);
        return;
    }
}


sub Commit {
    my $self = shift;
    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    MQCMIT(
           $self->{Hconn},
           $self->{CompCode},
           $self->{Reason},
          );
    if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
        delete $self->{_Pending};
        return 1;
    } else {
        $self->{Carp}->(qq/MQCMIT of $self->{QueueManager} failed (Reason = $self->{Reason})/);
        return;
    }
}


sub Pending {
    my $self = shift;
    return $self->{_Pending};
}


sub Put1 {
    my $self = shift;
    my %args = validate(@_, { 'Message'      => 1,
                              'ObjDesc'      => 0, # one of Queue or ObjDesc
                              'Queue'        => 0, # one of Queue or ObjDesc
                              'QueueManager' => 0,
                              'Sync'         => 0,
                              'PutMsgOpts'   => 0,
                              'PutMsgRecs'   => 0,
                              'PutConvert'   => 0,
                              'Properties'   => 0, # MQ v7
                            });

    my $ObjDesc = {};
    my $PutMsgOpts = { Options => MQSeries::MQPMO_FAIL_IF_QUIESCING, };

    my $retrycount = 0;
    my $buffer = undef;

    unless (ref $args{Message} and $args{Message}->isa("MQSeries::Message")) {
        $self->{Carp}->("Invalid argument: 'Message' must be an MQSeries::Message object");
        return;
    }

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    unless ($args{"ObjDesc"} or $args{Queue}) {
        $self->{Carp}->("Invalid argument: either 'ObjDesc' or " .
                        "'Queue' must be specified");
        return;
    }

    if ($args{"ObjDesc"}) {
        unless ( ref $args{"ObjDesc"} eq 'HASH' ) {
            $self->{Carp}->("Invalid ObjDesc argument; must be a HASH reference");
            return;
        }
        $ObjDesc = $args{"ObjDesc"};
    } else {
        if (ref $args{Queue} eq "ARRAY") {
            $ObjDesc->{ObjectRecs} = $args{Queue};
        } else {
            $ObjDesc->{ObjectName} = $args{Queue};
            $ObjDesc->{ObjectQMgrName} = $args{QueueManager};
        }
    }

    if ($args{PutMsgOpts}) {
        unless (ref $args{PutMsgOpts} eq 'HASH') {
            $self->{Carp}->("Invalid PutMsgOpts argument; must be a HASH reference");
            return;
        }
        $PutMsgOpts = $args{PutMsgOpts};
    } else {
        if ($args{PutMsgRecs}) {
            $PutMsgOpts->{PutMsgRecs} = $args{PutMsgRecs};
        }
        if ($args{Sync}) {
            $PutMsgOpts->{Options} |= MQSeries::MQPMO_SYNCPOINT;
        } else {
            $PutMsgOpts->{Options} |= MQSeries::MQPMO_NO_SYNCPOINT;
        }
    }

    #
    # Sanity check the data conversion CODE snippets.
    #
    $self->{"PutConvertReason"} = 0;
    $args{"Message"}->QueueManager($self);
    if ($args{PutConvert}) {
        if (ref $args{PutConvert} ne "CODE") {
            $self->{Carp}->("Invalid argument: 'PutConvert' must be a CODE reference");
            return;
        } else {
            $buffer = $args{PutConvert}->($args{Message}->Data());
            unless ( defined $buffer ) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed.");
                return;
            }
        }
    } else {
        if ($args{Message}->can("PutConvert")) {
            $buffer = $args{Message}->PutConvert($args{Message}->Data());
            unless (defined $buffer) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed.");
                return;
            }
        } elsif (ref $self->{PutConvert} eq "CODE") {
            $buffer = $self->{PutConvert}->($args{Message}->Data());
            unless ( defined $buffer ) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed.");
                return;
            }
        } else {
            $buffer = $args{Message}->Data();
        }
    }
    $args{"Message"}->QueueManager(undef);

    #
    # If the user specifies a Properties parameter, it must be a hash
    # reference or an MQSeries::Propeties object.  This ignores any
    # existing message-level properties object.
    #
    my $props_obj;              # Scope must extend past MQPUT1
    if (defined $args{Properties}) {
        my $props = $args{Properties};
        if (ref $props eq 'HASH') {
            $props_obj = MQSeries::Properties::->
              new('QueueManager' => $self);
            while (my ($name, $value) = each %$props) {
                if (ref $value) {  # Assume hash-ref
                    $props_obj->SetProperty(%$value, 'Name' => $name);
                } else {        # String
                    $props_obj->SetProperty('Name'  => $name,
                                            'Value' => $value);
                }
            }
        } elsif (ref $props && $props->isa("MQSeries::Properties")) {
            $props_obj = $props;
        } else {
            $self->{Carp}->("Invalid argument 'Properties': must be a hash reference");
            return;
        }
        if (!defined $PutMsgOpts->{Version} ||
            $PutMsgOpts->{Version} < MQSeries::MQPMO_VERSION_3) {
            $PutMsgOpts->{Version} = MQSeries::MQPMO_VERSION_3;
        }
        $PutMsgOpts->{OriginalMsgHandle} = $props_obj->{Hmsg};
    }

    MQPUT1($self->{Hconn},
           $ObjDesc,
           $args{Message}->MsgDesc(),
           $PutMsgOpts,
           $buffer,
           $self->{CompCode},
           $self->{Reason},
          );
    if ($self->{CompCode} == MQSeries::MQCC_FAILED) {
        $self->{Carp}->("MQPUT1 failed (Reason = $self->{Reason})");
        return;
    } else {
        if ($PutMsgOpts->{Options} & MQSeries::MQPMO_SYNCPOINT) {
            $self->{_Pending}->{Put}++;
        }
        return 1;
    }
}


sub Connect {
    my $self = shift;
    my @combined_params = ( %{$self->{ConnectArgs}}, @_ );
    my %args = validate(@combined_params,
                        { 'RetryCount'           => 0,
                          'RetrySleep'           => 0,
                          'RetryReasons'         => 0,
                          'ConnectTimeout'       => 0,
                          'ConnectTimeoutSignal' => 0,
                          'ClientConn'           => 0,
                          'SSLConfig'            => 0,
                          'SecurityParms'        => 0,
                          'AutoConnect'          => 0,
                        });

    return 1 if $self->{Hconn};

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;
    my $retrycount = 0;

    foreach my $key ( qw( RetryCount RetrySleep ConnectTimeout ) ) {
        next unless exists $args{$key};
        unless ( $args{$key} =~ /^\d+$/ ) {
            $self->{Carp}->("Invalid argument: '$key' must numeric");
            return;
        }
        $self->{$key} = $args{$key};
    }

    #
    # The ConnectTimeout functionality requires:
    #
    # (a) A working fork()
    # (b) Support for signals
    # (c) The ability to send signals to other processes (Win32 loses,
    #     cause you can only send signals to yourself)
    #

    if ( $self->{ConnectTimeout} && $^O =~ /win32/i ) {
        $self->{Carp}->("MQCONN timeout functionality is not yet supported on Win32");
        $self->{ConnectTimeout} = 0;
    }

    if ( $self->{ConnectTimeout} && not defined $Config{d_fork} ) {
        $self->{Carp}->("This platform does not support fork()\n" .
                        "MQCONN timeout functionality is disabled");
        $self->{ConnectTimeout} = 0;
    }

    if ( $self->{ConnectTimeout} && not defined $Config{sig_name} ) {
        $self->{Carp}->("Signals are not available in this version of perl\n" .
                        "MQCONN timeout functionality is disabled");
        $self->{ConnectTimeout} = 0;
    }

    if ( $self->{ConnectTimeout} ) {

        $self->{ConnectTimeoutSignal} = $args{ConnectTimeoutSignal} if $args{ConnectTimeoutSignal};

        my %signame = map { $_ => 1 } split(/\s+/,$Config{sig_name});

        unless ( $signame{$self->{ConnectTimeoutSignal}} ) {
            $self->{Carp}->("Signal name '$self->{ConnectTimeoutSignal}' is not supported on this platform\n" .
                            "MQCONN timeout functionality is disabled");
            $self->{ConnectTimeout} = 0;
        }

    }

    if ( $args{RetryReasons} ) {

        unless (
                ref $args{RetryReasons} eq "ARRAY" ||
                ref $args{RetryReasons} eq "HASH"
               ) {
            $self->{Carp}->("Invalid Argument: 'RetryReasons' must be an ARRAY or HASH reference");
            return;
        }

        if ( ref $args{RetryReasons} eq 'HASH' ) {
            $self->{RetryReasons} = $args{RetryReasons};
        } else {
            $self->{RetryReasons} = { map { $_ => 1 } @{$args{RetryReasons}} };
        }

    }

    my $mqconnx_opts = {};
    foreach my $opt (qw(ClientConn SSLConfig SecurityParms)) {
        $mqconnx_opts->{$opt} = $args{$opt} if ($args{$opt});
    }
  CONNECT:
    {

        my $Hconn = "";
        my $timedout = 0;

        if ( $self->{ConnectTimeout} ) {

            my $alarm = "MQSeries::QueueManager MQCONN timeout";
            my $child = 0;

          FORK:
            {

                if ( $child = fork ) {
                    #
                    # We're in the parent.  Set the signal
                    # handler, and call MQCONN inside an eval.  If
                    # the child kills us, $@ will indicate this.
                    #
                    eval {
                        local $SIG{$self->{ConnectTimeoutSignal}} = sub { die $alarm };
                        $Hconn = MQCONNX($self->{ProxyQueueManager} ||
                                         $self->{QueueManager},
                                         $mqconnx_opts,
                                         $self->{CompCode},
                                         $self->{Reason},
                                        );
                    };
                    kill $self->{ConnectTimeoutSignal}, $child;
                    waitpid($child,0);
                    $timedout++ if $@ =~ /$alarm/;
                } elsif ( defined $child ) {
                    #
                    # We're in the child.  Hand around and then
                    # send a signal to the parent letting it know
                    # the timeout period was reached.
                    #
                    local $SIG{$self->{ConnectTimeoutSignal}} = sub { exit 0; };
                    my $ppid = getppid();
                    sleep $self->{ConnectTimeout};
                    kill $self->{ConnectTimeoutSignal}, $ppid;
                    exit 0;
                } else {
                    # XXX do we even want retry logic here???  Hmm...
                    $self->{Carp}->("Unable to fork: $!");
                    return;
                }
            }
        } else {
            $Hconn = MQCONNX($self->{ProxyQueueManager} ||
                             $self->{QueueManager},
                             $mqconnx_opts,
                             $self->{CompCode},
                             $self->{Reason},
                            );
        }


        if ( $self->{Reason} == MQSeries::MQRC_NONE ||
             $self->{Reason} == MQSeries::MQRC_ALREADY_CONNECTED ) {
            $self->{Hconn} = $Hconn;
            $MQSeries::QueueManager::Pid2Hconn{$$}->{$self->{Hconn}}++;

            #
            # Inquire the command level and some config parameters,
            # and cache them.
            #
            eval {
                $self->Open();
                my %attr = $self->Inquire(qw(CommandLevel
                                             MaxMsgLength
                                             MaxUncommittedMsgs
                                             Platform));
                $self->Close();
                $self->{QMgrConfig} = \%attr;
            };
            if ($@) {
                $self->{Carp}->("Could not inquire queue manager attributes");
            }

            return 1;
        }

        if ( $timedout ) {
            $self->{Carp}->("MQCONN failed (interrupted after $self->{ConnectTimeout} seconds)");
        } else {
            $self->{Carp}->(qq{MQCONN failed (Reason = $self->{Reason}) (} .
                            MQReasonToText($self->{Reason}) . ")");
        }

        if (
            $self->{RetryCount} &&
            ( exists $self->{RetryReasons}->{$self->{Reason}} || $timedout )
           ) {

            if ( $retrycount < $self->{RetryCount} ) {
                $retrycount++;
                $self->{Carp}->("Retrying MQCONN call in $self->{RetrySleep} seconds...");
                sleep $self->{RetrySleep};
                redo CONNECT;
            } else {
                $self->{Carp}->("Maximum retry attempts reached ($self->{RetryCount})");
            }

        }

        return;

    }
}


#
# Return status information on previous operations (MQ v7).  Right
# now, this returns info on asynchronous puts; IBM may extend this in
# the future.
#
# Returns:
# - Ref to hash with statistics
#
sub StatusInfo {
    my $self = shift;

    unless ($self->{Hconn}) {
        $self->{Carp}->("Must be connected before invoking MQSTAT\n");
        return;
    }

    my $stats = {};
    MQSTAT($self->{Hconn},
           MQSeries::MQSTAT_TYPE_ASYNC_ERROR,
           $stats,
           $self->{CompCode},
           $self->{Reason});
    if ($self->{CompCode} != MQSeries::MQCC_OK) {
        $self->{Carp}->("MQSTAT failed (Reason = $self->{Reason}\n");
    }
    return $stats;
}


1;

__END__

=head1 NAME

MQSeries::QueueManager - OO interface to the MQSeries Queue Manager

=head1 SYNOPSIS

  use MQSeries qw(:functions);
  use MQSeries::QueueManager;

  #
  # Simplest, trivial usage
  #
  my $qmgr = MQSeries::QueueManager->
    new(QueueManager => 'some.queue.manager' ) ||
    die("Unable to connect to queue manager\n");

  #
  # The best way to do error checking.  Handle the object
  # instantiation and connection to the queue manager independently.
  #
  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager => 'some.queue.manager',
     AutoConnect  => 0,
    ) || die "Unable to instantiate MQSeries::QueueManager object\n";

  $qmgr->Connect() ||
    die("Unable to connect to queue manager\n" .
        "CompCode => " . $qmgr->CompCode() . "\n" .
        "Reason => " . $qmgr->Reason() .
        " (", MQReasonToText($qmgr->Reason()) . ")\n");

  #
  # Advanced usage.  Enable the connection timeout, and connection
  # retry logic.
  #
  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager       => 'some.queue.manager',
     AutoConnect        => 0,
     ConnectTimeout     => 120,
     RetryCount         => 60,
     RetrySleep         => 10,
    ) || die "Unable to instantiate MQSeries::QueueManager object\n";

  $qmgr->Connect() ||
    die("Unable to connect to queue manager\n" .
        "CompCode => " . $qmgr->CompCode() . "\n" .
        "Reason => " . $qmgr->Reason() .
        " (", MQReasonToText($qmgr->Reason()) . ")\n";

  #
  # Avoid a channel table file or MQSERVER variable and specify
  # the client connect options directly.
  #
  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager => 'some.queue.manager',
     ClientConn   => { 'ChannelName'    => 'FOO',
                       'TransportType'  => 'TCP', # Default
                       'ConnectionName' => "hostname(1414)",
                       'MaxMsgLength'   => 16 * 1024 * 1024,
                     },
    ) || die("Unable to connect to queue manager\n");

  #
  # Put a message under syncpoint, then commit/backout (in most cases,
  # a Put is done using an MQSeries::Queue object instead)
  #
  my $msg = MQSeries::Message->new(Data => $msg_data);
  $qmgr->Put1(Message => $msg,
              Queue   => 'SOME.QUEUE.NAME',
              Sync    => 1,
             );
  if (some_other_work_succeeds()) {
      $qmgr->Commit();
  } else {
      $qmgr->Backout();
  }

  #
  # MQ v7: perform multiple asynchronous Put1 operations,
  # then check if any of them ran into issues.  Asnchronous
  # puts can also be performed from a queue objects, and are
  # allowed with syncpoint.
  #
  foreach my $msg_data (@data_to_be_sent) {
      my $msg = MQSeries::Message->new(Data => $msg_data);
      $qmgr->Put1(Message    => $msg,
                  Queue      => 'SOME.QUEUE.NAME',
                  PutMsgOpts => { Options => (MQSeries::MQPMO_ASYNC_RESPONSE |
                                              MQSeries::MQPMO_FAIL_IF_QUIESCING),
                                },
                 );
  }
  my $status = $qmgr->StatusInfo();

=head1 DESCRIPTION

The MQSeries::QueueManager object is an OO mechanism for connecting to
an MQSeries queue manager, and/or opening and inquiring a queue
manager object.

This module is used together with MQSeries::Queue, MQSeries::Message
and MQSeries::Properties, and the other MQSeries::* modules.  These
objects provide a simpler, higher level interface to the MQI.

This module also provides special support for connect timeouts (for
interrupting MQCONNX() calls that may hang forever), as well as connect
retry logic, which will retry failed MQCONNX() calls for a specific
list of reason codes.

See the "Special Considerations" section for a discussion of these
advanced, but powerful, features.

=head1 METHODS

=head2 new

The constructor takes a hash as an argument, with the following keys:

  Key                           Value
  ===                           =====
  QueueManager                  String
  Carp                          CODE reference
  AutoConnect                   Boolean
  AutoCommit                    Boolean
  ConnectTimeout                Numeric
  ConnectTimeoutSignal          String
  GetConvert                    CODE reference
  PutConvert                    CODE reference
  RetrySleep                    Numeric
  RetryCount                    Numeric
  RetryReasons                  HASH Reference
  CompCode                      Reference to Scalar Variable
  Reason                        Reference to Scalar Variable

=over 4

=item QueueManager

This is simply the name of the Queue Manager to which to connect.
This is passed directly to the MQCONNX() call as-is.

Normally, this is simply the name of the queue manager to which you
wish to connect, but if the "default" queue manager is to be used,
then this can either be the empty string "", or simply omitted
entirely.

=item Carp

This key specifies a code reference to a routine to replace all of the
carp() calls in the API, allowing the user of the API to trap and
handle all of the error message generated internally, or simply
redirect how they get logged.

For example, one might want everything to be logged via syslog:

  sub MyLogger {
      my ($message) = @_;
      foreach my $line (split(/\n+/, $message)) {
          syslog("err", $line);
      }
  }

Then, one tells the object to use this routine:

  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager       => 'some.queue.manager',
     Carp               => \&MyLogger,
    ) || die("Unable to connect to queue manager.\n");

The default, as one might guess, is Carp::carp();

=item AutoConnect

This is an optional parameter that defaults to true.  If the value of
this argument is false, then the constructor will not automatically
call the C<Connect()> method, allowing the developer to call it
explicitly, and thus independently error check object instantiation
and the connection to the queue manager.  See the section on Error
Handling in Special Considerations.

=item AutoCommit

If the value of this argument is true, then pending transactions will
be committed during object destruction.  If it is false, then pending
transactions will be backed out before disconnecting from the queue
manager during object destruction.

See the section on "AutoCommit" in "Special Considerations".

=item ClientConn

For client connections, the connection details must be provided
somehow.  By default, the client channel table file (AMQCLCHL.TAB) or
MQSERVER environment variable is used.  This optional parameter allows
you to specify the details in your code (possibly read from some sort
of configuration file or directory service).

The C<ClientConn> parameter is a hash reference of which the
C<ChannelName>, C<ConnectionName> and C<MaxMsgLength> are most
relevant.  See the description of the C<MQCD> parameter structure in
the Application Programming Reference guide for details on the other
fields.

=item SSLConfig

For client connections using SSL, the SSL key repository must be
specified.  Than can be done usign the C<MQSSLKEYR> environment
variable, but also using the C<MQSCO> data structured specified on the
MQCONNX.  The C<SSLConfig> parameters provides a way to specify the
key repositority, and overrides the C<MQSSLKEYR> environment
variable. The example below shows how it can be used:

  my $qmgr = MQSeries::QueueManager->
    new(QueueManager => 'some.queue.manager',
        SSLConfig    => { 'KeyRepository' => '/var/mqm/ssl/key' },
       );

The C<SSLConfig> option is usually combined with the C<ClientConn>
parameter documented above.

=item SecurityParms

In MQ v6 and above, security parameters can be specified.  The example
below shows how it can be used:

  my $qmgr = MQSeries::QueueManager->
    new(QueueManager  => 'some.queue.manager',
        SecurityParms => { 'AuthenticationType' => MQSeries::MQZAT_INITIAL_CONTEXT,
                           'CSPUserId'          => $userid,
                           'CSPPassword'        => $passwd,
                         },
       );

By default, no authentication takes place, and channel security exits
can be used.

The C<SecurityParms> parameter is a hash reference with members
C<AuthenticationType>, C<CSPUserid> and C<CSPPassword>.  See the
description of the C<MQCSP> parameter structure in the Application
Programming Reference guide for details on the other fields.

=item ConnectTimeout

If this value is given, it must be a positive integer.  This is the
time, in seconds, in which an MQCONNX() must complete before the MQI
call will be interrupted.  The default value is zero, which means the
MQCONNX() call will not be interrupted.

There are outage scenarios, in the experience of the author, where the
MQCONNX() call will block indefinitely and never return.  This happens
when a queue manager is "hung", and completely unresponsive, in some
cases.

This feature should be used with caution, since it is implemented
using a SIGALRM handler, and the alarm() system call.  See the section
on "Connection Timeouts" in "Special Considerations".

Attempts to use this feature on unsupported platforms that do not
support signals will generate a warning, and be silently ignored.

=item ConnectTimeoutSignal

By default, the ConnectTimeout mechanism is implemented using a signal
handler for SIGUSR1, but the signal used to interrupt the MQCONNX()
call can be customized using this attribute.

The signal handler installed by this API is done using local(), so the
effects of the handler will only override the applications handler
during the call to MQCONNX().

The string used for this attribute should be the short hand name of
the signal, for example, to set the signal to SIGUSR2:

   my $qmgr = MQSeries::QueueManager->new
     (
      QueueManager              => 'FOO',
      ConnectTimeout            => 300,
      ConnectTimeoutSignal      => 'USR2',
     ) || die;

=item RetryCount

This is an integer value, and specifies the maximum number of times to
retry the connection, before failing.  The default is 0.

=item RetrySleep

This is an integer value, and specified the number of seconds to sleep
between retries.  The maximum timeout for an outage is the product of
the RetrySleep and RetryCount parameters.  The default is 0.

=item PutConvert, GetConvert

These are CODE references to subroutines which are used to convert the
data in a MQSeries::Message object prior to passing it to the MQPUT
MQI call, or convert the data retreived from the queue by the MQGET
MQI call before inserting it into a MQSeries::Message object.

These must be CODE references, or the new() constructor will fail.  A
properly written conversion routine will be passed a single scalar
value and return a single scalar value.  In the event of an error, the
conversion routine should return 'undef'.

The example shown in the synopsis shows how one might use a pair of
home grown encryption and decryption subroutines to keep data in clear
text in core, but encrypted in the contents of the message on the
queue.  This is probably not the most hi-tech way to encrypt MQSeries
data, of course.

The MQSeries::Message::Storable class provides an example of how to
subclass MQSeries::Message to have this type of conversion handled
transparently, in the class definition.

=item CompCode, Reason

When the constructor encounters an error, it returns nothing, and you
can not make method calls off of a non-existent object.  Thus, you do
not have access to the CompCode() and Reason() method calls.  If you
want to extract these values, you will have to pass a scalar reference
value to the constructor, for example:

  my $CompCode = MQSeries::MQCC_FAILED;
  my $Reason = MQSeries::MQRC_UNEXPECTED_ERROR;

  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager               => 'some.queue.manager',
     CompCode                   => \$CompCode,
     Reason                     => \$Reason,
    ) || die "Unable to connect to QueueManager: CompCode => $CompCode, Reason => $Reason\n";

But, this is ugly (authors' opinion, but then, we get to write the
docs, too).  Use the C<AutoConnect> option instead to separate C<new>
and C<Connect>.

=item RetryCount

The call to MQCONNX() (implemented via the Connect() method), can be
told to retry the failure for a specific list of reason codes.  This
functionality is only enabled if the RetryCount is non-zero. By
default, this value is zero, and thus retries are disabled.

=item RetrySleep

This argument is the amount of time, in seconds, to sleep between
subsequent retry attempts.

=item RetryReasons

This argument is either an ARRAY or HASH reference indicating the
specific reason code for which retries will be attempted.  If given as
an ARRAY, the elements are simply the reason codes, and if given as a
HASH, then the keys are the reason codes (and the values ignored).

=back

=head2 Connect

This method takes no arguments, and merely calls MQCONNX() to connect
to the queue manager.  The various options are all set via the
MQSeries::QueueManager constructor (see above).

This method is called automatically by the constructor, unless the
C<AutoConnect> argument is specified and set to false.

Note that this is a new method as of the 1.06 release, and is provided
to enable more fine grained error checking.  See the ERROR HANDLING
section.

=head2 Disconnect

This method takes no arguments, and merely calls MQDISC() to disconnect
from the queue manager.

It is important to note that normally, this method need not be called,
since it is implicitly called via the object destructor.  If the
Disconnect() call errors need to be handled, then it can be done
explicitly.  See the ERROR HANDLING section.

=head2 Backout

This method takes no arguments, and merely calls MQBACK.  It returns
true on success, and false on failure.

=head2 Commit

This method takes no arguments, and merely calls MQCMIT.  It returns
true on success, and false on failure.

=head2 Put1

This method wraps the MQPUT1 call.  The arguments are a hash, with the
following key/value pairs (required keys are marked with a '*'):

  Key           Value
  ===           =====
  Message*      MQSeries::Message object
  Queue         String, or ARRAY reference (distribution list)
  QueueManager  String
  ObjDesc       HASH reference
  PutMsgOpts    HASH Reference
  PutMsgRecs    ARRAY Reference
  Sync          Boolean
  PutConvert    CODE reference
  Properties    HASH Reference or MQSeries::Properties object

The return value is true or false, depending on the success of the
underlying MQPUT1() call.  If the operation fails, then the Reason()
and CompCode() methods will return the appropriate error codes, if the
error was an MQSeries error.

If a PutConvert() method failed before the actual MQPUT1() function
was called, then the Reason() code will be MQRC_UNEXPECTED_ERROR, and
the PutConvertReason() will be true.  All of the PutConvert() methods
supplied with the various MQSeries::Message subclasses in this
distribution will generate some form of error via carp (or the Carp
attribute of the objects, if overridden).

=over 4

=item Message

This argument is the message to be placed onto the queue.  The value
must be an MQSeries::Message object.

=item Queue

This is the queue, or list of queue if using a distribution list, to
which to put the message.  If it is a single queue, then this value is
a string, naming the queue.  If it is a distribution list, then this
value is an ARRAY reference, listing the target queues.  There are
three ways to specify the list.

The list may be a simple array of strings:

  $qmgr->Put1(
              Message => $message,
              Queue   => [qw( QUEUE1 QUEUE2 QUEUE3 )],
             )

or, it can be an array of arrays, each one specifying the queue and
queue manager name of the target queue:

  $qmgr->Put1(
              Message => $message,
              Queue => [
                        [qw( QUEUE1 QM1 )],
                        [qw( QUEUE2 QM2 )],
                        [qw( QUEUE3 QM3 )],
                       ],
             )

or finally, it can be an array of hash references, each naming the
queue and queue manager:

  $qmgr->Put1(
              Message => $message,
              Queue => [
                        {
                         ObjectName             => 'QUEUE1',
                         ObjectQMgrName         => 'QM1',
                        },
                        {
                         ObjectName             => 'QUEUE2',
                         ObjectQMgrName         => 'QM2',
                        },
                        {
                         ObjectName             => 'QUEUE3',
                         ObjectQMgrName         => 'QM3',
                        },
                       ],
              )

In the latter two cases, the queue manager names are optional.  Which
method to use is largely a choice of style.

=item QueueManager

Note that this key is B<only> relevant when not using distribution
lists.  This identifies the queue manager of the target queue, to
which the message is being written.  This is an optional key.

=item ObjDesc

The entire ObjDesc structure passed to the underlying MQPUT1() call
can be specified via this key.  In this case, the Queue and/or
QueueManager are simply ignored.  Use of this key would be considered
somewhat non-conventional, as the OO API is attempting to hide the
complexity of these underlying data structures.

However, this allows the developer access to the entire ObjDesc, if
necessary.

=item PutMsgOpts

This argument forces the developer to specify the complete PutMsgOpts
structure, and will override the use of convenience flags, such as
Sync.  Similar to the use of ObjDesc, this is non-conventional, but
provided to allow access to the complete API, if necessary.

=item PutMsgRecs

This argument is relevant only when using distribution lists.

The value is an ARRAY reference, specifying the put message records
for the individual queues in the distribution list.  Normally, these
are specified as part of the PutMsgOpts, but this API attempts to hide
the complexity of the PutMsgOpts structure from the user.

When using distribution lists, PutMsgRecs are often necessary to
control how the MsgId, CorrelId, and three other specific fields in
the MsgDesc are handled.

For details, see the MQPUT() and MQPUT1() documentation in
MQSeries(3).

=item Sync

This is a flag to indicate that the Syncpoint option is to be used,
and the message(s) not committed to the queue until an MQBACK or
MQCOMM call is made.  These are both wrapped with the Backout() and
Commit() methods respectively.

The value is simply interpreted as true or false.

=item PutConvert

See the new() constuctor documentation for the verbose details.  This
can be specified for just the Put1() method in the event that a
converted message format needs to be put to a queue on a
MQSeries::QueueManager object for which default conversion routines
have not been installed.

If you have a QueueManager for which all of the Queue use the same
message formats, then you can simply specify the PutConvert and
GetConvert CODE references once, when the MQSeries::QueueManager
object is instantiated.  Alternately, you may be specifying the
conversion routined for only a few specific queues.  In the latter
case, it is entirely possible that you will need to specify PutConvert
when performing an MQPUT1 MQI call via the Put1() method.

=item Properties

This parameter is only supported if the module has been compiled with
the MQ v7 libraries.  It allows properties to be specified with the
message.  This can be used for selectors or for publish/subscribe.

The Properties parameter can be a hash reference or an
MQSeries::Properties object.  If it is a hash reference, it can be
specified in two ways: as key/value pairs, or with property options.

Specifying the proeprties as key/value pairs is straightforward:

  Properties => { 'perl.MQSeries.label'    => 'important',
                  'perl.MQSeries.customer' => 'BigCompany',
                }

In this case, the property values are specified to MQ as strings,
which is usually the correct thing to do.  However, property options
can be specified if so desired:

  Properties => { 'perl.MQSeries.label' => 'important',
                  'perl.MQSeries.price' => { Type  => MQSeries::MQTYPE_FLOAT64,
                                             Value => '8.99',
                                           },
                  'perl.MQSeries.count' => { Type  => MQSeries::MQTYPE_INT32,
                                             Value => 12,
                                           },
                }

In addition to Name and Value, you can also specify Encoding and CCSID.

=back

=head2 StatusInfo

This method returns status information and is only supported if the
module has been compiled for MQ v7.  It returns information on
previous asynchronous put operations, which can be queue manager Put1
operations or queue Put operations.

The StatusInfo method takes no parameters and returns a hash reference
matching the MQSTS data structure.  (See the Application Programming
Reference for details, or run Data::Dumper on the return value.)

=head2 CompCode

This method returns the MQI Completion Code for the most recent MQI
call attempted.

=head2 Reason

This method returns the MQI Reason Code for the most recent MQI
call attempted.

=head2 PutConvertReason

This method returns a true of false value, indicating if a PutConvert
method failed or not.  Similar to the MQRC reason codes, false
indicates success, and true indicates some form of error.  If there
was no PutConvert method called, this will always return false.

=head2 Reasons

This method call returns an array reference, and each member of the
array is a Response Record returned as a possible side effect of
calling a Put1() method to put a message to a distribution list.

The individual records are hash references, with two keys: CompCode
and Reason.  Each provides the specific CompCode and Reason associated
with the put of the message to each individual queue in the
distribution list, respectively.

=head2 Open

This method takes two optional (but typically not necessary)
arguments, and calls MQOPEN() on the Queue Manager, in order to enable
the Inquire method.  The arguments are a has, with the following
keys:

  Key                           Value
  ===                           =====
  Options                       MQOPEN 'Options' Values
  ObjDesc                       HASH reference (MQOD structure)

The Options default to MQOO_INQUIRE|MQOO_FAIL_IS_QUIESCING, which is
usually correct.  Note that you can not call MQSET() on a queue
manager, so MQOO_SET is meaningless, as are most of the other options.
Advanced users can set this as they see fit.

The ObjDesc argument is also not terribly interesting, as you most of
the values have reasonable defaults for a queue manager.  Again, the
API supports advanced users, so you can set this as you see fit.  The
keys of the ObjDesc hash are the fields in the MQOD structure.

This method returns a true of false values depending on its success or
failure.  Investigate the CompCode() and Reason() for
MQSeries-specific error codes.

=head2 Close

This method takes no arguments, and merely calls MQCLOSE() to close
the actual queue manager object.  This is meaningful only if the queue
manager has been Open()ed for use by Inquire().

It is important to note that normally, this method need not be called,
since it is implicitly called via the object destructor, if necessary.
If the Close() call errors need to be handled, then it can be done
explicitly.  See the ERROR HANDLING section.

=head2 Inquire

This method is an interface to the MQINQ() API call, however, it takes
more convenient, human-readable strings in place of the C macros for
the selectors, as well as supports more readable strings for some of
the data values as well.

For example, to query the Platform and DeadLetterQName of a queue
manager:

  my %qmgrattr = $qmgr->Inquire( qw(Platform DeadLetterQName) );

The argument to this method is a list of "selectors", or QueueManager
attributes, to be queried.  The following table shows the complete set
of possible keys, and their underlying C macro.

Note that this list is all-inclusive, and that many of these are not
supported on some of the MQSeries releases or platforms.  Consult the IBM
documentation for such details.

    Key                         Macro
    ===                         =====
    AccountingConnOverride      MQIA_ACCOUNTING_CONN_OVERRIDE,
    AccountingInterval          MQIA_ACCOUNTING_INTERVAL,
    ActivityRecording           MQIA_ACTIVITY_RECORDING,
    AlterationDate              MQCA_ALTERATION_DATE,
    AlterationTime              MQCA_ALTERATION_TIME,
    AdoptNewMCACheck            MQIA_ADOPTNEWMCA_CHECK,
    AdoptNewMCAType             MQIA_ADOPTNEWMCA_TYPE,
    AlterationTime              MQCA_ALTERATION_TIME,
    AuthorityEvent              MQIA_AUTHORITY_EVENT,
    BridgeEvent                 MQIA_BRIDGE_EVENT,
    ChannelAutoDef              MQIA_CHANNEL_AUTO_DEF,
    ChannelAutoDefEvent         MQIA_CHANNEL_AUTO_DEF_EVENT,
    ChannelAutoDefExit          MQCA_CHANNEL_AUTO_DEF_EXIT,
    ChannelEvent                MQIA_CHANNEL_EVENT,
    ChannelInitiatorControl     MQIA_CHINIT_CONTROL,
    ChannelMonitoring           MQIA_MONITORING_CHANNEL,
    ChannelStatistics           MQIA_STATISTICS_CHANNEL,
    ChinitAdapters              MQIA_CHINIT_ADAPTERS,
    ChinitDispatchers           MQIA_CHINIT_DISPATCHERS,
    ChinitServiceParm           MQCA_CHINIT_SERVICE_PARM,
    ChinitTraceAutoStart        MQIA_CHINIT_TRACE_AUTO_START,
    ChinitTraceTableSize        MQIA_CHINIT_TRACE_TABLE_SIZE,
    ClusterSenderMonitoringDefault MQIA_MONITORING_AUTO_CLUSSDR,
    ClusterSenderStatistics     MQIA_STATISTICS_AUTO_CLUSSDR,
    ClusterWorkLoadData         MQCA_CLUSTER_WORKLOAD_DATA,
    ClusterWorkLoadExit         MQCA_CLUSTER_WORKLOAD_EXIT,
    ClusterWorkLoadLength       MQIA_CLUSTER_WORKLOAD_LENGTH,
    CLWLMRUChannels             MQIA_CLWL_MRU_CHANNELS,
    CLWLUseQ                    MQIA_CLWL_USEQ,
    CodedCharSetId              MQIA_CODED_CHAR_SET_ID,
    CommandEvent                MQIA_COMMAND_EVENT,
    CommandInputQName           MQCA_COMMAND_INPUT_Q_NAME,
    CommandLevel                MQIA_COMMAND_LEVEL,
    CommandServerControl        MQIA_CMD_SERVER_CONTROL,
    ConfigurationEvent          MQIA_CONFIGURATION_EVENT,
    CPILevel                    MQIA_CPI_LEVEL,
    CreationDate                MQCA_CREATION_DATE,
    CreationTime                MQCA_CREATION_TIME,
    DeadLetterQName             MQCA_DEAD_LETTER_Q_NAME,
    DefXmitQName                MQCA_DEF_XMIT_Q_NAME,
    DistLists                   MQIA_DIST_LISTS,
    DNSGroup                    MQCA_DNS_GROUP,
    DNSWLM                      MQIA_DNS_WLM,
    ExpiryInterval              MQIA_EXPIRY_INTERVAL,
    IGQUserId                   MQCA_IGQ_USER_ID,
    IGQPutAuthority             MQIA_IGQ_PUT_AUTHORITY,
    InhibitEvent                MQIA_INHIBIT_EVENT,
    IntraGroupQueueing          MQIA_INTRA_GROUP_QUEUING,
    IPAddressVersion            MQIA_IP_ADDRESS_VERSION,
    ListenerTimer               MQIA_LISTENER_TIMER,
    LocalEvent                  MQIA_LOCAL_EVENT,
    LoggerEvent                 MQIA_LOGGER_EVENT,
    LUGroupName                 MQCA_LU_GROUP_NAME,
    LUName                      MQCA_LU_NAME,
    LU62ARMSuffix               MQCA_LU62_ARM_SUFFIX,
    LU62Channels                MQIA_LU62_CHANNELS,
    MaxActiveChannels           MQIA_ACTIVE_CHANNELS,
    MaxChannels                 MQIA_MAX_CHANNELS,
    MaxHandles                  MQIA_MAX_HANDLES,
    MaxMsgLength                MQIA_MAX_MSG_LENGTH,
    MaxPriority                 MQIA_MAX_PRIORITY,
    MaxPropertiesLength         MQIA_MAX_PROPERTIES_LENGTH,
    MaxUncommittedMsgs          MQIA_MAX_UNCOMMITTED_MSGS,
    MQIAccounting               MQIA_ACCOUNTING_MQI,
    MQIStatistics               MQIA_STATISTICS_MQI,
    MsgMarkBrowseInterval       MQIA_MSG_MARK_BROWSE_INTERVAL,
    OutboundPortMax             MQIA_OUTBOUND_PORT_MAX,
    OutboundPortMin             MQIA_OUTBOUND_PORT_MIN,
    Parent                      MQCA_PARENT,
    PerformanceEvent            MQIA_PERFORMANCE_EVENT,
    Platform                    MQIA_PLATFORM,
    PubSubMaxMsgRetryCount      MQIA_PUBSUB_MAXMSG_RETRY_COUNT,
    PubSubMode                  MQIA_PUBSUB_MODE,
    PubSubNPInputMsg            MQIA_PUBSUB_NP_MSG,
    PubSubNPResponse            MQIA_PUBSUB_NP_RESP,
    PubSubSyncPoint             MQIA_PUBSUB_SYNC_PT,
    QMgrDesc                    MQCA_Q_MGR_DESC,
    QMgrIdentifier              MQCA_Q_MGR_IDENTIFIER,
    QMgrName                    MQCA_Q_MGR_NAME,
    QSharingGroupName           MQCA_QSG_NAME,
    QueueAccounting             MQIA_ACCOUNTING_Q,
    QueueMonitoring             MQIA_MONITORING_Q,
    QueueStatistics             MQIA_STATISTICS_Q,
    ReceiveTimeout              MQIA_RECEIVE_TIMEOUT,
    ReceiveTimeoutMin           MQIA_RECEIVE_TIMEOUT_MIN,
    ReceiveTimeoutType          MQIA_RECEIVE_TIMEOUT_TYPE,
    RemoteEvent                 MQIA_REMOTE_EVENT,
    RepositoryName              MQCA_REPOSITORY_NAME,
    RepositoryNamelist          MQCA_REPOSITORY_NAMELIST,
    SecurityCase                MQIA_SECURITY_CASE,
    SharedQQMgrName             MQIA_SHARED_Q_Q_MGR_NAME,
    SSLCRLNamelist              MQCA_SSL_CRL_NAMELIST,
    SSLCryptoHardware           MQCA_SSL_CRYPTO_HARDWARE,
    SSLEvent                    MQIA_SSL_EVENT,
    SSLFipsRequired             MQIA_SSL_FIPS_REQUIRED,
    SSLKeyRepository            MQCA_SSL_KEY_REPOSITORY,
    SSLKeyResetCount            MQIA_SSL_RESET_COUNT,
    SSLTasks                    MQIA_SSL_TASKS,
    StartStopEvent              MQIA_START_STOP_EVENT,
    StatisticsInterval          MQIA_STATISTICS_INTERVAL,
    SyncPoint                   MQIA_SYNCPOINT,
    TCPChannels                 MQIA_TCP_CHANNELS,
    TCPKeepAlive                MQIA_TCP_KEEP_ALIVE,
    TCPStackType                MQIA_TCP_STACK_TYPE,
    TCPName                     MQCA_TCP_NAME,
    TraceRouteRecording         MQIA_TRACE_ROUTE_RECORDING,
    TreeLifeTime                MQIA_TREE_LIFE_TIME,
    TriggerInterval             MQIA_TRIGGER_INTERVAL,

The return value of this method is a hash, whose keys are those given
as arguments, and whose values are the queried queue manager
attributes.  In almost all cases, the values are left unmolested, but
in the following case, the values are mapped to more readable strings.

=over 4

=item Platform                  (integer)

    Key                         Macro
    ===                         =====
    MVS                         MQPL_MVS
    NSK                         MQPL_NSK
    OS2                         MQPL_OS2
    OS400                       MQPL_OS400
    UNIX                        MQPL_UNIX
    Win16                       MQPL_WINDOWS
    Win32                       MQPL_WINDOWS_NT

=back

=head2 ObjDesc

This method can be used to query the ObjDesc data structure.  If no
argument is given, then the ObjDesc hash reference is returned.  If a
single argument is given, then this is interpreted as a specific key,
and the value of that key in the ObjDesc hash is returned.

NOTE: This method is meaningless unless the queue manager has been
MQOPEN()ed via the Open() method.

=head1 Special Considerations

=head2 AutoCommit

Normally, when you have pending transactions (i.e. MQPUT() and/or
MQGET() calls with syncpoint), they will be automatically committed
when MQDISC() is called.  The MQSeries::QueueManager object
destructor, in an attempt to make things easy for the programmer,
automatically calls MQDISC() for you.  The result is that transactions
will be automatically committed when the application exits in any way
that allows the object destruction to occur.

This behavior is somewhat counter intuitive, as you would expect
transactions to be backed out unless you explicitly say otherwise
(i.e. call MQCMIT(), or in this context, the Commit() method call).

As of the 1.12 release of the MQSeries Perl API, this behavior is
under the control of the developer.  The AutoCommit argument to the
object constructor is a Boolean value that specifies whether
AutoCommit is on or off.  If enabled, then a pending transaction will
be committed before disconnecting.  If disabled, then the transaction
will be backed out, and only if the backout succeeds will we cleanly
disconnect.

NOTE: The default behavior was backwards compatible in the 1.12
release, meaning that AutoCommit is enabled by default.  However, if
you do B<not> specify the AutoCommit behavior explicitly, then the
automatic commit of a pending transaction will generate a warning when
the object is destroyed.  This is because we (the MQSeries Perl API
authors) feel that depending on this functionality is dangerous.

ANOTHER NOTE: The default behavior did change with the 1.13 release,
and AutoCommit now defaults to 0, not 1, making the intuitive behavior
the default.

=head2 Connection Timeout Support

There are known outage scenarios wherein the queue manager will be in
a "hung" state, where it is entirely unresponsive, but still up and
running.  Attempts to connect to such a queue manager can block
indefinetely, with the MQCONNX() call never returning, until the queue
manager is shutdown and restarted.  Normally, applications can not
trap this error, since they will be stuck in the MQCONNX() call,
forever.

By setting the ConnectTimeout argument to the MQSeries::QueueManager
constructor, a time limit on MQCONNX() can be imposed, and applications
will be able to detect this situation, and take action, if so desired.

This functionality is implemented by forking a child process, which
sleeps for the duration of the ConnectTimeout, and then sends a signal
to the parent to interrupt the MQCONNX() call.  If the MQCONNX() call
succeeds before the timeout is reached, then the parent kill the child
with the same signal.

By default, SIGUSR1 is used, and the handlers are installed locally,
so there should be no conflict with any signal handlers installed by
the application, unless you really need your own SIGUSR1 to be enabled
during the MQCONNX() call.  You can customize the signal used via the
ConnectTimeoutSignal argument.

If the timeout occurs, it will be considered a retryable error. (See
the next section).

NOTE: This functionality is only supported on platforms that support
fork(), and signals, of course.  Win32 is not supported, since it does
not support sending signals to other processes.

=head2 Connection Retry Support

Normally, when MQCONNX() fails, the method that called it (Connect() or
new()) also fails.  It is possible to have the Connect() method retry
the MQCONNX() call for a specific set of reason codes.

By default, the retry logic is disabled, but it can be enabled by
setting the RetryCount to a non-zero value.  The list of reason codes
defaults to a few reasonable values, but a list of retryable codes can
be specified via the RetryReasons argument.

You are probably wondering why this logic is useful for MQCONNX().  The
choice of the default RetryReasons is not without its own reason.

Consider an application that loses its connection to its queue
manager, and thus crashes and restarts.  It may very well attempt to
reconnect before the queue manager has recovered, and this support
allows the application to retry the connection for a while, until it
succeeds.

Alternately, consider an application that is started at boot time,
possible in parallel with the queue manager.  If the application comes
up before the queue manager, the MQCONNX() call will fail.  Retrying
this initial connection will make the application startup more robust.

This makes it easier to have applications recover from queue manager
failures, or that have more robust startup logic, but note that this
retry logic only applies to the initial connection.  Reconnecting at
arbitrary points in the code is far more complex, and it left as a
(painful) exercise to the reader.

=head2 Error Handling

Most methods return a true or false value indicating success of
failure, and internally, they will call the Carp subroutine (either
Carp::Carp, or something user-defined) with a text message indicating
the cause of the failure.

In addition, the most recent MQI Completion and Reason codes will be
available via the CompCode() and Reason() methods:

  $qmgr->CompCode()
  $qmgr->Reason()

When distribution lists are used, then it is possible for a list of
reason codes to be returned by the API.  Normally, these are buried
inside the ObjDesc strucure, but they are also available via the

  $qmgr->Reasons()

method.  In this case, the $queue->Reason() will always return
MQRC_MULTIPLE_REASONS.  The return value of the Reasons() method is an
array reference, and each array item is a hash reference with two
keys: CompCode and Reason.  These correspond, respectively, with the
CompCode and Reason associated with the individual queues in the
distribution list.

For example, the Reason code associated with the 3rd queue in the list
would be:

  $qmgr->Reasons()->[2]->{Reason}

In the case of the constructor new(), which returns nothing when it
fails, these methods are not available.  Most applications will not
need to handle the specific CompCode and Reason when the instantiation
fails, but if necessary, these can be obtained in one of two ways.

The older method, which is supported for backwards compabitility but
strongly discouarged, is to pass references to scalar variables to
new().  See the new() documentation above for more details.

The newer method would be to explicitly call the Open() method, and
error check it yourself.  This will mean that the constructor will now
fail only if there is an error processing the constructor arguments,
as opposed to an error in the MQSeries infrastructure.

Some examples should make this clear.

The simplest way to create an MQSeries::QueueManager object is:

  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager               => 'some.queue.manager',
    ) || die;

But in this case, the connection to the queue manager could fail, and
your application will not be able to determine why.

In order to explicitly have access to the CompCode and Reason one
would do the following:

  my $qmgr = MQSeries::QueueManager->new
    (
     QueueManager               => 'some.queue.manager',
     AutoConnect                => 0,
    ) || die "Unable to instantiate MQSeries::QueueManager object\n";

  # Call the Connect method explicitly
  unless ( $qmgr->Connect() ) {
    die("Connection to queue manager failed\n" .
        "CompCode => " . $qmgr->CompCode() . "\n" .
        "Reason   => " . $qmgr->Reason() . "\n");
  }

=head2 Conversion Precedence

Once you have read all the MQSeries::* documentation, you might be
confused as to how the various PutConvert/GetConvert method arguments
and constructor arguments interact with the MQSeries::Message
PutConvert() and GetConvert() methods.

The following is the precedence of the various places you can specify
a PutConvert or GetConvert subroutine, from highest to lowest:

  [A] Put(), Get(), and Put1() method arguments
  [B] MQSeries::Message PutConvert() and GetConvert() methods
  [C] MQSeries::Queue object defaults (set as arguments to new())
  [C] MQSeries::QueueManager object defaults (set as arguments to new())

The cleanest way to code these is probably (and here your mileage will
vary wildly with your tastes) to implement a subclass of
MQSeries::Message which provides the appropriate GetConvert() and
PutConvert() methods, one seperate class for each type of data
conversion which is necessary.

Then the conversion happens "under the covers" when message objects of
that class are put to or gotten from a queue.

=head1 SEE ALSO

MQSeries(3), MQSeries::Queue(3), MQSeries::Message(3), MQSeries::Properties(3)

=cut
