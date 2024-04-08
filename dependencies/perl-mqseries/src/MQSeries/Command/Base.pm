#
# $Id: Base.pm,v 38.8 2012/09/26 16:10:14 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::Base;

use 5.008;

use strict;
use Carp;

use MQSeries qw(:functions);
use MQSeries::Command;
use MQSeries::Command::PCF;
use MQSeries::Command::MQSC;
use MQSeries::Message;
use MQSeries::Message::PCF qw(MQEncodePCF MQDecodePCF);

our $VERSION = '1.34';

sub new {

    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %args = @_;

    my %MsgDesc =
      (
       MsgType  => $class =~ /::Request/ ? MQSeries::MQMT_REQUEST : MQSeries::MQMT_REPLY,
       Format   => $args{Type} eq 'MQSC' ? MQSeries::MQFMT_STRING : MQSeries::MQFMT_ADMIN,
      );

    if ( exists $args{MsgDesc} ) {
        unless ( ref $args{MsgDesc} eq "HASH" ) {
            $args{Carp}->("Invalid argument: 'MsgDesc' must be a HASH reference.\n");
            return;
        }
        foreach my $key ( keys %{$args{MsgDesc}} ) {
            $MsgDesc{$key} = $args{MsgDesc}->{$key};
        }
    }

    $args{MsgDesc} = {%MsgDesc};

    my $self = MQSeries::Message->new(%args) || return;

    #
    # What type of request is this?  PCF or MQSC?
    #
    if ( $args{Type} ) {
        unless ( $args{Type} eq 'PCF' or $args{Type} = 'MQSC' ) {
            $self->{Carp}->("Invalid argument: 'Type' must be one of: PCF MQSC");
            return;
        }
        $self->{Type} = $args{Type};
    } else {
        $self->{Type} = 'PCF';
    }

    #
    # The Command argument is required... but now (1.12 and later) we
    # check this in PutConvert.
    #
    if ( $args{"Header"} ) {
        if ( ref $args{"Header"} eq 'HASH' ) {
            $self->{"Header"} = $args{"Header"};
            $self->{Command} = $self->{"Header"}->{Command}
              if exists $self->{"Header"}->{Command};
        } else {
            $self->{Carp}->("Invalid argument: 'Header' must be a HASH reference");
            return;
        }
    }

    if ( $args{Command} ) {
        if ( $self->{Type} eq 'PCF' ) {
            unless ( exists $MQSeries::Command::PCF::Requests{$args{Command}} ) {
                $self->{Carp}->("Invalid PCF command '$args{Command}'\n");
                return;
            }
        } else {
            unless ( exists $MQSeries::Command::MQSC::Requests{$args{Command}} ) {
                $self->{Carp}->("Invalid MQSC command '$args{Command}'\n");
                return;
            }
        }
        $self->{Command} = $args{Command};
        $self->{"Header"}->{Command} = $args{Command};
    }

    #
    # The Parameters argument is optional
    #
    if ( $args{Parameters} ) {

        if ( ref $args{Parameters} eq 'HASH' ) {
            $self->{Parameters} = $args{Parameters};
        } else {
            $self->{Carp}->("Invalid argument: 'Parameters' must be a HASH reference");
            return;
        }
    } else {
        $self->{Parameters} = {};
    }

    #
    # Do we want strict mapping turned on?
    #
    if ( exists $args{StrictMapping} ) {
        $self->{StrictMapping} = $args{StrictMapping};
    }

    #
    # At last, we need to pass the required PCF version to set Version and Type
    #  in the PCF header
    #
    $self->{CommandVersion} = $args{CommandVersion};

    bless ($self, $class);

    return $self;

}


