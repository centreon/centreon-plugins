#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package network::alcatel::omniswitch::snmp::mode::components::chassis;

use strict;
use warnings;
use network::alcatel::omniswitch::snmp::mode::components::resources qw(%oids $mapping);

sub load {}

sub check_temp_aos6 {
    my ($self, %options) = @_;

    my $mapping_temp = {
        boardTemp => { oid => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.4', default => -1 }, # chasHardwareBoardTemp
        threshold => { oid => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.7', default => -1 }, # chasTempThreshold
        danger    => { oid => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.3.1.8', default => -1 }  # chasDangerTempThreshold
    };

    my $result = $self->{snmp}->map_instance(mapping => $mapping_temp, results => $self->{results}->{entity}, instance => $options{instance});

    return if ($result->{boardTemp} <= 0);

    $self->{output}->output_add(
        long_msg => sprintf(
            "chassis '%s/%s' [instance: %s] board temperature is %s degree centigrade",
            $options{name},
            $options{descr},
            $options{instance}, 
            $result->{boardTemp}
        )
    );

    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $options{instance}, value => $result->{boardTemp});
    if ($checked == 0) {
        my $warn_th = $result->{threshold} > 0 ? $result->{threshold} : '';
        my $crit_th = $result->{danger} > 0 ? $result->{danger} : '';

        $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $options{instance}, value => $warn_th);
        $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $options{instance}, value => $crit_th);

        $exit = $self->{perfdata}->threshold_check(
            value => $result->{boardTemp},
            threshold => [
                { label => 'critical-temperature-instance-' . $options{instance}, exit_litteral => 'critical' },
                { label => 'warning-temperature-instance-' . $options{instance}, exit_litteral => 'warning' }
            ]
        );
    
        $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $options{instance});
        $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $options{instance})
    }

    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf(
                "chassis '%s/%s/%s' board temperature is %s degree centigrade",
                $options{name},
                $options{descr},
                $options{instance}, 
                $result->{boardTemp}
            )
        );
    }

    $self->{output}->perfdata_add(
        nlabel => 'hardware.temperature.celsius',
        unit => 'C',
        instances => [$options{name}, $options{descr}, $options{instance}, 'Chassis'],
        value => $result->{boardTemp},
        warning => $warn,
        critical => $crit
    );
}

