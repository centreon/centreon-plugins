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

package hardware::sensors::messpc::ethernetbox::snmp::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Sensor '%s' status: %s, valid %s",
        $self->{result_values}->{name},
        $self->{result_values}->{status},
        $self->{result_values}->{valid}
    );
}

sub custom_temp_output {
    my ($self, %options) = @_;

    return sprintf(
        'temperature: %s %s',
        $self->{result_values}->{temperature},
        $self->{instance_mode}->{temp_unit_short}
    );
}

sub custom_temp_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => 'sensor.temperature.' . $self->{instance_mode}->{temp_unit},
        instances => $self->{result_values}->{display},
        value     => $self->{result_values}->{temperature},
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0,
        unit      => $self->{instance_mode}->{temp_unit_short}
    );
}

sub custom_humidity_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel    => 'sensor.humidity.percent',
        instances => $self->{result_values}->{display},
        value     => $self->{result_values}->{humidity},
        warning   => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical  => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min       => 0,
        max       => 100,
        unit      => '%'
    );
}

sub custom_sensor_threshold {
    my ($self, %options) = @_;

    my $warn_limit;
    if (defined($self->{instance_mode}->{option_results}->{'warning-' . $self->{label}}) && $self->{instance_mode}->{option_results}->{'warning-' . $self->{label}} ne '') {
        $warn_limit = $self->{instance_mode}->{option_results}->{'warning-' . $self->{label}};
    }
    $self->{perfdata}->threshold_validate(
        label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display},
        value => $warn_limit
    );

    my $crit_limit = $self->{result_values}->{limit_lo} . ':' . $self->{result_values}->{limit_hi};
    if (defined($self->{instance_mode}->{option_results}->{'critical-' . $self->{label}}) && $self->{instance_mode}->{option_results}->{'critical-' . $self->{label}} ne '') {
        $crit_limit = $self->{instance_mode}->{option_results}->{'critical-' . $self->{label}};
    }
    $self->{perfdata}->threshold_validate(
        label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display},
        value => $crit_limit
    );

    my $exit = $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{$self->{label} },
        threshold =>
            [
                {
                    label         => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display},
                    exit_litteral => 'critical'
                },
                {
                    label         => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display},
                    exit_litteral => 'warning'
                }
            ]
    );
    return $exit;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'sensor',
            type             => 1,
            cb_prefix_output => 'prefix_sensor_output',
            message_multiple => 'All sensors are ok',
            skipped_code     => { -10 => 1 }
        },
    ];

    $self->{maps_counters}->{sensor} = [
        {
            label            => 'status',
            type             => 2,
            unknown_default  => '%{valid} eq 0',
            critical_default => '%{status} eq "high"',
            warning_default  => '%{status} eq "warning"',
            set              => {
                key_values                     => [ { name => 'status' }, { name => 'name' }, { name => 'valid' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'temperature', set => {
            key_values                     => [
                { name => 'temperature' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            closure_custom_output          => $self->can('custom_temp_output'),
            closure_custom_perfdata        => $self->can('custom_temp_perfdata'),
            closure_custom_threshold_check => $self->can('custom_sensor_threshold'),
        }
        },
        { label => 'humidity', set => {
            key_values                     => [
                { name => 'humidity' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            output_template                => 'humidity %.2f %%',
            closure_custom_perfdata        => $self->can('custom_humidity_perfdata'),
            closure_custom_threshold_check => $self->can('custom_sensor_threshold'),
        }
        },
        { label => 'brightness', nlabel => 'sensor.brightness.percentage', set => {
            key_values      => [
                { name => 'brightness' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            output_template => 'brightness %.2f %%',
            perfdatas       => [
                {
                    value                => 'brightness',
                    template             => '%.2f',
                    unit                 => '%',
                    min                  => 0,
                    max                  => 100,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                },
            ]
        }
        },
        { label => 'contact', nlabel => 'sensor.contact', set => {
            key_values      => [
                { name => 'contact' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            output_template => 'contact %d',
            perfdatas       => [
                {
                    value                => 'contact',
                    template             => '%d',
                    min                  => 0,
                    max                  => 1,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                },
            ]
        }
        },
        { label => 'smoke', nlabel => 'sensor.smoke', set => {
            key_values      => [
                { name => 'smoke' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            output_template => 'smoke %d',
            perfdatas       => [
                {
                    value                => 'smoke',
                    template             => '%d',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                },
            ]
        }
        },
        { label => 'voltage', nlabel => 'sensor.voltage.volt', set => {
            key_values      => [
                { name => 'voltage' },
                { name => 'limit_hi' },
                { name => 'limit_lo' },
                { name => 'display' }
            ],
            output_template => 'voltage %d V',
            perfdatas       => [
                {
                    value                => 'voltage',
                    template             => '%d',
                    unit                 => 'V',
                    min                  => 0,
                    label_extra_instance => 1,
                    instance_use         => 'display'
                },
            ]
        }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-sensor-type:s' => { name => 'filter_sensor_type', default => '^(?!na$).+' }
        });

    return $self;
}

sub prefix_sensor_output {
    my ($self, %options) = @_;

    return "Sensor '" . $options{instance_value}->{name} . "' ";
}

my $map_sensor_type = {
    0 => 'na',
    1 => 'temperature',
    2 => 'brightness',
    3 => 'humidity',
    4 => 'contact',
    5 => 'voltage',
    6 => 'smoke'
};

my $map_status = {
    0 => 'undefined',
    1 => 'low',
    2 => 'normal',
    3 => 'high'
};

my $map_temp_unit = {
    0 => 'celsius',
    1 => 'fahrenheit',
    2 => 'kelvin'
};

my $map_temp_unit_short = {
    0 => 'C',
    1 => 'F',
    2 => 'K'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_temp_unit = '.1.3.6.1.4.1.14848.2.1.1.3.0';
    my @oids = ($oid_temp_unit);

    my $snmp_result = $options{snmp}->get_leef(oids => [ @oids ], nothing_quit => 1);
    $self->{temp_unit} = $map_temp_unit->{$snmp_result->{$oid_temp_unit}};
    $self->{temp_unit_short} = $map_temp_unit_short->{$snmp_result->{$oid_temp_unit}};

    my $mapping = {
        name       => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.2' },
        sensorType => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.3', map => $map_sensor_type },
        status     => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.11', map => $map_status },
        valid      => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.7' },
        valueint10 => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.5' },
        lowlimit   => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.8' },
        highlimit  => { oid => '.1.3.6.1.4.1.14848.2.1.2.1.9' },
    };

    my $sensor_entry = '.1.3.6.1.4.1.14848.2.1.2.1';

    $snmp_result = $options{snmp}->get_table(
        oid   => $sensor_entry,
        start => $mapping->{name}->{oid},
        end   => $mapping->{status}->{oid}
    );

    $self->{sensor} = {};

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        if (defined($self->{option_results}->{filter_sensor_type}) && $self->{option_results}->{filter_sensor_type} ne '' &&
            $result->{sensorType} !~ /$self->{option_results}->{filter_sensor_type}/) {
            $self->{output}->output_add(
                long_msg => "skipping '" . $result->{sensorType} . "': no matching filter.",
                debug    => 1
            );
            next;
        }

        (my $display = $result->{name}) =~ s/\s+/_/g;

        $self->{sensor}->{$instance} = {
            display               => $display,
            name                  => $result->{name},
            sensor_type           => $result->{sensorType},
            $result->{sensorType} => defined($result->{valueint10}) ? $result->{valueint10} / 10 : undef,
            status                => $result->{status},
            valid                 => $result->{valid},
            limit_hi              => defined($result->{highlimit}) ? $result->{highlimit} : '',
            limit_lo              => defined($result->{lowlimit}) ? $result->{lowlimit} : '',
        };
    }
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{valid} eq 0').
You can use the following variables: %{status}, %{valid}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{status} eq "warning"').
You can use the following variables: %{status}, %{valid}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "high"').
You can use the following variables: %{status}, %{valid}

=item B<--warning-*>

Warning threshold.
Can be: C<temperature>, C<humidity>, C<voltage>, C<smoke>, C<contact>, C<brightness>.

=item B<--critical-*>

Critical threshold.
Can be: C<temperature>, C<humidity>, C<voltage>, C<smoke>, C<contact>, C<brightness>.

=back

=cut
