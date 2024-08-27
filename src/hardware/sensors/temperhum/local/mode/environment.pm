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

package hardware::sensors::temperhum::local::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_device_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'drive', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All measures are OK' },
    ];

    $self->{maps_counters}->{drive} = [
        { label => 'humidity', set => {
                key_values => [ { name => 'humidity' }, { name => 'display' } ],
                output_template => 'Humidity: %.2f%%',
                perfdatas => [
                    { label => 'humidity', template => '%.2f',
                      unit => '%', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'temperature' }, { name => 'dewpoint' },  { name => 'display' } ],
                output_template => 'Temperature: %.2f C',
                perfdatas => [
                    { label => 'temperature', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'dew-point', set => {
                key_values => [ { name => 'dewpoint' }, { name => 'display' } ],
                output_template => 'Dew Point : %.2f C',
                perfdatas => [
                    { label => 'dew_point', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'delta', set => {
                key_values => [ { name => 'delta' }, { name => 'display' } ],
                output_template => 'Delta (Temp - Dew) : %.2f C',
                perfdatas => [
                    { label => 'delta', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-drive:s' => { name => 'filter_drive', default => '.*' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'tempered',
        command_path => '/opt/PCsensor/TEMPered/utils'
    );

    $self->{drive} = {};
    foreach (split(/\n/, $stdout)) {
        next if !/(\/dev\/[a-z0-9]+).*temperature\s(\d*\.?\d+).*relative\shumidity\s(\d*\.?\d+).*dew\spoint\s(\d*\.?\d+)/;
        my ($drive, $temp, $hum, $dew) = ($1, $2, $3, $4);
        next if ($drive !~ /$self->{option_results}->{filter_drive}/);
        $self->{drive}->{$drive} = { humidity => $hum, temperature => $temp, dewpoint => $dew, delta => ($temp - $dew), display => $drive };
    }

    if (scalar(keys %{$self->{drive}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No informations gathered, please check your filters");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check metrics from TemPerHum sensors.

Command used: '/opt/PCsensor/TEMPered/utils/tempered'

=over 8

=item B<--filter-drive>

Filter by drive name (example: --filter-drive raw4)

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'temperature', 'humidity', 'dew-point', 'delta'

=back

=cut
