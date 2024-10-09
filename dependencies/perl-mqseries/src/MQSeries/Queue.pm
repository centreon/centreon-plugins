#
# $Id: Queue.pm,v 37.6 2012/09/26 16:15:19 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Queue;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::QueueManager;
use MQSeries::Properties;
use MQSeries::Utils qw(ConvertUnit);
use Params::Validate qw(validate);

#
# Well, now that we're using the same constants for the Inquire/Set
# interface, they no longer are really part of the Command/PCF
# hierarchy.  We may or may not address this namespace asymmetry in a
# future release.
#
use MQSeries::Command::PCF;

our $VERSION = '1.34';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = validate(@_, { 'Carp'              => 0,
                              'QueueManager'      => 0,
                              'Queue'             => 0,
                              'ObjDesc'           => 0,
                              'DynamicQName'      => 0,
                              'Options'           => 0,
                              'Mode'              => 0,
                              'CompCode'          => 0,
                              'Reason'            => 0,
                              'PutConvert'        => 0,
                              'GetConvert'        => 0,
                              'CloseOptions'      => 0,
                              'RetrySleep'        => 0,
                              'RetryCount'        => 0,
                              'RetryReasons'      => 0,
                              'AutoOpen'          => 0,
                              'DisableAutoResize' => 0,
			      'SelectionString'   => 0,
                            }),

    my %ObjDesc = ();

    #
    # Note -- because we have a ObjDesc method, we'd have to
    # quote the ObjDesc key everywhere, so...
    #
    my $self =
      {
       Options          => MQSeries::MQOO_FAIL_IF_QUIESCING,
       ObjDescPtr       => \%ObjDesc,
       Carp             => \&carp,
       RetryCount       => 0,
       RetrySleep       => 60,
       RetryReasons     => {
                            map { $_ => 1 }
                            (
                             MQSeries::MQRC_OBJECT_IN_USE,
                            )
                           },
       OpenArgs         => {},
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
    # We'll need a Queue Manager, one way or another.
    #
    # NOTE: if nothing is given, then the MQSeries::QueueManager
    # constructor will assume you want the "default" QM.
    #
    if ( ref $args{QueueManager} ) {
        if ( $args{QueueManager}->isa("MQSeries::QueueManager") ) {
            $self->{QueueManager} = $args{QueueManager};
        } else {
            $self->{Carp}->("Invalid argument: 'QueueManager' must be an MQSeries::QueueManager object");
            return;
        }
    } else {
        $self->{QueueManager} = MQSeries::QueueManager->new
          (
           QueueManager                 => $args{QueueManager},
           Carp                         => $self->{Carp},
          )     or return;
    }

    #
    # If the queue manager is MQ v7, set the ObjDesc to version 4.
    # The benefit of this is that, when an Alias queue is opened, the
    # type/name of the resolved queue is returned.  This can be
    # queried with the ObjDesc() method.
    #
    if ($MQSeries::MQ_VERSION >= 7 &&
	defined $self->{QueueManager}->{QMgrConfig} &&
	$self->{QueueManager}->{QMgrConfig}{CommandLevel} >= 700) {
	$self->{ObjDescPtr}{Version} = MQSeries::MQOD_VERSION_4;
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
        } elsif ( ref $self->{QueueManager}->{$key} eq "CODE" ) {
            # 'Inherit' them from the queue manager object
            $self->{$key} = $self->{QueueManager}->{$key};
        }
    }

    #
    # We require (minimally) a Queue name (and yes, "0" is a valid
    # queue name, even if it's a really stupid one)
    #
    if ( defined($args{Queue}) && $args{Queue} ne q{} ) {
        $self->{Queue} = $args{Queue};
        if ( ref $args{Queue} eq "ARRAY" ) {
            # Distribution list
            $self->{ObjDescPtr}->{ObjectRecs} = $args{Queue};
        } else {
            $self->{ObjDescPtr}->{ObjectName} = $args{Queue};
        }
    } elsif ( not $args{ObjDesc} ) {
        $self->{Carp}->("One of 'Queue' or 'ObjDesc' must be specified");
        return;
    }

    #
    # Optionally, if the Queue is a model queue, you'll want to
    # specify the Dynamic Queue name
    #
    if ( $args{DynamicQName} ) {
        $self->{ObjDescPtr}->{DynamicQName} = $args{DynamicQName};
    }

    #
    # If a SelectionString is specified, add it to the ObjDesc, an set
    # the version to MQOD_VERSION_4.
    #
    if ($args{SelectionString}) {
	$self->{ObjDescPtr}->{SelectionString} = $args{SelectionString};
	if (!defined $self->{ObjDescPtr}->{Version} ||
	    $self->{ObjDescPtr}->{Version} < MQSeries::MQOD_VERSION_4) {
	    $self->{ObjDescPtr}->{Version} = MQSeries::MQOD_VERSION_4;
	}
    }

    #
    # You can also pass the close options, which will be used in the
    # Close() method, which is called upon object destruction.
    #
    if ( $args{CloseOptions} ) {
        $self->{CloseOptions} = $args{CloseOptions};
    } else {
        $self->{CloseOptions} = 0;
    }

    #
    # Maximum flexibility.  If you provide the ObjDesc, its a full
    # override, and you have to know what you are doing.
    #
    if ( exists $args{ObjDesc} ) {
        if ( ref $args{ObjDesc} eq "HASH" ) {
            $self->{ObjDescPtr} = $args{ObjDesc};
        } else {
            $self->{Carp}->("Invalid argument: 'ObjDesc' must be a HASH reference");
            return;
        }
    }

    #
    # How are we opening this?  Only one of Options or Mode can be
    # specified.  Actually, cut people some slack here.  If AutoOpen
    # is false, then you might very well be passing Mode or Options to
    # the Open() method
    #
    unless (exists $args{'AutoOpen'} && $args{'AutoOpen'} == 0) {
        if (
            ( exists $args{Options} and exists $args{Mode} )
            or
            ( not exists $args{Options} and not exists $args{Mode} )
           ) {
            $self->{Carp}->("Incompatible arguments: one and only one of 'Options' or 'Mode' must be given");
            return;
        }
    }

    #
    # Optionally disable the automatic message buffer resizing
    #
    if ( $args{DisableAutoResize} ) {
        $self->{DisableAutoResize} = $args{DisableAutoResize};
    }

    #
    # All of these options can be passed to the Open() method, so
    # we'll defer checking them until then.
    #
    foreach my $openarg (qw(Options Mode RetrySleep RetryCount RetryReasons)) {
        next unless exists $args{$openarg};
        $self->{OpenArgs}->{$openarg} = $args{$openarg};
    }

    #
    # By default, we open the queue during the constructor.  This can
    # be turned off (for more detailed error handling) by passing
    # AutoOpen as 0.
    #
    # On failure, we don't return an object, so there's nothing to
    # call CompCode or Reason on.  Scalar references can eb passed to
    # get access to the completion code and reason.
    #
    unless (exists $args{'AutoOpen'} && $args{'AutoOpen'} == 0) {
        my $result = $self->Open();
        foreach my $code ( qw(CompCode Reason) ) {
            if ( ref $args{$code} eq "SCALAR" ) {
                ${ $args{$code} } = $self->{$code};
            }
        }
        return unless $result;
    }

    return $self;
}


sub CompCode {
    my $self = shift;
    return $self->{CompCode};
}


sub PutConvertReason {
    my $self = shift;
    return $self->{"PutConvertReason"};
}


sub GetConvertReason {
    my $self = shift;
    return $self->{"GetConvertReason"};
}


sub Reason {
    my $self = shift;
    return $self->{Reason};
}


sub Reasons {
    my $self = shift;
    return $self->{ObjDesc}->{ResponseRecs};
}


