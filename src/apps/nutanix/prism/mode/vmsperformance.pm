#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::mode::vmsperformance;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf("power state is '%s'", $self->{result_values}->{power_state});
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'vms',
            type             => 1,
            cb_prefix_output => 'prefix_vm_output',
            message_multiple => 'All VMs are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{vms} = [
        # Power state status
        {
            label           => 'status',
            type            => 2,
            warning_default => '%{power_state} ne "ON"',
            set             => {
                key_values => [
                    { name => 'name'        },
                    { name => 'power_state' },
                ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # CPU usage percentage (hypervisor_cpu_usage_ppm / 10000)
        {
            label  => 'cpu-usage',
            nlabel => 'vm.cpu.usage.percentage',
            set    => {
                key_values      => [ { name => 'cpu_usage_pct' }, { name => 'name' } ],
                output_template => 'CPU usage: %.2f%%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        max                  => 100,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
        # Memory usage percentage
        {
            label  => 'memory-usage',
            nlabel => 'vm.memory.usage.percentage',
            set    => {
                key_values      => [ { name => 'memory_usage_pct' }, { name => 'name' } ],
                output_template => 'memory usage: %.2f%%',
                perfdatas       => [
                    {
                        template             => '%.2f',
                        unit                 => '%',
                        min                  => 0,
                        max                  => 100,
                        label_extra_instance => 1,
                        instance_use         => 'name',
                    }
                ]
            }
        },
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    return "VM '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s'  => { name => 'filter_name' },
            'filter-state:s' => { name => 'filter_state' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result   = $options{custom}->get_vms();
    my $entities = $result->{entities} // [];

    $self->{vms} = {};
    for my $vm (@{$entities}) {
        my $name        = $vm->{name}        // $vm->{uuid} // 'unknown';
        my $power_state = $vm->{power_state} // 'UNKNOWN';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }
        if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '') {
            next if $power_state !~ /$self->{option_results}->{filter_state}/i;
        }

        my $stats = $vm->{stats} // {};
        # CPU: hypervisor_cpu_usage_ppm in parts-per-million → divide by 10000 for %.
        my $cpu_pct = ($stats->{hypervisor_cpu_usage_ppm} // 0) / 10000;
        my $mem_pct = ($stats->{hypervisor_memory_usage_ppm} // 0) / 10000;

        # Key on UUID for uniqueness; fall back to name if uuid is absent.
        my $key = $vm->{uuid} // $name;
        $self->{vms}->{$key} = {
            name             => $name,
            power_state      => $power_state,
            cpu_usage_pct    => $cpu_pct,
            memory_usage_pct => $mem_pct,
        };
    }

    if (scalar(keys %{$self->{vms}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No VM found (check filters).');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix VM CPU and memory usage through Prism REST API.

Stats are retrieved from the VM list endpoint — no extra per-VM API call.

=over 8

=item B<--filter-name>

Filter VMs by name (regexp). Example: C<--filter-name='^prod-'>

=item B<--filter-state>

Filter VMs by power state (case-insensitive regexp). Example: C<--filter-state='^ON$'>

=item B<--warning-status>

Warning threshold for VM power state.
Default: C<%{power_state} ne "ON">

Variables: C<%{name}>, C<%{power_state}>

=item B<--critical-status>

Critical threshold for VM power state.

=item B<--warning-cpu-usage>

Warning threshold for CPU usage (%). Example: C<--warning-cpu-usage=80>

=item B<--critical-cpu-usage>

Critical threshold for CPU usage (%). Example: C<--critical-cpu-usage=90>

=item B<--warning-memory-usage>

Warning threshold for memory usage (%).

=item B<--critical-memory-usage>

Critical threshold for memory usage (%).

=back

=cut
