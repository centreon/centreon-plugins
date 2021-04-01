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

package centreon::common::adic::tape::snmp::mode::components::subsystem;

use strict;
use warnings;

my %map_status = (
    1 => 'good',
    2 => 'failed',
    3 => 'degraded',
    4 => 'warning',
    5 => 'informational',
    6 => 'unknown',
    7 => 'invalid',
);

# In MIB 'ADIC-TAPE-LIBRARY-MIB'
my $mapping = {
    powerStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.1', map => \%map_status, label => 'power', instance => 1 },
    coolingStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.2', map => \%map_status, label => 'cooling', instance => 2 },
    controlStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.3', map => \%map_status, label => 'control', instance => 3 },
    connectivityStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.4', map => \%map_status, label => 'connectivity', instance => 4 },
    roboticsStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.5', map => \%map_status, label => 'robotics', instance => 5 },
    mediaStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.6', map => \%map_status, label => 'media', instance => 6 },
    driveStatus => { oid => '.1.3.6.1.4.1.3764.1.10.10.12.6', map => \%map_status, label => 'drive', instance => 7 },
};
my $oid_rasSubSystem = '.1.3.6.1.4.1.3764.1.10.10.12';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_rasSubSystem };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking subsystems");
    $self->{components}->{subsystem} = {name => 'subsystems', total => 0, skip => 0};
    return if ($self->check_filter(section => 'subsystem'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_rasSubSystem}, instance => '0');
    foreach my $name (keys %$mapping) {
        if (!defined($result->{$name})) {
            $self->{output}->output_add(long_msg => sprintf("skipping %s status: no value.", $mapping->{$name}->{label})); 
            next;
        }

        next if ($self->check_filter(section => 'subsystem', instance => $mapping->{$name}->{instance}));
        $self->{components}->{subsystem}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("%s status is %s [instance: %s].",
                                    $mapping->{$name}->{label}, $result->{$name},
                                    $mapping->{$name}->{instance}
                                    ));
        my $exit = $self->get_severity(section => 'subsystem', label => 'default', value => $result->{$name});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("%s status is %s",
                                                             ucfirst($mapping->{$name}->{label}), $result->{$name}));
        }
    }
}

1;