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

package apps::podman::restapi::mode::containerusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw/is_empty/;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'container', type => 0 }
    ];

    $self->{maps_counters}->{container} = [
        { label  => 'cpu-usage',
          nlabel => 'podman.container.cpu.usage.percent',
          set    => {
              key_values      => [ { name => 'cpu_usage' } ],
              output_template => 'CPU: %.2f%%',
              perfdatas       => [
                  { label    => 'cpu',
                    value    => 'cpu_usage',
                    template => '%.2f',
                    unit     => '%',
                    min      => 0,
                    max      => 100 }
              ]
          }
        },
        { label  => 'memory-usage',
          nlabel => 'podman.container.memory.usage.bytes',
          set    => {
              key_values          => [ { name => 'memory_usage' } ],
              output_template     => 'Memory: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'memory',
                    value    => 'memory_usage',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label  => 'read-io',
          nlabel => 'podman.container.io.read',
          set    => {
              key_values          => [ { name => 'io_read' } ],
              output_template     => 'Read : %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'read.io',
                    value    => 'io_read',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label  => 'write-io',
          nlabel => 'podman.container.io.write',
          set    => {
              key_values          => [ { name => 'io_write' } ],
              output_template     => 'Write : %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'write.io',
                    value    => 'io_write',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label  => 'network-in',
          nlabel => 'podman.container.network.in',
          set    => {
              key_values          => [ { name => 'network_in' } ],
              output_template     => 'Network in: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'network_in',
                    value    => 'network_in',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label  => 'network-out',
          nlabel => 'podman.container.network.out',
          set    => {
              key_values          => [ { name => 'network_out' } ],
              output_template     => 'Network out: %s%s',
              output_change_bytes => 1,
              perfdatas           => [
                  { label    => 'network_out',
                    value    => 'network_out',
                    template => '%s',
                    unit     => 'B',
                    min      => 0 }
              ]
          }
        },
        { label            => 'state',
          type             => 2,
          warning_default  => '%{state} =~ /Paused/i',
          critical_default => '%{state} =~ /Exited/i',
          set              => {
              key_values                     => [ { name => 'state' } ],
              output_template                => 'State: %s',
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
        'container-name:s' => { name => 'container_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{output}->option_exit(short_msg => "Need to specify --container-name option.")
        if (is_empty($self->{option_results}->{container_name}));
}

sub manage_selection {
    my ($self, %options) = @_;

    my $container = $options{custom}->get_container_infos(
        container_name => $self->{option_results}->{container_name}
    );
    # if there is no state, it means the container could not be found => unknown
    $self->{output}->option_exit(short_msg => "State of container " . $self->{option_results}->{container_name} . " not found.")
        if (is_empty($container->{state}));

    $self->{container} = $container;
}

1;

__END__

=head1 MODE

Check container usage.

=over 8

=item B<--container-name>

Container name.

=item B<--warning-cpu-usage>

Threshold warning for CPU usage.

=item B<--critical-cpu-usage>

Threshold critical for CPU usage.

=item B<--warning-memory-usage>

Threshold warning for memory usage.

=item B<--critical-memory-usage>

Threshold critical for memory usage.

=item B<--warning-read-io>

Threshold warning for read IO.

=item B<--critical-read-io>

Threshold critical for read IO.

=item B<--warning-write-io>

Threshold warning for write IO.

=item B<--critical-write-io>

Threshold critical for write IO.

=item B<--warning-network-in>

Threshold warning for network in.

=item B<--critical-network-in>

Threshold critical for network in.

=item B<--warning-network-out>

Threshold warning for network out.

=item B<--critical-network-out>

Threshold critical for network out.

=item B<--warning-container-state>

Define the conditions to match for the state to be WARNING (default: C<'%{state} =~ /Paused/'>).
You can use the following variables: C<%{state}>

=item B<--critical-container-state>

Define the conditions to match for the state to be CRITICAL (default: C<'%{state} =~ /Exited/'>).
You can use the following variables: C<%{state}>

=back

=cut
