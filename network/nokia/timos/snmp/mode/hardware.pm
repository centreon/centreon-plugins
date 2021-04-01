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

package network::nokia::timos::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^temperature$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [
            ['unknown', 'UNKNOWN'],
            ['inService', 'OK'],
            ['outOfService', 'OK'],
            ['diagnosing', 'OK'],
            ['failed', 'CRITICAL'],
            ['booting', 'OK'],
            ['empty', 'OK'],
            ['unprovisioned', 'OK'],
            ['provisioned', 'OK'],
            ['upgrade', 'OK'],
            ['downgrade', 'OK'],
            ['resetPending', 'OK'],
            ['softReset', 'OK'],
            ['preExtension', 'OK']
        ]
    };
    
    $self->{components_path} = 'network::nokia::timos::snmp::mode::components';
    $self->{components_module} = ['entity'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request}, return_type => 1);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

=head1 MODE

Check Hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'entity'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=entity,fan.1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='entity,fan..*,CRITICAL,booting'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,20'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,30'

=back

=cut

package network::nokia::timos::snmp::mode::components::entity;

use strict;
use warnings;

my %map_class = (
    1 => 'other', 2 => 'unknown', 3 => 'physChassis',
    4 => 'container', 5 => 'powerSupply', 6 => 'fan',
    7 => 'sensor', 8 => 'ioModule', 9 => 'cpmModule',
    10 => 'fabricModule', 11 => 'mdaModule',
    12 => 'flashDiskModule', 13 => 'port', 14 => 'mcm',
    15 => 'ccm', 16 => 'oesCard', 17 => 'oesControlCard',
    18 => 'oesUserPanel', 19 => 'alarmInputModule',
);
my %map_truth = (1 => 'true', 2 => 'false');
my %map_oper_state = (
    1 => 'unknown', 2 => 'inService', 3 => 'outOfService',
    4 => 'diagnosing', 5 => 'failed', 6 => 'booting',
    7 => 'empty', 8 => 'provisioned', 9 => 'unprovisioned',
    10 => 'upgrade', 11 => 'downgrade', 12 => 'inServiceUpgrade',
    13 => 'inServiceDowngrade', 14 => 'resetPending',
    15 => 'softReset', 16 => 'preExtension',
);

my $mapping = {
    tmnxHwClass         => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.7', map => \%map_class },
    tmnxHwName          => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.8' },
    tmnxHwOperState     => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.16', map => \%map_oper_state },
    tmnxHwTempSensor    => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.17', map => \%map_truth },
    tmnxHwTemperature   => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.18' },
    tmnxHwTempThreshold => { oid => '.1.3.6.1.4.1.6527.3.1.2.2.1.8.1.19' },
};

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{tmnxHwClass}->{oid} }, { oid => $mapping->{tmnxHwName}->{oid} },
        { oid => $mapping->{tmnxHwTempSensor}->{oid} }, { oid => $mapping->{tmnxHwOperState}->{oid} },
        { oid => $mapping->{tmnxHwTemperature}->{oid} }, { oid => $mapping->{tmnxHwTempThreshold}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking entities");
    $self->{components}->{entity} = {name => 'entity', total => 0, skip => 0};
    return if ($self->check_filter(section => 'entity'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}})) {
        next if ($oid !~ /^$mapping->{tmnxHwName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => $instance);
        
        next if ($self->check_filter(section => 'entity', instance => $result->{tmnxHwClass} . '.' . $instance));
        
        $self->{components}->{entity}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("%s '%s' status is '%s' [instance = %s, temperature = %s]",
                                                        $result->{tmnxHwClass}, $result->{tmnxHwName}, 
                                                        $result->{tmnxHwOperState}, $result->{tmnxHwClass} . '.' . $instance,
                                                        $result->{tmnxHwTempSensor} eq 'true' ? $result->{tmnxHwTemperature} : '-'));
        $exit = $self->get_severity(label => 'default', section => 'entity', instance => $result->{tmnxHwClass} . '.' . $instance, value => $result->{tmnxHwOperState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s '%s' status is '%s'", $result->{tmnxHwClass}, $result->{tmnxHwName}, $result->{tmnxHwOperState}));
        }
        
        next if ($result->{tmnxHwTempSensor} eq 'false');
        ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $result->{tmnxHwClass} . '.' . $instance,, value => $result->{tmnxHwTemperature});            
        if ($checked == 0 && $result->{tmnxHwTempThreshold} != -1 ) {
            $self->{perfdata}->threshold_validate(label => 'critical-temperature-instance-' . $result->{tmnxHwClass} . '.' . $instance, value => $result->{tmnxHwTempThreshold});

            $exit = $self->{perfdata}->threshold_check(value => $result->{slHdwTempSensorCurrentTemp}, threshold => [ { label => 'critical-temperature-instance-' . $instance, exit_litteral => 'critical' }]);
            $warn = undef;
            $crit = $self->{perfdata}->get_perfdata_for_output(label => 'critical-temperature-instance-' . $result->{tmnxHwClass} . '.' . $instance);
        }
        
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s '%s' temperature is '%s' C", $result->{tmnxHwClass}, 
                                            $result->{tmnxHwName}, $result->{tmnxHwTemperature}));
        }
        $self->{output}->perfdata_add(
            label => 'temperature', unit => 'C',
            nlabel => 'hardware.entity.temperature.celsius',
            instances => $result->{tmnxHwName},
            value => $result->{tmnxHwTemperature},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
