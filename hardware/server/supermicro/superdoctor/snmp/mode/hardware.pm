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

package hardware::server::supermicro::superdoctor::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(sensor\..*)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        sensor => [
            ['ok', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL']
        ],
        default => [
            ['ok', 'OK'],
            ['critical', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::server::supermicro::superdoctor::snmp::mode::components';
    $self->{components_module} = ['sensor', 'memory', 'disk', 'cpu'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'sensor', 'disk', 'memory'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensor,temperature.*

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor.temperature,OK,warning'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='sensor.temperature,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='sensor.temperature,.*,40'

=back

=cut

package hardware::server::supermicro::superdoctor::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_sensor_status = (0 => 'ok', 1 => 'warning', 2 => 'critical');
my %map_sensor_type = (
    0 => 'fan', 1 => 'voltage', 2 => 'temperature', 3 => 'discrete',
);
my %map_sensor_monitored = (
    0 => 'not monitored', 1 => 'monitored',
);

my $mapping = {
    smHealthMonitorName         => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.2' },
    smHealthMonitorType         => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.3', map => \%map_sensor_type },
    smHealthMonitorReading      => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.4' },
    smHealthMonitorMonitor      => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.10', map => \%map_sensor_monitored },
    smHealthMonitorReadingUnit  => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.11' },
    smHealthMonitorStatus       => { oid => '.1.3.6.1.4.1.10876.2.1.1.1.1.12', map => \%map_sensor_status },
};
my $oid_smHealthMonitorEntry = '.1.3.6.1.4.1.10876.2.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_smHealthMonitorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_smHealthMonitorEntry}})) {
        next if ($oid !~ /^$mapping->{smHealthMonitorReading}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_smHealthMonitorEntry}, instance => $instance);

        next if (defined($result->{smHealthMonitorMonitor}) && $result->{smHealthMonitorMonitor} eq 'not monitored');

        next if ($self->check_filter(section => 'sensor', instance => $result->{smHealthMonitorType} . '.' . $instance));

        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor '%s' status is '%s' [instance = %s, value = %s]",
                $result->{smHealthMonitorName}, 
                defined($result->{smHealthMonitorStatus}) ? $result->{smHealthMonitorStatus} : 'undefined', 
                $result->{smHealthMonitorType} . '.' . $instance,
                defined($result->{smHealthMonitorReading}) ? $result->{smHealthMonitorReading} : '-'
            )
        );

        if (defined($result->{smHealthMonitorStatus})) {
            my $exit = $self->get_severity(label => 'sensor', section => 'sensor.' . $result->{smHealthMonitorType}, value => $result->{smHealthMonitorStatus});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "Sensor '%s' status is '%s'",
                        $result->{smHealthMonitorName},
                        $result->{smHealthMonitorStatus}
                    )
                );
            }
        }

        next if ($result->{smHealthMonitorReading} !~ /[0-9]/);
        $result->{smHealthMonitorReadingUnit} = '' if (defined($result->{smHealthMonitorReadingUnit}) && $result->{smHealthMonitorReadingUnit} =~ /N\/A/i);

        my $component = 'sensor.' . $result->{smHealthMonitorType};
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $component, instance => $instance, value => $result->{smHealthMonitorReading});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Sensor '%s' is %s %s",
                    $result->{smHealthMonitorName},
                    $result->{smHealthMonitorReading}, 
                    defined($result->{smHealthMonitorReadingUnit}) ? $result->{smHealthMonitorReadingUnit} : ''
                )
            );
        }

        # need some snmpwalk to do unit mapping!! experimental
        $self->{output}->perfdata_add(
            label => $component, unit => $result->{smHealthMonitorReadingUnit},
            nlabel => 'hardware.sensor.' . $result->{smHealthMonitorType} . '.' . $result->{smHealthMonitorReadingUnit},
            instances => $result->{smHealthMonitorName},
            value => $result->{smHealthMonitorReading},
            warning => $warn,
            critical => $crit
        );
    }
}

1;

package hardware::server::supermicro::superdoctor::snmp::mode::components::memory;

use strict;
use warnings;

my %map_memory_status = (0 => 'ok', 2 => 'critical');

my $mapping_memory = {
    memTag          => { oid => '.1.3.6.1.4.1.10876.100.1.3.1.1' },
    memDeviceStatus => { oid => '.1.3.6.1.4.1.10876.100.1.3.1.3', map => \%map_memory_status },
};
my $oid_memEntry = '.1.3.6.1.4.1.10876.100.1.3.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_memEntry, end => $mapping_memory->{memDeviceStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking memories");
    $self->{components}->{memory} = {name => 'memory', total => 0, skip => 0};
    return if ($self->check_filter(section => 'memory'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_memEntry}})) {
        next if ($oid !~ /^$mapping_memory->{memDeviceStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_memory, results => $self->{results}->{$oid_memEntry}, instance => $instance);

        next if ($self->check_filter(section => 'memory', instance => $instance));

        $self->{components}->{memory}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "memory '%s' status is '%s' [instance = %s]",
                $result->{memTag}, 
                $result->{memDeviceStatus},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'memory', value => $result->{memDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Memory '%s' status is '%s'",
                    $result->{memTag},
                    $result->{memDeviceStatus}
                )
            );
        }
    }
}

1;

package hardware::server::supermicro::superdoctor::snmp::mode::components::disk;

use strict;
use warnings;

my %map_disk_status = (0 => 'ok', 2 => 'critical', 3 => 'unknown');

my $mapping_disk = {
    diskName        => { oid => '.1.3.6.1.4.1.10876.100.1.4.1.2' },
    diskSmartStatus => { oid => '.1.3.6.1.4.1.10876.100.1.4.1.4', map => \%map_disk_status },
};
my $oid_diskEntry = '.1.3.6.1.4.1.10876.100.1.4.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_diskEntry, end => $mapping_disk->{diskSmartStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking disks");
    $self->{components}->{disk} = {name => 'disk', total => 0, skip => 0};
    return if ($self->check_filter(section => 'disk'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_diskEntry}})) {
        next if ($oid !~ /^$mapping_disk->{diskSmartStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_disk, results => $self->{results}->{$oid_diskEntry}, instance => $instance);

        next if ($self->check_filter(section => 'disk', instance => $instance));

        $self->{components}->{memory}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "disk '%s' status is '%s' [instance = %s]",
                $result->{diskName}, 
                $result->{diskSmartStatus},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'disk', value => $result->{diskSmartStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "Disk '%s' status is '%s'",
                    $result->{diskName},
                    $result->{diskSmartStatus}
                )
            );
        }
    }
}

1;

package hardware::server::supermicro::superdoctor::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_cpu_status = (0 => 'ok', 2 => 'critical');

my $mapping_cpu = {
    cpuDeviceStatus => { oid => '.1.3.6.1.4.1.10876.100.1.2.1.5', map => \%map_cpu_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $mapping_cpu->{cpuDeviceStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping_cpu->{cpuDeviceStatus}->{oid}}})) {
        $oid =~ /^$mapping_cpu->{cpuDeviceStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping_cpu, results => $self->{results}->{$mapping_cpu->{cpuDeviceStatus}->{oid}}, instance => $instance);

        next if ($self->check_filter(section => 'cpu', instance => $instance));

        $self->{components}->{cpu}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "cpu '%s' status is '%s' [instance = %s]",
                $instance, 
                $result->{cpuDeviceStatus},
                $instance
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'cpu', value => $result->{cpuDeviceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf(
                    "CPU '%s' status is '%s'",
                    $instance,
                    $result->{cpuDeviceStatus}
                )
            );
        }
    }
}

1;
