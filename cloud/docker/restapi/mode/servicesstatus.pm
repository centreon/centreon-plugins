#
# Copyright 2020 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Authors : Yoann Calamai <yoann.calamai@marmous.net>

package cloud::docker::restapi::mode::servicesstatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{services} = $options{custom}->api_list_services();
}

sub run {
    my ($self, %options) = @_;
    my $NodeID;
    my $NodeName;
    my $ServiceID;
    my $ServiceName;
    my $ContainerID;
    my $DesiredState;
    my $State;
    my $StateMessage;
    my $CountFailedServices = 0;
    my @SuccessServices;
    my @FailedServices;
    my $msg;

    $self->manage_selection(%options);
    foreach my $task_id (sort keys %{$self->{services}}) {
        # get nodeid and check if empty
        $NodeID = $self->{services}->{$task_id}->{NodeId};
        $NodeID = $self->check_if_string_empty(stringToCheck => $NodeID, defaultvalue => "null");
        # get nodename and check if empty
        $NodeName = $self->{services}->{$task_id}->{NodeName};
        $NodeName = $self->check_if_string_empty(stringToCheck => $NodeName, defaultvalue => "null");
        # get serviceid and check if empty
        $ServiceID = $self->{services}->{$task_id}->{ServiceId};
        $ServiceID = $self->check_if_string_empty(stringToCheck => $ServiceID, defaultvalue => "null");
        # get servicename and check if empty
        $ServiceName = $self->{services}->{$task_id}->{ServiceName};
        $ServiceName = $self->check_if_string_empty(stringToCheck => $ServiceName, defaultvalue => "null");
        # get containerid and check if empty
        $ContainerID = $self->{services}->{$task_id}->{ContainerId};
        $ContainerID = $self->check_if_string_empty(stringToCheck => $ContainerID, defaultvalue => "null");
        # get desiredstate and check if empty
        $DesiredState = $self->{services}->{$task_id}->{DesiredState};
        $DesiredState = $self->check_if_string_empty(stringToCheck => $DesiredState, defaultvalue => "null");
        # get state and check if empty
        $State = $self->{services}->{$task_id}->{State};
        $State = $self->check_if_string_empty(stringToCheck => $State, defaultvalue => "null");
        # get statemessage and check if empty
        $StateMessage = $self->{services}->{$task_id}->{StateMessage};
        $StateMessage = $self->check_if_string_empty(stringToCheck => $StateMessage, defaultvalue => "null");

        # construct detailed info for --verbose option
        $msg =  "[taskid = '" . $task_id . "']" .
               " [nodeid = '" . $NodeID . "']" .
               " [nodename = '" . $NodeName . "']" .
               " [serviceid = '" . $ServiceID . "']" .
               " [servicename = '" . $ServiceName . "']" .
               " [containerid = '" . $ContainerID . "']" .
               " [desiredstate = '" . $DesiredState . "']" .
               " [state = '" . $State . "']" .
               " [statemessage = '" . $StateMessage . "']";

        # check service health
        if ($DesiredState ne $State && $State ne "complete" && $State ne "preparing"){
            $CountFailedServices++;
            push @FailedServices, $msg;
        } else {
            push @SuccessServices, $msg;
        }
    }

    # display message
    if ($CountFailedServices eq 0){
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All services running well');
        foreach my $m (@SuccessServices){
            $self->{output}->output_add(long_msg => $m);
        }
    }else{
        $self->{output}->output_add(severity => 'Critical',
                                    short_msg => $CountFailedServices . ' services not in desired stated');
        foreach my $m (@FailedServices){
            $self->{output}->output_add(long_msg => $m);
        }
    }
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

# check if string is empty and apply a default value
sub check_if_string_empty{
    my ($self, %options) = @_;
    return (defined $options{stringToCheck} && length $options{stringToCheck}) ? $options{stringToCheck} : $options{defaultvalue};
}

1;

__END__

=head1 MODE

Check service status.

=over 8

=back

=cut
