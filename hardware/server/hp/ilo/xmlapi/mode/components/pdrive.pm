#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package hardware::server::hp::ilo::xmlapi::mode::components::pdrive;

use strict;
use warnings;
use centreon::plugins::misc;

sub load { }

sub check_ilo4 {
    my ($self) = @_;
    
    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}));

    #<STORAGE>
    #      <CONTROLLER>
    #           ...
    #           <LOGICAL_DRIVE>
    #               <PHYSICAL_DRIVE>
    #                     <LABEL VALUE = "Port 1I Box 1 Bay 1"/>
    #                     <STATUS VALUE = "OK"/>
    #                     <SERIAL_NUMBER VALUE = "KHG25T5R"/>
    #                     <MODEL VALUE = "EG0450FBVFM"/>
    #                     <CAPACITY VALUE = "419 GB"/>
    #                     <LOCATION VALUE = "Port 1I Box 1 Bay 1"/>
    #                     <FW_VERSION VALUE = "HPD9"/>
    #                     <DRIVE_CONFIGURATION VALUE = "Configured"/>
    #                     <ENCRYPTION_STATUS VALUE = "Not Encrypted"/>
    #
    foreach my $ctrl (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{STORAGE}->{CONTROLLER}}) {
        next if (!defined($ctrl->{LOGICAL_DRIVE}));
        
        foreach my $ldrive (@{$ctrl->{LOGICAL_DRIVE}}) {
            next if (!defined($ldrive->{PHYSICAL_DRIVE}));
            
            foreach my $result (@{$ldrive->{PHYSICAL_DRIVE}}) {
                my $instance = $result->{LABEL}->{VALUE};
                
                next if ($self->check_filter(section => 'pdrive', instance => $instance));
                next if ($result->{STATUS}->{VALUE} =~ /not installed|n\/a|not present|not applicable/i &&
                         $self->absent_problem(section => 'pdrive', instance => $instance));

                $self->{components}->{pdrive}->{total}++;
                
                $self->{output}->output_add(long_msg => sprintf("physical drive '%s' status is '%s' [instance = %s]",
                                            $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}, $instance));
                
                my $exit = $self->get_severity(label => 'default', section => 'pdrive', value => $result->{STATUS}->{VALUE});
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Physical drive '%s' status is '%s'", $result->{LABEL}->{VALUE}, $result->{STATUS}->{VALUE}));
                }
            }
        }
    }
}

sub check_ilo2 {
    my ($self) = @_;

    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{DRIVES}->{DRIVE_BAY}));
    # In ILO2:
    # <DRIVES>
    #    <BACKPLANE FIRMWARE_VERSION="1.16" ENCLOSURE_ADDR="224"/>
    #    <DRIVE_BAY NUM="1" STATUS="Ok" UID_LED="Off" />
    #    <DRIVE_BAY NUM="2" STATUS="Ok" UID_LED="Off" />
    #    <DRIVE_BAY NUM="3" STATUS="Not Installed" UID_LED="Off" />
    foreach my $result (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{DRIVES}->{DRIVE_BAY}}) {
        my $instance = $result->{NUM};
        
        next if ($self->check_filter(section => 'pdrive', instance => $instance));
        next if ($result->{STATUS} =~ /not installed|n\/a|not present|not applicable/i &&
                 $self->absent_problem(section => 'pdrive', instance => $instance));

        $self->{components}->{pdrive}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("physical drive '%s' status is '%s' [instance = %s]",
                                    centreon::plugins::misc::trim($result->{NUM}), $result->{STATUS}, $instance));
        
        my $exit = $self->get_severity(label => 'default', section => 'pdrive', value => $result->{STATUS});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Physical drive '%s' status is '%s'", $result->{NUM}, $result->{STATUS}));
        }
    }
}

sub check_ilo3 {
    my ($self) = @_;

    return if (!defined($self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{DRIVES}->{BACKPLANE}));
    # In ILO3:
    # <DRIVES>
    #   <BACKPLANE>
    #        <FIRMWARE_VERSION VALUE="1.14"/>
    #        <ENCLOSURE_ADDR VALUE="224"/>
    #        <DRIVE_BAY NUM="1" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="2" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="3" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="4" STATUS="Not Installed" UID_LED="Off" />
    #    </BACKPLANE>
    #    <BACKPLANE>
    #        <FIRMWARE_VERSION VALUE="1.14"/>
    #        <ENCLOSURE_ADDR VALUE="226"/>
    #        <DRIVE_BAY NUM="5" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="6" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="7" STATUS="Ok" UID_LED="Off" />
    #        <DRIVE_BAY NUM="8" STATUS="Not Installed" UID_LED="Off" />
    #    </BACKPLANE>
    foreach my $backplane (@{$self->{xml_result}->{GET_EMBEDDED_HEALTH_DATA}->{DRIVES}->{BACKPLANE}}) {
        next if (!defined($backplane->{DRIVE_BAY}));
        
        foreach my $result (@{$backplane->{DRIVE_BAY}}) {
            my $instance = $result->{NUM};
            
            next if ($self->check_filter(section => 'pdrive', instance => $instance));
            next if ($result->{STATUS} =~ /not installed|n\/a|not present|not applicable/i &&
                     $self->absent_problem(section => 'pdrive', instance => $instance));

            $self->{components}->{pdrive}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("physical drive '%s' status is '%s' [instance = %s]",
                                        $result->{NUM}, $result->{STATUS}, $instance));
            
            my $exit = $self->get_severity(label => 'default', section => 'pdrive', value => $result->{STATUS});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Physical drive '%s' status is '%s'", $result->{NUM}, $result->{STATUS}));
            }
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking physical drives");
    $self->{components}->{pdrive} = {name => 'pdrive', total => 0, skip => 0};
    return if ($self->check_filter(section => 'pdrive'));

    check_ilo4($self);
    check_ilo3($self);
    check_ilo2($self);
}

1;
