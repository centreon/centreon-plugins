#
# $Id: MQSC.pm,v 33.11 2012/09/26 16:10:14 jettisu Exp $
#
# (c) 1999-2012 Morgan Stanley & Co. Incorporated
# See ..../src/LICENSE for terms of distribution.
#

package MQSeries::Command::MQSC;

use strict;

our @ISA = qw(MQSeries::Command);
our $VERSION = '1.34';

use MQSeries qw(:functions);

#
# Note -- the order is important, so resist the anal retentive urge to
# sort these lines in the interest of cosmetic appearance.
#
require "MQSeries/Command/MQSC/RequestValues.pl";
require "MQSeries/Command/MQSC/RequestParameterRemap.pl";
require "MQSeries/Command/MQSC/RequestParameterPrimary.pl";
require "MQSeries/Command/MQSC/RequestParameters.pl";
require "MQSeries/Command/MQSC/RequestArgs.pl";
require "MQSeries/Command/MQSC/Requests.pl";
require "MQSeries/Command/MQSC/ResponseValues.pl";
require "MQSeries/Command/MQSC/ResponseParameters.pl";
require "MQSeries/Command/MQSC/Responses.pl";
require "MQSeries/Command/MQSC/SpecialParameters.pl";

#
# This is a bit wierd....  well, all of the MQSC stuff is wierd....
# I'll try to stop whining all over the comments.
#
# The MQSC response starts with an indicator of the total number of
# messages, then has data messages, then ends on an end line.  This
# basically checks whether the total number of messages, as indicated
# up front, has been received.
#
sub _LastSeen {
    my $self = shift;

    return unless ($self->{Response}->[0] &&
                   $self->{Response}->[0]->Header('LastMsgSeqNumber') == scalar @{$self->{Response}});

    return 1;
}


sub _ProcessResponses {
    my $self = shift;
    my $command = shift;

    my $MQSCHeader = { Command => $command };

    my $MQSCMsgDesc = {};
    my $MQSCParameters = {};

    #
    # Key difference with PCF: we are going to toss out some of the
    # responses, and reset the Response array.
    #
    my @responses;

    $self->{Buffers} = [];

    foreach my $response ( @{$self->{Response}} ) {
        #
        # XXX -- Special hack to collect raw text
        #
        push(@{$self->{Buffers}},$response->{Buffer});

        #
        # Let the object-wide compcode and reason be the first
        # non-zero result found in all of the messages.  This is
        # *usually* good enough, but the data will be available via
        # Response() if you want to parse the full header for each
        # message.
        #
        if (
            $self->{"CompCode"} == MQSeries::MQCC_OK &&
            $self->{"Reason"} == MQSeries::MQRC_NONE &&
            (
             $response->Header("CompCode") != MQSeries::MQCC_OK ||
             $response->Header("Reason") != MQSeries::MQRC_NONE
            )
           ) {
            $self->{"CompCode"} = $response->Header("CompCode");
            $self->{"Reason"} = $response->Header("Reason");
        }

        if ( $command eq 'InquireChannelStatus' ) {
            if (
                (
                 $self->{"CompCode"} == 0 &&
                 $self->{"Reason"} == 4
                ) ||
                $response->ReasonText() =~ /no chstatus found/mi
               ) {
                $response->{Parameters}->{ChannelStatus} = 'NotFound';
                $self->{"Reason"} = MQSeries::MQRCCF_CHL_STATUS_NOT_FOUND;
            }
        }

        #
        # Ok, now it gets even more complicated (yes, that is
        # always possible).
        #
        # Remember that we are trying very hard to have one
        # interface, and one format for the results.  PCF has
        # these InquireFooNames calls, that do *not* map
        # cleanly to MQSC.  We need to collect the multiple
        # messages into one, to keep the results in the same
        # format
        #
        if ( $MQSeries::Command::MQSC::ResponseList{$command} ) {
            my ($oldkey,$newkey) = @{$MQSeries::Command::MQSC::ResponseList{$command}};
            push(@{$MQSCParameters->{$newkey}},$response->Parameters($oldkey))
              if $response->Parameters($oldkey);
            # Save the last response's MsgDesc.  See below...
            $MQSCMsgDesc = $response->MsgDesc();
        } else {
            push(@responses, $response);
        }
    }                           # End foreach: response

    #
    # For these commands, we create a fake response message, and feed
    # that back.  These are:
    #
    # InquireProcessNames
    # InquireQueueNames
    # InquireChannelNames
    # InquireNamelistNames
    #
    # We're ignoring the raw responses above, and simply extracting
    # the single key we care about, and creating a fake response with
    # one parameter, and one value (an ARRAY ref of values,
    # eg. QNames).
    #
    if ( $MQSeries::Command::MQSC::ResponseList{$command} ) {
        my $response = MQSeries::Command::Response->new
          (
           MsgDesc              => $MQSCMsgDesc,
           Header               => $MQSCHeader,
           Parameters           => $MQSCParameters,
           Type                 => $self->{Type},
          ) || do {
              $self->{"CompCode"} = MQSeries::MQCC_FAILED;
              $self->{"Reason"} = MQSeries::MQRC_UNEXPECTED_ERROR;
              return;
          };
        push(@responses, $response);
    }

    #
    # Reset the Response list, since we're about to re-populate it.
    #
    $self->{Response} = [];

    #
    # Only send back responses which have non-empty parameters.
    # And yes, we're violating the OO concept of using methods
    # to get at data members.  We're somewhat incestuous here...
    #
    if ( @responses ) {
        my $responsecount = 0;
        foreach my $response ( @responses ) {
            if ( keys %{$response->{Parameters}} ) {
                $response->{Header}->{MsgSeqNumber} = ++$responsecount;
                $response->{Header}->{Control} = MQSeries::MQCFC_NOT_LAST;
                $response->{Header}->{ParameterCount} = scalar keys %{$response->{Parameters}};
                delete $response->{Header}->{LastMsgSeqNumber};
                push(@{$self->{Response}},$response);
            }
        }
        #
        # Yank back the last response, and set its control value
        # to MQCFC_LAST
        #
        if ( scalar(@{$self->{Response}}) ) {
            my $response = pop(@{$self->{Response}});
            $response->{Header}->{Control} = MQSeries::MQCFC_LAST;
            push(@{$self->{Response}},$response);
        }
        #
        # One last thing.  If we now have *no* responses, then
        # pass back the first one.  This is possible if we get
        # multiple responses, but none have parameters.
        #
        else {
            $responses[0]->{Header}->{MsgSeqNumber} = 1;
            $responses[0]->{Header}->{Control} = MQSeries::MQCFC_LAST;
            $responses[0]->{Header}->{ParameterCount} = 0;
            delete $responses[0]->{Header}->{LastMsgSeqNumber};
            push(@{$self->{Response}}, $responses[0]);
        }
    }

    return 1;
}


1;
