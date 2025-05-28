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

package apps::podman::restapi::mode::podstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pod', type => 0 }
    ];

    $self->{maps_counters}->{pod} = [
        { label  => 'cpu-usage',
          nlabel => 'podman.pod.cpu.usage.percent',
          set    => {
              key_values      => [ { name => 'cpu' } ],
              output_template => 'CPU: %.2f%%',
              perfdatas       => [
                  { label    => 'cpu',
                    value    => 'cpu',
                    template => '%.2f',
                    unit     => '%',
                    min      => 0,
                    max      => 100 }
              ]
          }
        },
        { label  => 'memory-usage',
          nlabel => 'podman.pod.memory.usage.bytes', set => {
              key_values          => [ { name => 'memory' } ],
              output_template     => 'Memory: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'memory',
                    value    => 'memory',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label  => 'running-containers',
          nlabel => 'podman.pod.containers.running.count',
          set    => {
              key_values      => [ { name => 'containers_running' } ],
              output_template => 'Running containers: %s',
              perfdatas       => [
                  { label    => 'containers_running',
                    value    => 'containers_running',
                    template => '%s',
                    min      => 0 }
              ]
          }
        },
        { label  => 'stopped-containers',
          nlabel => 'podman.pod.containers.stopped.count',
          set    => {
              key_values      => [ { name => 'containers_stopped' } ],
              output_template => 'Stopped containers: %s',
              perfdatas       => [
                  { label    => 'containers_stopped',
                    value    => 'containers_stopped',
                    template => '%s',
                    min      => 0 }
              ]
          }
        },
        { label  => 'paused-containers',
          nlabel => 'podman.pod.containers.paused.count',
          set    => {
              key_values      => [ { name => 'containers_paused' } ],
              output_template => 'Paused containers: %s',
              perfdatas       => [
                  { label    => 'containers_paused',
                    value    => 'containers_paused',
                    template => '%s',
                    min      => 0 }
              ]
          }
        },
        { label            => 'state',
          type             => 2,
          warning_default  => '%{state} =~ /Exited/',
          critical_default => '%{state} =~ /Degraded/',
          set              => {
              key_values                     => [ { name => 'state' } ],
              output_template                => 'State: %s',
              closure_custom_perfdata        => sub { return 0; },
              closure_custom_threshold_check => \&catalog_status_threshold_ng
          }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'pod-name:s' => { name => 'pod_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (centreon::plugins::misc::is_empty($self->{option_results}->{pod_name})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --pod-name option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_pod_infos(
        pod_name => $self->{option_results}->{pod_name}
    );

    $self->{pod} = {
        cpu                => $result->{cpu},
        memory             => $result->{memory},
        containers_running => $result->{running_containers},
        containers_stopped => $result->{stopped_containers},
        containers_paused  => $result->{paused_containers},
        state              => $result->{state}
    };
}

1;

__END__

=head1 MODE

Check node status.

=over 8

=item B<--pod-name>

Pod name.

=item B<--warning-cpu-usage>

Threshold warning for CPU usage.

=item B<--critical-cpu-usage>

Threshold critical for CPU usage.

=item B<--warning-memory-usage>

Threshold warning for memory usage.

=item B<--critical-memory-usage>

Threshold critical for memory usage.

=item B<--warning-running-containers>

Threshold warning for running containers.

=item B<--critical-running-containers>

Threshold critical for running containers.

=item B<--warning-stopped-containers>

Threshold warning for stopped containers.

=item B<--critical-stopped-containers>

Threshold critical for stopped containers.

=item B<--warning-paused-containers>

Threshold warning for paused containers.

=item B<--critical-paused-containers>

Threshold critical for paused containers.

=item B<--warning-state>

Define the conditions to match for the state to be WARNING (default: C<'%{state} =~ /Exited/'>).
You can use the following variables: C<%{state}>

=item B<--critical-state>

Define the conditions to match for the state to be CRITICAL (default: C<'%{state} =~ /Degraded/'>).
You can use the following variables: C<%{state}>

=back

=cut
