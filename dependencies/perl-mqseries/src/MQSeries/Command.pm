#
# $Id: Command.pm,v 37.13 2012/09/26 16:10:14 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::QueueManager;
use MQSeries::Queue;
use MQSeries::Command::Request;
use MQSeries::Command::Response;
#use MQSeries::Command::PCF;
#use MQSeries::Command::MQSC;
use MQSeries::Utils qw(ConvertUnit);
use Params::Validate qw(validate);

our $VERSION = '1.34';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = validate(@_, { 'QueueManager'      => 0,
                              'Type'              => 0,
                              'CommandVersion'    => 0,
                              'Carp'              => 0,
                              'DynamicQName'      => 0,
                              'Expiry'            => 0,
                              'Wait'              => 0,
                              'ModelQName'        => 0,
                              'StrictMapping'     => 0,
                              'CommandQueue'      => 0,
                              'CommandQueueName'  => 0,
                              'RealQueueManager'  => 0,
                              'ProxyQueueManager' => 0,
                              'ReplyToQMgr'       => 0,
                              'ReplyToQ'          => 0,
                            });

    my $self =
      {
       Reason                   => 0,
       CompCode                 => 0,
       CommandVersion           => MQSeries::MQCFH_VERSION_1,
       Wait                     => 60000, # 60 second wait for replies...
       #Expiry                  => 600, # 60 second expiry on requests
       Expiry                   => 999999999,
       Carp                     => \&carp,
       Type                     => 'PCF',
       ModelQName               => 'SYSTEM.DEFAULT.MODEL.QUEUE',
       DynamicQName             => 'PERL.COMMAND.*',
       StrictMapping            => 0,
       Stats                    => {},
       DefaultMsgDesc           => {},
      };                        # Blessed later - see below

    #
    # A large set of optional parameters that become data members if
    # present.
    #
    foreach my $param (qw(Carp
                          DynamicQName ModelQName
                          StrictMapping CommandQueue CommandVersion
                          CommandQueueName ReplyToQMgr)) {
        $self->{$param} = $args{$param} if (defined $args{$param});
    }

    #
    # You can specify the type, but we'll default to PCF; this in turn
    # determines our class (if need be, we dynamically load the
    # subclass).
    #
    if (defined $args{Type}) {
        unless ($args{Type} eq 'PCF' or $args{Type} eq 'MQSC') {
            $self->Carp("Invalid argument: 'Type' must be one of: PCF MQSC");
            return;
        }
        $self->{Type} = $args{Type};
    }
    if ($class =~ /::(PCF|MQSC)$/) {
        if ($self->{Type} ne $1) {
            $self->Carp("Invalid argument: 'Type' $self->{Type} does not match $class");
            return;
        }
    } else {
        $class .= "::" . $self->{Type};
        eval { "use $class" } || do {
            $self->Carp("Could not load sub-class '$class': $@");
            return;
        };
    }
    bless ($self, $class);

    #
    # Where do we send requests?
    #
    # - CommandQueue (may set RealQueueManager for message display)
    # - CommandQueueName (may set RealQueueManager for message display)
    # - SYSTEM.COMMAND.INPUT / SYSTEM.ADMIN.COMMAND.QUEUE
    #
    if ($args{CommandQueue}) {
        #
        # This is subject to a number of requirements:
        # - CommandQueue is an MQSeries::Queue object
        # - QueueManager, CommandQueueName is omitted
        # - RealQueueManager is specified
        # - ProxyQueueManager (= ReplyToQMgr) is optional
        #
        unless (ref $args{CommandQueue} &&
                $args{CommandQueue}->isa("MQSeries::Queue")) {
            $self->Carp("CommandQueue argument must be an MQSeries::Queue object");
            return;
        }
        foreach my $fld (qw(RealQueueManager)) {
            next if (defined $args{$fld});
            $self->Carp("CommandQueue: required argument $fld is missing");
            return;
        }
        foreach my $fld (qw(QueueManager CommandQueueName)) {
            next unless (defined $args{$fld});
            $self->Carp("CommandQueue: argument $fld is not allowed");
            return;
        }
        $self->{'RealQueueManager'} = $args{'RealQueueManager'};
    } elsif ($args{CommandQueueName}) {
        #
        # NOTE: This may be distribution-list notation
        #       (queue@xmitqname), in which case the RealQueueManager
        #       name may specify the target queue manager name for
        #       display purposes.
        #
        $self->{CommandQueueName} = $args{CommandQueueName};
        if (defined $args{'RealQueueManager'}) {
            $self->{'RealQueueManager'} = $args{'RealQueueManager'};
        }
    } else {
        #
        # Some reasonable defaults.  If we're proxying to a MQSC queue
        # manager, then this is (in the author's case anyway) probably
        # an MVS queue manager with no direct client access.
        #
        if ($self->{Type} eq 'MQSC') {
            $self->{CommandQueueName} = "SYSTEM.COMMAND.INPUT";
        } else {
            $self->{CommandQueueName} = "SYSTEM.ADMIN.COMMAND.QUEUE";
        }
    }

    #
    # But if you specify the proxy, things are a bit more complex.
    #
    # NOTE: This value can be a empty string, to indicate the
    # "default" queue manager.
    #
    if ($self->{CommandQueue}) {
        #
        # NOTE: Have already verified that RealQueueManager is
        # present. ProxyQueueManager is optional.
        #
        $self->{QueueManager} = $self->{CommandQueue}->QueueManager();
        if ($args{ProxyQueueManager} && ! $args{ReplyToQMgr}) {
            $self->{ReplyToQMgr}  = $args{ProxyQueueManager};
        }
    } elsif (exists $args{ProxyQueueManager}) {
        if (ref $args{QueueManager} || $args{QueueManager} eq "") {
            $self->Carp("QueueManager must be a non-empty string when ProxyQueueManager is specified");
            return;
        }

        $self->{ProxyQueueManager} = $args{ProxyQueueManager};
        $self->{RealQueueManager}  = $args{QueueManager};
        $self->{ReplyToQMgr}       = $args{ProxyQueueManager};

        #
        # This assumes that a default command queue name, such as
        # SYSTEM.COMMAND.INPUT, will have a remote queue on the proxy
        # called SYSTEM.COMMAND.INPUT.<TargetQueueManager>.
        #
        unless (exists $args{CommandQueueName}) {
            $self->{CommandQueueName} .= ".$args{QueueManager}";
        }

        if (ref $args{ProxyQueueManager}) {
            if ( $args{ProxyQueueManager}->isa("MQSeries::QueueManager") ) {
                $self->{QueueManager} = $args{ProxyQueueManager};
            } else {
                $self->Carp("Invalid argument: 'ProxyQueueManager' " .
                            "must be an MQSeries::QueueManager object");
                return;
            }
        } else {
            $self->{QueueManager} = MQSeries::QueueManager::->
              new(QueueManager => $args{ProxyQueueManager},
                  Carp         => $self->{Carp},
                 ) or return;
        }
    } else {                    # No proxy specified: connect directly
        if (ref $args{QueueManager}) {
            if ($args{QueueManager}->isa("MQSeries::QueueManager")) {
                $self->{QueueManager} = $args{QueueManager};
            } else {
                $self->Carp("Invalid argument: 'QueueManager' " .
                            "must be an MQSeries::QueueManager object");
                return;
            }
        } else {                # Name is deprecated
            $self->{QueueManager} = MQSeries::QueueManager::->
              new(QueueManager => $args{QueueManager},
                  Carp         => $self->{Carp},
                 ) or return;
        }
    }

    #
    # The Wait and Expiry parameters can be tweaked, too, but go
    # through a 'ConvertUnit' step to support '60s', '2m' strings.
    #
    foreach my $parameter (qw(Expiry Wait)) {
        if (defined $args{$parameter}) {
            $self->{$parameter} = ConvertUnit($parameter, $args{$parameter});
        }
    }

    #
    # CommandVersion may need to be bumped if we're talking to a MVS
    # qmgr and we stayed with the default of MQCFH_VERSION_1.  We
    # should be able to determine this now that we're actually
    # connected to the qmgr.  Note that if you're using a proxy qmgr,
    # this may still end up wrong, so the caller should really do this
    # for us.
    #
    if (!defined($args{"CommandVersion"}) &&
        $self->{"QueueManager"}->{"QMgrConfig"}->{"Platform"} eq "MVS") {
        $self->{"CommandVersion"} = MQSeries::MQCFH_VERSION_3;
    }

    #
    # Open the command queue, and assume that the MQSeries::Queue
    # object will whine appropriately.
    #
    $self->{CommandQueue} ||= MQSeries::Queue::->
      new(QueueManager  => $self->{QueueManager},
          Queue         => $self->{CommandQueueName},
          Mode          => 'output',
          Carp          => $self->{Carp},
          Reason        => \$self->{"Reason"},
          CompCode      => \$self->{"CompCode"},
         ) || do {
             $self->Carp("Unable to instantiate MQSeries::Queue object for $self->{CommandQueueName}");
             return;
         };

    #
    # Open the ReplyToQ
    #
    if ($args{ReplyToQ}) {
        if (ref $args{ReplyToQ}) {
            if ($args{ReplyToQ}->isa("MQSeries::Queue")) {
                $self->{ReplyToQ} = $args{ReplyToQ};
            } else {
                $self->Carp("Invalid argument: 'ReplyToQ' " .
                            "must be an MQSeries::Queue object");
                return;
            }
        } else {
            $self->{ReplyToQ} = MQSeries::Queue::->
              new(QueueManager  => $self->{QueueManager},
                  Queue         => $args{ReplyToQ},
                  Mode          => 'input',
                  Carp          => $self->{Carp},
                  Reason        => \$self->{"Reason"},
                  CompCode      => \$self->{"CompCode"},
                 ) || do {
                     $self->Carp("Unable to instantiate MQSeries::Queue object for $args{ReplyToQ}");
                     return;
                 };
        }
    } else {
        $self->{ReplyToQ} = MQSeries::Queue::->
          new(QueueManager => $self->{QueueManager},
              Queue        => $self->{ModelQName},
              DynamicQName => $self->{DynamicQName},
              Mode         => 'input',
              Carp         => $self->{Carp},
              Reason       => \$self->{"Reason"},
              CompCode     => \$self->{"CompCode"},
             ) || do {
                 $self->Carp("Unable to instantiate MQSeries::Queue object for $self->{ModelQName}");
                 return;
             };
    }

    return $self;
}