sub Close {
    my $self = shift;
    my (%args) = @_;

    return 1 unless $self->{Hobj};

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    if ( $args{Options} ) {
        $self->{CloseOptions} = $args{Options};
    }

    #
    # No need to call MQCLOSE if we're not connected to MQ
    #
    return if(! defined $self->{QueueManager}->{Hconn});

    MQCLOSE(
            $self->{QueueManager}->{Hconn},
            $self->{Hobj},
            $self->{CloseOptions},
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
                        qq/$self->{QueueManager}->{QueueManager} failed (Reason = $self->{Reason})/);
        return;
    }
}


sub DESTROY {
    my $self = shift;
    $self->Close();
}


#
# The real work is usually done with Put() and Get()
#
sub Put {
    my $self = shift;
    my %args = @_;

    return unless $self->Open();

    $self->{CompCode}         = MQSeries::MQCC_FAILED;
    $self->{Reason}           = MQSeries::MQRC_UNEXPECTED_ERROR;

    my $PutMsgOpts =
      {
       Options                  => MQSeries::MQPMO_FAIL_IF_QUIESCING,
      };

    my $buffer = "";

    unless ( $self->{PutEnable} ) {
        $self->{Carp}->("Put() is disabled; Queue not opened for output");
        return;
    }

    unless ( ref $args{Message} and $args{Message}->isa("MQSeries::Message") )  {
        $self->{Carp}->("Invalid argument: 'Message' must be an MQSeries::Message object");
        return;
    }

    if ( $args{PutMsgOpts} ) {
        unless ( ref $args{PutMsgOpts} eq 'HASH' ) {
            $self->{Carp}->("Invalid PutMsgOpts argument; must be a HASH reference");
            return;
        }

        $PutMsgOpts = $args{PutMsgOpts};
    } else {
        if ( $args{PutMsgRecs} ) {
            $PutMsgOpts->{PutMsgRecs} = $args{PutMsgRecs};
        }
    }

    #
    # Support Sync flag, but check it does not conflict with
    # user-specified PutMsgOpts.
    #
    if (defined $args{Sync}) {
        my $set = MQSeries::MQPMO_SYNCPOINT;
        my $check = MQSeries::MQPMO_NO_SYNCPOINT;
        unless ($args{Sync}) {  # No syncpoint: reverse set/check
            ($set, $check) = ($check, $set);
        }
        if (($PutMsgOpts->{Options} & $check) == $check) {
            confess "Option Sync => $args{Sync} conflicts with PutMsgOptions";
        }
        $PutMsgOpts->{Options} |= $set;
    }

    $self->{"PutConvertReason"} = 0;

    $args{"Message"}->QueueManager($self->{"QueueManager"});
    if ( $args{PutConvert} ) {
        if ( ref $args{PutConvert} ne "CODE" ) {
            $self->{Carp}->("Invalid argument: 'PutConvert' must be a CODE reference");
            return;
        } else {
            $buffer = $args{PutConvert}->($args{Message}->Data());
            unless ( defined $buffer ) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed");
                return;
            }
        }
    } else {
        if ( $args{Message}->can("PutConvert") ) {
            $buffer = $args{Message}->PutConvert($args{Message}->Data());
            unless ( defined $buffer ) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed");
                return;
            }
        } elsif ( ref $self->{PutConvert} eq "CODE" ) {
            $buffer = $self->{PutConvert}->($args{Message}->Data());
            unless ( defined $buffer ) {
                $self->{"PutConvertReason"} = 1;
                $self->{Carp}->("Data conversion hook (PutConvert) failed");
                return;
            }
        } else {
            $buffer = $args{Message}->Data();
        }
    }
    $args{"Message"}->QueueManager(undef);

    #
    # If the user specifies a Properties parameter, it must be a hash
    # reference or an MQSeries::Properties object.  This ignores any
    # existing message-level properties object.
    #
    my $props_obj;		# Scope must extend past MQPUT
    if (defined $args{Properties}) {
	my $props = $args{Properties};
	if (ref $props eq 'HASH') {
	    $props_obj = MQSeries::Properties::->
	      new('QueueManager' => $self->{QueueManager});
	    while (my ($name, $value) = each %$props) {
		if (ref $value) {  # Assume hash-ref
		    $props_obj->SetProperty(%$value, 'Name' => $name);
		} else {	# String
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

    MQPUT(
	  $self->{QueueManager}->{Hconn},
	  $self->{Hobj},
	  $args{Message}->MsgDesc(),
	  $PutMsgOpts,
	  $buffer,
	  $self->{CompCode},
	  $self->{Reason},
	 );

    if ( $self->{CompCode} == MQSeries::MQCC_FAILED ) {
        $self->{Carp}->(qq/MQPUT failed (Reason = $self->{Reason})/);
        return;
    } else {

        if ( $PutMsgOpts->{Options} & MQSeries::MQPMO_SYNCPOINT ) {
            $self->{QueueManager}->{_Pending}->{Put}++;
        }

        if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
            return 1;
        } elsif ( $self->{CompCode} == MQSeries::MQCC_WARNING ) {
            # What do we do here?  These are 'partial' successes.
            return -1;
        }

    }
}


#
# Get a message from a queue.   This returns with three-values logic:
#   1: successfully read
#   0: failure (see $queue->Reason())
#  -1: no message available
#
# Hash with named parameters:
# - Message: MQSeries::Message object
# - Sync: syncpoint (boolean; default: 0)
# - Wait: wait interval (1/1000 second; strings with 's' and 'm' supported)
# - GetMsgOpts: ref to hash with get-message options
# - GetConvert: ref to get-conversion function
# - Convert: message conversion (boolean; default: 1)
# - DisableAutoResize
#
sub Get {
    my $self = shift;
    my %args = validate(@_, { 'Convert'           => 0,
                              'DisableAutoResize' => 0,
                              'GetConvert'        => 0,
                              'GetMsgOpts'        => 0,
                              'Message'           => 0,
                              'Sync'              => 0,
                              'Wait'              => 0,
                            });

    return unless $self->Open();

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my $GetMsgOpts = {};

    unless ( $self->{GetEnable} ) {
        $self->{Carp}->("Get() is disabled; Queue not opened for input");
        return;
    }

    unless (ref $args{Message} and $args{Message}->isa("MQSeries::Message")) {
        $self->{Carp}->("Invalid argument: 'Message' must be an MQSeries::Message object");
        return;
    }

    #
    # Allow user to set get-message options, but still
    # add in Wait/Convert/Sync later.
    #
    if ($args{GetMsgOpts}) {
        unless (ref $args{GetMsgOpts} eq 'HASH') {
            $self->{Carp}->("Invalid GetMsgOpts argument; must be a HASH reference");
            return;
        }

        $GetMsgOpts = $args{GetMsgOpts};
    }

    my $options_flag = $GetMsgOpts->{Options}  ||
      MQSeries::MQGMO_FAIL_IF_QUIESCING;

    if (defined $args{Convert}) {
        if ($args{Convert}) {
            $options_flag |= MQSeries::MQGMO_CONVERT;
        } else {                # Possibly override GetMsgOpts
            $options_flag &= (~MQSeries::MQGMO_CONVERT);
        }
    } else {                    # Default = convert
        $options_flag |= MQSeries::MQGMO_CONVERT;
    }

    if (defined $args{Sync}) {  # Compare against GetMsgOptions, if specified
        my @check;
        if ($args{Sync}) {
            @check = (MQSeries::MQGMO_NO_SYNCPOINT,
                      MQSeries::MQGMO_SYNCPOINT_IF_PERSISTENT);
            $options_flag |= MQSeries::MQGMO_SYNCPOINT;
        } else {
            @check = (MQSeries::MQGMO_SYNCPOINT,
                      MQSeries::MQGMO_SYNCPOINT_IF_PERSISTENT);
        }
        foreach my $opt (@check) {
            if (($options_flag & $opt) == $opt) {
                confess "GetMsgOptions specifies a syncpoint option not compatible with 'Sync' => $args{Sync}";
            }
        }
    }

    if (exists $args{Wait}) {
        my $value = ConvertUnit('Wait', $args{'Wait'});
        if ($value == 0) {
            $options_flag &= (~MQSeries::MQGMO_WAIT);
            $options_flag |= MQSeries::MQGMO_NO_WAIT; # No-op: NO_WAIT = zero
        } elsif ($value == -1) {
            $options_flag |= MQSeries::MQGMO_WAIT;
            $GetMsgOpts->{WaitInterval} = MQSeries::MQWI_UNLIMITED;
        } else {
            $options_flag |= MQSeries::MQGMO_WAIT;
            $GetMsgOpts->{WaitInterval} = $value;
        }
    } else {
        $options_flag |= MQSeries::MQGMO_NO_WAIT; # No-op: NO_WAIT = zero
    }
    $GetMsgOpts->{Options} = $options_flag;

    if ($args{GetConvert} && ref $args{GetConvert} ne "CODE") {
        $self->{Carp}->("Invalid argument: 'GetConvert' must be a CODE reference");
        return;
    }

    #
    # If compiled for MQ v7 and connected to a V7 queue manager, make
    # sure the message has a properties object, and specify it for the
    # GetMsgOpts.
    #
    if ($MQSeries::MQ_VERSION >= 7 &&
	defined $self->{QueueManager}->{QMgrConfig} &&
	$self->{QueueManager}->{QMgrConfig}{CommandLevel} >= 700) {
	my $props_obj = $args{Message}->Properties();
	unless (defined $props_obj) {
	    $props_obj = MQSeries::Properties::->
	      new('QueueManager' => $self->{QueueManager});
	    $args{Message}->Properties($props_obj);
	}
	if (!defined $GetMsgOpts->{Version} ||
	    $GetMsgOpts->{Version} < MQSeries::MQGMO_VERSION_4) {
	    $GetMsgOpts->{Version} = MQSeries::MQGMO_VERSION_4;
	}
	$GetMsgOpts->{MsgHandle} = $props_obj->{Hmsg};
    } else {
	#print "Not compiled for V7 and connected to V7, ignoring properties\n";
    }

    #
    # This flag is used to prevent the redo logic from looping.  We
    # want to handle MQRC_TRUNCATED_MSG_FAILED retries exactly once
    # for the same message.
    #
    # If DisableAutoResize is given as either an argument to the
    # object constructor, *or* to the Get method call, then this will
    # effectively disable the redo logic.
    #
    # However, the redo issue is more complex than you'd hope: if we
    # have to issue a re-read, we have to do so with the original
    # MQMD, as the encoding or the message we just read partially may
    # screw us up on a re-read.  And in the meantime, somebody else
    # may take that message away from us...
    #
    my $retry_allowed = not($self->{DisableAutoResize} ||
                            $args{DisableAutoResize});
    my $retry_msgid = '';       # Msg id of message in retry
    my %orig_mqmd = %{ $args{Message}->MsgDesc() }; # Deep copy

    while (1) {
        $self->{"GetConvertReason"} = 0;

        my $data = undef;
        my $datalength = $args{Message}->BufferLength();

        my $buffer = MQGET(
                           $self->{QueueManager}->{Hconn},
                           $self->{Hobj},
                           $args{Message}->MsgDesc(),
                           $GetMsgOpts,
                           $datalength,
                           $self->{CompCode},
                           $self->{Reason},
                          );

        #
        # We attempt the data conversion hook if we accepted a
        # truncated message.  Note that it may very well fail, but
        # we'll try anyway.
        #
        if ($self->{CompCode} == MQSeries::MQCC_OK ||
            (
             $self->{CompCode} == MQSeries::MQCC_WARNING &&
             $self->{Reason} == MQSeries::MQRC_TRUNCATED_MSG_ACCEPTED
            ) ||
            (
             $self->{CompCode} == MQSeries::MQCC_WARNING &&
             $self->{Reason} == MQSeries::MQRC_FORMAT_ERROR &&
             $args{Message}->MsgDesc('Format') eq MQSeries::MQFMT_NONE
            )) {                # Successful read

            if ($GetMsgOpts->{Options} & MQSeries::MQGMO_SYNCPOINT ||
                (
                 $GetMsgOpts->{Options} & MQSeries::MQGMO_SYNCPOINT_IF_PERSISTENT &&
                 $args{Message}->MsgDesc('Persistence')
                )) {
                $self->{QueueManager}->{_Pending}->{Get}++;
            }

            if ( $args{GetConvert} ) {
                $data = $args{GetConvert}->($buffer);
                unless ( defined $data ) {
                    $self->{"GetConvertReason"} = 1;
                    $self->{Carp}->("Data conversion hook (GetConvert) failed");
                    return;
                }
            } else {
                if ($args{Message}->can("GetConvert") ) {
                    $data = $args{Message}->GetConvert($buffer);
                    unless ( defined $data ) {
                        $self->{"GetConvertReason"} = 1;
                        $self->{Carp}->("Data conversion hook (GetConvert) failed");
                        return;
                    }
                } elsif ( ref $self->{GetConvert} eq "CODE" ) {
                    $data = $self->{GetConvert}->($buffer);
                    unless ( defined $data ) {
                        $self->{"GetConvertReason"} = 1;
                        $self->{Carp}->("Data conversion hook (GetConvert) failed");
                        return;
                    }
                } else {
                    $data = $buffer;
                }
            }

            $args{Message}->Data($data);

            return 1;

        } elsif ( $self->{CompCode} == MQSeries::MQCC_WARNING ) {

            if ( $self->{Reason} == MQSeries::MQRC_TRUNCATED_MSG_FAILED
                 and $retry_allowed ) {
                #
                # FIXME: Maybe add some buffer poker-space
                #
                $args{Message}->BufferLength($datalength);
                $retry_msgid = $args{Message}->MsgDesc('MsgId');
                $args{Message}{'MsgDesc'} = { %orig_mqmd,
                                              'MsgId' => $retry_msgid,
                                            };
                next;           # Retry
            } else {
                #
                # Make buffer available, even though it may be garbage.
                # If the app chooses to ignore MQCC_WARNING, it may
                # be of use to it.
                #
                $args{Message}->Data($buffer) if ($buffer);
                $self->{Carp}->(qq/MQGET failed (Reason = $self->{Reason})/);
                return;
            }

        } else {
            if ( $self->{Reason} == MQSeries::MQRC_NO_MSG_AVAILABLE ) {
                #
                # If we are in a retry, somebody else beat us to the
                # message.  Retry for a fresh message...
                #
                if ($retry_msgid) { # In retry - clean up
                    $retry_msgid = '';
                    $args{Message}{'MsgDesc'} = { %orig_mqmd };
                    next;
                }

                return -1;
            } else {
                $self->{Carp}->(qq/MQGET failed (Reason = $self->{Reason})/);
                return;
            }
        }
    }                           # End while

    #
    # NOTREACHED
    #
}


#
# Return the queue manager object used for this queue
#
sub QueueManager {
    my ($self) = @_;

    return $self->{'QueueManager'};
}


sub Inquire {
    my $self = shift;
    my (@args) = @_;

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my (@keys) = ();

    my $ForwardMap = $MQSeries::Command::PCF::RequestValues{Queue};
    my $ReverseMap = $MQSeries::Command::PCF::_Responses{MQSeries::MQCMD_INQUIRE_Q}->[1];

    foreach my $key ( @args ) {

        unless ( exists $ForwardMap->{$key} ) {
            $self->{Carp}->("Unrecognized Queue attribute: '$key'");
            return;
        }

        push(@keys,$ForwardMap->{$key});

    }

    my (@values) = MQINQ(
                         $self->{QueueManager}->{Hconn},
                         $self->{Hobj},
                         $self->{CompCode},
                         $self->{Reason},
                         @keys,
                        );

    unless ( $self->{CompCode} == MQSeries::MQCC_OK && $self->{Reason} == MQSeries::MQRC_NONE ) {
        $self->{Carp}->("MQINQ call failed. " .
                        qq(CompCode => '$self->{CompCode}', ) .
                        qq(Reason => '$self->{Reason}'\n));
        return;
    }

    # In case the data parsing fails...
    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my (%values) = ();

    for ( my $index = 0 ; $index <= $#keys ; $index++ ) {

        my ($key,$value) = ($keys[$index],$values[$index]);

        my ($newkey,$ValueMap) = @{$ReverseMap->{$key}};

        if ( $ValueMap ) {
            unless ( exists $ValueMap->{$value} ) {
                $self->{Carp}->("Unrecognized value '$value' for key '$newkey'\n");
                return;
            }
            $values{$newkey} = $ValueMap->{$value};
        } else {
            $values{$newkey} = $value;
        }

    }

    $self->{CompCode} = MQSeries::MQCC_OK;
    $self->{Reason} = MQSeries::MQRC_NONE;

    return %values;
}


sub Set {
    my $self = shift;
    my (%args) = @_;

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my (%keys) = ();

    my $ForwardMap = $MQSeries::Command::PCF::RequestParameters{Queue};

    foreach my $key ( keys %args ) {

        my $value = $args{$key};

        unless ( exists $ForwardMap->{$key} ) {
            $self->{Carp}->("Unrecognized Queue attribute: '$key'");
            return;
        }

        my ($newkey,$ValueMap) = @{$ForwardMap->{$key}}[0,2];

        if ( $ValueMap ) {
            unless ( exists $ValueMap->{$value} ) {
                $self->{Carp}->("Unrecognized Queue attribute value '$value' for key '$key'\n");
                return;
            }
            $keys{$newkey} = $ValueMap->{$value};
        } else {
            $keys{$newkey} = $value;
        }

    }

    MQSET(
          $self->{QueueManager}->{Hconn},
          $self->{Hobj},
          $self->{CompCode},
          $self->{Reason},
          %keys,
         );

    unless ( $self->{CompCode} == MQSeries::MQCC_OK && $self->{Reason} == MQSeries::MQRC_NONE ) {
        $self->{Carp}->("MQSET call failed. " .
                        qq/CompCode => '$self->{CompCode}', / .
                        qq/Reason => '$self->{Reason}'\n/);
        return;
    }

    return 1;
}


#
# Unlike *most* of these methods (here, and in most other code), this
# returns a hard reference to the entire hash
#
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


sub Open {
    my $self = shift;
    my @combined_params = ( %{$self->{OpenArgs}}, @_ );
    my %args = validate(@combined_params,
                        { 'Mode'         => 0,
                          'Options'      => 0,
                          'RetryCount'   => 0,
                          'RetrySleep'   => 0,
                          'RetryReasons' => 0,
                        });

    return 1 if $self->{Hobj};

    $self->{CompCode} = MQSeries::MQCC_FAILED;
    $self->{Reason} = MQSeries::MQRC_UNEXPECTED_ERROR;

    my $retrycount = 0;

    if ( exists $args{Options} and exists $args{Mode} ) {
        $self->{Carp}->("Incompatible arguments: one and only one of 'Options' or 'Mode' must be given");
        return;
    }

    #
    # If the options are given, we assume you know what you're doing.
    #
    if ( exists $args{Options} ) {
        $self->{Options} = $args{Options};
        # And, we'll let the MQI whine at you if you misuse it.
        $self->{GetEnable} = 1;
        $self->{PutEnable} = 1;
    }

    #
    # If the Mode is given, then we have a few defaults to choose from
    #
    if ( exists $args{Mode} ) {
        if ( $args{Mode} eq 'input' ) {
            $self->{Options} |= MQSeries::MQOO_INPUT_AS_Q_DEF;
            $self->{GetEnable} = 1;
        } elsif ( $args{Mode} eq 'input_exclusive' ) {
            $self->{Options} |= MQSeries::MQOO_INPUT_EXCLUSIVE;
            $self->{GetEnable} = 1;
        } elsif ( $args{Mode} eq 'input_shared' ) {
            $self->{Options} |= MQSeries::MQOO_INPUT_SHARED;
            $self->{GetEnable} = 1;
        } elsif ( $args{Mode} eq 'output' ) {
            $self->{Options} |= MQSeries::MQOO_OUTPUT;
            $self->{PutEnable} = 1;
        } else {
            $self->{Carp}->("Invalid argument: 'Mode' value $args{Mode} not yet supported");
            return;
        }
    }

    #
    # The Retry options...
    #
    foreach my $key ( qw( RetryCount RetrySleep ) ) {
        if ( exists $args{$key} ) {
            unless ( $args{$key} =~ /^\d+$/ ) {
                $self->{Carp}->("Invalid Argument: '$key' must be numeric");
                return;
            }
            $self->{$key} = $args{$key};
        }
    }

    if ( $args{RetryReasons} ) {
        unless (
                ref $args{RetryReasons} eq "ARRAY" ||
                ref $args{RetryReasons} eq "HASH"
               ) {
            $self->{Carp}->("Invalid Argument: 'RetryReasons' must be an ARRAY or HASh reference");
            return;
        }

        if ( ref $args{RetryReasons} eq 'HASH' ) {
            $self->{RetryReasons} = $args{RetryReasons};
        } else {
            $self->{RetryReasons} = { map { $_ => 1 } @{$args{RetryReasons}} };
        }
    }

  OPEN:
    {
        #
        # Open the Queue
        #
        my $Hobj = MQOPEN(
                          $self->{QueueManager}->{Hconn},
                          $self->{ObjDescPtr},
                          $self->{Options},
                          $self->{CompCode},
                          $self->{Reason},
                         );

        if ( $self->{CompCode} == MQSeries::MQCC_OK ) {
            $self->{Hobj} = $Hobj;
            return 1;
        } elsif ( $self->{CompCode} == MQSeries::MQCC_WARNING ) {
            # This is when Reason == MQRC_MULTIPLE_REASONS
            $self->{Hobj} = $Hobj;
            return -1;
        } elsif ( $self->{CompCode} == MQSeries::MQCC_FAILED ) {

            if ( exists $self->{RetryReasons}->{$self->{Reason}} ) {
                if ( $retrycount < $self->{RetryCount} ) {
                    $retrycount++;
                    $self->{Carp}->(qq/MQOPEN failed (Reason = $self->{Reason}), will sleep / .
                                    "$self->{RetrySleep} seconds and retry...");
                    sleep $self->{RetrySleep};
                    redo OPEN;
                } else {
                    $self->{Carp}->(qq/MQOPEN failed (Reason = $self->{Reason}), retry timed out/);
                    return;
                }
            } else {
                $self->{Carp}->(qq/MQOPEN failed (Reason = $self->{Reason}), not retrying./);
                return;
            }

        } else {
            $self->{Carp}->(qq/MQOPEN failed, unrecognized CompCode: '$self->{CompCode}'/);
            return;
        }
    }
}


1;

__END__

=head1 NAME

MQSeries::Queue -- OO interface to the MQSeries Queue objects

=head1 SYNOPSIS

  use MQSeries qw(:functions);
  use MQSeries::QueueManager;
  use MQSeries::Queue;
  use MQSeries::Message;

  #
  # Open a queue for input, loop getting messages, updating some
  # database with the data.
  #
  my $qmgr_obj = MQSeries::QueueManager->
    new(QueueManager => 'some.queue.manager');
  my $queue = MQSeries::Queue->
    new(QueueManager => $qmgr_obj,
        Queue        => 'SOME.QUEUE',
        Mode         => 'input_exclusive',
       ) or die("Unable to open queue.\n");

  while (1) {
    my $getmessage = MQSeries::Message->new();

    $queue->
      Get(Message => $getmessage,
          Sync    => 1,
         ) or die("Unable to get message\n" .
                  "CompCode = " . $queue->CompCode() . "\n" .
                  "Reason = " . $queue->Reason() . "\n");

    if ( UpdateSomeDatabase($getmessage->Data()) ) {
        $qmgr_obj->Commit()
          or die("Unable to commit changes to queue.\n" .
                 "CompCode = " . $queue->CompCode() . "\n" .
                 "Reason = " . $queue->Reason() . "\n");
    } else {
        $qmgr_obj->Backout()
          or die("Unable to backout changes to queue.\n" .
                 "CompCode = " . $queue->CompCode() . "\n" .
                 "Reason = " . $queue->Reason() . "\n");
    }
  }

  #
  # Put a message into the queue, using Storable to allow use of
  # references as message data. (NOTE: this is done for you if use the
  # MQSeries::Message::Storable class.)
  #
  use Storable;
  my $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              => 'SOME.QUEUE',
     Mode               => 'output',
     PutConvert         => \&Storable::nfreeze,
     GetConvert         => \&Storable::thaw,
    )
    or die("Unable to open queue.\n");

  my $putmessage = MQSeries::Message->new
    (
     Data => {
              a => [qw( b c d )],
              e => {
                    f => "Huh?",
                    g => "Wow!",
                   },
              h => 42,
             },
    );

  $queue->Put( Message => $putmessage )
    or die("Unable to put message onto queue.\n" .
           "CompCode = " . $queue->CompCode() . "\n" .
           "Reason = " . $queue->Reason() . "\n");

  #
  # Alternate mechanism for specifying the conversion routines.
  #
  my $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              => 'SOME.QUEUE',
     Mode               => 'output',
    )
    or die("Unable to open queue.\n");

  my $putmessage = MQSeries::Message->new
    (
     Data => {
              a => [qw( b c d )],
              e => {
                    f => "Huh?",
                    g => "Wow!",
                   },
              h => 42,
             },
    );

  $queue->Put(Message    => $putmessage
              PutConvert => \&Storable::freeze,
             )
    or die("Unable to put message onto queue.\n" .
           "CompCode = " . $queue->CompCode() . "\n" .
           "Reason = " . $queue->Reason() . "\n");

