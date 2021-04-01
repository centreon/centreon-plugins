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

package snmp_standard::mode::entity;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(sensor\..*)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        sensor => [
            ['unavailable', 'OK'],
            ['ok', 'OK'],
            ['nonoperational', 'WARNING'],
        ],
    };
    
    $self->{components_path} = 'snmp_standard::mode::components';
    $self->{components_module} = ['sensor'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'sensor-scale' => { name => 'sensor_scale' },
    });

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    my $oid_entPhysicalName     = '.1.3.6.1.2.1.47.1.1.1.1.7';
    my $oid_entPhysicalDescr    = '.1.3.6.1.2.1.47.1.1.1.1.2';
    $self->{snmp} = $options{snmp};
    push @{$self->{request}}, { oid => $oid_entPhysicalName }, { oid => $oid_entPhysicalDescr };
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check entity sensors (ENTITY-SENSOR-MIB).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'sensor'.

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensor,celsius.*

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor.celsius,OK,nonoperational'

=item B<--warning>

Set warning threshold (syntax: type,regexp,threshold)
Example: --warning='sensor.celsius,.*,30'

=item B<--critical>

Set critical threshold (syntax: type,regexp,threshold)
Example: --critical='sensor.celsius,.*,40'

=item B<--sensor-scale>

Apply scaling value (some equipments are buggy. So we don't use scale by default).

=back

=cut

package snmp_standard::mode::components::sensor;

use strict;
use warnings;

my %map_sensor_status = (1 => 'ok', 2 => 'unavailable', 3 => 'nonoperational');
my %map_sensor_type = (
    1 => 'other', 
    2 => 'unknown',
    3 => 'voltsAC',
    4 => 'voltsDC',
    5 => 'amperes',
    6 => 'watts',
    7 => 'hertz',
    8 => 'celsius',
    9 => 'percentRH',
    10 => 'rpm',
    11 => 'cmm',
    12 => 'truthvalue',
    13 => 'specialEnum',
    14 => 'dBm',
);
my %map_sensor_scale = (
    1 => -24, # yocto, 
    2 => -21, # zepto
    3 => -18, # atto
    4 => -15, # femto 
    5 => -12, # pico
    6 => -9, # nano
    7 => -6, # micro
    8 => -3, # milli
    9 => 0, #units
    10 => 3, #kilo
    11 => 6, #mega
    12 => 9, #giga
    13 => 12, #tera
    14 => 18, #exa
    15 => 15, #peta
    16 => 21, #zetta
    17 => 24, #yotta
);
my %perfdata_unit = ('other' => '', 'unknown' => '', 'voltsAC' => 'V',
    'voltsDC' => 'V', 'amperes' => 'A', 'watts' => 'W',
    'hertz' => 'Hz', 'celsius' => 'C', 'percentRH' => '%',
    'rpm' => 'rpm', 'cmm' => '', 'truthvalue' => '',
    'specialEnum' => '', 'dBm' => 'dBm',
);

my $mapping = {
    entPhySensorType        => { oid => '.1.3.6.1.2.1.99.1.1.1.1', map => \%map_sensor_type },
    entPhySensorScale       => { oid => '.1.3.6.1.2.1.99.1.1.1.2', map => \%map_sensor_scale },
    entPhySensorPrecision   => { oid => '.1.3.6.1.2.1.99.1.1.1.3' },
    entPhySensorValue       => { oid => '.1.3.6.1.2.1.99.1.1.1.4' },
    entPhySensorOperStatus  => { oid => '.1.3.6.1.2.1.99.1.1.1.5', map => \%map_sensor_status },
};
my $oid_entPhySensorEntry = '.1.3.6.1.2.1.99.1.1.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_entPhySensorEntry, end => $mapping->{entPhySensorOperStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';
    my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_entPhysicalName}})) {
        next if ($oid !~ /^$oid_entPhysicalName\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_entPhySensorEntry}, instance => $instance);
        next if (!defined($result->{entPhySensorOperStatus}));
        
        next if ($self->check_filter(section => 'sensor', instance => $result->{entPhySensorType} . '.' . $instance));

        my $name = $self->{results}->{$oid_entPhysicalName}->{$oid} ne '' ? 
            $self->{results}->{$oid_entPhysicalName}->{$oid} : $self->{results}->{$oid_entPhysicalDescr}->{$oid_entPhysicalDescr . '.' . $instance};
        # It seems there is no scale
        if (!defined($self->{option_results}->{sensor_scale})) {
            $result->{entPhySensorValue} = defined($result->{entPhySensorValue}) ? 
                $result->{entPhySensorValue} * (10 ** -($result->{entPhySensorPrecision})) : undef;
        } else {
            $result->{entPhySensorValue} = defined($result->{entPhySensorValue}) ? 
                $result->{entPhySensorValue} * (10 ** ($result->{entPhySensorScale}) * (10 ** -($result->{entPhySensorPrecision})))  : undef;
        }
        
        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "sensor '%s' status is '%s' [instance = %s, value = %s]",
                $name,
                $result->{entPhySensorOperStatus},
                $result->{entPhySensorType} . '.' . $instance,
                defined($result->{entPhySensorValue}) ? $result->{entPhySensorValue} : '-'
            )
        );
        my $exit = $self->get_severity(label => 'sensor', section => 'sensor.' . $result->{entPhySensorType}, value => $result->{entPhySensorOperStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' status is '%s'", $name, $result->{entPhySensorOperStatus}));
        }
        
        next if (!defined($result->{entPhySensorValue}) || $result->{entPhySensorValue} !~ /[0-9]/);
        
        my $component = 'sensor.' . $result->{entPhySensorType};
        my ($exit2, $warn, $crit, $checked) = $self->get_severity_numeric(section => $component, instance => $instance, value => $result->{entPhySensorValue});
        if (!$self->{output}->is_status(value => $exit2, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit2,
                short_msg => sprintf(
                    "Sensor '%s/%s' is %s %s",
                    $name,
                    $instance,
                    $result->{entPhySensorValue},
                    $perfdata_unit{$result->{entPhySensorType}}
                )
            );
        }
        $self->{output}->perfdata_add(
            label => $component . '_' . $name, unit => $perfdata_unit{$result->{entPhySensorType}},
            value => $result->{entPhySensorValue},
            warning => $warn,
            critical => $crit
        );
    }
}

1;