#
# FIXME: This uses the cached response object.  We probably want
#        to keep track of this info another way, or get rid of
#        this method call altogether.
#
sub DataParameters {
    my $self = shift;

    my @parameters;

    foreach my $response ( @{$self->{Response}} ) {
        next if $response->Header('CompCode') == MQSeries::MQCC_FAILED;
        push(@parameters,$response->Parameters());
    }

    return @parameters;
}


#
# FIXME: This, too, probably will have to go.
#
sub ErrorParameters {

    my $self = shift;

    my @parameters;

    foreach my $response ( @{$self->{Response}} ) {
        next if $response->Header('CompCode') != MQSeries::MQCC_FAILED;
        push(@parameters,$response->Parameters());
    }

    return @parameters;

}


sub CompCode {
    my ($self) = @_;
    return $self->{"CompCode"};
}


sub Reason {
    my ($self) = @_;
    return $self->{"Reason"};
}


sub ReasonText {
    my ($self) = @_;
    if (defined $self->{'ReasonText'}) { # Cached from MF response
        return $self->{'ReasonText'};
    }
    return MQReasonToText($self->{"Reason"});
}


#
# Set default message-descriptor options
#
sub MsgDesc {
    my ($this, %dft) = @_;
    while (my ($k, $v) = each %dft) {
        $this->{DefaultMsgDesc}->{$k} = $v;
    }
    return $this->{DefaultMsgDesc};
}


#
# Don't autoload this....
#
sub DESTROY { 1 }


#
# This AUTOLOAD will allow any random method to be interpreted as a
# command request.  If the command isn't defined, then _Command
# will blow up.
#
sub AUTOLOAD {
    our $AUTOLOAD;
    my ($self) = shift @_;
    my $name = $AUTOLOAD;
    $name =~ s/.*://;
    return $self->_Command($name,{@_});
}