=head1 DESCRIPTION

The C<MQSeries::Queue> object is an OO mechanism for opening MQSeries
Queues, and putting and getting messages from those queues, with an
interface which is much simpler than the full MQI.

This module is used together with C<MQSeries::QueueManager>,
C<MQSeries::Message> and C<MQSeries::Properties>.  These objects
provide a subset of the MQI, with a simpler interface.

The primary value added by this interface is logic to retry the
connection under certain failure conditions.  Basically, any Reason
Code which represents a transient condition, such as a Queue Manager
shutting down, or a connection lost (possible due to a network
glitch?), will result in the MQCONN call being retried, after a short
sleep.  See below for how to tune this behavior.

This is intended to allow developers to write MQSeries applications
which recover from short term outages without intervention.  This
behavior is critically important to the authors applications, but may
not be right for yours.

=head1 METHODS

=head2 new

The arguments to the constructor are a hash, with the following
key/value pairs (required keys are marked with a '*'):

  Key                           Value
  ===                           =====
  QueueManager                  MQSeries::QueueManager object
  Queue*                        String, or ARRAY reference (distribution list)
  Mode*                         String
  Options*                      MQOPEN 'Options' values
  CloseOptions                  MQCLOSE 'Options' values
  DynamicQName                  String
  DisableAutoResize             Boolean
  AutoOpen                      Boolean
  ObjDesc                       HASH Reference
  Carp                          CODE Reference
  PutConvert                    CODE Reference
  GetConvert                    CODE Reference
  CompCode                      Reference to Scalar Variable
  Reason                        Reference to Scalar Variable
  RetrySleep                    Numeric
  RetryCount                    Numeric
  RetryReasons                  HASH Reference
  SelectionString               String (MQ v7)

