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

package hardware::sensors::temperhum::local::mode::environment;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

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
                    { label => 'humidity', value => 'humidity', template => '%.2f',
                      unit => '%', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
        { label => 'temperature', set => {
                key_values => [ { name => 'temperature' }, { name => 'dewpoint' },  { name => 'display' } ],
                output_template => 'Temperature: %.2f C',
                perfdatas => [
                    { label => 'temperature', value => 'temperature', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            },
        },
        { label => 'dew-point', set => {
                key_values => [ { name => 'dewpoint' }, { name => 'display' } ],
                output_template => 'Dew Point : %.2f C',
                perfdatas => [
                    { label => 'dew_point', value => 'dewpoint', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'delta', set => {
                key_values => [ { name => 'delta' }, { name => 'display' } ],
                output_template => 'Delta (Temp - Dew) : %.2f C',
                perfdatas => [
                    { label => 'delta', value => 'delta', template => '%.2f',
                      unit => 'C', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'tempered' },
                                  "command-path:s"    => { name => 'command_path', default => '/opt/PCsensor/TEMPered/utils/' },
                                  "command-options:s" => { name => 'command_options' },
                                  "filter-drive:s"    => { name => 'filter_drive', default => '.*' },
                                });
    return $self;
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{drive} = {};
    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

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

Check metrics from TemPerHum sensors 

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'tempered').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '-u').

=item B<--filter-drive>
Filter by drive name (e.g --filter-drive raw4)

=item B<--warning-*>
Threshold Warning
Can be: 'temperature', 'humidity', 'dew-point', 'delta'

=item B<--critical-*>
Threshold Critical
Can be: 'temperature', 'humidity', 'dew-point', 'delta'

=back

=cut