#
# This method will query the object, and if it exists, check the
# attributes to see if they match, and if they do, do nothing.  That
# is, its a conditional creation of the given object.
#
# Hash with named parameters:
# - Verify (optional boolean): run for real (false, dft) / verify only (true)
# - Quiet: (optional boolean): display activity (true) / silent (false, dft)
# - Clear: (optional, boolean): clear queue if recreated
# - Attrs: Ref to hash with attributes of object to be created
# - Force: (optional, boolean): use force option when recreating queue
# - Callback (optional): code ref used to coprae attributes
# Returns:
# - Boolean: false if create/verify failed, true if create/verify succeeded
#   If true: -1 if no differences/changes, 1 if differences/changes made
#
sub CreateObject {
    my ($self, %args) = @_;
    my ($Verify, $Quiet, $Clear, $Attrs, $Force, $Callback) =
      @args{qw(Verify Quiet Clear Attrs Force Callback)};
    $Callback ||= \&_CompareAttributes;

    unless (ref $Callback eq 'CODE') {
        $self->Carp("'Callback' parameter must be a subroutine reference");
        return;
    }

    #
    # Queue Manager name used for reporting (could need to extract
    # from default queue manager after connecting).
    #
    my $QMgr = ($self->{RealQueueManager} ||
                $self->{QueueManager}->{QueueManager}
               );

    my $Need                    = 1;

    my $Inquire                 = "";
    my $Create                  = "";
    my $Delete                  = "";
    my $Change                  = "";

    my $method                  = "";

    my $Key                     = "";
    my $Type                    = "";

    my @KeyNames                = qw(ChannelName NamelistName ProcessName
                                     QName StorageClassName AuthInfoName
                                     CFStructName CFStrucName
                                     ListenerName ServiceName
                                     SubName TopicName ChlAuth ComminfoName);
    my $KeyCount                = 0;

    #
    # Verify that we have only been given exactly *one* of the primary
    # keys that let us determine the object type.
    #
    foreach my $KeyName ( @KeyNames ) {
        $KeyCount++ if exists $Attrs->{$KeyName};
    }

    #
    # ProcessName is a valid attribute for Queues, so allow this:
    #
    $KeyCount-- if exists $Attrs->{QName} && exists $Attrs->{ProcessName};

    if ( $KeyCount != 1  ) {
        $self->Carp("CreateObject: Unable to determine object type.\n" .
                        (
                         $KeyCount == 0
                         ? "One of the following must be specified:\n"
                         : ( "More than one of the following was specified:\n" .
                             "(Exception: ProcessName and QName can both be present, since\n" .
                             "the former is an attribute of the latter.\n" .
                             "We assume ObjectType == Queue in this case)\n" )
                        ) .
                        "\t" . join("\n\t",@KeyNames) . "\n");
        return;
    }

    if ( $Attrs->{ChannelName} ) {
        $Inquire                = "InquireChannel";
        $Create                 = "CreateChannel";
        $Change                 = "ChangeChannel";
        $Key                    = "ChannelName";
        $Type                   = "$Attrs->{ChannelType} Channel";
    } elsif ( $Attrs->{NamelistName} ) {
        $Inquire                = "InquireNamelist";
        $Create                 = "CreateNamelist";
        $Change                 = "ChangeNamelist";
        $Key                    = "NamelistName";
        $Type                   = "Namelist";
    } elsif ( $Attrs->{QName} ) {
        $Inquire                = "InquireQueue";
        $Create                 = "CreateQueue";
        $Change                 = "ChangeQueue";
        $Delete                 = "DeleteQueue";
        $Key                    = "QName";

        if ( $Attrs->{QType} eq 'Remote' && $Attrs->{RemoteQName} eq '' ) {
            $Type               = "QMgr Alias";
        } elsif ( $Attrs->{QType} eq 'Local' && defined($Attrs->{Usage}) && $Attrs->{Usage} eq 'XMITQ' ) {
            $Type               = "Transmission Queue";
        } else {
            $Type               = "$Attrs->{QType} Queue";
        }
    } elsif ( $Attrs->{ProcessName} ) {
        $Inquire                = "InquireProcess";
        $Create                 = "CreateProcess";
        $Change                 = "ChangeProcess";
        $Key                    = "ProcessName";
        $Type                   = "Process";
    } elsif ( $Attrs->{StorageClassName} ) {
        $Inquire                = "InquireStorageClass";
        $Create                 = "CreateStorageClass";
        $Change                 = "ChangeStorageClass";
        $Key                    = "StorageClassName";
        $Type                   = "StorageClass";
    } elsif ( $Attrs->{AuthInfoName} ) {
        $Inquire                = "InquireAuthInfo";
        $Create                 = "CreateAuthInfo";
        $Change                 = "ChangeAuthInfo";
        $Key                    = "AuthInfoName";
        $Type                   = "AuthInfo";
    } elsif ( $Attrs->{CFStructName} ) {                # Kept for backward compatibility
        $Inquire                = "InquireCFStruct";
        $Create                 = "CreateCFStruct";
        $Change                 = "ChangeCFStruct";
        $Key                    = "CFStructName";
        $Type                   = "CFStruct";
    } elsif ( $Attrs->{CFStrucName} ) {
        $Inquire                = "InquireCFStruc";
        $Create                 = "CreateCFStruc";
        $Change                 = "ChangeCFStruc";
        $Key                    = "CFStrucName";
        $Type                   = "CFStruc";
    } elsif ( $Attrs->{ServiceName} ) {
        $Inquire                = "InquireService";
        $Create                 = "CreateService";
        $Change                 = "ChangeService";
        $Key                    = "ServiceName";
        $Type                   = "Service";
    } elsif ( $Attrs->{ListenerName} ) {
        $Inquire                = "InquireChannelListener";
        $Create                 = "CreateChannelListener";
        $Change                 = "ChangeChannelListener";
        $Key                    = "ListenerName";
        $Type                   = "Listener";
    } elsif ( $Attrs->{SubName} ) {
        $Inquire                = "InquireSubscription";
        $Create                 = "CreateSubscription";
        $Change                 = "ChangeSubscription";
        $Key                    = "SubName";
        $Type                   = "Subscription";
    } elsif ( $Attrs->{TopicName} ) {
        $Inquire                = "InquireTopic";
        $Create                 = "CreateTopic";
        $Change                 = "ChangeTopic";
        $Key                    = "TopicName";
        $Type                   = "Topic";
    } elsif ($Attrs->{ChlAuth} ) {
        $Inquire                = "InquireChlAuthRecs";
        $Create                 = "SetChlAuthRec";
        $Change                 = "SetChlAuthRec";
        $Key                    = "ChlAuth";
        $Type                   = "ChlAuthRec";
    } elsif ($Attrs->{ComminfoName} ) {
        $Inquire                = "InquireComminfo";
        $Create                 = "CreateComminfo";
        $Change                 = "ChangeComminfo";
        $Key                    = "ComminfoName";
        $Type                   = "Comminfo";
    } 
        

    #
    # First check to see if it exists.
    #
    my ($Object) = $self->$Inquire( $Key => $Attrs->{$Key} );

    #
    # XXX -- shouldn't we be checking for no such object specifically?
    # Of course we should...
    #
    if ( $self->Reason() &&
         $self->Reason() != MQSeries::MQRC_UNKNOWN_OBJECT_NAME &&
         $self->Reason() != MQSeries::MQRCCF_CHANNEL_NOT_FOUND &&
         $self->Reason() != MQSeries::MQRC_NO_SUBSCRIPTION &&
         $self->Reason() != MQSeries::MQRCCF_CHLAUTH_NOT_FOUND
       ) {
        my $rc = $self->Reason();
        $self->Carp("Unable to verify existence of $Type '$QMgr/$Attrs->{$Key}' (Reason=$rc)\n");
        return;
    }

    my $Changes;
    if ( ref $Object eq 'HASH' ) {
        $method = $Change;

        #
        # If an object has been created with QSGDisposition
        # 'Group', then a normal 'Inquire' command returns QSPDisp
        # 'Copy' - which, if the queue manager is up, represents the
        # object unless it is just being changed on another queue
        # manager.
        #
        # We'll amend that to read QSGDisp 'Group', as that is what
        # we need to compare against.
        #
        if (defined $Object->{'QSGDisposition'} &&
            $Object->{'QSGDisposition'} eq 'Copy') {
            $Object->{'QSGDisposition'} = 'Group';
        }

        #
        # For mq 7.1 and above
        # Channel Authentication Records are added/replaced/removed
        # with the same command but with different action parameters
        #
        if ($Attrs->{'ChlAuth'} && (! defined $Attrs->{'Action'})) {
            $Attrs->{'Action'} = 'Replace';
        }

        #
        # If it exists, let's assume we don't need to create it.  If
        # any of the attributes are wrong, we'll then say we "Need"
        # it.
        #
        $Changes = $Callback->($Attrs, $Object, \&_CompareOneAttribute);
        $Need = scalar(keys %$Changes);

        unless ($Quiet) {
            foreach my $Attr (sort keys %$Changes) {
                print("Incorrect attribute '$Attr' for $Type '$QMgr/$Attrs->{$Key}'\n");

                if (ref $Attrs->{$Attr} eq "ARRAY") {
                    print "Should be:\n\t" . join("\n\t",map { qq{'$_'} } @{$Changes->{$Attr}}) . "\n";
                } else {
                    print "Should be: '$Changes->{$Attr}'\n";
                }

                if (ref $Object->{$Attr} eq "ARRAY") {
                    print "Currently is:\n\t" . join("\n\t",map { qq{'$_'} } @{$Object->{$Attr}} ) . "\n";
                } else {
                    print "Currently is: '$Object->{$Attr}'\n";
                }
            }
        }
    } else {
        print "$Type '$QMgr/$Attrs->{$Key}' is missing\n" unless $Quiet;
        $method = $Create;

        if ($Attrs->{'ChlAuth'} && (! defined $Attrs->{'Action'})) {
            $Attrs->{'Action'} = 'Add';
        }
        $Changes = $Callback->($Attrs);
    }

    unless ($Need) {
        print "$Type '$QMgr/$Attrs->{$Key}' is correctly configured\n" unless $Quiet;
        return -1;              # -1: No changes
    }

    return 1 if $Verify;        # 1: Things changed

    #
    # If we have any changes, make sure we include the QName/QType,
    # ChannelName/ChannelType, ProcessName, StorageClass,
    # AuthInfoName or CFStructName.
    #
    # We must do this here, as user's callbacks will get it wrong...
    #
    if (keys %$Changes) {
        $Changes->{$Key} = $Attrs->{$Key};
        if ($Key eq 'QName') {
            $Changes->{'QType'} = $Attrs->{'QType'};
        } elsif ($Key eq 'ChannelName') {
            $Changes->{'ChannelType'} = $Attrs->{'ChannelType'};
        } elsif ($Key eq 'AuthInfoName' &&
                defined($self->{QueueManager}->{QMgrConfig}) &&
                $self->{QueueManager}->{QMgrConfig}->{CommandLevel} >= 700) {
            $Changes->{'AuthInfoType'} = $Attrs->{'AuthInfoType'};
        } elsif ($Key eq 'ChlAuth') {
            $Changes->{'ChlAuthType'} = $Attrs->{'ChlAuthType'};
            $Changes->{'Action'} = $Attrs->{'Action'}; 
        }
    }

    #
    # If a Queue QType has changed, or any object CFStructure or
    # QSGDisposition has changed, we'll have to delete the
    # old object first.
    #
    # This looks complicated because you don't want to alter a dynamic
    # queue that should be recreated as a real local queue (you want
    # to delete it first) or fail to delete a permdyn queue that
    # should be a tempdyn queue (but don't delete model queues where
    # this is true), etc.
    #
    # NOTE: We do *not* purge, unless the 'Clear' flag is specified.
    # That should be checked out manually, as it will be an odd case
    # anyway.  In any event, this will be somewhat rare.
    #
    my $delete_first = 0;
    if ($Key eq 'QName' && $Object &&
        ($Attrs->{QType} ne $Object->{QType} ||
         (defined $Attrs->{DefinitionType} &&
          defined $Object->{DefinitionType} &&
          $Attrs->{QType} ne 'Model' &&
          $Attrs->{DefinitionType} ne $Object->{DefinitionType} ) ) ) {
        $delete_first = 1;
    } elsif ($Object) {
        foreach my $fld (qw(QSGDisposition
                            CFStructure)) {
            if (defined $Attrs->{$fld} && $Attrs->{$fld} ne $Object->{$fld}) {
                $delete_first = 1;
            }
        }
    }
    if ($delete_first) {
        print "Deleting $Type $QMgr/$Attrs->{$Key}'\n"
          unless $Quiet;

        #
        # CommandScope break in certain combinations
        # Since MQ uses the CommandScope underneath the covers,
        # CommandScope is no longer used
        #
        $self->$Delete
          (
           $Key                 => $Attrs->{$Key},
           QType                => $Object->{QType},
           (
            $Clear && $Key eq 'QName' && $Object->{QType} eq 'Local' ?
            ( Purge             => 1 ) : (),
            (defined $Object->{QSGDisposition} ?
            (QSGDisposition => $Object->{QSGDisposition}) : ()),
           )
          ) || do {
              $self->Carp("Unable to delete $Object->{QType} Queue '$QMgr/$Attrs->{$Key}'\n" . $self->ReasonText() . "\n");
              return;
          };

        $method = $Create;
        $Changes = $Callback->($Attrs);
        $Object = undef;
    }

    unless ( $Quiet ) {
        my $action;
        if ((defined $Attrs->{'ChlAuth'}) && (defined $Attrs->{'Action'})) {
            $action = $Attrs->{'Action'} eq "Add" ? "Creating" : "Updating";
        }
        else {
            $action = $method eq $Change ? "Updating" : "Creating"; 
        }
        print("$action $Type '$QMgr/$Attrs->{$Key}'\n");
    }

    #
    # Force can only be specified when changing queue objects, but not
    # when creating them.  Therefore, this is passed as an argument to
    # CreateObject, and not as an "attribute".  Note that Force and
    # Replace aren't really object attributes anyway; they are options
    # to the command server, and thus our treatement of them is really
    # a better design.
    #
    # Take that, IBM... ;-)
    #
    if ( $Force && $Key eq 'QName' && $Changes->{'QType'} ne 'Model' &&
         $method eq $Change ) {
        $Changes->{Force} = 1;
    }

    #
    # If the QSGDisposition field is set in the object,
    # also set it in the changes.
    #
    my $disp_field = 'QSGDisposition';
    if (defined $Object->{$disp_field}) {
        $Changes->{$disp_field} = $Object->{$disp_field};
    }

    #
    # Here's a bit of an ugly hack, but it tends to be required...
    # you cannot change a queue StorageClass (MF attribute) if the
    # queue has messages or is in use.  Attempting to do so results in
    # a partially-updated object.  So if the StorageClass needs to be
    # changed, and the queue seems open/with messages, perform a
    # two-step update.
    #
    my $Changes2;
    if ($method ne $Create &&
        $Key eq 'QName' && defined $Changes->{'StorageClass'} &&
        scalar(keys %$Changes) > 2) {
        $Changes2->{'QType'} = $Changes->{'QType'};
        $Changes2->{$disp_field} = $Changes->{$disp_field}
          if (defined $Changes->{$disp_field});
        $Changes2->{'StorageClass'} = delete $Changes->{'StorageClass'};
    }

    foreach my $diffs ($Changes, $Changes2) {
        next unless (defined $diffs); # $Changes2 is optional
        $self->$method($Key => $Changes->{$Key},
                       %$diffs,
                      ) || do {
            $self->Carp("Unable to " .
                        ( $method eq $Change ? "update" : "create" ) .
                        " $Type '$QMgr/$Changes->{$Key}'\n" .
                        $self->ReasonText() . "\n");
            return;
        };
    }

    return 1;                   # 1: Things changed
}