NOTE: Only B<one> or the 'Options' or 'Mode' keys can be specified.
They are mutually exclusive.  If 'AutoOpen' is given, then both
'Options' and 'Mode' are optional, as they can be passed directly to
the Open() method.

=over 4

=item QueueManager

The Queue Manager to connect to must be specified, unless you want to
connect to the "default" queue manager, and your site supports such a
configuration.

This can either be an C<MQSeries::QueueManager> object, or the name of
the Queue Manager.  Specifying the queue manager name is deprecated
and will stop working in a future release.

=item Queue

The name of the Queue obviously must be specified.  This can be either
a plain ASCII string, indicating a single queue, or an ARRAY
reference, indicating a distribution list.  There are three ways to
specify the list.

The list may be a simple array of strings:

  $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              => [qw( QUEUE1 QUEUE2 QUEUE3 )],
    )

or, it can be an array of arrays, each one specifying the queue and
queue manager name of the target queue:

  $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              => [
                            [qw( QUEUE1 QM1 )],
                            [qw( QUEUE2 QM2 )],
                            [qw( QUEUE3 QM3 )],
                           ],
    )

or finally, it can be an array of hash references, each naming the
queue and queue manager:

  $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              =>
     [
      {
       ObjectName       => 'QUEUE1',
       ObjectQMgrName   => 'QM1',
      },
      {
       ObjectName       => 'QUEUE2',
       ObjectQMgrName   => 'QM2',
      },
      {
       ObjectName       => 'QUEUE3',
       ObjectQMgrName   => 'QM3',
      },
     ],
    )

