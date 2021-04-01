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

package centreon::common::fortinet::fortigate::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^sensors$';

    $self->{cb_hook1} = 'get_system_information';
    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        sensors => [
            ['on', 'CRITICAL'],
            ['off', 'OK'],
        ],
    };

    $self->{components_path} = 'centreon::common::fortinet::fortigate::snmp::mode::components';
    $self->{components_module} = ['sensors'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, 
        no_absent => 1, no_load_components => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub get_system_information {
    my ($self, %options) = @_;

    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0';
    my $oid_fgSysVersion = '.1.3.6.1.4.1.12356.101.4.1.1.0';

    my $result = $options{snmp}->get_leef(oids => [$oid_sysDescr, $oid_fgSysVersion]);#, nothing_quit => 1);
    $self->{output}->output_add(
        long_msg => sprintf(
            '[System: %s] [Firmware: %s]',
            $result->{$oid_sysDescr}, 
            defined($result->{$oid_fgSysVersion}) ? $result->{$oid_fgSysVersion} : 'unknown'
        )
    );
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check hardware.
It's deprecated. Work only for 'FortiGate-5000 Series Chassis'.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'sensors'.

=item B<--add-name-instance>

Add literal description for instance value (used in filter, and threshold options).

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensors,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensors,WARNING,off'

=item B<--warning>

Set warning threshold for 'sensors' (syntax: type,regexp,threshold)
Example: --warning='sensors,.*,30'

=item B<--critical>

Set critical threshold for 'sensors' (syntax: type,regexp,threshold)
Example: --critical='sensors,.*,50'


=back

=cut

package centreon::common::fortinet::fortigate::snmp::mode::components::sensors;

use strict;
use warnings;

my %alarm_map = (
    0 => 'off',
    1 => 'on',
);
my $mapping = {
    fgHwSensorEntName        => { oid => '.1.3.6.1.4.1.12356.101.4.3.2.1.2' },
    fgHwSensorEntValue       => { oid => '.1.3.6.1.4.1.12356.101.4.3.2.1.3' },
    fgHwSensorEntAlarmStatus => { oid => '.1.3.6.1.4.1.12356.101.4.3.2.1.4', map => \%alarm_map },
};
my $oid_fgHwSensorEntry = '.1.3.6.1.4.1.12356.101.4.3.2.1';

sub load {
    my ($self) = @_;

    push @{$self->{request}}, { oid => $oid_fgHwSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensors} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensors'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_fgHwSensorEntry}})) {
        next if ($oid !~ /^$mapping->{fgHwSensorEntAlarmStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_fgHwSensorEntry}, instance => $instance);
        my $name = centreon::plugins::misc::trim($result->{fgHwSensorEntName});

        next if ($self->check_filter(section => 'sensors', instance => $instance, name => $name));

        $self->{components}->{sensors}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor '%s' status is '%s' [instance = %s] [value = %s]",
                $name, $result->{fgHwSensorEntAlarmStatus}, $instance,
                defined($result->{fgHwSensorEntValue}) ? $result->{fgHwSensorEntValue} : '-'
            )
        );

        my $exit = $self->get_severity(section => 'sensors', name => $name, value => $result->{fgHwSensorEntAlarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Sensor '%s' status is '%s'", $name, $result->{fgHwSensorEntAlarmStatus})
            );
        }

        next if (!defined($result->{fgHwSensorEntValue}));

        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'sensors', instance => $instance, name => $name, value => $result->{fgHwSensorEntValue});

        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf("Sensor '%s' measure is %s", $name, $result->{fgHwSensorEntValue})
            );
        }
        $self->{output}->perfdata_add(
            nlabel => 'hardware.sensors.measure',
            instances => $name,
            value => $result->{fgHwSensorEntValue},
            warning => $warn,
            critical => $crit,
        );
    }
}

1;