#
# This method codes the basic request/reply logic common to both PCF
# and MQSC command formats.
#
sub _Command {
    my $self                    = shift;
    my $command                 = shift;
    my $parameters              = shift;
    my $key                     = "";

    #
    # IMPORTANT: each and every case where we return *must* set a
    # reasonable value for the Reason and CompCode.
    #
    $self->{"Reason"}           = 0;
    $self->{"CompCode"}         = 0;

    #
    # We set the ReasonText if we get a MQSC response message with an
    # error.  In other cases, we'll use MQReasonToText on the Reason
    # field.
    #
    delete $self->{"ReasonText"};

    #
    # Allow the 'name' keys to default to '*' if not given.
    #
    my %command2name =
      (
       InquireNamelist           => 'NamelistName',
       InquireNamelistNames      => 'NamelistName',
       InquireProcess            => 'ProcessName',
       InquireProcessNames       => 'ProcessName',
       InquireQueue              => 'QName',
       InquireQueueNames         => 'QName',
       InquireQueueStatus        => 'QName',
       ResetQueueStatistics      => 'QName',
       InquireChannel            => 'ChannelName',
       InquireChannelNames       => 'ChannelName',
       InquireChannelStatus      => 'ChannelName',
       InquireStorageClass       => 'StorageClassName',
       InquireStorageClassNames  => 'StorageClassName',
       InquireService            => 'ServiceName',
       InquireAuthInfo           => 'AuthInfoName',
       InquireAuthInfoNames      => 'AuthInfoName',
       InquireCFStruc            => 'CFStrucName',
       InquireCFStrucNames       => 'CFStrucName',
       InquireCFStrucStatus      => 'CFStrucName',
       InquireCFStruct           => 'CFStructName',
       InquireCFStructNames      => 'CFStructName',
       InquireThread             => 'ThreadName',
       InquireChannelListener    => 'ListenerName',
       InquireSubscription       => 'SubName',
       InquireSubscriptionStatus => 'SubName',
       InquireTopic              => 'TopicName',
       InquireTopicNames         => 'TopicName',
       InquireTopicStatus        => 'TopicString',
       InquireChlAuthRecs        => 'ChlAuth',
       InquireComminfo		 => 'ComminfoName',
      );

    if ( $command2name{$command} ) {
        unless ($parameters->{$command2name{$command}} ) {
            $parameters->{$command2name{$command}} = '*';

            #
            # For InquireTopicStatus, use '#', not '*'
            #
            if ($command eq 'InquireTopicStatus') {
                $parameters->{$command2name{$command}} = '#';
            }
        }
    }

    #
    # If you are (re)creating a non-dynamic local queue, you should
    # not specify DefinitionType=Predefined.  It was needed above in
    # order to see if we need to pre-delete a dynamic local queue, but
    # it should go no further.
    #
    if ($command eq "CreateQueue" && $parameters->{"DefinitionType"} &&
        $parameters->{"DefinitionType"} eq "Predefined") {
        delete($parameters->{"DefinitionType"});
    }

    #
    # Allow 'GenericConnectionId' of InquireConnection to default to '00'
    #
    if ( $command eq 'InquireConnection' ) {
        unless ( $parameters->{'GenericConnectionId'} || $parameters->{'ConnectionId'} ) {
            $parameters->{'GenericConnectionId'} = '00';
        }
    }

    #
    # Allow the 'attr' keys to default to 'All' if not given.
    #
    # NOTE: v5 PCF does this for you, but V2 PCF and MQSC do NOT.
    # Remember -- we're after a single interface to all these formats.
    #
    my %command2all =
      (
       InquireChannel                   => 'ChannelAttrs',
       InquireChannelStatus             => 'ChannelInstanceAttrs',
       InquireChlAuthRecs               => 'ChlAuthAttrs',
       InquireClusterQueueManager       => 'ClusterQMgrAttrs',
       InquireComminfo                  => 'ComminfoAttrs',
       InquireConnection                => 'ConnectionAttrs',
       InquireNamelist                  => 'NamelistAttrs',
       InquireProcess                   => 'ProcessAttrs',
       InquireQueue                     => 'QAttrs',
       InquireQueueManager              => 'QMgrAttrs',
       InquireQueueStatus               => 'QStatusAttrs',
       InquireStorageClass              => 'StorageClassAttrs',
       InquireAuthInfo                  => 'AuthInfoAttrs',
       InquireCFStruct                  => 'CFStructAttrs',
       InquireCFStruc                   => 'CFStrucAttrs',
       InquireService                   => 'ServiceAttrs',
       InquireSubscription              => 'SubscriptionAttrs',
       InquireSubscriptionStatus        => 'SubscriptionStatusAttrs',
       InquireTopic                     => 'TopicAttrs',
       InquireTopicStatus               => 'TopicStatusAttrs',
       InquirePubSubStatus              => 'PubSubStatusAttrs',
      );

    if ( $command2all{$command} ) {
        unless ( $parameters->{$command2all{$command}} ) {
            $parameters->{$command2all{$command}} = ['All'];
        }
    }

    #
    # The request message descriptor is computed from the
    # defaults set in DefaultMsgDesc, plus some hard-wired
    # constants.
    #
    # FIXME: Maybe copy ReplyToQ, ReplyToQMgr and Expiry
    #        to the default message descriptor and use that?
    #
    my $req_msgdesc =
      { %{ $self->{DefaultMsgDesc} },
        ReplyToQ    => $self->{ReplyToQ}->ObjDesc("ObjectName"),
        ReplyToQMgr => $self->{ReplyToQMgr},
        #ReplyToQMgr => (defined $self->{ReplyToQMgr} ? $self->{ReplyToQMgr} : ''),
        Expiry      => $self->{Expiry},
      };
    my $putmsg_options =
      { Options => MQSeries::MQPMO_FAIL_IF_QUIESCING,
      };

    #
    # If identity context / origin context is overridden, make sure
    # the proper put-message options have been specified.
    #
    # Obviously, this is ignored unless the command-queue has been
    # opened with MQOO_SET_IDENTITY_CONTEXT or MQOO_SET_ALL_CONTEXT.
    #
    if (defined $req_msgdesc->{ApplIdentityData} ||
        defined $req_msgdesc->{UserIdentifier}) {
        #print STDERR "XXX: Adding set-identity context to PMO\n";
        $putmsg_options->{Options} |= MQSeries::MQPMO_SET_IDENTITY_CONTEXT;
    }
    if (defined $req_msgdesc->{ApplOriginData}) {
        #print STDERR "XXX: Adding set-all context to PMO\n";
        $putmsg_options->{Options} |= MQSeries::MQPMO_SET_ALL_CONTEXT;
    }

    $self->{Request} = MQSeries::Command::Request::->
      new(MsgDesc        => $req_msgdesc,
          Type           => $self->{Type},
          Command        => $command,
          Parameters     => $parameters,
          Carp           => $self->{Carp},
          StrictMapping  => $self->{StrictMapping},
          CommandVersion => $self->{CommandVersion},
         ) || do {
             $self->{"CompCode"} = MQSeries::MQCC_FAILED;
             $self->{"Reason"} = MQSeries::MQRC_UNEXPECTED_ERROR;
             return;
         };

    my $putresult = $self->{CommandQueue}->
      Put(Message    => $self->{Request},
          PutMsgOpts => $putmsg_options,
          Sync       => 0,
         );

    #
    # Keep track of stats: no of requests, total bytes, largest
    #
    {
        $self->{'Stats'}->{'NoRequests'}++;
        my $put_size = !defined($self->{'Request'}->Buffer()) ? 0 :
          length($self->{'Request'}->Buffer());
        $self->{'Stats'}->{'RequestBytes'} += $put_size;
        $self->{'Stats'}->{'MaxRequest'} = $put_size
          if (! defined $self->{'Stats'}->{'MaxRequest'} ||
              $put_size > $self->{'Stats'}->{'MaxRequest'});
    }

    unless ($putresult) {
        $self->{"CompCode"} = $self->{CommandQueue}->CompCode();
        $self->{"Reason"} = $self->{CommandQueue}->Reason();
        return;
    }

    $self->{Response} = [];

    my $MQSCHeader = { Command => $command };

    my @response_buffers;
    while ( 1 ) {
        my $response = MQSeries::Command::Response::->
          new(MsgDesc           =>
              {
               CorrelId         => $self->{Request}->MsgDesc("MsgId"),
              },
              Type              => $self->{Type},
              Header            => $self->{Type} eq 'PCF' ? "" : {%$MQSCHeader},
              StrictMapping     => $self->{StrictMapping},
             ) || do {
                 $self->{"CompCode"} = MQSeries::MQCC_FAILED;
                 $self->{"Reason"} = MQSeries::MQRC_UNEXPECTED_ERROR;
                 return;
             };
        my $getresult = $self->{ReplyToQ}->
          Get(Message   => $response,
              Wait      => $self->{Wait},
             );
        #
        # Stats again: keep track of no replies, total bytes, largest
        #
        {
            $self->{'Stats'}->{'NoResponses'}++;
            my $buffer = $response->Buffer();
            my $get_size = defined($buffer) ? length($buffer) : 0;
            $self->{'Stats'}->{'ResponseBytes'} += $get_size;
            $self->{'Stats'}->{'MaxResponse'} = $get_size
              if (! defined $self->{'Stats'}->{'MaxResponse'} ||
                  $get_size > $self->{'Stats'}->{'MaxResponse'});
        }

        unless ($getresult) {
            $self->{"CompCode"} = $self->{ReplyToQ}->CompCode();
            $self->{"Reason"} = $self->{ReplyToQ}->Reason();
            $self->Carp("MQGET from ReplyQ failed.\n" .
                        "Reason => " . MQReasonToText($self->{"Reason"}) . "\n");
            return;
        }

        #
        # Keep going until there are no more messages.  This is
        # essential for MQSC, but PCF tells us when the last response
        # is in.
        #
        last if $self->{ReplyToQ}->Reason() == MQSeries::MQRC_NO_MSG_AVAILABLE;

        #print STDERR "XXX: Response buffer [$response->{'Buffer'}]\n"
        #   if ($self->{Type} eq 'MQSC');

        #
        # Ugly hack:
        # - If this is MQSC
        # - We are asking for an InquireChannelStatus/DeleteChannel,
        #   which gives us a count message, then a 'command accepted'
        #   message, then the real data that we care about
        # - This is that 'command accepted' message
        # Then bin the message.
        #
        push @response_buffers, $response->{'Buffer'};
        if ($self->{Type} eq 'MQSC' &&
            ($command eq 'InquireChannelStatus' ||
             $command eq 'DeleteChannel') &&
            scalar(@{$self->{Response}}) <= 2 &&
            "@response_buffers" =~ m!\bCSQM[A-Z][A-Z][A-Z][A-Z]\b.*\bACCEPTED\s*$!s) {

            #
            # Reset the responses so far.  We must reset the 'reusable'
            # header as well, as the next response may have a different
            # count, return or reason code.
            #
            $self->{Response} = [];
            @response_buffers = ();
            $MQSCHeader = { Command => $command };
            next;
        }

        #
        # FIXME: We probably don't want to keep the response
        #        objects around.
        #
        push(@{$self->{Response}}, $response);

        # Have to "reuse" the header.... blegh.
        $MQSCHeader = $response->Header() if $self->{Type} eq 'MQSC';

        last if $self->_LastSeen();
    }

    #
    # OK, now what do we feed back?
    #
    # If we didn't see the last message, then return the empty list.
    #
    unless ( $self->_LastSeen() ) {
        $self->{"CompCode"} = MQSeries::MQCC_FAILED
          if $self->{"CompCode"} == MQSeries::MQCC_OK;
        $self->{"Reason"} = MQSeries::MQRC_UNEXPECTED_ERROR
          if $self->{"Reason"} == MQSeries::MQRC_NONE;
        $self->Carp("Last response message never seen\n");
        return;
    }

    #
    # Massage the responses.  This varies wildly between PCF and MQSC
    #
    $self->_ProcessResponses($command) || return;

    #
    # Handle the InquireFooNames commands -- they're very easy.
    #
    if ($command eq "InquireChannelNames") {
	#
	# Elide everything but the last response -- we may have gotten
	# individual channel names back for client conns here (as if
	# we had done InquireChannelName) and we don't want them.
	#
	@{$self->{Response}} = $self->{Response}->[-1];
    }
    if ( $command =~ /^Inquire(\w+?Names)$/ ) {
        $key = $1;
        $key = 'QNames' if $key eq 'QueueNames';
        # beware -- the command may have worked, but there may be no
        # names, in which case, $names will be undef.
        my $names = $self->{Response}->[0]->Parameters($key);
        if ( ref $names eq 'ARRAY' ) {
            return @$names;
        } else {
            return;
        }
    }
    #
    # Next handle anything which returns a list of parameters
    #
    elsif ( $command =~ /^(Inquire|ResetQueue|Escape)/ ) {
        my @parameters = $self->DataParameters();
        if ( wantarray ) {
            return @parameters;
        } else {
            return $parameters[0];
        }
    }
    #
    # Handle the "partial completion" reason codes returned by MQSC
    # for some commands.  This just means the command is asynchronous,
    # and will be completed "later".  Eg: StopChannel will stop the
    # channel, but you really need to poll the status with
    # InquireChannelStatus to figure out *when* it has stopped.  Yeah,
    # that sucks...
    #
    elsif ( $command =~ /^(Start|Stop)Channel$/ ) {
        if (
            $self->{"CompCode"} ||
            ( $self->{"Reason"} != 0 && $self->{"Reason"} != 4 )
           ) {
            $self->Carp(qq/Command '$command' failed (Reason = $self->{"Reason"})/);
            return;
        } else {
            return 1;
        }
    }
    #
    # Finally the simple worked or failed commands
    #
    else {
        if ($self->{"CompCode"} == 0 && $self->{"Reason"} == 4 &&
            $self->{"Buffers"}[-1] =~ /CSQN13[78]I .* command (?:accepted|generated)/) {
            #
            # Deal with CommandScope for QSGs.  If CompCode=0 and Reason=4,
            # and the last response is one of:
            # - 'CSQN137I ... command accepted',
            # - 'CSQN138I ... command generated',
            # this is not an error.
            #
            return 1;
        } elsif ( $self->{"CompCode"} || $self->{"Reason"} ) {
            #
            # Save the MQSC ReasonText.  Leave undef (for translation
            # of normal reason code ->text) in other cases.
            #
            if (defined $MQSCHeader &&
                defined $MQSCHeader->{'ReasonText'}) {
                $self->{'Reason'} = 8; # Often corrupted, so sanitize
                $self->{'ReasonText'} = "@{ $MQSCHeader->{'ReasonText'} }";
            }
            $self->Carp(qq/Command '$command' failed (Reason = $self->{"Reason"})/);
            return;
        } else {
            return 1;
        }
    }
}


