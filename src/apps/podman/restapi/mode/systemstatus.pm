#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::podman::restapi::mode::systemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'system', type => 0 }
    ];

    $self->{maps_counters}->{system} = [
        { label  => 'cpu-usage',
          nlabel => 'podman.system.cpu.usage.percent',
          set    => {
              key_values      => [
                  { name => 'cpu_usage' }
              ],
              output_template => 'CPU: %.2f%%',
              perfdatas       => [
                  { label    => 'cpu',
                    template => '%.2f',
                    min      => 0,
                    max      => 100,
                    unit     => '%' }
              ]
          }
        },
        { label  => 'memory-usage',
          nlabel => 'podman.system.memory.usage.bytes',
          set    => {
              key_values          => [
                  { name => 'memory_usage' }
              ],
              output_template     => 'Memory: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'memory',
                    template => '%s',
                    min      => 0,
                    unit     => 'B' }
              ]
          }
        },
        { label  => 'swap-usage',
          nlabel => 'podman.system.swap.usage.bytes',
          set    => {
              key_values          => [
                  { name => 'swap_usage' }
              ],
              output_template     => 'Swap: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'swap',
                    template => '%s',
                    min      => 0,
                    unit     => 'B' }
              ]
          }
        },
        { label  => 'containers-running',
          nlabel => 'podman.system.containers.running.count',
          set    => {
              key_values      => [
                  { name => 'running_containers' },
                  { name => 'total_containers' }
              ],
              output_template => 'Running containers: %s',
              perfdatas       => [
                  { label    => 'running_containers',
                    template => '%s',
                    min      => 0,
                    max      => 'total_containers',
                    unit     => '' }
              ]
          }
        },
        { label  => 'containers-stopped',
          nlabel => 'podman.system.containers.stopped.count',
          set    => {
              key_values      => [
                  { name => 'stopped_containers' },
                  { name => 'total_containers' }
              ],
              output_template => 'Stopped containers: %s',
              perfdatas       => [
                  { label    => 'stopped_containers',
                    template => '%s',
                    min      => 0,
                    max      => 'total_containers',
                    unit     => '' }
              ]
          }
        },
        { label  => 'uptime',
          nlabel => 'podman.system.uptime.seconds',
          set    => {
              key_values      => [
                  { name => 'uptime' }
              ],
              output_template => 'Uptime: %s s',
              perfdatas       => [
                  { label    => 'uptime',
                    template => '%s',
                    min      => 0,
                    unit     => 's' }
              ]
          }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->system_info();

    my $uptime_string = $results->{host}->{uptime};
    my $uptime = 0;
    if ($uptime_string =~ /(\d+)h/) {
        $uptime += $1 * 3600;
    }
    if ($uptime_string =~ /(\d+)m/) {
        $uptime += $1 * 60;
    }
    if ($uptime_string =~ /(\d+)s/) {
        $uptime += $1;
    }

    $self->{system} = {
        cpu_usage          => $results->{host}->{cpuUtilization}->{userPercent} + $results->{host}->{cpuUtilization}->{systemPercent},
        memory_usage       => $results->{host}->{memTotal} - $results->{host}->{memFree},
        swap_usage         => $results->{host}->{swapTotal} - $results->{host}->{swapFree},
        running_containers => $results->{store}->{containerStore}->{running},
        stopped_containers => $results->{store}->{containerStore}->{stopped},
        total_containers   => $results->{store}->{containerStore}->{number},
        uptime             => $uptime
    };
}

1;

__END__

=head1 MODE

Check Podman system status.

=over 8

=item B<--warning-cpu-usage>

Threshold warning in percent for CPU usage.

=item B<--critical-cpu-usage>

Threshold critical in percent for CPU usage.

=item B<--warning-memory-usage>

Threshold warning in bytes for memory usage.

=item B<--critical-memory-usage>

Threshold critical in bytes for memory usage.

=item B<--warning-swap-usage>

Threshold warning in bytes for swap usage.

=item B<--critical-swap-usage>

Threshold critical in bytes for swap usage.

=item B<--warning-containers-running>

Threshold warning for the number of running containers.

=item B<--critical-containers-running>

Threshold critical for the number of running containers.

=item B<--warning-containers-stopped>

Threshold warning for the number of stopped containers.

=item B<--critical-containers-stopped>

Threshold critical for the number of stopped containers.

=item B<--warning-uptime>

Threshold warning for uptime in seconds.

=item B<--critical-uptime>

Threshold critical for uptime in seconds.

=back

=cut