#
# This routine replaces something I originally did in C, using the
# perl internals API, to lookup all of these hashes and arrays.
#
# Yes, I was insane...
#
sub _TranslatePCF {
    my ($self, $header, $origparams) = @_;

    my $command = $header->{Command};

    #
    # Set the type to either
    # - MQSeries::MQCFT_COMMAND (default)
    # - MQSeries::MQCFT_COMMAND_XR (PCF against the MF, filters)
    #
    ($header->{Type}) = ( $self->isa("MQSeries::Command::Response") ?
                          MQSeries::MQCFT_RESPONSE :
                          ( $self->{CommandVersion} < 3 ?
                            MQSeries::MQCFT_COMMAND :
                            MQSeries::MQCFT_COMMAND_XR ),
                        );

    my $parameters = [];

    my ($ForwardMap) = ( $self->isa("MQSeries::Command::Response") ?
                         \%MQSeries::Command::PCF::Responses :
                         \%MQSeries::Command::PCF::Requests );

    my ($RequiredMap) = ( $self->isa("MQSeries::Command::Response") ?
                          {} :
                          \%MQSeries::Command::PCF::RequestParameterRequired );

    #
    # Special handling for error responses.
    #
    my $CommandMap = $ForwardMap->{$command} || do {
        $self->{Carp}->("Unknown command '$command'");
        return;
    };

    $header->{Command} = $CommandMap->[0];

    my ($ParameterMap) = ( $header->{CompCode} ?
                           $ForwardMap->{Error}->[1] :
                           $CommandMap->[1] );

    my ($ParameterRequired) = ( exists $RequiredMap->{$command} ?
                                $RequiredMap->{$command} :
                                {} );

    #
    # Now copy the required parameters list so that we can muck with
    # the copy.  Some of the values in the list may, in fact, be code
    # refs (and not just plain numbers), which will decide (at this
    # time, based on the target qmgr's command level) whether they are
    # required or not.
    #
    $ParameterRequired = { %{$ParameterRequired} };
    foreach my $param (keys %{$ParameterRequired}) {
        next if (ref($ParameterRequired->{$param}) ne "CODE");
        my $newval = delete($ParameterRequired->{$param})->
            ($self->{QueueManager}->{QMgrConfig}->{CommandLevel});
        next if (!defined($newval));
        $ParameterRequired->{$param} = $newval;
    }

    my @required_order = sort { $ParameterRequired->{$a} <=>
                                $ParameterRequired->{$b}
                              } keys %$ParameterRequired;
    my $ParameterOrderList = $MQSeries::Command::PCF::RequestParameterOrder{$command};
    my @optional_order = ($ParameterOrderList ? @$ParameterOrderList : ());

    my %ParameterOrderHash = map { ($_,1) } (@required_order, @optional_order);

    #
    # If a FilterCommand has been specified, translate it into a
    # StringFilterCommand, IntegerFilterCommand, or a
    # ByteStringFilterCommand.
    #
    # We accept two types of filters:
    # - string: QDepth > 500
    # - hash: Parameter -> QDepth, Operator -> greater, Value -> 500
    #
    my $filter = delete $origparams->{FilterCommand};
    if (defined $filter) {
        #
        # We only support filters for requests; and filters require
        # the command version is 3.
        #
        if ($self->isa("MQSeries::Command::Response")) {
            $self->{Carp}->("FilterCommand only support for PCF requests, not responses");
            return;
        }
        if ($self->{CommandVersion} < MQSeries::MQCFH_VERSION_3) {
            $self->{Carp}->("FilterCommand requires PCF commands with CommandVersion >= ", MQSeries::MQCFH_VERSION_3);
            return;
        }

        my $valid = 0;
        if (ref $filter) {
            if (ref $filter eq 'HASH' &&
                keys %$filter == 3 &&
                defined $filter->{Parameter} &&
                defined $filter->{Operator} &&
                defined $filter->{Value}) {
                $valid = 1;
            }
        } else {
            if ($filter =~ /^ \s* (\w+) \s*
                            ([<>!=]+ | \s+ like \s+ | \s+ contains \s+ | \s+ excludes \s+ | \s+ contains_gen \s+ | \s+ excludes_gen \s+ | \s+ not \s+ like \s+)
                            \s* ( -?\d+ | \w+ | \'[^']+\' ) \s* $/ix) {
                my ($param, $op, $val) = ($1, $2, $3);
                $val = substr($val, 1, length($val)-2) if ($val =~ /^\'.*\'$/);
                #print "_TranslatePCF: translate filter 'filter' into p $param, op $op, val $val\n";
                $op = lc $op;   # for like / not like / ...
                $op =~ s/^\s+//; # trim
                $op =~ s/\s+$//;  # rtrim
                $op =~ s/\s+/ /g; # for 'not like'
                $filter = { 'Parameter' => $param,
                            'Operator'  => $op,
                            'Value'     => $val,
                          };
                $valid = 1;
            } else {
                $self->{Carp}->("Cannot parse filter '$filter', expected format 'QDepth > 500'");
                return;
            }
        }
        unless ($valid) {
            $self->{Carp}->("Filter must be specified as a string or as a hash reference with Parameter, Operator, and Value");
            return;
        }

        #
        # Now find parameter; based on type, create the right filter type
        #
        # The parameters that can be specified are all the attributes
        # for the object.  Since we need to have the type and possible
        # values, we need to get the response parameters, not the
        # request parameters.  Filters effectively apply to what is
        # coming back, not what you are asking for.
        #
        my $param_map = $MQSeries::Command::PCF::Responses{$command}->[1];
        unless (defined $param_map->{ $filter->{Parameter} }) {
            $self->{Carp}->("Invalid filter: parameter '$filter->{Parameter}' not known");
            return;
        }
        my ($paramkey,$paramtype,$ValueMap) = @{ $param_map->{ $filter->{Parameter} } };
        if ($paramtype == MQSeries::MQCFT_STRING ||
            $paramtype == MQSeries::MQCFT_STRING_LIST) {
            $filter->{Command} = 'StringFilterCommand';
        } elsif ($paramtype == MQSeries::MQCFT_BYTE_STRING) {
            $filter->{Command} = 'ByteStringFilterCommand';
        } elsif ($paramtype == MQSeries::MQCFT_INTEGER ||
                 $paramtype == MQSeries::MQCFT_INTEGER64 ||
                 $paramtype == MQSeries::MQCFT_INTEGER_LIST ||
                 $paramtype == MQSeries::MQCFT_INTEGER64_LIST) {
            $filter->{Command} = 'IntegerFilterCommand';
        } else {
            $self->{Carp}->("Unexpected type '$paramtype' for filter parameter '$filter->{Parameter}'");
            return;
        }
        if (defined $origparams->{ $filter->{Command} }) {
            $self->{Carp}->("Cannot use both 'Filter' and '$filter->{Command}'");
            return;
        }

        #
        # Translate the operator string to an MQ constant
        #
        my %ops = ('<'    => MQSeries::MQCFOP_LESS,
                   '<='   => MQSeries::MQCFOP_NOT_GREATER,
                   '=='   => MQSeries::MQCFOP_EQUAL,
                   '!='   => MQSeries::MQCFOP_NOT_EQUAL,
                   '<>'   => MQSeries::MQCFOP_NOT_EQUAL,
                   '>'    => MQSeries::MQCFOP_GREATER,
                   '>='   => MQSeries::MQCFOP_NOT_LESS,
                   'like' => MQSeries::MQCFOP_LIKE,
                   'not like' => MQSeries::MQCFOP_NOT_LIKE,
                  );
        my %list_ops = ('=='           => MQSeries::MQCFOP_CONTAINS,
                        'contains'     => MQSeries::MQCFOP_CONTAINS,
                        '!='           => MQSeries::MQCFOP_EXCLUDES,
                        '<>'           => MQSeries::MQCFOP_EXCLUDES,
                        'excludes'     => MQSeries::MQCFOP_EXCLUDES,
                        'like'         => MQSeries::MQCFOP_CONTAINS_GEN,
                        'contains_gen' => MQSeries::MQCFOP_CONTAINS_GEN,
                        'not like'     => MQSeries::MQCFOP_EXCLUDES_GEN,
                        'excludes_gen' => MQSeries::MQCFOP_EXCLUDES_GEN,
                       );
        my $op = $ops{ $filter->{Operator} };
        if ($paramtype == MQSeries::MQCFT_INTEGER_LIST ||
            $paramtype == MQSeries::MQCFT_INTEGER64_LIST ||
            $paramtype == MQSeries::MQCFT_STRING_LIST) {
            $op = $list_ops{ $filter->{Operator} };
        }
        unless (defined $op) {
            $self->{Carp}->("Unexpected operator '$filter->{Operator}'  for filter parameter '$filter->{Parameter}'");
            return;
        }

        #
        # May have to translate value from text -> number
        #
        my $value = $filter->{Value};
        if (defined $ValueMap) {
            # VALUEMAP-CODEREF
            my $mapped = ref($ValueMap) eq "CODE" ?
                $ValueMap->(encodepcf => $value) : $ValueMap->{$value};
            if (defined $mapped) {
                #print "Translate value '$value' to '$mapped'\n";
                $value = $mapped;
            } else {
                $self->{Carp}->("Cannot translate value '$value' to numeric constant for filter parameter '$filter->{Parameter}'");
                return;
            }
        } else {
            #print "No need to translate filter parameter '$filter->{Parameter}' value '$value'\n";
        }

        #
        # The PCF XS code expects an array reference of format
        # [ Parameter, Operator, Value ]
        #
        $origparams->{ $filter->{Command} } =
          [ $paramkey, $op, $value ];
    }

    #
    # Verify that all of the parameters are known - this finds my typos...
    #
    {
        my $unknown = 0;
        foreach my $param (keys %$origparams) {
            next if (defined $ParameterMap->{$param});
            $self->{'Carp'}->("Unknown parameter '$param' for command '$command'");
            $unknown++;
        }
        return if $unknown;
    }

    #
    # Verify that all of the required parameters have been given.
    #
    {
        my $required = 0;
        foreach my $param ( keys %$ParameterRequired ) {
            next if (defined $origparams->{$param});
            $self->{Carp}->("Required parameter '$param' not specified for command '$command'");
            $required++;
        }
        return if $required;
    }

    #
    # Sort the parameters, required then optional, and if necessary,
    # command dependent order.
    #
    my @ordered_params = ();
    foreach my $pair ( [ 'Required', \@required_order ],
                       [ 'Optional', \@optional_order ] ) {
        my ($type, $list) = @$pair;

        foreach my $param (@$list) {
            next unless defined $origparams->{$param};
            push @ordered_params, $param;
        }
        #print STDERR "Ordered: @ordered_params\n";

        foreach my $param (keys %$origparams) {

            next if ($type eq 'Required' &&
                     not exists $ParameterRequired->{$param});
            next if ($type eq 'Optional' &&
                     exists $ParameterRequired->{$param});
            push @ordered_params, $param
              unless $ParameterOrderHash{$param};
        }
    }
    #print STDERR "Ordered: @ordered_params\n";

    my @groupstack;
    for (my $idx = 0; $idx < @ordered_params; $idx++) {
        my $param = $ordered_params[$idx];
        my $origvalue = $origparams->{$param};

        #print STDERR "Param : $param\n";
        #if (ref $origvalue) {
        #    print STDERR "OrigVal:", @$origvalue,"\n";
        #}

        my ($paramkey,$paramtype,$ValueMap) = @{ $ParameterMap->{$param} };

        #print STDERR "PKey: $paramkey\n";
        #print STDERR "PType: $paramtype\n";
        #if (ref $ValueMap) {
        #    print STDERR "ValMap:", %$ValueMap, "\n";
        #}

        my $newparameter =
          {
           Parameter    => $paramkey,
           Type         => $paramtype,  # PCF.xs might want to know...
          };

        #
        # If the value passed is is an ARRAY, then make the
        # parameter a string list (Strings).  If not, and the
        # $paramtype requires a string list (MQCFT_STRING_LIST),
        # then make the value into a single entry array.
        #
        # NOTE: We forcibly quote the values to force them into
        # strings, otherwise SvPOK() will complain about integers,
        # which can of course be represented as strings.  This
        # might just be a bad choice on my part in the XS code.
        #
        if ( $paramtype == MQSeries::MQCFT_STRING ||
             $paramtype == MQSeries::MQCFT_STRING_LIST ) {
            if ( ref($ValueMap) eq "CODE" ) {
                # VALUEMAP-CODEREF - leave type and $origvalue alone
            } elsif ( ref $origvalue eq "ARRAY" &&
                 $paramtype == MQSeries::MQCFT_STRING ) {
                # flip type to match list
                $newparameter->{"Type"} = $paramtype =
                    MQSeries::MQCFT_STRING_LIST;
            } elsif ( ref $origvalue ne "ARRAY" &&
                      $paramtype == MQSeries::MQCFT_STRING_LIST ) {
                # array-ify non array
                $origvalue = [ $origvalue ];
            }
            if (ref($ValueMap) eq "CODE") {
                my ($typename, $newvalue);
                if ($paramtype == MQSeries::MQCFT_STRING) {
                    $typename = "String";
                    # VALUEMAP-CODEREF
                    $newvalue = $ValueMap->(encodepcf => $origvalue);
                } elsif (ref($origvalue) eq "ARRAY") {
                    $typename = "Strings";
                    # VALUEMAP-CODEREF
                    $newvalue = [map({ $ValueMap->(encodepcf => $_) }
                                     @{$origvalue})];
                } else {
                    $typename = "Strings";
                    # VALUEMAP-CODEREF
                    $newvalue = [$ValueMap->(encodepcf => $origvalue)];
                }
                $newparameter->{$typename} = $newvalue;
            } elsif ( $paramtype == MQSeries::MQCFT_STRING_LIST ) {
                $newparameter->{Strings} = [];
                foreach my $value ( @$origvalue ) {
                    my $newvalue = length($value) == 0 ? " " : "$value";
                    push(@{$newparameter->{Strings}},"$newvalue");
                }
            } else {
                my $newvalue = length($origvalue) == 0 ? " " : "$origvalue";
                $newparameter->{String} = $newvalue;
            }
        }

        #
        # BYTE_STRING - Added newly for WMQ6 : Not fully tested
        #
        if ( $paramtype == MQSeries::MQCFT_BYTE_STRING ) {
            my $newvalue = length($origvalue)== 0 ? "\0" : pack("H*",$origvalue);
            #print "byte string orig value: [$origvalue] - new value: [$newvalue]\n";
            $newparameter->{ByteString} = "$newvalue";
        }

        if ( $paramtype == MQSeries::MQCFT_INTEGER ||
             $paramtype == MQSeries::MQCFT_INTEGER64 ) {
            if (!ref($ValueMap)) {
                $newparameter->{Value} = $origvalue;
            }
            elsif (ref($ValueMap) eq "CODE") {
                # VALUEMAP-CODEREF
                $newparameter->{Value} = $ValueMap->(encodepcf => $origvalue);
            }
            elsif (exists($ValueMap->{$origvalue})) {
                $newparameter->{Value} = $ValueMap->{$origvalue};
            }
            if (!defined($newparameter->{Value})) {
                $self->{Carp}->("Unknown int value '$origvalue' for " .
                                "parameter '$param', command '$command'");
                return;
            }
        }

        if ( $paramtype == MQSeries::MQCFT_INTEGER_LIST ||
             $paramtype == MQSeries::MQCFT_INTEGER64_LIST ) {
            foreach my $value ( @$origvalue ) {
                if ( ref $ValueMap ) {
                    # VALUEMAP-CODEREF
                    my $mapped = ref($ValueMap) eq "CODE" ?
                        $ValueMap->(encodepcf => $value) : $ValueMap->{$value};
                    if (!defined($mapped)) {
                        $self->{Carp}->("Unknown intlist value '$value' for " .
                                        "parameter '$param', command '$command'");
                        return;
                    }
                    push(@{$newparameter->{Values}}, $mapped);
                } else {
                    push(@{$newparameter->{Values}},$value);
                }
            }
        }

        #
        # MQ v6 and above: Integer/String/ByteString Filter
        #
        if ($paramtype == MQSeries::MQCFT_BYTE_STRING_FILTER) {
            unless (ref $origvalue eq 'ARRAY' &&
                    @$origvalue == 3) {
                $self->{Carp}->("Invalid byte string filter for parameter '$param', command '$command': must be an array-reference with three elements");
                return;
            }
            #print STDERR "XXX: Have byte string filter for [@$origvalue]\n";
            $newparameter->{ByteStringFilter} = $origvalue;
        } elsif ($paramtype == MQSeries::MQCFT_INTEGER_FILTER) {
            unless (ref $origvalue eq 'ARRAY' &&
                    @$origvalue == 3) {
                $self->{Carp}->("Invalid integer filter for parameter '$param', command '$command': must be an array-reference with three elements");
                return;
            }
            #print STDERR "XXX: Have integer filter for [@$origvalue]\n";
            $newparameter->{IntegerFilter} = $origvalue;
        } elsif ($paramtype == MQSeries::MQCFT_STRING_FILTER) {
            unless (ref $origvalue eq 'ARRAY' &&
                    @$origvalue == 3) {
                $self->{Carp}->("Invalid string filter for parameter '$param', command '$command': must be an array-reference with three elements");
                return;
            }
            #print STDERR "XXX: Have string filter for [@$origvalue]\n";
            $newparameter->{StringFilter} = $origvalue;
        } elsif ($paramtype == MQSeries::MQCFT_GROUP) {
            if (ref($origvalue) ne 'ARRAY') {
                $self->{Carp}->("Invalid group for parameter '$param', command '$command': must be an array-reference");
                return;
            }
            # replace current parameter with an ObjectCount; the group
            # itself will be handled below
            if (!defined($header->{"Version"})) {
                $header->{"Version"} = MQSeries::MQCFH_VERSION_3;
            }
            $newparameter = {
                             "Parameter" => MQSeries::MQIAMO_OBJECT_COUNT,
                             "Type"      => MQSeries::MQCFT_INTEGER,
                             "Value"     => scalar(@{$origvalue}),
                            };
        }

        push(@$parameters,$newparameter);

        # if we're entering a group, add group stack frames
        if ($paramtype == MQSeries::MQCFT_GROUP) {
            # push all group elements into *this* encoding unit
            my $top = $parameters;
            # replace encoding state with all group elements (note
            # that while they actually get encoded in reverse order,
            # they are added to $parameters here in the proper order)
            foreach my $gelem (0..$#{$origvalue}) {
                # make and add a brand new parameter to $top
                $newparameter = {
                                 "Parameter" => $paramkey, 
                                 "Type"      => $paramtype,
                                 "Group"     => [],
                                };
                push(@$top, $newparameter);
                # save current encoding state
                my $frame = [$origparams, $parameters, $ParameterMap,
                             $idx, @ordered_params];
                push(@groupstack, $frame);
                # flip encoding state to *this* group element
                $origparams     = $origvalue->[$gelem];
                $parameters     = $newparameter->{"Group"};
                $ParameterMap   = $ValueMap;
                $idx            = -1; # account for increment in top for (;;)
                # XXX - note that @ordered_params is actually unordered
                # (maybe we'll fix this later)
                @ordered_params = keys %{$origparams};
            }
        }

        # if we're done with a group, pop off group stack frames
        while ($idx + 1 >= @ordered_params && @groupstack) {
            my $frame = pop(@groupstack);
            ($origparams, $parameters, $ParameterMap,
             $idx, @ordered_params) = @{$frame};
        }
    }
    #print STDERR "Params returned:", @$parameters,"\n";

#     foreach my $el(@$parameters) {
#       print "Element:", %$el,"\n";
#        foreach my $val(values %$el) {
#            if (ref $val) {
#                print "Values: ", @$val, "\n";
#            }
#        }
#     }

    #
    # Lets set the Version to work with advanced V6 cmds and V6 MF qmgrs
    #
    $header->{Version} = MQSeries::MQCFH_CURRENT_VERSION
        unless ( $self->{CommandVersion} lt 3 );

    #print STDERR "Request Header: $header->{Type}, $header->{StrucLength}, $header->{Version}, $header->{Command}, $header->{Reason}, $header->{ParameterCount}...\n";
    #print STDERR "header\n", map { "\t$_:$header->{$_}\n" } sort keys %$header;

    return ($header,$parameters);
}


#
# This routine does the reverse mapping of _TranslatePCF.
#
sub _UnTranslatePCF {

    my $self = shift;

    my ($header,$origparams) = @_;

    my $command = $header->{Command};

    #print STDERR "Response Header - $command, $header->{Type}, $header->{Version}, $header->{Reason}, $header->{ParameterCount}\n";
    #print STDERR "header\n", map { "\t$_:$header->{$_}\n" } sort keys %$header;

    #
    # The (rather obscure) 'Escape' command requires special handling
    # of the reply reminiscent of the MQSC command handling.  Courtesy
    # of Mike Surikov.
    #
    # NOTE: Since MQIACF_ESCAPE_TYPE conflicts with the Morgan Stanley
    #       extension for MQIAE_AUTH_PASSID, we have to exclude the
    #       MQCMDE_INQUIRE_AUTHORITY from this processing.
    #
    if( $command != MQSeries::MQCMDE_INQUIRE_AUTHORITY &&
        $self->isa("MQSeries::Command::Response") &&
        scalar(@$origparams) &&
        exists($origparams->[0]->{Parameter}) &&
        ($origparams->[0]->{Parameter} == MQSeries::MQIACF_ESCAPE_TYPE ||
         $origparams->[0]->{Parameter} == MQSeries::MQCACF_ESCAPE_TEXT) ) {
        $command = MQSeries::MQCMD_ESCAPE;
    }

    my $parameters = {};

    my ($ReverseMap) = ( $self->isa("MQSeries::Command::Response") ?
                         \%MQSeries::Command::PCF::_Responses :
                         \%MQSeries::Command::PCF::_Requests );

    my $CommandMap = $ReverseMap->{$command} || do {
        $self->{Carp}->("Unknown command '$command'");
        return;
    };

    $header->{Command} = $CommandMap->[0];

    my $ParameterMap = ( $header->{CompCode} ?
                         $ReverseMap->{Error}->[1] :
                         $CommandMap->[1] );

    my @groupstack;
    for (my $idx = 0; $idx < @$origparams; $idx++) {
        my $origparam = $origparams->[$idx];

        #print "OrigP: $origparam\n";
        my $paramkey = $ParameterMap->{$origparam->{Parameter}}->[0];
        #unless (defined $paramkey) {
        #    warn "Unexpected PCF parameter '$origparam->{Parameter}'\n";
        #}
        my $paramvalue = "";

        #print "ParamKey: [$origparam->{Parameter}] [$paramkey]\n";
        #print  "param\n", map { "\t$_:$origparam->{$_}\n" } sort keys %$origparam;

        if ( exists $origparam->{String} ) {
            ( $paramvalue = $origparam->{String} ) =~ s/\s+$//;
        } elsif ( exists $origparam->{ByteString} ) {
            $paramvalue = unpack("H*",$origparam->{ByteString});
        } elsif ( exists $origparam->{Strings} ) {
            $paramvalue = [];
            foreach my $string ( @{$origparam->{Strings}} ) {
                $string =~ s/\s+$//;
                push(@{$paramvalue}, $string);
            }
        } elsif ( exists $origparam->{Value} ) {
            $paramvalue = $origparam->{Value};
        } elsif ( exists $origparam->{Values} ) {
            $paramvalue = $origparam->{Values};
        } elsif ( exists $origparam->{FilterValue} ) {
            $paramvalue = $origparam->{FilterValue};
        } elsif ( exists $origparam->{Group} ) {
            $paramvalue = $origparam->{Group};
        } else {
            # Uh...  MQDecodePCF shouldn't ever let this happen...
            $self->{Carp}->("Unable to map parameter '$paramkey'\n");
            return;
        }

        my $ValueMap = $ParameterMap->{$origparam->{Parameter}}->[1];

        #
        # Restructure.  What we have here is either a group (in which
        # case the current parser state goes into the groupstack) or a
        # regular attribute (which might be a filter, might require
        # looking into the $ValueMap, etc).  Either way, then we fall
        # into the other end of group handling which pops state off
        # the group stack.
        #
        if ($origparam->{Group}) {
            my $frame = [$parameters, $ParameterMap, $idx, $origparams];
            push(@groupstack, $frame);
            my $newparameters = {};
            push(@{$parameters->{$paramkey}}, $newparameters);
            $parameters = $newparameters;
            $ParameterMap = $ValueMap;
            $idx = -1; # account for increment in top for (;;)
            $origparams = $paramvalue;
        }
        else {
            #
            # First, regardless of whether this is a filter or a known
            # parameter, the value (or values) may require remapping
            # via $ValueMap, so do that first.  Coerce singular values
            # into an array for this so that we don't have the
            # duplicate code.
            #
            if ($ValueMap) {
                my @o;
                foreach my $value ((ref($paramvalue) eq 'ARRAY') ?
                                   @{$paramvalue} : $paramvalue) {
                    if (ref($ValueMap) eq "CODE" &&
                        # VALUEMAP-CODEREF
                        defined(my $dvalue = $ValueMap->(decodepcf => $value))) {
                        push(@o, $dvalue);
                    }
                    elsif (ref($ValueMap) eq "HASH" &&
                           exists($ValueMap->{$value})) {
                        push(@o, $ValueMap->{$value});
                    }
                    elsif (!$self->{StrictMapping}) {
                	push(@o, $value);
                    }
                    else {
                        $self->{Carp}->("Unable to map value of '$value' for parameter '$paramkey'");
                        return;
                    }
                }
                $paramvalue = (ref($paramvalue) eq 'ARRAY') ? [@o] : shift(@o);
            }

            #
            # Now to the decoding of the parameter itself.  If this is
            # a filter, that gets "special" decoding since it's not a
            # plain key/value tuple ($paramvalue is the value being
            # matched against, got valuemap handling done above, but
            # we also need the operator and parameter parts of the
            # filter for completeness).  What we emit here may not be
            # precisely the same as what went into _TranslatePCF(),
            # but _TranslatePCF() should be able to give back what
            # we're looking at now.
            #
	    if ($origparam->{"FilterValue"}) {
                my %revop = (
                             # duplicates are commented out and the
                             # less ambiguous mappings were selected
                             MQSeries::MQCFOP_LESS         => '<',
                             MQSeries::MQCFOP_NOT_GREATER  => '<=',
                             MQSeries::MQCFOP_EQUAL        => '==',
                             MQSeries::MQCFOP_NOT_EQUAL    => '!=',
                             # MQSeries::MQCFOP_NOT_EQUAL    => '<>',
                             MQSeries::MQCFOP_GREATER      => '>',
                             MQSeries::MQCFOP_NOT_LESS     => '>=',
                             MQSeries::MQCFOP_LIKE         => 'like',
                             MQSeries::MQCFOP_NOT_LIKE     => 'not like',
                             # MQSeries::MQCFOP_CONTAINS     => '==',
                             MQSeries::MQCFOP_CONTAINS     => 'contains',
                             # MQSeries::MQCFOP_EXCLUDES     => '!=',
                             # MQSeries::MQCFOP_EXCLUDES     => '<>',
                             MQSeries::MQCFOP_EXCLUDES     => 'excludes',
                             # MQSeries::MQCFOP_CONTAINS_GEN => 'like',
                             MQSeries::MQCFOP_CONTAINS_GEN => 'contains_gen',
                             # MQSeries::MQCFOP_EXCLUDES_GEN => 'not like',
                             MQSeries::MQCFOP_EXCLUDES_GEN => 'excludes_gen',
                            );
                my $op = $origparam->{Operator};
                if ($self->{StrictMapping} && !defined($revop{$op})) {
                    $self->{Carp}->("Unable to map operator '$op' for filter parameter '$paramkey'");
                }
                $parameters->{"FilterCommand"} =
                {
                 "Parameter" => $paramkey,
                 "Operator"  => $revop{$op} || $op,
                 "Value"     => $paramvalue,
                };
            }
            elsif (!defined($paramkey)) {
                #
                # If $paramkey is not defined, that means we couldn't
                # map the number to a name.  Rather than just stuff it
                # in "as is" (which tends to be less than useless),
                # save the original parameter in an array under "*".
                # This makes it easier to see what's missing and fix
                # it.
                #
                # Drop the result we have in $paramvalue; if the
                # $paramkey is not defined, neither will the $ValueMap
                # be, so they are the same as in $origparam.
                #
                push(@{$parameters->{"*"}}, $origparam);
            }
            else {
                $parameters->{$paramkey} = $paramvalue;
            }
        }

        while ($idx + 1 >= @$origparams && @groupstack) {
            my $frame = pop(@groupstack);
            ($parameters, $ParameterMap, $idx, $origparams) = @{$frame};
        }
    }
    return ($header,$parameters);

}

sub GetConvert {

    my $self = shift;
    ($self->{Buffer}) = @_;

    my ($header,$parameters);

    if ( $self->{Type} eq 'PCF' ) {

        ($header,$parameters) = MQDecodePCF($self->{Buffer}) or do {
            $self->{Carp}->("Unable to decode PCF buffer\n");
            return undef;
        };

        ($self->{"Header"},$self->{Parameters}) = $self->_UnTranslatePCF($header,$parameters) or do {
            $self->{Carp}->("Unable to translate Command/Parameters from MQDecodePCF output\n");
            return undef;
        };

    } else {

        if ( $self->isa("MQSeries::Command::Request") ) {

            $self->{Carp}->("MQGETing a MQSeries::Command::Request is not supported for type MQSC\n");
            return undef;

        } else {

            ($header,$self->{Parameters}) = $self->MQDecodeMQSC($self->{"Header"},$self->{Buffer}) or do {
                $self->{Carp}->("Unable to parse MQSeries Command response from message\n");
                return undef;
            };

            foreach my $key ( keys %$header ) {
                if ( $key eq "ReasonText" ) {
                    push(@{$self->{"Header"}->{$key}},$header->{$key});
                } else {
                    $self->{"Header"}->{$key} = $header->{$key};
                }
            }

        }

    }

    return 1;

}

sub PutConvert {

    my $self = shift;

    unless ( $self->{Command} ) {
        $self->{Carp}->("Required argument 'Command' is missing\n");
        return undef;
    }

    if ( $self->{Type} eq 'PCF' ) {

        my ($header,$parameters) = $self->_TranslatePCF($self->{Header},$self->{Parameters}) or do {
            $self->{Carp}->("Unable to translate Command/Parameters into MQEncodePCF input\n");
            return undef;
        };
        $self->{Buffer} = MQEncodePCF($header,$parameters);
    } else {
        if ( $self->isa("MQSeries::Command::Response") ) {
            $self->{Carp}->("MQPUTing a MQSeries::Command::Response is not supported for type MQSC\n");
            return undef;
        } else {
            $self->{Buffer} = $self->MQEncodeMQSC($self->{Command},$self->{Parameters});
        }
    }

    if ( $self->{Buffer} ) {
        return $self->{Buffer};
    } else {
        $self->{Carp}->("Unable to encode MQSeries Request Header and Parameters\n");
        return undef;
    }

}

sub Parameters {

    my $self = shift;

    unless (
            ref $self->{Parameters} eq 'HASH' and
            keys %{$self->{Parameters}}
           ) {
        return;
    }

    if ( $_[0] ) {
        return $self->{Parameters}->{$_[0]};
    } else {
        return $self->{Parameters};
    }

}

sub Header {

    my $self = shift;

    unless (
            ref $self->{"Header"} eq 'HASH' and
            keys %{$self->{"Header"}}
           ) {
        return;
    }

    if ( $_[0] ) {
        return $self->{"Header"}->{$_[0]};
    } else {
        return $self->{"Header"};
    }

}

sub Command {
    my $self = shift;
    if ( $self->{Command} ) {
        return $self->{Command};
    } elsif ( ref $self->{"Header"} ) {
        return $self->{"Header"}->{Command};
    } else {
        return;
    }
}

sub CompCode {
    my $self = shift;
    if ( ref $self->{"Header"} ) {
        return $self->{"Header"}->{"CompCode"};
    } else {
        return;
    }
}

sub Reason {
    my $self = shift;
    if ( ref $self->{"Header"} ) {
        return $self->{"Header"}->{"Reason"};
    } else {
        return;
    }
}

sub ReasonText {

    my $self = shift;
    my $reasontext = "";

    if ( ref $self->{"Header"} ) {
        if ( exists $self->{"Header"}->{"ReasonText"} ) {
            $reasontext = join("\n",@{$self->{"Header"}->{"ReasonText"}});
        } elsif ( exists $self->{"Header"}->{"Reason"} ) {
            $reasontext = MQReasonToText($self->{"Header"}->{"Reason"});
        }
    }

    return $reasontext;

}


sub MQEncodeMQSC {
    my ($self, $command, $parameters) = @_;
    my @buffer = ();
    my @parameters = ();
    my %skipparam = ();

    unless ( exists $MQSeries::Command::MQSC::Requests{$command} ) {
        $self->{Carp}->("No such MQSC command '$command'\n");
        return;
    }

    unless ( ref $MQSeries::Command::MQSC::Requests{$command} eq 'ARRAY' ) {
        $self->{Carp}->("PCF command '$command' not supported via MQSC\n");
        return;
    }

    my ($requestname, $requestparameters, $requestargs) =
      @{$MQSeries::Command::MQSC::Requests{$command}};

    push(@buffer,$requestname);

    my $foundattribute = 0;

    if ( $MQSeries::Command::MQSC::RequestParameterPrimary{$command} ) {
        @parameters = (
                       $MQSeries::Command::MQSC::RequestParameterPrimary{$command},
                       grep(
                            $_ ne $MQSeries::Command::MQSC::RequestParameterPrimary{$command},
                            keys %$parameters
                           )
                      );
    } else {
        @parameters = keys %$parameters;
    }
    foreach my $parameter ( @parameters ) {
        next if $skipparam{$parameter};

        unless (defined $requestparameters->{$parameter} ) {
            $self->{Carp}->("No such request parameter '$parameter' for command '$command'\n");
            return;
        }

        if ( ref $requestargs && not $requestargs->{$parameter} ) {
            $foundattribute = 1;
        }

        my ($key,$type) = @{$requestparameters->{$parameter}};

        my $value = $parameters->{$parameter};

#     print STDERR "$parameter: Key:$key: Type:$type: Value: $value\n";

        if ( $key ) {

            if ( ref $key eq 'HASH' ) {

                my ($subkey,$subvalues) = ($key->{Key},$key->{Values});

                unless ( $parameters->{$subkey} ) {
                    $self->{Carp}->("Required parameter '$subkey' for command '$command' missing\n");
                    return;
                }

                unless (defined $subvalues->{$parameters->{$subkey}} ) {
                    $self->{Carp}->("Unknown value '$parameters->{$subkey}' for parameter '$subkey'\n");
                    return;
                }

                $key = $subvalues->{$parameters->{$subkey}};

                $skipparam{$subkey}++;

            }

            $type = '' unless (defined $type); # -w cleanness
            if ( $type eq 'integer' ) {
                push(@buffer,"$key($value)");
            } elsif ( $type eq 'string' ) {
                #print STDERR "Command [$command], parameter [$parameter]\n";
                #
                # Trust IBM to get this wrong... "Display Thread" is
                # the only MQSC command where, if you ask for a
                # specific thread name, it has to be quoted, but to
                # ask for all threads, the asterisk may not be quoted.
                #
                # The same goes for 'CommandScope'...
                #
                if ($command eq 'InquireThread' &&
                    $parameter eq 'ThreadName' &&
                    $value eq '*') {
                    push @buffer, "$key($value)";
                } elsif ($parameter eq 'CommandScope' && $value eq '*') {
                    push @buffer, "$key($value)";
                } else {
                    push @buffer,"$key('$value')";
                }
            }elsif ( ref $type eq 'ARRAY' ) {
                if ( $value ) {
                    push(@buffer,"$key($type->[1])");
                } else {
                    push(@buffer,"$key($type->[0])");
                }
            } elsif ( ref $type eq 'CODE' ) {
                # VALUEMAP-CODEREF
                my $newval = $type->(encodemqsc => $value);
                if (!defined($newval)) {
                    $self->{Carp}->("Unknown value '$value' for parameter '$parameter'\n");
                    return;
                }
                push(@buffer, "$key($newval)");
            } elsif ( ref $type eq 'HASH' ) {
                #
                # Fix for Header Compression and Message Compression introduced in V6
                #
                if ( ref $value eq 'ARRAY' &&
                    exists $MQSeries::Command::MQSC::SpecialParameters{$parameter} )  {
                    if ( scalar(@$value) ) {
                        my $completestring;
                        foreach my $string ( @$value ) {
                            unless (defined $type->{$string} ) {
                                $self->{Carp}->("Unknown value '$string' for parameter '$parameter'\n");
                                return;
                            }
                            $completestring .= "$type->{$string}" . ',';
                        }
                        $completestring =~ s/,$//;
                        push(@buffer,"$key($completestring)");
                    }
                } else {
                    push(@buffer,"$key($type->{$value})");
                }

            } else {
                push(@buffer,$key);
            }
        } else {
            #
            # Perform the specified key/value mapping of the data
            #
            if ( ref $type eq 'HASH' ) {
                if ( ref $value eq 'ARRAY' ) {
                    if ( scalar(@$value) ) {
                        foreach my $string ( @$value ) {
                            unless (defined $type->{$string} ) {
                                $self->{Carp}->("Unknown value '$string' for parameter '$parameter'\n");
                                return;
                            }
                            push(@buffer,$type->{$string});
                        }
                    }
                    else {
                        # If the array is empty, we have to ignore this attribute
                        $foundattribute = 0;
                    }
                }
                else {
                    unless ( $type->{$value} ) {
                        $self->{Carp}->("Unknown value '$value' for parameter '$parameter'\n");
                        return;
                    }
                    push(@buffer,$type->{$value});
                }
            }
            #
            # Perform a boolean lookup of the value to map it to
            # things like "NOREPLACE" or "REPLACE".
            #
            elsif ( ref $type eq 'ARRAY' ) {
                if ( $value ) {
                    push(@buffer,$type->[1]);
                }
                else {
                    push(@buffer,$type->[0]);
                }
            }
            #
            # The data is either passed through as-is, or if an ARRAY
            # is given, then the 'type' is the character to join the
            # data with.
            #
            else {
                if ( ref $value eq "ARRAY" ) {
                    push(@buffer,join($type,@$value));
                }
                else {
                    push(@buffer,$value);
                }
            }
        }

    }

    if ( ref $requestargs && $foundattribute == 0 ) {
        push(@buffer,"ALL");
    }

    #print STDERR "MQEncodeMQSC: Returning command [@buffer]\n";
    return "@buffer";
}


sub MQDecodeMQSC {
    my $self = shift;
    my ($oldheader,$buffer) = @_;
    #print STDERR "DecodeMQSC: Have buffer [$buffer]\n";

    my $command = $oldheader->{"Command"};
    # XXX - I think we should be initializing this to the oldheader
    my $newheader = $oldheader;
    my $parameters = {};

    #
    # OK, this is nothing short of obscene....
    #
    # If we have already seen ReasonText for this sequence of
    # messages, then we are just taking everything else and returning
    # it as reasontext.  This is because of the way MVS wraps the last
    # message into multiple lines, and then sends each line as a
    # seperate message.
    #
    if ( $oldheader->{"ReasonText"} ) {
        $newheader = { "ReasonText" => $buffer };
        return $newheader;
    }

    #
    # The easy part...
    #
    # The header is in a separate message, so if we see one, we're
    # done.  There are no parameters, so just return the header.
    #
    if ( $buffer =~ m{
                      ^CSQN\S+\s+               # Message ID
                      COUNT=\s+(\d+),\s*        # LastMsgSeqNumber
                      RETURN=(\w+),\s*          # CompCode
                      REASON=(\w+)              # Reason
                     }x ) {
        $newheader =
          {
           "LastMsgSeqNumber"   => $1,
           "CompCode"           => hex($2),
           "Reason"             => hex($3),
          };
        return $newheader;
    }

    #
    # Look for the error feedback...
    #
    # We recognize this because:
    # - The message looks like CSQxxxxx *XYZZY or CSQxxxx /XYZZY
    # - The message code is not CSQM4xxI, which is the normal message
    #   return
    # - The message code is documented to be followed bya csect name
    #   (CSQ9018E, CSQ9022I, CSQ9023E, CSQ9029E)
    #
    # NOTE: In MQ 5.2 for OS/390, the *XYZZY occurs in CSQM409I, but this
    #       did not occur in previous version.  Hence, we have to take
    #       care not to assume any *XYZZY or /XYYZY is an error.
    #
    if ( $buffer =~ m{
                      ^(?!CSQM4\d\dI)\S+\s+     # Message ID
                      [\*/]\w+\s*               # The leading * or / is the key
                      (.*)
                     }x ) {
        $newheader =
          {
           "ReasonText"         => $1,
          };
        return $newheader;
    } elsif ( $buffer =~ m{
                           ^(?:CSQ9018E|CSQ9022I|CSQ9023E|CSQ9029E) \s+
                           \S+ \s+ \S+ \s+
                           ((?:ENDING|\'|FAILURE).*)
                          }x ) {
        $newheader =
          {
           "ReasonText"         => $1,
          };
        return $newheader;
    }

    #
    # Now things get hard...
    #
    unless ( $MQSeries::Command::MQSC::Responses{$command} ) {
        $self->{Carp}->("Unknown MQSC command '$command'\n");
        return;
    }

    my $responseparameters = $MQSeries::Command::MQSC::Responses{$command};

    #
    # Strip off the first message ID, label, whatever that is...
    #
    $buffer =~ s/^\S+\s+//;

    #
    # Strip off any trailing white noise, er, space
    #
    $buffer =~ s/\s+$//;

    #
    # In MQ 5.2 for OS/390, there is also a leading *<QMgrName> or
    # +<QMgrName> at the start of the buffer, so we strip that off
    # here.
    #
    $buffer =~ s!^[\*\+]\S+\s+!!;

    #
    # This is used solely for debugging, since we strip $buffer to
    # nothing while parsing it.
    #
    my $origbuffer = $buffer;

    while ( $buffer ) {
        my ($key,$value,$realkey,$realvalue);
        my ($requestvalues);
        my $valuetype;

        #
        # XXX -- MQSeries V2.2 on OS/390 changes the text returned by
        # the command server.  In 2.1 and earlier, the messages look
        # like:
        #
        #   CSQM409I   QMNAME(CSQ1 .....
        #
        # but now there is an extra field:
        #
        #   CSQM409I ]QMH1 QMNAME(QMH1
        #
        # So, as of 1.12, we'll accept bare keywords that are any
        # non-whitespace, and then just let the bogus tag be ignored.
        #
        # Did I mention I hate this code yet? -- wpm, 8/18/2000
        #
        if ( $buffer =~ s{
                          ^([\w\]]+)            # keyword
                          \b(?!\()              # with NO following paren
                          \s*                   # trailing whitespace
                         }{}x ) {
            $key = $1;
            $value = 1;
            $valuetype = 'implicit';
        }
        #
        # ARGHH!!!  I hate this code.  Seriously....
        #
        # Special case for parsing "CONNAME(hostname(port))", which
        # has embedded parens in the TCP case.  This code gets more
        # vile, sick and obscene every time I touch it.  PCF is so
        # damn easy....
        #
        elsif ( $buffer =~ s{
                             ^(CONNAME|LOCLADDR)\( # Evil keyword with embedded parens
                             (                  # the usual hostname(port) syntax
                              [^\(\)]+          #           hostname
                              \(                #                   (
                              [^\(\)]+          #                    port
                              \)                #                        )
                              [^\)]+            # everything that is not a closing paren
                             )
                             \)\s*              # close paren, and some whitespace
                            }{}x ) {

            ($key,$value) = ($1,$2);

            # Extra whitespace is evil (well, at least really ugly)
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $valuetype = 'explicit';

        } elsif ( $buffer =~ s{
                               ^(\w+)\(         # keyword with open paren
                               ([^\)]*)         # everything that is not a closing paren
                               \)\s*            # close paren, and some whitespace
                              }{}x ) {

            ($key,$value) = ($1,$2);

            # Extra whitespace is evil (well, at least really ugly)
            $value =~ s/^\s+//;
            $value =~ s/\s+$//;
            $valuetype = 'explicit';

        } else {
            $self->{Carp}->("Unrecognized MQSC buffer: $buffer\n");
            last;
        }

        unless ( $responseparameters->{$key} ) {
            $self->{Carp}->("Unrecognized response parameter '$key' (with value '$value') for command '$command'\n");
            next;
        }

        ($realkey,$requestvalues) = @{$responseparameters->{$key}};
        $realvalue = $value;

        # A null realkey means this is to be ignored
        next unless $realkey;

        if ( $valuetype eq 'explicit' ) {
            if ( ref $requestvalues eq 'HASH' ) {
                #
                # Add a check for parameters of Array Type
                # New in WMQ 6
                #
                if ( exists $MQSeries::Command::MQSC::SpecialParameters{$realkey} ) {
                    my @split_values = split(',',$value);
                    foreach my $eachvalue (@split_values) {
                        $eachvalue =~ s/^\s+//;
                        $eachvalue =~ s/\s+$//;
                        unless ( exists $requestvalues->{$eachvalue} ) {
                           $self->{Carp}->("Unrecognized value '$eachvalue' for parameter '$realkey' for command '$command'\n");
                        } else {
                           $realvalue =~ s/$eachvalue/$requestvalues->{$eachvalue}/;
                        }
                    }
                } else {
                    unless ( exists $requestvalues->{$value} ) {
                        $self->{Carp}->("Unrecognized value '$value' for parameter '$realkey' for command '$command'\n");
                    } else {
                        $realvalue = $requestvalues->{$value};
                    }
                }
            } elsif (ref($requestvalues) eq "CODE") {
                # VALUEMAP-CODEREF
                my $newval = $requestvalues->(decodemqsc => $value);
                if (!defined($newval)) {
                    $self->{Carp}->("Unrecognized value '$value' for parameter '$realkey' for command '$command'\n");
                } else {
                    $realvalue = $newval;
                }
            }
        } else {
            if (defined $requestvalues and not ref $requestvalues) {
                $realvalue = $requestvalues;
            }
        }

        $parameters->{$realkey} = $realvalue;
    }

    return ($newheader,$parameters);
}


# VALUEMAP-CODEREF
sub strinteger {
    my ($direction, $value, $number, $string, $limit) = @_;

    if (defined($value)) {
        # use "eq" for a numeric compare so that we don't get warnings
        # for a non-numeric one
        if ($value eq $number || lc($value) eq lc($string)) {
            # note that BOTH decodes and ALSO encodemqsc intentionally
            # render as STRING
            return ($direction eq "encodepcf") ? $number : uc($string);
        }
        if ($value =~ /^(0|[1-9]\d+)$/ &&
            (!defined($limit) || $value <= $limit)) {
            return $value;
        }
    }

    return; # fail!
};


1;
