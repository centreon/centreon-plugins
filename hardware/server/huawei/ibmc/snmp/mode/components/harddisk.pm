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

package hardware::server::huawei::ibmc::snmp::mode::components::harddisk;

use strict;
use warnings;

my %map_status = (
    1 => 'ok',
    2 => 'minor',
    3 => 'major',
    4 => 'critical',
    5 => 'absence',
    6 => 'unknown',
);

my %map_installation_status = (
    1 => 'absence',
    2 => 'presence',
    3 => 'unknown',
);

my $mapping = {
    hardDiskPresence             => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.18.50.1.2', map => \%map_installation_status },
    hardDiskStatus               => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.18.50.1.3', map => \%map_status },
    hardDiskDevicename           => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.18.50.1.6' },
    hardDiskTemperature          => { oid => '.1.3.6.1.4.1.2011.2.235.1.1.18.50.1.20' },
};
my $oid_hardDiskDescriptionEntry = '.1.3.6.1.4.1.2011.2.235.1.1.18.50.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, {
        oid => $oid_hardDiskDescriptionEntry,
        start => $mapping->{hardDiskPresence}->{oid},
        end => $mapping->{hardDiskTemperature}->{oid},
    };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking hard disks");
    $self->{components}->{harddisk} = {name => 'hard disks', total => 0, skip => 0};
    return if ($self->check_filter(section => 'harddisk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_hardDiskDescriptionEntry}})) {
        next if ($oid !~ /^$mapping->{hardDiskStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_hardDiskDescriptionEntry}, instance => $instance);

        next if ($self->check_filter(section => 'harddisk', instance => $instance));
        next if ($result->{hardDiskPresence} !~ /presence/);
        $self->{components}->{harddisk}->{total}++;

        if (defined($result->{hardDiskTemperature}) && $result->{hardDiskTemperature} =~ /[0-9]/) {
            my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'harddisk', instance => $instance, value => $result->{hardDiskTemperature});
            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Hard Disk '%s' temperature is %s celsius degrees", $result->{hardDiskDevicename}, $result->{hardDiskTemperature}));
            }

            $self->{output}->perfdata_add(
                label => 'temperature', unit => 'C',
                nlabel => 'hardware.harddisk.temperature.celsius', 
                instances => $result->{hardDiskDevicename},
                value => $result->{hardDiskTemperature},
                warning => $warn,
                critical => $crit,
                min => 0
            );
        }
        
        $self->{output}->output_add(long_msg => sprintf("Hard disk '%s' status is '%s' [instance = %s]",
                                    $result->{hardDiskDevicename}, $result->{hardDiskStatus}, $instance, 
                                    ));
   
        my $exit = $self->get_severity(label => 'default', section => 'harddisk', value => $result->{hardDiskStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Hard disk '%s' status is '%s'", $result->{hardDiskDevicename}, $result->{hardDiskStatus}));
        }
    }
}

1;
