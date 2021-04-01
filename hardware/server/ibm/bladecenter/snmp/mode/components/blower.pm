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

package hardware::server::ibm::bladecenter::snmp::mode::components::blower;

use strict;
use warnings;

my %map_blower_state = (
    0 => 'unknown', 
    1 => 'good', 
    2 => 'warning', 
    3 => 'bad',
);
my %map_controller_state = (
    0 => 'operational',
    1 => 'flashing',
    2 => 'notPresent',
    3 => 'communicationError',
    255 => 'unknown',
);

# In MIB 'mmblade.mib'
my $oid_blowers = '.1.3.6.1.4.1.2.3.51.2.2.3';
my $entry_blower_state = '10';
my $entry_blower_speed = '1';
my $entry_controller_state = '30';
my $count = 4;

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_blowers };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking blowers");
    $self->{components}->{blower} = {name => 'blowers', total => 0, skip => 0};
    return if ($self->check_filter(section => 'blower'));

    for (my $i = 0; $i < $count; $i++) {
        my $instance = $i + 1;
        next if (!defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_state + $i) . '.0'}));
        my $blower_state = $map_blower_state{$self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_state + $i) . '.0'}};
        my $blower_speed = defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_speed + $i) . '.0'}) ? $self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_blower_speed + $i) . '.0'} : 'unknown';
        my $ctrl_state = defined($self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_controller_state + $i) . '.0'}) ? $map_controller_state{$self->{results}->{$oid_blowers}->{$oid_blowers . '.' . ($entry_controller_state + $i) . '.0'}} : undef;
    
        next if ($self->check_filter(section => 'blower', instance => $instance));
        next if ($blower_speed =~ /No Blower/i && 
                 $self->absent_problem(section => 'blower', instance => $instance));
        $self->{components}->{blower}->{total}++;

        if ($blower_speed =~ /^(\d+)%/) {
            $blower_speed = $1;
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'blower', instance => $instance, value => $blower_speed);
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("Blower speed '%s' is %s %%", $instance, $blower_speed));
            }
            $self->{output}->perfdata_add(
                label => "blower_speed", unit => '%',
                nlabel => 'hardware.blower.speed.percentage',
                instances => $instance,
                value => $blower_speed,
                warning => $warn,
                critical => $crit,
                min => 0, max => 100
            );
        }
        
        $self->{output}->output_add(long_msg => sprintf("Blower '%s' state is %s (%d %%).", 
                                    $instance, $blower_state, $blower_speed));
        my $exit = $self->get_severity(section => 'blower', value => $blower_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blower '%s' state is %s", 
                                            $instance, $blower_state));
        }
        
        next if (!defined($ctrl_state));
        
        next if ($self->check_filter(section => 'blowerctrl', instance => $instance));
        next if ($ctrl_state =~ /notPresent/i && 
                 $self->absent_problem(section => 'blowerctrl', instance => $instance));
        $self->{output}->output_add(long_msg => sprintf("Blower controller '%s' state is %s.", 
                                    $instance, $ctrl_state));
        $exit = $self->get_severity(section => 'blowerctrl', value => $ctrl_state);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Blower controller '%s' state is %s", 
                                            $instance, $ctrl_state));
        }
    }
}

1;
