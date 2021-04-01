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

package network::a10::ax::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        psu => [
            ['off', 'CRITICAL'],
            ['on', 'OK'],
            ['unknown', 'UNKNOWN']
        ],
        fan => [
            ['failed', 'CRITICAL'],
            ['okFixedHigh', 'OK'],
            ['okLowMed', 'OK'],
            ['okMedMed', 'OK'],
            ['okMedHigh', 'OK'],
            ['notReady', 'WARNING'],
            ['unknown', 'UNKNOWN']
        ]
    };
    
    $self->{components_path} = 'network::a10::ax::snmp::mode::components';
    $self->{components_module} = ['psu', 'fan', 'temperature'];
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
    
    my $oid_axSysHwInfo = '.1.3.6.1.4.1.22610.2.4.1.5';
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_table(oid => $oid_axSysHwInfo);
}

1;

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'psu', 'fan', 'temperature'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=psu,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,OK,off'

=item B<--warning>

Set warning threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut

package network::a10::ax::snmp::mode::components::fan;

use strict;
use warnings;

my %map_fan_status = (0 => 'failed', 4 => 'okFixedHigh',
    5 => 'okLowMed', 6 => 'okMedMed', 7 => 'okMedHigh',
    -2 => 'notReady', -1 => 'unknown'
);

my $mapping = {
    axFanName   => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.9.1.2' },
    axFanStatus => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.9.1.3', map => \%map_fan_status },
    axFanSpeed  => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.9.1.4' },    
};

sub load { }

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$mapping->{axFanStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        next if ($self->check_filter(section => 'fan', instance => $instance));

        $self->{components}->{fan}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("fan '%s' status is '%s' [instance = %s, speed = %s]",
                                                        $result->{axFanName}, $result->{axFanStatus}, $instance, $result->{axFanSpeed}));
        my $exit = $self->get_severity(section => 'fan', value => $result->{axFanStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("fan '%s' status is '%s'", $result->{axFanName}, $result->{axFanStatus}));
        }
        
        if ($result->{axFanSpeed} > 0) {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'fan', instance => $instance, value => $result->{axFanSpeed});            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("fan '%s' speed is %s rpm", $result->{axFanName}, $result->{axFanSpeed}));
            }
            $self->{output}->perfdata_add(
                label => 'fan', unit => 'rpm',
                nlabel => 'hardware.fan.speed.rpm',
                instances => $result->{axFanName},
                value => $result->{axFanSpeed},
                warning => $warn,
                critical => $crit, min => 0
            );
        }
    }
}

1;

package network::a10::ax::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (0 => 'off', 1 => 'on', -1 => 'unknown');

my $mapping_psu = {
    axSysLowerPowerSupplyStatus    => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.7', map => \%map_psu_status },
    axSysUpperPowerSupplyStatus    => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.8', map => \%map_psu_status },
};

sub load {}

sub check_psu {
    my ($self, %options) = @_;

    return if (!defined($options{status}));
    return if ($self->check_filter(section => 'psu', instance => $options{instance}));

    $self->{components}->{psu}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("power supply '%s' status is '%s' [instance = %s]",
                                                    $options{instance}, $options{status}, $options{instance}));
    my $exit = $self->get_severity(section => 'psu', value => $options{status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("power supply '%s' status is '%s'", $options{instance}, $options{status}));
    }
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psu', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_psu, results => $self->{results}, instance => '0');

    check_psu($self, status => $result->{axSysLowerPowerSupplyStatus}, instance => 1);
    check_psu($self, status => $result->{axSysUpperPowerSupplyStatus}, instance => 2);
}

1;

package network::a10::ax::snmp::mode::components::temperature;

use strict;
use warnings;

my $mapping_temp = {
    axSysHwPhySystemTemp    => { oid => '.1.3.6.1.4.1.22610.2.4.1.5.1' },
};

sub load {}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking temperature");
    $self->{components}->{temperature} = {name => 'temperature', total => 0, skip => 0};
    return if ($self->check_filter(section => 'temperature'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_temp, results => $self->{results}, instance => '0');

    return if (!defined($result->{axSysHwPhySystemTemp}));
    $self->{components}->{temperature}->{total}++;
    $self->{output}->output_add(long_msg => sprintf("physical temperature is %s C [instance = %s]",
                                                    $result->{axSysHwPhySystemTemp}, '0'));
    my ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => '0', value => $result->{axSysHwPhySystemTemp});            
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("physical temperature is %s C", $result->{axSysHwPhySystemTemp}));
    }
    $self->{output}->perfdata_add(
        label => 'temperature', unit => 'C',
        nlabel => 'hardware.temperature.celsius',
        instances => 'physical',
        value => $result->{axSysHwPhySystemTemp},
        warning => $warn,
        critical => $crit
    );
}

1;