#
# This routine is the default call-back invoked by the CreateObject
# method.  It compares the requested attributes with the attributes
# found, then returns a list of attributes that need to be changed.
#
# Parameters:
# - Ref to hash with requested attributes, as passed to CreateObject
# - Ref to hash with attributes found (undef if object doesn't exist)
# - Ref to built-in "compare one attribute" function
# Returns:
# - Ref to hash with requested changes
#
sub _CompareAttributes {
    my ($request, $found, $cmp_sub) = @_;

    my $retval = {};
    foreach my $attr (sort keys %$request) {
        #
        # Don't bother comparing Attrs passed in which don't get
        # returned by the Inquire commands, eg. Replace, Force and
        # others that make no sense.
        #
        next if (defined $found && !exists $found->{$attr});

        my $NeedAttr = (defined $found
                        ? $cmp_sub->($attr, $request->{$attr}, $found->{$attr})
                        : 1);
        if ($NeedAttr) {
            $retval->{$attr} = $request->{$attr};
        }
    }                           # End foreach: attribute

    return $retval;
}


#
# Helper routine: compare one attribute, handling the scalar/array
# cases as well as the whitespace issues.
#
# Parameters:
# - Attribute name
# - Requested value
# - Object value / undef
# Returns:
# - 0: unchanged, 1: changed
#
sub _CompareOneAttribute {
    my ($name, $request, $found) = @_;

    my $diff = 0;

    #
    # The HeaderCompression and MessageCompression attributes can
    # return an array padded with '-1' (not available) entries.  If
    # so, we remove such entries (but we keep at least one).
    #
    if (($name eq 'HeaderCompression' || $name eq 'MessageCompression') &&
        ref($found) eq 'ARRAY' && grep { $_ == -1 } @$found) {
        $found = [ grep { $_ != -1 } @$found ];
        if (@$found == 0) {     # No elements set
            $found = -1;
        } elsif (@$found == 1) {
            $found = $found->[0];  # Turn into scalar
        }
    }

    #
    # One special case -- we don't need this attribute is they are
    # both empty and/or white space.  Bear in mind that you have
    # to feed a single space to some of these damn commands.  Very
    # annoying.
    #
    # Well, actually, more than one special case.  If the
    # attribute is a list, then it will be represented as an ARRAY
    # reference.  This does complicate things...
    #
    # First, check to see if we've been fed an array with only one
    # element.  If so, flatten it.  This greatly simplifies the
    # comparison, since the query will not return an ARRAY if
    # there is only one element of any given attribute.
    #
    if (ref $request eq "ARRAY" &&
        scalar @$request == 1) {
        $request = $request->[0];
    }

    if (ref $request ne "ARRAY") {
        if (ref $found eq "ARRAY" ) {
            $diff = 1;
        } elsif ($request !~ /^\s*$/ || $found !~ /^\s*$/ ) {
            if ($request =~ /^\d+\s*$/ ) { # Assume both numeric
                if ($request != $found) {
                    $diff = 1;
                }
            } else {            # Text
                if ($request ne $found) {
                    $diff = 1;
                }
            }
        } else {
            # Both blank, ignore
        }
    } else {                    # Array case
        if (ref $found ne "ARRAY") {
            $diff = 1;
        } elsif (scalar(@$request) != scalar(@$found)) {
            $diff = 1;
        } else {                # Both arrays, same size - compare elements
            for (my $index = 0; $index < scalar(@$request); $index++ ) {
                next if ($request->[$index] =~ /^\s*$/ &&
                         $found->[$index] =~ /^\s*$/);
                if ($request->[$index] =~ /^\d+/ ) {
                    if ($request->[$index] != $found->[$index] ) {
                        $diff = 1;
                    }
                } else {        # Text
                    if ($request->[$index] ne $found->[$index] ) {
                        $diff = 1;
                    }
                }
            }               # End foreach: element
        }                   # End else: Arrays same size
    }                       # End if: scalar/array
    return $diff;
}


#
# FIXME: We want to get rid of this (and of all the response message
# buffering, unless a 'KeepResponses' options is given).  For now,
# we'll alert whenever this method is being used, as a prelude to
# fixing this.
#
sub Responses {
    my $self = shift;

    $self->Carp("MQSeries::Command - Responses() being invoked");

    if ( ref $self->{"Response"} eq "ARRAY" ) {
        return @{$self->{"Response"}};
    } else {
        return;
    }
}


#
# Internal helper routine: Issue a warning message using the
# 'Carp' reference
#
sub Carp {
    my ($self, $message) = @_;

    $self->{'Carp'}->($message);
    return $self;
}


#
# Return the usage statistics
#
sub GetStatistics {
    my ($self) = @_;

    return { %{ $self->{'Stats'} } };
}


#
# Wipe the statistics so far
#
sub ResetStatistics {
    my ($self) = @_;

    $self->{'Stats'} = {};
    return $self;
}


1;

__END__


=head1 NAME

MQSeries::Command - OO interface to the Programmable Commands

=head1 SYNOPSIS

  use MQSeries;
  use MQSeries::Command;

  #
  # Simplest usage
  #
  my $qmgr_obj = MQSeries::QueueManager->
    new(QueueManager => 'some.queue.manager');
  my $command = MQSeries::Command->new(QueueManager => $qmgr_obj);
    or die("Unable to instantiate command object\n");

  #
  # To use MQ v6 features (PCF for z/OS, Filter commands,
  # InquireConnection)
  #
  my $command = MQSeries::Command->new(QueueManager   => $qmgr_obj,
                               CommandVersion => MQSeries::MQCFH_VERSION_3);
    or die("Unable to instantiate command object\n");

  #
  # Inquire XXX Names returns object names,
  # all other Inquire XX commands return hash references
  #
  @qnames = $command->InquireQueueNames()
    or die "Unable to list queue names\n";

  foreach my $qname ( @qnames ) {
      $attr = $command->InquireQueue
        (
         QName          => $qname,
         QAttrs         => [qw(
                               OpenInputCount
                               OpenOutputCount
                               CurrentQDepth
                              )],
        ) or die "InquireQueue: " . MQReasonToText($command->Reason()) . "\n";

      print "QName = $qname\n";

      foreach my $key ( sort keys %$attr ) {
          print "\t$key => $attr->{$key}\n";
      }
  }

  #
  # Filter commands (requires MQ v6 and CommandVersion 3)
  # Like other Inquire XXX commands (excpet Inquire XXX Names),
  # this returns a list of hash references, not obejct names.
  #
  my @full_queues = $command->
    InquireQueueStatus('FilterCommand' => "CurrentQDepth > 10000");
  my @ip_conns = $command->
    InquireConnection('FilterCommand' => "ConnectionName like '144.44.*'");

  #
  # High-level wrapper method: CreateObject
  #
  $command->CreateObject
    (
     Attrs              =>
     {
      QName             => 'FOO.BAR.REQUEST',
      QType             => 'Local',
      MaxQDepth         => '50000',
      MaxMsgLength      => '20000',
     }
    ) || die "CreateObject: " . MQReasonToText($command->Reason()) . "\n";

  $command->CreateObject
    (
     Clear              => 1,
     Attrs              =>
     {
      QName             => 'FOO.BAR.REPLY',
      QType             => 'Remote',
      RemoteQName       => 'FOO.BAR.REPLY',
      RemoteQMgrName    => 'SAT1',
     }
    ) || die "CreateObject: " . MQReasonToText($command->Reason()) . "\n";

