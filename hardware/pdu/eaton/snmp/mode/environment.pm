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

package hardware::pdu::eaton::snmp::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = "status '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pdu', type => 3, cb_prefix_output => 'prefix_pdu_output', cb_long_output => 'pdu_long_output', indent_long_output => '    ', message_multiple => 'All pdu sensors are ok',
            group => [
                { name => 'temperature', display_long => 1, cb_prefix_output => 'prefix_temperature_output',  message_multiple => 'All temperature sensors are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'humidity', display_long => 1, cb_prefix_output => 'prefix_humidity_output',  message_multiple => 'All humidity sensors are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{temperature} = [
        { label => 'temperature-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'temperature', nlabel => 'sensor.temperature.celsius', set => {
                key_values => [ { name => 'value' }, { name => 'display' } ],
                output_template => 'temperature %.1f C',
                perfdatas => [
                    { value => 'value', template => '%.1f', 
                      unit => 'C', label_extra_instance => 1 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{humidity} = [
        { label => 'humidity-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'humidity', nlabel => 'sensor.humidity.percentage', set => {
                key_values => [ { name => 'value' }, { name => 'display' } ],
                output_template => 'humidity %.2f %%',
                perfdatas => [
                    { value => 'value', template => '%.2f', 
                      unit => '%', min => 0, max => 100, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'unknown-temperature-status:s'  => { name => 'unknown_temperature_status', default => '' },
        'warning-temperature-status:s'  => { name => 'warning_temperature_status', default => '' },
        'critical-temperature-status:s' => { name => 'critical_temperature_status', default => '%{status} eq "bad"' },
        'unknown-humidity-status:s'     => { name => 'unknown_humidity_status', default => '' },
        'warning-humidity-status:s'     => { name => 'warning_humidity_status', default => '' },
        'critical-humidity-status:s'    => { name => 'critical_humidity_status', default => '%{status} eq "bad"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(
        macros => [
            'warning_temperature_status', 'critical_temperature_status', 'unknown_temperature_status',
            'warning_humidity_status', 'critical_humidity_status', 'unknown_humidity_status',
        ]
    );
}

sub prefix_pdu_output {
    my ($self, %options) = @_;

    return "PDU '" . $options{instance_value}->{display} . "' : ";
}

sub pdu_long_output {
    my ($self, %options) = @_;

    return "checking pdu '" . $options{instance_value}->{display} . "'";
}

sub prefix_temperature_output {
    my ($self, %options) = @_;

    return "temperature '" . $options{instance_value}->{display} . "' ";
}

sub prefix_humidity_output {
    my ($self, %options) = @_;

    return "humidity '" . $options{instance_value}->{display} . "' ";
}   

my $mapping_scale = { 0 => 'celsius', 1 => 'fahrenheit' };
my $mapping_probe = { -1 => 'bad', 0 => 'disconnected', 1 => 'connected' };

my $mapping = {
    serialNumber     => { oid => '.1.3.6.1.4.1.534.6.6.7.1.2.1.4' },
    temperatureScale => { oid => '.1.3.6.1.4.1.534.6.6.7.1.2.1.9' },
};
my $mapping2 = {
    temperatureName        => { oid => '.1.3.6.1.4.1.534.6.6.7.7.1.1.2' },
    temperatureProbeStatus => { oid => '.1.3.6.1.4.1.534.6.6.7.7.1.1.3', map => $mapping_probe },
    temperatureValue       => { oid => '.1.3.6.1.4.1.534.6.6.7.7.1.1.4' },
};
my $mapping3 = {
    humidityName        => { oid => '.1.3.6.1.4.1.534.6.6.7.7.2.1.2' },
    humidityProbeStatus => { oid => '.1.3.6.1.4.1.534.6.6.7.7.2.1.3', map => $mapping_probe },
    humidityValue       => { oid => '.1.3.6.1.4.1.534.6.6.7.7.2.1.4' },
};
my $oid_unitEntry = '.1.3.6.1.4.1.534.6.6.7.1.2.1';
my $oid_temperatureEntry = '.1.3.6.1.4.1.534.6.6.7.7.1.1';
my $oid_humidityEntry = '.1.3.6.1.4.1.534.6.6.7.7.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_unitEntry, start => $mapping->{serialNumber}->{oid}, end => $mapping->{temperatureScale}->{oid} },
            { oid => $oid_temperatureEntry, start => $mapping2->{temperatureName}->{oid}, end => $mapping2->{temperatureValue}->{oid} },
            { oid => $oid_humidityEntry, start => $mapping3->{humidityName}->{oid}, end => $mapping3->{humidityValue}->{oid} },
        ],
        nothing_quit => 1
    );

    $self->{pdu} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_unitEntry}}) {
        next if ($oid !~ /^$mapping->{serialNumber}->{oid}\.(.*)$/);
        my $strapping_index = $1;
        
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_unitEntry}, instance => $strapping_index);
        my $temp_scale = $result->{temperatureScale};
        my $pdu_serial = $result->{serialNumber};
        $self->{pdu}->{$pdu_serial} = {
            display => $pdu_serial,
            temperature => {},
            humidity => {},
        };

        foreach (keys %{$snmp_result->{$oid_temperatureEntry}}) {
            next if (! /^$mapping2->{temperatureProbeStatus}->{oid}\.$strapping_index\.(.*)$/);
            $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_temperatureEntry}, instance => $strapping_index . '.' . $1);

            my $name = defined($result->{temperatureName}) && $result->{temperatureName} ne '' ? $result->{temperatureName} : $1;
            my $value = $result->{temperatureValue} / 10;
            $value = centreon::plugins::misc::convert_fahrenheit(value => $value) if ($temp_scale eq 'fahrenheit');
            $self->{pdu}->{$pdu_serial}->{temperature}->{$name} = {
                display => $name,
                status => $result->{temperatureProbeStatus},
                value => $value,
            };
        }

        foreach (keys %{$snmp_result->{$oid_humidityEntry}}) {
            next if (! /^$mapping3->{humidityProbeStatus}->{oid}\.$strapping_index\.(.*)$/);
            $result = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$oid_humidityEntry}, instance => $strapping_index . '.' . $1);

            my $name = defined($result->{humidityName}) && $result->{humidityName} ne '' ? $result->{humidityName} : $1;
            $self->{pdu}->{$pdu_serial}->{humidity}->{$name} = {
                display => $name,
                status => $result->{humidityProbeStatus},
                value => $result->{humidityValue} / 10,
            };
        }
    }

    if (scalar(keys %{$self->{pdu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No pdu found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check pdu environmental sensors.

=over 8

=item B<--unknown-temperature-status>

Set unknon threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-temperature-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-temperature-status>

Set critical threshold for status (Default: '%{status} eq "bad"').
Can used special variables like: %{status}, %{display}

=item B<--unknown-humidity-status>

Set unknon threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-humidity-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-humidity-status>

Set critical threshold for status (Default: '%{status} eq "bad"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'humidity' (%), 'temperature' (C).

=back

=cut