In the latter two cases, the queue manager names are optional.  Which
method to use is largely a choice of style.

=item Mode

If the B<Mode> key is specified, then the B<Options> key may B<NOT> be
specified.  These are mutually exclusive.

The B<Mode> is a shorthand for opening the Queue for output or input,
without requiring the developer to work with the Options flags
directly.  The mode may have one of the following values, which
implies the Options shown.

  Mode Value       Equivalent MQOPEN Options
  ==========       =========================
  input            MQOO_INPUT_AS_Q_DEF | MQOO_FAIL_IF_QUIESCING
  input_shared     MQOO_INPUT_SHARED | MQOO_FAIL_IF_QUIESCING
  input_exclusive  MQOO_INPUT_EXCLUSIVE | MQOO_FAIL_IF_QUIESCING
  output           MQOO_OUTPUT | MQOO_FAIL_IF_QUIESCING

=item Options

If the B<Options> key is specified, then the B<Mode> key may B<NOT> be
specified.  These are mutually exclusive.  This is a used as-is as the
Options field in the MQOPEN call.  Refer to the MQI documentation on
MQOPEN() for more details.

=item CloseOptions

This option allows you to specify the MQCLOSE() Options to be used
when the perl object destructor closes the queue for you.  Since there
are many close options to begin with, this is primarily useful for
creating Permanent Dynamic queues that you want to automatically
destroy when you are finished with them.

The value specified here will be passed directly to the MQCLOSE()
call, so it should be specified as:

        CloseOptions    => MQSeries::MQCO_DELETE_PURGE,

for example.

=item DynamicQName

This is the template string to use when opening a dynamic queue.  This
is only relevant is the Queue specified is a model queue.  Normally,
this would be some kind of string ending in a '*', resulting in a
unique queue name for the application.

=item DisableAutoResize

This is a Boolean value, which if true, will disable the automatic
resizing of the message buffer when it is either truncated, or the
converted message will not fit.

See the Get() method documentation for more information.

=item AutoOpen

This is an optional parameter that defaults to true.  If the value of
this argument is false, then the constructor will not implicitly call
the C<Open()> method, thus requiring the application to call it
itself.  This allows for more fine-grained error checking, since the
constructur will then fail only if there is a problem parsing the
constructor arguments.  The subsequent call to C<Open()> can be error
checked independently of the C<new()> constructor.

=item ObjDesc

The value of this key is a hash reference which sets the key/values of
the ObjDesc structure.  See the "MQSeries Application Programming
Reference" documentation for the possible keys and values of the MQOD
structure.

Also, see the examples section for specific usage of this feature.
This is one area of the API which is not easily hidden; you have to
know what you are doing.

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

  my $queue = MQSeries::Queue->new
    (
     QueueManager       => $qmgr_obj,
     Queue              => 'SOME.QUEUE',
     Carp               => \&MyLogger,
    ) or die("Unable to connect to queue manager.\n");

The default, as one might guess, is Carp::carp();

=item PutConvert, GetConvert

These are CODE references to subroutines which are used to convert the
data in a MQSeries::Message object prior to passing it to the MQPUT
MQI call, or convert the data retrieved from the queue by the MQGET
MQI call before inserting it into a MQSeries::Message object.

