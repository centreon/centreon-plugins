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

package network::radware::alteon::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

sub set_system {
    my ($self, %options) = @_;
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        cpu => [
            ['normal', 'OK'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL'],
        ],
        psu => [
            ['singlePowerSupplyOk', 'OK'],
            ['firstPowerSupplyFailed', 'CRITICAL'],
            ['secondPowerSupplyFailed', 'CRITICAL'],
            ['doublePowerSupplyOk', 'OK'],
            ['unknownPowerSupplyFailed', 'UNKNOWN'],
        ],
        temperature => [
            ['ok', 'OK'],
            ['exceed', 'WARNING'],
        ],
        fan => [
            ['ok', 'OK'],
            ['fail', 'CRITICAL'],
        ],
    };
    
    $self->{components_path} = 'network::radware::alteon::snmp::mode::components';
    $self->{components_module} = ['cpu', 'temperature', 'psu', 'fan'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_leef(oids => $self->{request});
}

1;

=head1 MODE

Check hardware (ALTEON-CHEETAH-SWITCH-MIB).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'cpu', 'temperature', 'psu', 'fan'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=cpu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,OK,unknownPowerSupplyFailed'

=back

=cut

package network::radware::alteon::snmp::mode::components::cpu;

use strict;
use warnings;

my %map_cpu_status = (1 => 'normal', 2 => 'warning', 3 => 'critical');

my $mapping_cpu = {
    hwTemperatureThresholdStatusCPU1Get    => { oid => '.1.3.6.1.4.1.1872.2.5.1.3.1.28.3', map => \%map_cpu_status },
    hwTemperatureThresholdStatusCPU2Get    => { oid => '.1.3.6.1.4.1.1872.2.5.1.3.1.28.4', map => \%map_cpu_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_cpu->{hwTemperatureThresholdStatusCPU1Get}->{oid} . '.0', $mapping_cpu->{hwTemperatureThresholdStatusCPU2Get}->{oid} . '.0';
}

sub check_cpu {
    my ($self, %options) = @_;
    
    return if (!defined($options{status}));
    return if ($self->check_filter(section => 'cpu', instance => $options{instance}));
    
    $self->{components}->{cpu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("cpu '%s' status is '%s' [instance = %s]",
                                                    $options{instance}, $options{status}, $options{instance}));
    my $exit = $self->get_severity(section => 'cpu', value => $options{status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Cpu '%s' status is '%s'", $options{instance}, $options{status}));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking cpu");
    $self->{components}->{cpu} = {name => 'cpu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'cpu'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_cpu, results => $self->{results}, instance => '0');

    check_cpu($self, status => $result->{hwTemperatureThresholdStatusCPU1Get}, instance => 1);
    check_cpu($self, status => $result->{hwTemperatureThresholdStatusCPU2Get}, instance => 2);
}

1;

package network::radware::alteon::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (1 => 'ok', 2 => 'fail');

my $mapping_fan = {
    hwFanStatus    => { oid => '.1.3.6.1.4.1.1872.2.5.1.3.1.4', map => \%map_fan_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_fan->{hwFanStatus}->{oid} . '.0';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_fan, results => $self->{results}, instance => '0');

    return if (!defined($result->{hwFanStatus}));
    $self->{components}->{fan}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("fan status is '%s' [instance = %s]",
                                                    $result->{hwFanStatus}, '0'));
    my $exit = $self->get_severity(section => 'fan', value => $result->{hwFanStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Fan status is '%s'", $result->{hwFanStatus}));
    }
}

1;

package network::radware::alteon::snmp::mode::components::temperature;

use strict;
use warnings;

my %map_temp_status = (1 => 'ok', 2 => 'exceed');

my $mapping_temp = {
    hwTemperatureStatus    => { oid => '.1.3.6.1.4.1.1872.2.5.1.3.1.3', map => \%map_temp_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_temp->{hwTemperatureStatus}->{oid} . '.0';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature");
    $self->{components}->{temperature} = {name => 'temperature', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_temp, results => $self->{results}, instance => '0');

    return if (!defined($result->{hwTemperatureStatus}));
    $self->{components}->{temperature}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("temperature status is '%s' [instance = %s]",
                                                    $result->{hwTemperatureStatus}, '0'));
    my $exit = $self->get_severity(section => 'temperature', value => $result->{hwTemperatureStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Temperature status is '%s'", $result->{hwTemperatureStatus}));
    }
}

1;

package network::radware::alteon::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (1 => 'singlePowerSupplyOk',
    2 => 'firstPowerSupplyFailed', 3 => 'secondPowerSupplyFailed', 4 => 'doublePowerSupplyOk',
    5 => 'unknownPowerSupplyFailed'
);

my $mapping_psu = {
    hwPowerSupplyStatus    => { oid => '.1.3.6.1.4.1.1872.2.5.1.3.1.29.2', map => \%map_psu_status },
};

sub load {
    my ($self) = @_;

    push @{$self->{request}}, $mapping_psu->{hwPowerSupplyStatus}->{oid} . '.0';
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking psus");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_psu, results => $self->{results}, instance => '0');

    return if (!defined($result->{hwPowerSupplyStatus}));
    $self->{components}->{psu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("power supply status is '%s' [instance = %s]",
                                                    $result->{hwPowerSupplyStatus}, '0'));
    my $exit = $self->get_severity(section => 'psu', value => $result->{hwPowerSupplyStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Power supply status is '%s'", $result->{hwPowerSupplyStatus}));
    }
}

1;
    
