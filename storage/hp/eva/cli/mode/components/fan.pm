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

package storage::hp::eva::cli::mode::components::fan;

use strict;
use warnings;

sub load {
    my ($self) = @_;
    
    $self->{ssu_commands}->{'ls diskshelf full xml'} = 1;
    $self->{ssu_commands}->{'ls controller full xml'} = 1;
}

sub fan_ctrl {
    my ($self) = @_;
    
    # <object>
    #    <objecttype>controller</objecttype>
    #    <objectname>\Hardware\Rack 1\Controller Enclosure 7\Controller B</objectname>
    #    <fans>
    #        <fan>
    #          <fanname>fan0</fanname>
    #          <status>normal</status>
    #          <speed>2240</speed>
    #        </fan>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'controller');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{fans}->{fan}}) {
            my $instance = $object->{objectname} . '/' . $result->{fanname};
            
            next if ($self->check_filter(section => 'fan', instance => $instance));
            next if ($result->{status} =~ /notinstalled/i &&
                     $self->absent_problem(section => 'fan', instance => $instance));

            $self->{components}->{fan}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s] [value = %s]",
                                        $instance, $result->{status}, $instance, 
                                        $result->{speed}));
            
            my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{status});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan '%s' status is '%s'", $instance, $result->{status}));
            }
            
            next if ($result->{speed} !~ /[0-9]/);
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{speed});        
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Fan '%s' is %s rpm", $instance, $result->{speed}));
            }
            $self->{output}->perfdata_add(
                label => 'fan_' . $instance, unit => 'rpm',
                nlabel => 'hardware.fan.controller.speed.rpm',
                instances => $instance,
                value => $result->{speed},
                warning => $warn,
                critical => $crit, 
                min => 0
            );
        }
    }
}

sub fan_diskshelf {
    my ($self) = @_;
        
    # <object>
    #    <objecttype>diskshelf</objecttype>
    #    <objectname>\Hardware\Rack 1\Disk Enclosure 3</objectname>
    #    <cooling>
    #        <fans>
    #           <fan>
    #               <name>fan1</name>
    #               <operationalstate>good</operationalstate>
    #               <failprediction>No</failprediction>
    #               <speed>speed_1_lowest</speed>
    #           </fan>
    foreach my $object (@{$self->{xml_result}->{object}}) {
        next if ($object->{objecttype} ne 'diskshelf');
        
        $object->{objectname} =~ s/\\/\//g;
        foreach my $result (@{$object->{cooling}->{fans}->{fan}}) {
            my $instance = $object->{objectname} . '/' . $result->{name};
            
            next if ($self->check_filter(section => 'fan', instance => $instance));
            next if ($result->{operationalstate} =~ /notinstalled/i &&
                     $self->absent_problem(section => 'fan', instance => $instance));

            $self->{components}->{fan}->{total}++;
            
            $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s]",
                                        $instance, $result->{operationalstate}, $instance, 
                                        ));
            
            my $exit = $self->get_severity(label => 'default', section => 'fan', value => $result->{operationalstate});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Fan '%s' status is '%s'", $instance, $result->{operationalstate}));
            }
        }
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));
    
    fan_ctrl($self);
    fan_diskshelf($self);
}

1;
