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

package storage::emc::DataDomain::mode::components::battery;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_battery_status = ();
my ($oid_nvramBatteryStatus, $oid_nvramBatteryCharge);
my $oid_nvramBatteryEntry = '.1.3.6.1.4.1.19746.1.2.3.1.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_nvramBatteryEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking nvram batteries");
    $self->{components}->{battery} = {name => 'nvram batteries', total => 0, skip => 0};
    return if ($self->check_filter(section => 'battery'));
    
    if (centreon::plugins::misc::minimal_version($self->{os_version}, '5.x')) {
        $oid_nvramBatteryStatus = '.1.3.6.1.4.1.19746.1.2.3.1.1.3';
        $oid_nvramBatteryCharge = '.1.3.6.1.4.1.19746.1.2.3.1.1.4';
        %map_battery_status = (0 => 'ok', 1 => 'disabled', 2 => 'discharged', 4 => 'softdisabled');
    } else {
        $oid_nvramBatteryStatus = '.1.3.6.1.4.1.19746.1.2.3.1.1.2';
        $oid_nvramBatteryCharge = '.1.3.6.1.4.1.19746.1.2.3.1.1.3';
        %map_battery_status =  (1 => 'ok', 2 => 'disabled', 3 => 'discharged', 4 => 'unknown', 
                                5 => 'softdisabled');
    }

    foreach my $oid (keys %{$self->{results}->{$oid_nvramBatteryEntry}}) {
        next if ($oid !~ /^$oid_nvramBatteryStatus\.(.*)$/);
        my $instance = $1;
        my $batt_status = defined($map_battery_status{$self->{results}->{$oid_nvramBatteryEntry}->{$oid}}) ?
                            $map_battery_status{$self->{results}->{$oid_nvramBatteryEntry}->{$oid}} : 'unknown';
        my $batt_value = $self->{results}->{$oid_nvramBatteryEntry}->{$oid_nvramBatteryCharge . '.' . $instance};

        next if ($self->check_filter(section => 'battery', instance => $instance));
        next if ($batt_status =~ /disabled/i && 
                 $self->absent_problem(section => 'battery', instance => $instance));
        
        $self->{components}->{battery}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Nvram battery '%s' status is '%s'",
                                    $instance, $batt_status));
        my $exit = $self->get_severity(section => 'battery', value => $batt_status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Nvram battery '%s' status is '%s'", $instance, $batt_status));
        }

        if (defined($batt_value) && $batt_value =~ /[0-9]/) {
            my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'battery', instance => $instance, value => $batt_value);
            $self->{output}->output_add(long_msg => sprintf("Nvram battery '%s' charge is %s %%", $instance, $batt_value));
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Nvram battery '%s' charge is %s %%", $instance, $batt_value));
            }
            $self->{output}->perfdata_add(
                label => 'nvram_battery', unit => '%',
                nlabel => 'hardware.battery.nvram.charge.percentage',
                instances => $instance,
                value => $batt_value,
                warning => $warn,
                critical => $crit,
                min => 0, max => 100
            );
        }
    }
}

1;