=head1 DESCRIPTION

The MQSeries::Command class implements an interface to the
Programmable Command Format messages documented in the:

  "WebSphere MQ Programmable Command Formats and Administration Interface"

section of the MQSeries documentation.  In particular, this document
will primarily explain how to interpret the above documentation, and
thus use this particular implementation in perl.  Please read and
understand the following sections of the above document:

  Programmable Command Formats
    Chapter . Definitions of the Programmable Command Formats
    Chapter . Structures used for commands and responses

This interface also supports the text-based MQSC format messages used
by the queue manager of some platforms, particularly MVS.  Using the
same interface, either PCF or MQSC command server can be queried, with
the results translated into the same format for responses as well.
Note that there are limits to how transparent this is (see MQSC
NOTES), but the code tries quite hard to hide as many of the
differences as possible.

=head2 COMMAND ARGUMENTS

Before we discuss the specific arguments and return values of each of
the methods supported by the MQSeries::Command module, we must explain
how the keys and values used by the interface were chosen, as this
will allow the developer to understand how to take advantage of the
very complete documentation provided by IBM (which will B<not> be
reproduced here).

For each command documented in 'Definitions of the Programmable
Command Formats' (there is a specific page listing all of the
commands, grouped by type), there is a corresponding method in this
class.  For example, there is a method named 'InquireQueueManager',
for the obvious (I hope) PCF command.

All of these methods take a hash of key/value pairs as an argument,
with the keys being those defined in the documentation for each
command.  When writing C code to produce PCF messages, the parameter
names are macros, such as:

  MQIACF_Q_MGR_ATTRS

to specify a list of queue manager attributes.  Rather than use these
names directly, the key strings are taken from the IBM documentation.
In this example, the string used for this key is:

  QMgrAttrs

The values depend on the structure type of the parameter.  If the
structure is a string (MQCFST), byte string (MQBACF) or an integer
(MQCFIN) then the value of the key is simply a scalar string or
integer in perl.  If it either a string list (MQCFSL) or an integer
list (MQCFIL), then the value of the key is an array reference (see
the InquireQueueManager example in the SYNOPSIS) of scalar strings or
integers.

=head2 RETURN VALUES

Most of the individual methods map to underlying commands which do not
return any data.  For all of these, the return value is simply
Boolean; true or false.  That is, the command either worked or failed.

Only the methods associated with those commands documented as
producing data responses:

  Escape
  Inquire AuthInfo
  Inquire AuthInfo Names
  Inquire Authority Records
  Inquire Authority Service
  Inquire Channel
  Inquire Channel Initiator
  Inquire Channel Listener
  Inquire Channel Listener Status
  Inquire Channel Names
  Inquire Channel Status
  Inquire Cluster Queue Manager
  Inquire Connection
  Inquire Entiry Authority
  Inquire Group
  Inquire Log
  Inquire Namelist
  Inquire Namelist Names
  Inquire Process
  Inquire Process Names
  Inquire Queue
  Inquire Queue Manager
  Inquire Queue Manager Status
  Inquire Queue Names
  Inquire Queue Status
  Inquire Service
  Inquire Service Status
  Inquire Subscription
  Inquire Subscription Status
  Inquire System
  Inquire Topic
  Inquire Topic Status
  Reset Queue Statistics

plus the following equivalents for MQSC

  Inquire CFStruc
  Inquire CFStruc Status
  Inquire Usage
  Inquire Security
  Inquire StorageClass

return interesting information.  Most of these will return an array of
hash references, one for each object matching the query criteria.  For
example.  The specific keys are documented in the section of the IBM
documentation which discusses the "Data responses to commands", on the
summary page "PCF commands and responses in groups".  If you have read
the IBM documentation as requested above, you should have found this
page.

Note that in an array context, the entire list is returned, but in a
scalar context, only the first item in the list is returned.

Some of these commands, however, have a simplified return value.  All
of the below:

  Inquire AuthInfo Names
  Inquire CFStruct Names
  Inquire Channel Names
  Inquire Namelist Names
  Inquire Process Names
  Inquire Queue Names
  Inquire StorageClass Names
  Inquire Topic Names

simply return an array of strings, containing the names which matched
the query criteria.

=head1 METHODS

=head2 new

The arguments to the constructor are a hash, with the following
key/value pairs:

  Key                Value
  ===                =====
  QueueManager       String or MQSeries::QueueManager object
  ProxyQueueManager  String or MQSeries::QueueManager object
  RealQueueManager   String
  ReplyToQ           String or MQSeries::Queue object
  CommandQueueName   String
  CommandQueue       MQSeries::Queue object
  CommandVersion     Numeric (1 or 3)
  DynamicQName       String
  ModelQName         String
  Type               String ("PCF" or "MQSC")
  Expiry             Numeric
  Wait               Numeric
  ReplyToQMgr        String
  Carp               CODE Reference
  StrictMapping      Boolean

=over 4

=item QueueManager

This argument specifies the queue manager to which commands are to be
sent.

If the 'ProxyQueueManager' argument is specified, this should be the
name of the target queue manager.

If the 'ProxyQueueManager' argument is not specified, this can either
be an C<MQSeries::QueueManager> object, or the name of the Queue
Manager.  Specifying the queue manager name is deprecated and may
stop working in a future release.

The 'QueueManager' argument can be omitted, in which case the "default
queue manager" is assumed.

=item ProxyQueueManager

The name of the queue manager to which to MQCONN(), and submit
messages on the QueueManagers behalf.  This is to be used if a direct
connection to the QueueManager is not possible, for example MVS queue
managers with support for direct client access.

The messages will be put to what is assumed to be a remote queue
definition which routes to the command queue on the desired
QueueManager.

In order to specify the "default" queue manager as the
ProxyQueueManager, an empty string must be explicitly given.

=item RealQueueManager

If a remote queue manager is controlled through a proxy, by having the
C<QueueManager> parameter specify the proxy and the
C<CommandQueueName> an object descriptor, then by default any output
will print the queue manager name incorrectly.  The
C<RealQueueManager> parameter specifies the name used for display
purposes.

=item ReplyToQ

The ReplyToQ can be opened by the application, and the MQSeries::Queue
object passed in to the MQSeries::Command constructor, if so desired,
os, a fixed queue name can be given.  This is a somewhat advanced
usage of the API, since the default behavior of opening a temporary
dynamic queue under the covers is usually prefered, and much simpler.

The responses are retrieved from the reply queue using gets by
CorrelId, so there should be no issue with using a pre-defined, shared
queue for this, if so desired.

=item CommandQueueName

This specifies the queue to which the command messages will be put.
The defaults are usually reasonable, and depend on the command message
Type (PCF or MQSC).

  PCF   => SYSTEM.ADMIN.COMMAND.QUEUE
  MQSC  => SYSTEM.COMMAND.INPUT

If the ProxyQueueManager has been specified, then we assume the
messages are being written to a remote queue definition, and the
defaults are then:

  PCF   => SYSTEM.ADMIN.COMMAND.QUEUE."QueueManager"
  MQSC  => SYSTEM.COMMAND.INPUT."QueueManager"

See "MQSC NOTES" for some examples of how to use this in practice.

Alternatively, the C<CommandQueue> parameter can be used.

=item CommandQueue

For complex set-ups, where a remote queue manager is managed by the
name of the command queue does not fit the standard scheme, the
command queue can be opened manually and specified in the
MQSeries::Command constructor as the C<CommandQueue> parameter.

The C<CommandQueue> parameter must be combined with the
C<RealQueueManager> parameter.  In the example below, a mainframe
queue manager C<CSQ1> is managed from the queue manager C<UNIXQM> with
a non-standard queue name:

    $queue = MQSeries::Queue::->
      new('QueueManager' => 'UNIXQM',
          'Queue'        => 'REMOTE.FOR.COMMANDQ.ON.CSQ1',
          'Mode'         => 'output',
         ) ||
      die "Cannot open queue";

    $cmd = MQSeries::Command::->
      new('ProxyQueueManager' => 'UNIXQM', # Also ReplyToQMgr
          'RealQueueManager'  => 'CSQ1',   # Displayed in messages
          'Type'              => "MQSC",
          'CommandQueue'      => $queue,
         ) ||
      die "Cannot create command";

If both queue managers run MQ v6, then PCF commands can be used to
communicate with MQ on z/OS.  The above example would be changed as
follows to use PCF commands:

    $cmd = MQSeries::Command::->
      new('ProxyQueueManager' => 'UNIXQM', # Also ReplyToQMgr
          'RealQueueManager'  => 'CSQ1',   # Displayed in messages
          'Type'              => 'PCF',
          'CommandVersion'    => MQSeries::MQCFH_VERSION_3,
          'CommandQueue'      => $queue,
         ) ||
      die "Cannot create command";