See the MQSeries::QueueManager documentation for details on the
calling and error handling syntax of these subroutines, as well as an
example using Storable.pm to pass perl references around in MQSeries
messages.

If this key is not specified, then the MQSeries::Queue objects will
inherit these CODE references from the MQSeries::QueueManager object.
If the QueueManager key was given as a name, and not an object, then
no conversion is performed.

Note that these can be overridden for individual Put() or Get() calls,
if necessary for a single message, just as PutConvert can be
overridden for a single Put1() call (see MQSeries::QueueManager docs).

Also, note that to disable these for a single message, or a single
queue, one would simply pass a function that returns its first
argument.

  PutConvert => sub { return $_[0]; },
  GetConvert => sub { return $_[0]; },

See also the section "CONVERSION PRECEDENCE" in the
MQSeries::QueueManager documentation.

=item CompCode, Reason

When the constructor encounters an error, it returns nothing, and you
can not make method calls off of a non-existent object.  Thus, you do
not have access to the CompCode() and Reason() method calls.  If you
want to extract these values, you will have to pass a scalar reference
value to the constructor, for example:

  my $CompCode = MQCC_FAILED;
  my $Reason = MQRC_UNEXPECTED_ERROR;

  my $queue = MQSeries::Queue->new
    (
     QueueManager               => $qmgr_obj,
     Queue                      => 'SOME,QUEUE',
     CompCode                   => \$CompCode,
     Reason                     => \$Reason,
    ) || die "Unable to open queue: CompCode => $CompCode, Reason => $Reason\n";

But, this is ugly (authors opinion, but then, he gets to write the
docs, too).

NOTE: If you let the MQSeries::Queue object implicitly create the
MQSeries::QueueManager object, and that fails, you will B<NOT> get the
CompCode/Reason values which resulted.  This is intentional.  If you
want this level of granularity, then instantiante the
MQSeries::QueueManager object yourself, and pass it to the
MQSeries::Queue constructor.

See the ERROR HANDLING section as well.

=item RetryCount

The call to MQOPEN() (implemented via the Open() method), can be told
to retry the failure for a specific list of reason codes.  This
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

=item SelectionString

This parameter is only supported if the module has been compiled with
the MQ v7 libraries.  It specifies the selector, which means the Get
method will only return messages with matching properties.  See the
documentation for the C<MQSeries::Properties> class for more details
on message properties.

=back

=head2 Open

This method will accept the following arguments which can be passed to
the constructor (new()), and it merely calls Open() to open the actual
queue object.

  Key                           Value
  ===                           =====
  Mode                          String
  Options                       MQOPEN 'Options' values
  RetrySleep                    Numeric
  RetryCount                    Numeric
  RetryReasons                  HASH Reference

This method is called automatically by the constructor, unless the
C<AutoOpen> argument is given.

Note that this is a new method as of the 1.06 release, and is provided
to enable more fine grained error checking.  See the ERROR HANDLING
section.

=head2 Close

The arguments to this method are a hash of key/value pairs, and
currently only one key is supported: "Options".  The value is the
Options argument to MQCLOSE().  This will override the "CloseOptions"
passed to the constructor.  This method merely calls MQCLOSE() to
close the actual queue object.

It is important to note that normally, this method need not be called,
since it is implicitly called via the object destructor.  If the
Close() call errors need to be handled, then it can be done
explicitly.  See the ERROR HANDLING section.

=head2 Put

This method wraps the MQPUT call.  The arguments are a hash, with the
following key/value pairs (required keys are marked with a '*'):

  Key         Value
  ===         =====
  Message*    MQSeries::Message object
  PutMsgOpts  HASH Reference
  PutMsgRecs  ARRAY Reference
  Sync        Boolean
  PutConvert  CODE Reference
  Properties  HASH Reference or MQSeries::Properties object

The return value is true or false, depending on the success of the
underlying MQPUT() call.  If the operation fails, then the Reason()
and CompCode() methods will return the appropriate error codes, if the
error was an MQSeries error.

If a PutConvert() method failed before the actual MQPUT() function
was called, then the Reason() code will be MQRC_UNEXPECTED_ERROR, and
the PutConvertReason() will be true.  All of the PutConvert() methods
supplied with the various MQSeries::Message subclasses in this
distribution will generate some form of error via carp (or the Carp
attribute of the objects, if overridden).

=over 4

=item Message

This argument is the message to be placed onto the queue.  The value
must be an MQSeries::Message object.

=item PutMsgOpts

This option allows the programmer complete control over the PutMsgOpts
structure passed to the MQPUT() call.  This may conflict with the
'Sync' option; see below.

The default options specified by the OO API are

  MQGMO_FAIL_IF_QUIESCING

See the MQPUT() documentation for the use of PutMsgOpts.

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
and the message(s) not committed to the queue until an MQBACK, MQCOMM
or MQDISC call is made.  These are both wrapped with the queue manager
Backout(), Commit() and Disconnect() methods respectively.

The value is simply interpreted as true or false.

If the C<Sync> option is combined with the C<PutMsgOpts> option, the
C<Options> field in the C<PutMsgOpts> is checked for compatibility.
If the C<Sync> flag is true and the C<PutMsgOpts> specifies
MQseries::MQPMO_NO_SYNCPOINT, or vice versa, a fatal error is raised.
If no conflict exists, the C<Sync> flag amends the C<PutMsgOpts>.

=item PutConvert

This is a means of overriding the PutConvert routine specified for the
MQSeries::Queue object, for a single Put.  See the new() documentation
for more details.

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

=head2 Get

This method wraps the MQGET call.  The arguments are a hash, with the
following key/value pairs (required keys are marked with a '*'):

    Key                Value
    ===                =====
    Message*           MQSeries::Message object
    GetMsgOpts         HASH Reference
    Wait               Numeric Value
    Sync               Boolean
    DisableAutoResize  Boolean
    GetConvert         CODE Reference
    Convert            Boolean (default: 1)

The return value of Get() is either 1, 0 or -1.  Success or failure
can still be interpreted in a Boolean context, with the following
caveat.  A value of 1 is returned when a message was successfully
retrieved from the queue.  A value of 0 is returned if some form of
error was encountered.  A value of -1 is returned when no message was
retrieved, but the MQGET call failed with a Reason Code of
"MQRC_NO_MSG_AVAILABLE".

The last condition (-1) may or may not be an error, depending on your
application.  This merely indicates that a message matching the
specified MsgDesc criteria was not found, or perhaps the queue was
just empty.  You have to decide how to handle this.

The return value of 0 may indicate an error in either the MQSeries
call itself, or if applicable, the failure of any GetConvert() method
called after a successful MQGET() call.  In this case, the
GetConvertReason() should be checked, as this error may indicate an
invalid or improperly formatted message.  This is akin to an error
encountered while parsing the body of the message.

By default, the Get() method will also handle the message buffer size
being too small for one very specific case.

Reason == MQRC_TRUNCATED_MSG_FAILED

In this case, the BufferLength of the Message object is reset to the
DataLength value returned by the MQGET() call, and the MQGET() call is
redone.

Note that this functionality can be disabled, if not desired, by
specifying DisableAutoResize as an argument to either the
MQSeries::Queue->new() constructor or the Get() method.

=over 4

=item Message

This argument is the MQSeries::Message object into which the message
extracted from the queue is placed.  This can be a 'raw'
MQSeries::Message, or it can be one with the MsgId, or some other key
in the MsgDesc explicitly specified, in order to retrieve a specific
message.  See MQSeries::Message documentation for more details.

=item GetMsgOpts

This option allows the programmer complete control over the GetMsgOpts
structure passed to the MQGET() call.  If this option is specified,
then the C<Sync>, C<Wait> and C<Convert> options may modify the
'Options' field in the get-message options or raise a fatal error; see
below.

The default options specified by the OO API are

  MQGMO_FAIL_IF_QUIESCING
  MQGMO_CONVERT

See the MQGET() documentation for the use of GetMsgOpts.

=item Wait

