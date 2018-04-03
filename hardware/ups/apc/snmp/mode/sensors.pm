#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;
    
    $self->{regexp_threshold_overload_check_section_option} = '^(sensor)$';
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|humidity)$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        sensor => [
            ['uioNormal', 'OK'],
            ['uioWarning', 'WARNING'],
            ['uioCritical', 'OK'],
            ['sensorStatusNotApplicable', 'OK'],
        ],
    };
    
    $self->{components_path} = 'hardware::ups::apc::snmp::mode::components';
    $self->{components_module} = ['sensor'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_load_components => 1);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check sensors.

=over 8

=item B<--filter>

Exclude some parts (comma seperated list)
Can also exclude specific instance: --filter=sensor,1.1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='sensor,CRITICAL,sensorStatusNotApplicable'

=item B<--warning>

Set warning threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,40'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity' (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,50'

=back

=cut

package hardware::ups::apc::snmp::mode::components::sensor;

use strict;
use warnings;

my %map_status = (1 => 'uioNormal', 2 => 'uioWarning', 3 => 'uioCritical', 4 => 'sensorStatusNotApplicable');

my $mapping = {
    uioSensorStatusSensorName       => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.3' },
    uioSensorStatusTemperatureDegC  => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.6' },
    uioSensorStatusHumidity         => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.7' },
    uioSensorStatusAlarmStatus      => { oid => '.1.3.6.1.4.1.318.1.1.25.1.2.1.9', map => \%map_status },    
};
my $oid_uioSensorStatusEntry = '.1.3.6.1.4.1.318.1.1.25.1.2.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_uioSensorStatusEntry };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking sensors");
    $self->{components}->{sensor} = {name => 'sensors', total => 0, skip => 0};
    return if ($self->check_filter(section => 'sensor'));

    my ($exit, $warn, $crit, $checked);
    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_uioSensorStatusEntry}})) {
        next if ($oid !~ /^$mapping->{uioSensorStatusAlarmStatus}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_uioSensorStatusEntry}, instance => $instance);
        
        next if ($self->check_filter(section => 'sensor', instance => $instance));

        $self->{components}->{sensor}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("sensor '%s' status is '%s' [instance = %s] [temperature = %s C] [humidity = %s %%]",
                                                        $result->{uioSensorStatusSensorName}, $result->{uioSensorStatusAlarmStatus}, $instance,
                                                        $result->{uioSensorStatusTemperatureDegC} != -1 ? $result->{uioSensorStatusTemperatureDegC} : '-',
                                                        $result->{uioSensorStatusHumidity} != -1 ? $result->{uioSensorStatusHumidity} : '-'));
        $exit = $self->get_severity(section => 'sensor', value => $result->{uioSensorStatusAlarmStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Sensor '%s' status is '%s'", $result->{uioSensorStatusSensorName}, $result->{uioSensorStatusAlarmStatus}));
        }
        
        if ($result->{uioSensorStatusTemperatureDegC} != -1) {
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'temperature', instance => $instance, value => $result->{uioSensorStatusTemperatureDegC});            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sensor temperature '%s' is %s C", $result->{uioSensorStatusSensorName}, $result->{uioSensorStatusTemperatureDegC}));
            }
            $self->{output}->perfdata_add(label => 'temp_' . $result->{uioSensorStatusSensorName}, unit => 'C', 
                                          value => $result->{uioSensorStatusTemperatureDegC},
                                          warning => $warn,
                                          critical => $crit
                                          );
        }
        
        if ($result->{uioSensorStatusHumidity} != -1) {
            ($exit, $warn, $crit, $checked) = $self->get_severity_numeric(section => 'humidity', instance => $instance, value => $result->{uioSensorStatusHumidity});            
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Sensor humidity '%s' is %s %%", $result->{uioSensorStatusSensorName}, $result->{uioSensorStatusHumidity}));
            }
            $self->{output}->perfdata_add(label => 'humidity_' . $result->{uioSensorStatusSensorName}, unit => '%', 
                                          value => $result->{uioSensorStatusHumidity},
                                          warning => $warn,
                                          critical => $crit, min => 0, max => 100
                                          );
        }
    }
}

1;