This mechanism can also be used when the command queue needs to be
opened with special options.  This is typically combined with a call
to the C<MsgDesc> method:

    my $queue = MQSeries::Queue::->
      new('QueueManager' => 'UNIXQM',
          'Queue'        => 'SYSTEM.ADMIN.COMMAND.QUEUE',
          'Options'      => (MQSeries::MQOO_FAIL_IF_QUIESCING |
                             MQSeries::MQOO_OUTPUT |
                             MQSeries::MQOO_SET_IDENTITY_CONTEXT,
                            ),
         ) ||
      die "Cannot open queue";

    $cmd = MQSeries::Command::->
      new('RealQueueManager' => 'UNIXQM',
          'Type'             => 'PCF',
          'CommandQueue'     => $queue,
         ) ||
      die "Cannot create command";

    $cmd->MsgDesc('ApplIdentityData' => "MyData",
                  'UserIdentifier'   => "mqm",
                 );

=item CommandVersion

This argument is introduced mainly to support the new PCF commands in
MQ v6 (such as FilterCommand filter options) and to use PCF with
QueueManagers on OS/390. It indicates the required PCF Command Version
(MQCFH_CURRENT_VERSION) and Type. This is an optional argument and
Version "1" is used as default. If a value '3' or higher is specified,
then the Command Type "MQCFT_COMMAND_XR" will be used and also the
version is set to "MQCFH_CURRENT_VERSION". Any value less then 3 will
be ignored and the defaults are used (MQCFT_COMMAND and default
version).

=item Type

This argument indicates whether the command server on the QueueManager
supports either PCF or MQSC messages.  The default is PCF.  See the
section "MQSC NOTES" for the Ugly Truth about the MQSC support.

=item Expiry

This value is used as the MQMD.Expiry field on all requests sent to
the command server.  The value is passed to the MQSeries::Message
constructor, and should specify the time in B<tenths of a second>.
The default is 600, or 60 seconds.

A symbolic value ending on 's' for seconds or 'm' for minutes may
also be specified, e.g. the symbolic value '45s' will have the same
meaning as the number 450.

=item Wait

This value is used as the Wait argument to the MQSeries::Queue->Get()
method call made against the ReplyToQ (a dynamic reply queue). and
should be a time specified in B<milliseconds>.  The default is 60000,
or 60 seconds.

A symbolic value ending on 's' for seconds or 'm' for minutes may
also be specified, e.g. the symbolic value '45s' will have the same
meaning as the number 45000.

NOTE: Both the Expiry and Wait defaults may be too slow for heavily
loaded queue managers.  Tune them appropriately.

=item ReplyToQMgr

The ReplyToQMgr normally defaults to the QueueManager, but it can be
overridden, perhaps as a means of specifying an alternate return path
over a specific channel.  For example, the author uses special
channels for SYSTEM related traffic, over which we forward MQSeries
events from one queue manager to another, and also over which we wish
the command server queries to flow.

The "default" path between QMA and QMB flows over a channel called
QMA.QMB, but this traffic is application data, not administrative
system data.  The system queries flow over QMA.QMB.SYSTEM, and we need
to ensure that replies to queries follow a similar reverse path.
Specifying the ReplyToQMgr as "QMB.SYSTEM" accomplishes this.

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

  my $command = MQSeries::Command->new(
                                       QueueManager => 'some.queue.manager',
                                       Carp => \&MyLogger,
                                      )
      or die("Unable to connect to queue manager.\n");

The default, as one might guess, is Carp::carp();

=item StrictMapping

If this argument has a true value, then strict mapping of PCF
parameters and values will be enforced.  Normally, if you feed a bogus
string into the API, it will attempt to map it to the underlying PCF
macro value, and if the mapping fails, it will quietly forgive you,
and ignore the parameter.  Enabling this feature will cause the
translation of an encoded PCF message into the data structure for a
Response, or the translation of a Request into an encoded PCF message,
to fail if any of the mappings fail.

Usually, the command server will generate errors if you feed bogus
data into the API. but that will only occur after the data has been
encoded and sent to the command server.  This feature will allow you
to detect this error before the data is ever sent.

=back

=head2 CompCode

This method will return the MQI CompCode for the most recent MQI call
made by the API.

=head2 Reason

This method will return the MQI Reason for the most recent MQI call
made by the API.

=head2 ReasonText

This method will return different strings depending on whether the
command is MQSC or PCF.  For MQSC, the command server sends back some
text explaining the reason code, and for PCF, we simply call
MQReasonToText on the reason code and return that instead.

MQSC sends back far less information encoded into the reason than PCF
does, and the interesting information is usually found in the
ReasonText.  Therefore, this method should be used when raising
exceptions, in order to get the most descriptive explanation for any
given error.

=head2 Responses

Normally, the data of interest is returned from the method in
question, but the individual responses are available via this method.
This returns a list of MQSeries::Command::Response objects, one for
each individual message recieved.

=head2 DataParameters

This method will return a list of parameters structures from all of
the responses messages sent back which were B<not> error responses.
Some errors will send back responses with parameters, and these could
easily be confused with real data (until you start looking at the
actual data, of course).

=head2 ErrorParameters

This method will return a list of parameters structures from all of
the responses messages sent back which B<were> error responses.  If a
command fails, the Reason() will usually tell you enough about the
cause of the failure, but if the reason is MQRCCF_CFIN_PARM_ID_ERROR,
then the parameters in the error message will indicate which Parameter
key was invalid.

=head2 MsgDesc

In some cases, it is useful or necessary to override specific MQMD
fields in outgoing request messages.  Examples include manually
changeing the Persistence field, or changing the message identity or
origin context.  The MsgDesc method allows you to do so:

  $cmd->MsgDesc('Persistence' => 0);

or

  $cmd->MsgDesc('ApplIdentityData' => "MyData",
                'UserIdentifier'   => "mqm",
               );

Note that setting the message identity or origin context requires you
to open the command queue with the relevant open options; see the
description of the C<CommandQueue> parameter to C<new>.

Note that the C<ReplyToQ>, C<ReplyToQMgr> and C<Expiry> fields for the
request message descriptor can be specified in the constructor C<new>.
The C<MsgDesc> method is intended for the more obscure options.

=head2 CreateObject

This is a generic "wrapper" method for creating any generic MQSeries
object.  The arguments to this method are a hash, with the following
key/value pairs:

  Key                Value
  ===                =====
  Attrs              HASH reference
  Verify             Boolean
  Clear              Boolean
  Quiet              Boolean
  Force              Boolean
  Callback           CODE reference

The key/value pairs in the Attrs argument are passed directly to the
corresponding CreateQueue(), CreateChannel(), or CreateProcess()
method.  However, there is more to this than just creating the object.
For clarity, this discussion will use creation of a queue as an
example.

First, InquireQueue is called to see if the object already exists.  If
it does not exist, then the object is simply created, with the
specified attributes.

If it does exist, and the QType matches, then the actual object
attributes are compared against those passed to the CreateObject
method, and if they match, then no action is taken, and the object is
not modified.

If it does exist, but of a different QType, then the existing object
is deleted, and the new object created as requested.

The idea here is to match the modification of the object conditional
on the need for modifying the object.  If the same CreateObject method
call, with the same arguments, is called twice, then the second method
invocation should be a noop, as far as the actual MQSeries object is
concerned.

=over

=item Attrs

As discussed above, this is a HASH reference, whose key/value pairs
are used to determine what type of object is being created or updated,
and those key/value pairs are passed as-is to the appropriate Create*
method call for the specified MQSeries object type.

=item Verify

If this key has a true value, then no changes will actually be
implemented.  They will merely be reported via test messages on
stdout.

=item Quiet

CreateObject is by default rather chatty about what it is doing, but
all of the messages, other than errors, can be suppressed if this key
has a true value.

=item Clear

Normally, when a Local queue is being replaced with another QType
(eg. Remote or Alias), then the Local queue is not cleared before
being deleted.  If there are messages on the queue, this will cause an
error.  If the queue needs to be cleared, then this key must be passed
with a true value.

This is a seperate option due to the inherit danger of destroying data
accidentally.  If you really want to clear the queues before
recreating them as another QType, you will have to be explicitl about
it.

=item Force

This option will be passed to the Change* method, if the object
already exists and is of type Queue, forcing changes to be applied to
objects which are currently in use.  It is ignored for the other
object types.  Note that this should B<not> be passed as a key to the
Attrs hash, since this is not really an object attribute.

If Force is given as an Attrs key, and the underlying Create* method
is called, since the object does not already exist, then the command
server will return an error.

=item Callback

This optional argument allows you to provide an object comparison
subroutine, instead of relying on the built-in function.  This is
virtually never required, unless your request contains some 'meta'
attributes that translate to multiple or different MQSeries
attributes.

The C<Callback> parameter must be a reference to a subroutine that
receives three parameters: a reference to the requested attributes, a
reference to the attributes found in the object, and a reference to a
subroutine that compares two single attribute values.  The return
value from the subroutine must be a reference to a hash with those
attribute names and values that actually should be changed.

Please see the source code of C<MQSeries::Command>, specifically the
C<_CompareAttributes> method, for the default callback.  Any callback
you provide must behave in a similar way.

=back

=head1 COMMAND REQUESTS

This section is B<NOT> intended to replace the IBM "MQSeries
Programmable System Management" documentation, and it merely serves to
document the specific keys and values used by the perl implementation
of the API.

In all cases, the keys which can be passed to the command are
identical to the strings found in the documentation.  However, some of
the values also have more convenient string mapping as well, as these
are not easily intuited by reading IBMs docs, thus these are clarified
here.

The IBM docs list the possible values for each key as a list of
MQSeries C macros (eg. MQCHT_SENDER), and if given, these will be
respected.  It will be faster to use the strings given, since these
map directly to the actual macro values via a hash lookup, rather than
a function call (all of the various C macros are implemented as
function calls via an AUTOLOAD).  Also, the author finds the
replacement strings far more readable.  YMMV.