This is a numeric or symbolic value, interpreted as follows.  A
symbolic value is a number ending on 's' for seconds or 'm' for
minutes, which will be converted to the appropriate numeric value.
If the value is greater than zero, then the MQGMO_WAIT option is used,
and the value is set as the WaitInterval in the GetMsgOpts structure.

Remember, if a numeric value is specified, it is interpreted by the
API as a number of milliseconds, not seconds (the rest of the OO-API
uses seconds).  Therefore, a symbolic value like "30s" or "2m"
is preferred.

If the value is 0, then the MQGMO_NO_WAIT option is used.

If the value is -1, then the MQGMO_WAIT option is used, and the
WaitInterval is set to MQWI_UNLIMITED, meaning the MQGET call will
block until a message appears on the queue.

The default is 0, the same as the MQGET() call itself.

NOTE: MQWI_UNLIMITED should be used with caution, as applications
which block forever can prevent queue managers from shutting down
elegantly, in some cases.

If the C<Wait> option is combined with the C<GetMsgOpts> option, it
will override the MQGMO_WAIT or MQGMO_NO_WAIT flag set in the
C<GetMsgOpts>.

=item Sync

This is a flag to indicate that the Syncpoint option is to be used,
and the message(s) not committed to the queue until an MQBACK or
MQCMIT call is made.  These are both wrapped with the Backout() and
Commit() methods respectively.

The value is simply interpreted as true or false.

If the C<Sync> option is combined with the C<GetMsgOpts> option, the
C<Options> field in the C<GettMsgOpts> is checked for compatibility.
If the C<Sync> flag is true and the C<GettMsgOpts> specifies
MQGMO_NO_SYNCPOINT, or vice versa, a fatal error is raised.  If no
conflict exists, the C<Sync> flag amends the C<GetMsgOpts>.

=item Convert

This is a flag to indicate that the conversion option is to be used.
The value is simply interpreted as true or false; if omitted, the
default is true.

The only reason to turn this option off is when trying to read binary
messages (MQFMT_NONE) generated in a different encoding.

If the C<Convert> option is combined with the C<GetMsgOpts> option, it
will override the MQGMO_CONVERT flag set in the C<GetMsgOpts>.

=item DisableAutoResize

This is a Boolean value, which if true, will disable the automatic
resizing of the message buffer when it is either truncated, or the
converted message will not fit.

=item GetConvert

This is a means of overriding the GetConvert routine specified for the
MQSeries::Queue object, for a single Get.  See the new() documentation
for more details.

=back

If the module has been compiled for MQ v7 and the queue manager
connected to runs MQ v7, then the MQGET call retrieves the message
proeprties by default.  After the message has been read, the
Properties method of the MQSeries::Message object can be called to
retrieve the message properties.  See the documentation of the
MQSeries::Properties class for an example.

=head2 Inquire

This method is an interface to the MQINQ() API call, however, it takes
more convenient, human-readable strings in place of the C macros for
the selectors, as well as supports more readable strings for some of
the data values as well.

For example, to query the MaxMsgLength and MaxQDepth of a queue:

  my %qattr = $queue->Inquire( qw(MaxMsgLength MaxQDepth) );

The argument to this method is a list of "selectors", or Queue
attributes, to be queried.  The following table shows the complete set
of possible keys, and their underlying C macro.

Note that this list is all-inclusive, and that many of these are not
supported on some of the MQSeries releases or platforms.  Consult the
IBM documentation for such details.

    Key                         Macro
    ===                         =====
    AlterationDate		MQCA_ALTERATION_DATE,
    AlterationTime		MQCA_ALTERATION_TIME,
    BackoutRequeueName		MQCA_BACKOUT_REQ_Q_NAME,
    BackoutThreshold		MQIA_BACKOUT_THRESHOLD,
    BaseQName			MQCA_BASE_Q_NAME,
    BaseType			MQIA_BASE_TYPE,	
    CFStructure			MQCA_CF_STRUC_NAME,
    CLWLQueuePriority		MQIA_CLWL_Q_PRIORITY,
    CLWLQueueRank		MQIA_CLWL_Q_RANK,
    CLWLUseQ			MQIA_CLWL_USEQ,	
    ClusterDate			MQCA_CLUSTER_DATE,
    ClusterName			MQCA_CLUSTER_NAME,
    ClusterNamelist		MQCA_CLUSTER_NAMELIST,
    ClusterQMgrName		MQCA_CLUSTER_Q_MGR_NAME,
    ClusterQType		MQIA_CLUSTER_Q_TYPE,
    ClusterTime			MQCA_CLUSTER_TIME,
    CreationDate		MQCA_CREATION_DATE,
    CreationTime		MQCA_CREATION_TIME,
    CurrentQDepth		MQIA_CURRENT_Q_DEPTH,
    DefBind			MQIA_DEF_BIND,
    DefinitionType		MQIA_DEFINITION_TYPE,
    DefInputOpenOption		MQIA_DEF_INPUT_OPEN_OPTION,
    DefPersistence		MQIA_DEF_PERSISTENCE,
    DefPriority			MQIA_DEF_PRIORITY,
    DefPutResponse		MQIA_DEF_PUT_RESPONSE_TYPE,
    DefReadAhead		MQIA_DEF_READ_AHEAD,	
    DistLists			MQIA_DIST_LISTS,
    HardenGetBackout		MQIA_HARDEN_GET_BACKOUT,
    HighQDepth			MQIA_HIGH_Q_DEPTH,
    InhibitGet			MQIA_INHIBIT_GET,
    InhibitPut			MQIA_INHIBIT_PUT,
    InitiationQName		MQCA_INITIATION_Q_NAME,
    MaxMsgLength		MQIA_MAX_MSG_LENGTH,
    MaxQDepth			MQIA_MAX_Q_DEPTH,
    MsgDeliverySequence		MQIA_MSG_DELIVERY_SEQUENCE,
    MsgDeqCount			MQIA_MSG_DEQ_COUNT,
    MsgEnqCount			MQIA_MSG_ENQ_COUNT,
    NonPersistentMsgClass	MQIA_NPM_CLASS,
    OpenInputCount		MQIA_OPEN_INPUT_COUNT,
    OpenOutputCount		MQIA_OPEN_OUTPUT_COUNT,
    PageSetId			MQIA_PAGESET_ID,
    ProcessName			MQCA_PROCESS_NAME,
    PropertyControl		MQIA_PROPERTY_CONTROL,
    QDepthHighEvent		MQIA_Q_DEPTH_HIGH_EVENT,
    QDepthHighLimit		MQIA_Q_DEPTH_HIGH_LIMIT,
    QDepthLowEvent		MQIA_Q_DEPTH_LOW_EVENT,
    QDepthLowLimit		MQIA_Q_DEPTH_LOW_LIMIT,
    QDepthMaxEvent		MQIA_Q_DEPTH_MAX_EVENT,
    QDesc			MQCA_Q_DESC,
    QMgrIdentifier		MQCA_Q_MGR_IDENTIFIER,
    QName			MQCA_Q_NAME,
    QNames			MQCACF_Q_NAMES,
    QueueAccounting		MQIA_ACCOUNTING_Q,
    QueueMonitoring		MQIA_MONITORING_Q,
    QueueStatistics		MQIA_STATISTICS_Q,
    QServiceInterval		MQIA_Q_SERVICE_INTERVAL,
    QServiceIntervalEvent	MQIA_Q_SERVICE_INTERVAL_EVENT,
    QType			MQIA_Q_TYPE,
    RemoteQMgrName		MQCA_REMOTE_Q_MGR_NAME,
    RemoteQName			MQCA_REMOTE_Q_NAME,
    RetentionInterval		MQIA_RETENTION_INTERVAL,
    Scope			MQIA_SCOPE,
    Shareability		MQIA_SHAREABILITY,
    StorageClass		MQCA_STORAGE_CLASS,
    TimeSinceReset		MQIA_TIME_SINCE_RESET,
    TPipeNames			MQCA_TPIPE_NAME,
    TriggerControl		MQIA_TRIGGER_CONTROL,
    TriggerData			MQCA_TRIGGER_DATA,
    TriggerDepth		MQIA_TRIGGER_DEPTH,
    TriggerMsgPriority		MQIA_TRIGGER_MSG_PRIORITY,
    TriggerType			MQIA_TRIGGER_TYPE,
    Usage			MQIA_USAGE,
    XmitQName			MQCA_XMIT_Q_NAME,