sub check_temp_aos7 {
    my ($self, %options) = @_;

    my $mapping_temp = {
        threshold => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.5', default => -1 }, # chasTempThreshold
        danger    => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.6', default => -1 }, # chasDangerTempThreshold
        CPMA      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.8', default => -1 }, # chasCPMAHardwareBoardTemp
        CFMA      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.9', default => -1 }, # chasCFMAHardwareBoardTemp
        CPMB      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.10', default => -1 }, # chasCPMBHardwareBoardTemp
        CFMB      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.11', default => -1 }, # chasCFMBHardwareBoardTemp
        CFMC      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.12', default => -1 }, # chasCFMCHardwareBoardTemp
        CFMD      => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.13', default => -1 }, # chasCFMDHardwareBoardTemp
        FanTray1  => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.14', default => -1 }, # chasFTAHardwareBoardTemp
        FanTray2  => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.15', default => -1 }, # chasFTBHardwareBoardTemp
        NI1       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.16', default => -1 }, # chasNI1HardwareBoardTemp
        NI2       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.17', default => -1 }, # chasNI2HardwareBoardTemp
        NI3       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.18', default => -1 }, # chasNI3HardwareBoardTemp
        NI4       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.19', default => -1 }, # chasNI4HardwareBoardTemp
        NI5       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.20', default => -1 }, # chasNI5HardwareBoardTemp
        NI6       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.21', default => -1 }, # chasNI6HardwareBoardTemp
        NI7       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.22', default => -1 }, # chasNI7HardwareBoardTemp
        NI8       => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.3.1.23', default => -1 }  # chasNI8HardwareBoardTemp
    };

    my $result = $self->{snmp}->map_instance(mapping => $mapping_temp, results => $self->{results}->{entity}, instance => $options{instance});

    foreach my $sensor ('CPMA', 'CFMA', 'CPMB', 'CFMB', 'CFMC', 'CFMD', 'FanTray1', 'FanTray2', 'NI1', 'NI2', 'NI3', 'NI4', 'NI5', 'NI6', 'NI7', 'NI8') {
        next if ($result->{$sensor} <= 0);

        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis '%s/%s/%s/%s' temperature is %s degree centigrade",
                $options{name},
                $options{descr},
                $options{instance},
                $sensor,
                $result->{$sensor}
            )
        );

        my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $options{instance}, value => $result->{$sensor});
        if ($checked == 0) {
            my $warn_th = $result->{threshold} > 0 ? $result->{threshold} : '';
            my $crit_th = $result->{danger} > 0 ? $result->{danger} : '';

            $self->{perfdata}->threshold_validate(label => 'warning-temperature-instance-' . $options{instance}, value => $warn_th);
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $options{instance}, value => $crit_th);

            $exit = $self->{perfdata}->threshold_check(
                value => $result->{$sensor},
                threshold => [
                    { label => 'critical-temperature-instance-' . $options{instance}, exit_litteral => 'critical' },
                    { label => 'warning-temperature-instance-' . $options{instance}, exit_litteral => 'warning' }
                ]
            );
        
            $warn = $self->{perfdata}->get_perfdata_for_output(label => 'warning-temperature-instance-' . $options{instance});
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $options{instance})
        }

        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "chassis '%s/%s/%s/%s' temperature is %s degree centigrade",
                    $options{name},
                    $options{descr},
                    $options{instance},
                    $sensor,
                    $result->{$sensor}
                )
            );
        }

        $self->{output}->perfdata_add(
            nlabel => 'hardware.temperature.celsius',
            unit => 'C',
            instances => [$options{name}, $options{descr}, $options{instance}, $sensor],
            value => $result->{$sensor},
            warning => $warn,
            critical => $crit
        );
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking chassis");
    $self->{components}->{chassis} = {name => 'chassis', total => 0, skip => 0};
    return if ($self->check_filter(section => 'chassis'));
    
    my @instances = ();
    foreach my $key (keys %{$self->{results}->{ $oids{common}->{entPhysicalClass} }}) {
        if ($self->{results}->{ $oids{common}->{entPhysicalClass} }->{$key} == 3) {
            next if ($key !~ /^$oids{common}->{entPhysicalClass}\.(.*)$/);
            push @instances, $1;
        }
    }
    
    foreach my $instance (@instances) {
        next if (!defined($self->{results}->{entity}->{ $oids{ $self->{type} }->{chasEntPhysAdminStatus} . '.' . $instance }));
        
        my $result = $self->{snmp}->map_instance(mapping => $mapping->{ $self->{type} }, results => $self->{results}->{entity}, instance => $instance);
        
        next if ($self->check_filter(section => 'chassis', instance => $instance));
        $self->{components}->{chassis}->{total}++;
        
        $self->{output}->output_add(
            long_msg => sprintf(
                "chassis '%s/%s' [instance: %s, admin status: %s] operationnal status is %s",
                $result->{entPhysicalName},
                $result->{entPhysicalDescr},
                $instance, 
                $result->{chasEntPhysAdminStatus},
                $result->{chasEntPhysOperStatus}
            )
        );

        if ($result->{chasEntPhysPower} > 0) {
            $self->{output}->perfdata_add(
                nlabel => 'hardware.chassis.power.watt',
                unit => 'W',
                instances => [$result->{entPhysicalName}, $result->{entPhysicalDescr}, $instance],
                value => $result->{chasEntPhysPower},
                min => 0
            );
        }

        if ($self->{type} eq 'aos6') {
            check_temp_aos6($self, instance => $instance, name => $result->{entPhysicalName}, descr => $result->{entPhysicalDescr});
        } else {
            check_temp_aos7($self, instance => $instance, name => $result->{entPhysicalName}, descr => $result->{entPhysicalDescr});
        }

        my $exit = $self->get_severity(label => 'admin', section => 'chassis.admin', value => $result->{chasEntPhysAdminStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "chassis '%s/%s/%s' admin status is %s",
                    $result->{entPhysicalName},
                    $result->{entPhysicalDescr},
                    $instance, 
                    $result->{chasEntPhysAdminStatus}
                )
            );
            next;
        }

        $exit = $self->get_severity(label => 'oper', section => 'chassis.oper', value => $result->{chasEntPhysOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "chassis '%s/%s/%s' operational status is %s",
                    $result->{entPhysicalName},
                    $result->{entPhysicalDescr},
                    $instance, 
                    $result->{chasEntPhysOperStatus}
                )
            );
        }
    }
}

1;
