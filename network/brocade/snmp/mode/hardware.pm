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

package network::brocade::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|fan)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        sensor => [
            ['unknown', 'UNKNOWN'],
            ['faulty', 'CRITICAL'],
            ['below-min', 'WARNING'],
            ['nominal', 'OK'],
            ['above-max', 'CRITICAL'],
            ['absent', 'OK']
        ],
        switch => [
            ['online', 'OK'],
            ['offline', 'WARNING'],
            ['testing', 'WARNING'],
            ['faulty', 'CRITICAL'],
            ['absent', 'OK']
        ]
    };
    
    $self->{components_path} = 'network::brocade::snmp::mode::components';
    $self->{components_module} = ['switch', 'sensor'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_load_components => 1);
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

Check brocade operational status and hardware sensors (SW.mib).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'switch', 'sensor'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensor,1.1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping)
Can be specific or global: --absent-problem=sensor,1.2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor,OK,unknown'

=item B<--warning>

Set warning threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'fan' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut

package network::brocade::snmp::mode::components::sensor;

use strict;
use warnings;
use centreon::plugins::misc;

my %map_status = (1 => 'unknown', 2 => 'faulty', 3 => 'below-min', 4 => 'nominal', 5 => 'above-max', 6 => 'absent');
my %map_type = (1 => 'temperature', 2 => 'fan', 3 => 'power-supply');
my %map_unit = (temperature => 'celsius', fan => 'rpm'); # No voltage value available

my $mapping = {
    swSensorType    => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.2', map => \%map_type },
    swSensorStatus  => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.3', map => \%map_status },
    swSensorValue   => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.4' },
    swSensorInfo    => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1.5' },    
};
my $oid_swSensorEntry = '.1.3.6.1.4.1.1588.2.1.1.1.1.22.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_swSensorEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_swSensorEntry}})) {
        next if ($oid !~ /^$mapping->{swSensorStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_swSensorEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'sensor', instance => $instance));
        next if ($result->{swSensorStatus} =~ /absent/i && 
                 $self->absent_problem(section => 'sensor', instance => $instance));

        $result->{swSensorInfo} = centreon::plugins::misc::trim($result->{swSensorInfo});
        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("%s sensor '%s' status is '%s' [instance = %s]",
                                                        $result->{swSensorType}, $result->{swSensorInfo}, $result->{swSensorStatus}, $instance));
        my $exit = $self->get_severity(section => 'sensor', value => $result->{swSensorStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("%s sensor '%s' status is '%s'", $result->{swSensorType}, $result->{swSensorInfo}));
        }
        
        if ($result->{swSensorValue} > 0 && $result->{swSensorType} ne 'power-supply') {
            my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $result->{swSensorType}, instance => $instance, value => $result->{swSensorValue});            
            if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit2,
                                            short_msg => sprintf("%s sensor '%s' is %s %s", $result->{swSensorType}, $result->{swSensorInfo}, $result->{swSensorValue},
                                                                 $map_unit{$result->{swSensorType}}));
            }
            $self->{output}->perfdata_add(
                label => 'sensor', unit => $map_unit{$result->{swSensorType}},
                nlabel => 'hardware.sensor.' . $result->{swSensorType} . '.' . $map_unit{$result->{swSensorType}},
                instances => $result->{swSensorInfo},
                value => $result->{swSensorValue},
                warning => $warn,
                critical => $crit
            );
        }
    }
}

1;

package network::brocade::snmp::mode::components::switch;

use strict;
use warnings;

my %map_oper_status = (1 => 'online', 2 => 'offline', 3 => 'testing', 4 => 'faulty');

my $mapping_global = {
    swFirmwareVersion   => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.6' },
    swOperStatus        => { oid => '.1.3.6.1.4.1.1588.2.1.1.1.1.7', map => \%map_oper_status },
};
my $oid_swSystem = '.1.3.6.1.4.1.1588.2.1.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_swSystem, start => $mapping_global->{swFirmwareVersion}->{oid}, end => $mapping_global->{swOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking switch");
    $self->{components}->{switch} = {name => 'switch', total => 0, skip => 0};
    return if ($self->check_filter(section => 'switch'));

    my $result = $self->{snmp}->map_instance(mapping => $mapping_global, results => $self->{results}->{$oid_swSystem}, instance => '0');
    return if (!defined($result->{swOperStatus}));

    $self->{components}->{switch}->{total}++;

    $self->{output}->output_add(long_msg => sprintf("switch operational status is '%s' [firmware: %s].",
                                                    $result->{swOperStatus}, $result->{swFirmwareVersion}
                                ));
    my $exit = $self->get_severity(section => 'switch', value => $result->{swOperStatus});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity =>  $exit,
                                    short_msg => sprintf("switch operational status is '%s'",
                                                         $result->{swOperStatus}));
    }
}

1;