The return value of this method is a hash, whose keys are those given
as arguments, and whose values are the queried queue attributes.  In
most cases, the values are left unmolested, but in the following
cases, the values are mapped to more readable strings.

=over 4

=item DefBind                   (integer)

    Key                         Macro
    ===                         =====
    OnOpen                      MQBND_BIND_ON_OPEN
    NotFixed                    MQBND_BIND_NOT_FIXED

=item DefinitionType            (integer)

    Key                         Macro
    ===                         =====
    Permanent                   MQQDT_PERMANENT_DYNAMIC
    Temporary                   MQQDT_TEMPORARY_DYNAMIC

=item DefInputOpenOption        (integer)

    Key                         Macro
    ===                         =====
    Exclusive                   MQOO_INPUT_EXCLUSIVE
    Shared                      MQOO_INPUT_SHARED

=item MsgDeliverySequence       (integer)

    Key                         Macro
    ===                         =====
    FIFO                        MQMDS_FIFO
    Priority                    MQMDS_PRIORITY

=item QServiceIntervalEvent     (integer)

    Key                         Macro
    ===                         =====
    High                        MQQSIE_HIGH
    None                        MQQSIE_NONE
    OK                          MQQSIE_OK

=item QType                     (integer)

    Key                         Macro
    ===                         =====
    Alias                       MQQT_ALIAS
    All                         MQQT_ALL
    Cluster                     MQQT_CLUSTER
    Local                       MQQT_LOCAL
    Model                       MQQT_MODEL
    Remote                      MQQT_REMOTE

=item Scope                     (integer)

    Key                         Macro
    ===                         =====
    Cell                        MQSCO_CELL
    QMgr                        MQSCO_Q_MGR

=item TriggerType               (integer)

    Key                         Macro
    ===                         =====
    Depth                       MQTT_DEPTH
    Every                       MQTT_EVERY
    First                       MQTT_FIRST
    None                        MQTT_NONE

=item Usage                     (integer)

    Key                         Macro
    ===                         =====
    Normal                      MQUS_NORMAL
    XMITQ                       MQUS_TRANSMISSION

=back

=head2 Set

This method is an interface to the MQSET() API call, and like
Inquire(), it takes more convenient, human-readable strings in place
of the C macros.

For example, to put inhibit a queue:

  $queue->Set( InhibitPut => 1 );

The argument to this method is a hash of key/value pairs representing
queue attributes to be set.  The MQSET() API supports setting a very
limited subset of specific queue attributes.  The following table
shows the complete set of possible keys, and their underlying C macros.

    Key                         Macro
    ===                         =====
    InhibitGet                  MQIA_INHIBIT_GET
    InhibitPut                  MQIA_INHIBIT_PUT
    DistLists                   MQIA_DIST_LISTS
    TriggerControl              MQIA_TRIGGER_CONTROL
    TriggerData                 MQCA_TRIGGER_DATA
    TriggerDepth                MQIA_TRIGGER_DEPTH
    TriggerMsgPriority          MQIA_TRIGGER_MSG_PRIORITY
    TriggerType                 MQIA_TRIGGER_TYPE

In addition, the data value for the "TriggerType" key can have one of
the following values:

    Key                         Macro
    ===                         =====
    Depth                       MQTT_DEPTH
    Every                       MQTT_EVERY
    First                       MQTT_FIRST
    None                        MQTT_NONE

All of the other values are simply Boolean (0 or 1), with the
exception of "TriggerData", which is a string.

This method call returns true upon success, and false upon failure.
CompCode() and Reason() will be set appropriately.

=head2 ObjDesc

This method can be used to query the ObjDesc data structure.  If no
argument is given, then the ObjDesc hash reference is returned.  If a
single argument is given, then this is interpreted as a specific key,
and the value of that key in the ObjDesc hash is returned.

=head2 QueueManager

This method takes no arguments, and returns the MQSeries::QueueManager
object used by the queue.

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

=head2 GetConvertReason

This method returns a true of false value, indicating if a GetConvert
method failed or not.  Similar to the MQRC reason codes, false
indicates success, and true indicates some form of error.  If there
was no GetConvert method called, this will always return false.

=head2 Reasons

This method call returns an array reference, and each member of the
array is a Response Record returned as a possible side effect of
calling a Put() method to put a message to a distribution list.

The individual records are hash references, with two keys: CompCode
and Reason.  Each provides the specific CompCode and Reason associated
with the put of the message to each individual queue in the
distribution list, respectively.

=head1 MQOPEN RETRY SUPPORT

Normally, when MQOPEN() fails, the method that called it (Open() or
new()) also fails.  It is possible to have the Open() method retry the
MQOPEN() call for a specific set of reason codes.

By default,  the retry logic  is  disabled, but it  can  be enabled by
setting the RetryCount to a non-zero value.  The  list of reason codes
defaults to just MQRC_OBJECT_IN_USE, but a list of retryable codes can
be specified via the RetryReasons argument.

You are probably wondering why this logic is useful for MQOPEN().  The
choice of the default RetryReasons is not without its own reason.

Consider an application that opens a queue for exclusive input.  If
that application crashes and restarts, there will typically be a
window of time when the queue manager has not yet noticed that the
crashed application instance has died.  The application which has been
restarted will not fail to open the queue, and MQOPEN() will set the
reason to MQRC_OBJECT_IN_USE.

By retrying this particular reason code, and tuning the RetryCount and
RetrySleep to be consistent with the timeout on the queue manager,
applications can restart, reconnect and reopen these queues
transparently.

There are almost certainly other scenarios where the RetryReasons may
need to be customized, and thus the code supports this flexibility.

=head1 ERROR HANDLING

Most methods return a true or false value indicating success of
failure, and internally, they will call the Carp subroutine (either
Carp::carp(), or something user-defined) with a text message
indicating the cause of the failure.

In addition, the most recent MQI Completion and Reason codes will be
available via the CompCode() and Reason() methods:

  $queue->CompCode()
  $queue->Reason()

When distribution lists are used, then it is possible for a list of
reason codes to be returned by the API.  Normally, these are buried
inside the ObjDesc strucure, but they are also available via the

  $queue->Reasons()

method.  In this case, the $queue->Reason() will always return
MQRC_MULTIPLE_REASONS.  The return value of the Reasons() method is an
array reference, and each array item is a hash reference with two
keys: CompCode and Reason.  These correspond, respectively, with the
CompCode and Reason associated with the individual queues in the
distribution list.

For example, the Reason code associated with the 3rd queue in the list
would be:

  $queue->Reasons()->[2]->{Reason}

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

The simplest way to create an MQSeries::Queue object is:

  my $queue = MQSeries::Queue->new
    (
     QueueManager               => 'some.queue.manager',
     Queue                      => 'SOME.QUEUE',
     Mode                       => 'input',
    ) || die;

But in this case, either the connection to the queue manager or the
open of the queue could fail, and your application will not be able to
determine why.

In order to explicitly have access to the CompCode and Reason one
would do the following:

  # Explicitly create your own MQSeries::QueueManager object
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

  my $queue = MQSeries::Queue->new
    (
     QueueManager               => $qmgr,
     Queue                      => 'SOME.QUEUE',
     Mode                       => 'input',
     AutoOpen                   => 0,
    ) || die "Unable to instantiate MQSeries::Queue object\n";

  # Call the Open method explicitly
  unless ( $queue->Open() ) {
    die("Open of queue failed\n" .
        "CompCode => " . $queue->CompCode() . "\n" .
        "Reason   => " . $queue->Reason() . "\n");
  }

=head1 SEE ALSO

MQSeries(3), MQSeries::QueueManager(3), MQSeries::Message(3),
MQSeries::Properties(3)

=cut