For each key shown, the format of value is one of the following:

=over 4

=item (string)

The value given must be a scalar value, interpretable as a text
string.

=item (string list)

The value must be an ARRAY reference of scalar values, all of which
must be interpretable as strings.

NOTE: Some of the parameters (for example, the MsgExit parameter for
the various Channel commands) can take either a string or string list.
In this case, the API will be forgiving, and try to determine what you
meant automatically.  If you pass a reference, it will create a string
list parameter, and if you pass a plain scalar, it will create a
string.

ANOTHER NOTE: if you pass a simple scalar string where a string list
is explicitly required (as opposed to optional), then the API will
create a list of one string for you.

=item (integer)

The value given must be a scalar value, interpretable as an integer.
In some cases, a table will show a mapping from more readable text
strings to the macros documented in the IBM manuals.

=item (integer list)

The value must be an ARRAY reference of scalar values, all of which
must be interpretable as integers.  As with the integer format, in
some cases, a table will show a mapping from more readable text
strings to the macros documented in the IBM manuals.

=item (Boolean)

The value given need only be 0 or 1.  This was done for some of the
integer types which are documented to take a pair of macros, whose
values were simply zero or one, and when the true/false nature of the
key was considered to be intiuitive.  For example, "DataConversion" is
either on (true) or off (false).

=back

Note: List of keys are not documented anymore to avoid needless redundancy.
Please refer to the IBM documentation for the names and values of keys.

=head2 AuthInfo Commands

  Change AuthInfo
  Copy AuthInfo
  Create AuthInfo
  Delete AuthInfo
  Inquire AuthInfo
  Inquire AuthInfo Names

=head2 Authority Records Commands

  Delete Authority Records
  Inquire Authority Records
  Set Authority Record

=head2 Channel Commands

  Change Channel
  Change Channel Listener
  Copy Channel
  Copy Channel Listener
  Create Channel
  Create Channel Listener
  Delete Channel
  Delete Channel Listener
  Inquire Channel
  Inquire Channel Initiator
  Inquire Channel Listener
  Inquire Channel Listener Status
  Inquire Channel Names
  Inquire Channel Status
  Ping Channel
  Reset Channel
  Resolve Channel
  Start Channel
  Start Channel Initiator
  Start Channel Listener
  Stop Channel
  Stop Channel Initiator
  Stop Channel Listener

=head2 CFStruc Commands

  Change CFStruc
  Create CFStruc
  Delete CFStruc
  Inquire CFStruc
  Inquire CFStruc Names

=head2 Cluster Commands

  Inquire Cluster Queue Manager
  Refresh Cluster
  Reset Cluster
  Resume Queue Manager Cluster
  Suspend Queue Manager Cluster

=head2 Connection Commands

  Inquire Connection
  Stop Connection

=head2 Namelist Commands

  Change Namelist
  Copy Namelist
  Create Namelist
  Delete Namelist
  Inquire Namelist
  Inquire Namelist Names

=head2 Process Commands

  Change Process
  Copy Process
  Create Process
  Delete Process
  Inquire Process
  Inquire ProcessNames

=head2 Queue Commands

  Change Queue
  Clear Queue
  Copy Queue
  Create Queue
  Delete Queue
  Inquire Queue
  Inquire Queue Names
  Move Queue
  Reset Queue Statistics

=head2 Inquire Queue Status Command

The C<InquireQueueStatus> command does not behave like the other queue
commands.  Please refer to IBM documentation for complete details.

For a request, the following keys are supported:

    QName
    StatusType
    OpenType
    QStatusAttrs

The output of the C<InquireQueueStatus> is dependent on the
C<StatusType> specified.

=head2 Queue Manager Commands

  Change Queue Manager
  Inquire Queue Manager
  Inquire Queue Manager Status
  Ping Queue Manager
  RefreshQueueManager
  ResetQueueManager
  ResumeQueueManager
  SuspendQueueManager

=head2 Security Commands

  ChangeSecurity
  InquireSecurity
  RefreshSecurity
  ReverifySecurity

=head2 Service Commands

  Change Service
  Copy Service
  Create Service
  Delete Service
  Inquire Service
  Inquire Service Status
  Start Service
  Stop Service

=head2 StorageClass Commands

  Change StorageClass
  Create StorageClass
  Delete StorageClass
  Inquire StorageClass
  Inquire StorageClass Names

=head2 Subscription Commands

  Change Subscription
  Copy Subscription
  Create Subscription
  Delete Subscription
  Inquire Subscription
  Inquire Subscription Status

=head2 System Commands

  Inquire Group
  Inquire Log
  Inquire System
  Inquire Usage
  Set Log
  Set System

=head2 Topic Commands

  Change Topic
  Clear Topic String
  Copy Topic
  Create Topic
  Delete Topic
  Inquire Topic
  Inquire Topic Names
  Inquire Topic Status

=head2 Escape Command

This command is not really part of a grouping, so its all by itself
here.

The following keys have special value mappings:

=over 4

=item EscapeType                (integer)

    Key                         Macro
    ===                         =====
    MQSC                        MQET_MQSC

=back

=head1 COMMAND RESPONSES

There are several commands which return data.  The return value of the
actual command methods depends on the specific command.  All of the
"Inquire*Names" commands return a list of the actual names returned,
which greatly simplifies the parsing of the return value.

For example:

  @qnames = $command->InquireQueueNames( QName => 'FOO.*' );

will result in @qnames containing a list of strings of all of the
queue names starting with FOO.

The rest of the commands return a list of Parameters HASH references,
extracted from each of the messages sent back from the command server.
In a scalar context, only the first Parameters HASH reference is
returned. Refer to the L</RETURN VALUES> section for the list of
commands.

For example:

  @queues = $command->InquireQueue( QName => 'FOO.*', QAttrs => 'All' );

will result in @queues containing a list of HASH references, each of
which has key/value pairs for the attributes of one of the queues
starting with FOO.

The keys in the Parameters HASH references are mapped from the numeric
macro values back into the same strings described above for
simplifying the input Parameters.

However, there are a few keys in the responses which are not supported
as keys in the inquiry.  In general, the return values are left
unmolested.

=head1 FILTERS

For PCF requests to MQ v6 and above, filter commands can be used to
have the queue manager filter out only objects of interest.  For
example, you can inquire for queues with a certain maximum message
length, for connections from specific IP addresses, or for queue
status with a minimum queue depth.

Filters require that the command object is created with CommandVersion
3, i.e.

  $command = MQSeries::Command::->
    new('QueueManager'   => 'SOME.QUEUE.MANAGER',
        'Type'           => 'PCF',
        'CommandVersion' => MQSeries::MQCFH_VERSION_3);

Following that, most Inquire commands accept an optional FilterCommand
parameter that specifies an attribute to filter on, a comparison
operator, and a value.  (See the IBM documentation for which Inquire
commands support filters.)

The filter can be specified in pseudo-SQL syntax, e.g. :

  @queues = $command->
    InquireQueue('FilterCommand' => "QName like 'SYSTEM.PE*'");
  @queues = $command->
    InquireQueue('FilterCommand' => "MaxQDepth > 10000");

Alternatively, if the value used contains quotes, or if the filter is
constructed dynamically, the filter can be specified as a hash
reference:

  @queues = $command->
    InquireQueue('FilterCommand' => { Parameter => 'MaxQDepth',
                                      Operator  => '>',
                                      Value     => 100_000,
                                    });

The supported filter parameters (field names) are almost any field
returned by the Inquire command (see the IBM documentation for
details).  The supported value can be an integer, string, string
wildcard (a value ending on a '*'), or (for enumerated types) the
constant name as returned by the Inquire command.  For example, for an
enumerated type, to query for alias queues that have a rmote queue as
their base type:

  @queues = $command->
    InquireQueue('FilterCommand' => "BaseType == Remote");

The operators supported depend on the parameter type.  All types
support equal (==) and unequal (<>, !=); numeric types also support
the numeric comparators (<, >, <=, >=); string types support 'like'
and 'not like' with a wildcard value ending on '*'; integer list types
support 'contains' and 'excludes'; and string list types support
'contains', 'excludes', 'contains_gen' and 'excludes_gen', where the
latter to values perform a wildcard comparison.  The examples below
illustrate supported usage.

  BaseType == Local
  BaseType <> Local
  BytesSent > 10000
  CurrentQDepth > 10000
  Msgs <= 100
  ConnectionName like '144.14.*'
  BaseQName not like 'SYSTEM.*'
  HeaderCompression contains 'gzip'
  HeaderCompression excludes 'gzip'

Note that the filter is not evaluated as a perl expression.  The
MQSeries::Command class parses the expression into a parameter,
operator and value; then converts the value to the appropriate type (a
value lookup for enumerated types, a conversion to integer for
numbers, and conversion to string for strings).  In other words, the
expected amount of DWIM is in place.

=head1 SEE ALSO

MQSeries(3), MQSeries::Queue(3), MQSeries::Message(3),
  MQSeries::Command::Request(3), MQSeries::Command::Response(3)

In addition, the MQSeries documentation is the primary source of
documentation for the commands and their arguments, especially the
following sections.

For MQSeries 5.2 and before, this is:

  "MQSeries Programmable System Management"
  Part 2. Programmable Command Formats
    Chapter 8. Definitions of the Programmable Command Formats
    Chapter 9. Structures used for commands and responses

For WebSphere MQ 5.3, this is:

  "WebSphere MQ Programmable Command Formats and Administration Interface"
  Part 1. Programmable Command Formats
    Chapter 4. Definitions of the Programmable Command Formats
    Chapter 5. Structures used for commands and responses

For WebSphere MQ 6.0 and 7.0, this is:

  Same as 5.3 except the Chapter numbers. In 6.0 doc they are Chapter 3 and 4.

=cut
