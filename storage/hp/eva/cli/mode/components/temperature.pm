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

package storage::hp::eva::cli::mode::components::temperature;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    $self->{ssu_commands}->{'ls diskshelf full xml'} = 1;
    $self->{ssu_commands}->{'ls controller full xml'} = 1;
}

sub temp_ctrl {
    my ($self) = @_;
    
    # <object>
    #    <objecttype>controller</objecttype>
    #    <objectname>\Hardware\Rack 1\Controller Enclosure 7\Controller B</objectname>
    #    <sensors>
    #        <sensor>
    #            <name>i2csensor1</name>
    #            <tempc>28</tempc>
    #            <tempf>82</tempf>
    #         </sensor>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'controller');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{sensors}->{sensor}}) {
            next if ($result->{name} eq '');
            my $instance = $object->{objectname} . '/' . $result->{name};
            
            next if ($self->check_filter(section => 'temperature', instance => $instance));

            $self->{components}->{temperature}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("temperature '%s' is %s C [instance = %s]",
                                        $instance, $result->{tempc}, $instance, 
                                        ));
            
            next if ($result->{tempc} !~ /[0-9]/);
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{tempc});        
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' is %s C", $instance, $result->{tempc}));
            }
            $self->{output}->perfdata_add(
                label => 'temperature', unit => 'C',
                nlabel => 'hardware.temperature.controller.celsius',
                instances => $instance,
                value => $result->{tempc},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

sub temp_diskshelf {
    my ($self) = @_;
        
    # <object>
    #    <objecttype>diskshelf</objecttype>
    #    <objectname>\Hardware\Rack 1\Disk Enclosure 3</objectname>
    #    <cooling>
    #        <sensors>
    #            <sensor>
    #                <name>ps1</name>
    #                <tempf>91.4</tempf>
    #                <tempc>33.0</tempc>
    #                <operationalstate>good</operationalstate>
    #                <tempalarmstatus>no_alarm</tempalarmstatus>
    #            </sensor>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'diskshelf');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{cooling}->{sensors}->{sensor}}) {
            next if ($result->{name} eq '');
            my $instance = $object->{objectname} . '/' . $result->{name};

            next if ($self->check_filter(section => 'temperature', instance => $instance));
            next if ($result->{operationalstate} =~ /notinstalled/i &&
                     $self->absent_problem(section => 'temperature', instance => $instance));

            $self->{components}->{temperature}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("temperature '%s' status is '%s' [instance = %s]",
                                        $instance, $result->{operationalstate}, $instance, 
                                        ));
            
            my $exit = $self->get_severity(label => 'default', section => 'temperature', value => $result->{operationalstate});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Temperature '%s' status is '%s'", $instance, $result->{operationalstate}));
            }
            
            next if ($result->{tempc} !~ /[0-9]/);
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{tempc});        
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Temperature '%s' is %s C", $instance, $result->{tempc}));
            }
            $self->{output}->perfdata_add(
                label => 'temperature', unit => 'C', 
                nlabel => 'hardware.temperature.diskshelf.celsius',
                instances => $instance,
                value => $result->{tempc},
                warning => $warn,
                critical => $crit,
            );
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperatures");
    $self->{components}->{temperature} = {name => 'temperatures', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));
    
    temp_ctrl($self);
    temp_diskshelf($self);
}

1;
