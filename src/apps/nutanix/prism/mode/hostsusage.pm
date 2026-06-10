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

package apps::nutanix::prism::mode::hostsusage;

use strict;
use warnings;
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    return sprintf(
        "host '%s' state is '%s'",
        $self->{result_values}->{name},
        $self->{result_values}->{state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name             => 'hosts',
            type             => 1,
            cb_prefix_output => 'prefix_host_output',
            message_multiple => 'All hosts are OK',
            skipped_code     => { -10 => 1 },
        }
    ];

    $self->{maps_counters}->{hosts} = [
        # Statut de l'hôte
        {
            label           => 'status',
            type            => 2,
            warning_default => '%{state} ne "NORMAL"',
            set             => {
                key_values                     => [ { name => 'name' }, { name => 'state' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
        # Utilisation CPU en pourcentage
        {
            label  => 'cpu-usage',
            nlabel => 'host.cpu.usage.percentage',
            set    => {
                key_values      => [ { name => 'cpu_usage_pct' }, { name => 'name' } ],
                output_template => 'CPU usage: %.2f%%',
                perfdatas       => [
                    {
                        template         => '%.2f',
                        unit             => '%',
                        min              => 0,
                        max              => 100,
                        label_extra_instance => 1,
                        instance_use     => 'name',
                    }
                ]
            }
        },
        # Utilisation RAM en pourcentage
        {
            label  => 'memory-usage',
            nlabel => 'host.memory.usage.percentage',
            set    => {
                key_values      => [ { name => 'memory_usage_pct' }, { name => 'name' } ],
                output_template => 'memory usage: %.2f%%',
                perfdatas       => [
                    {
                        template         => '%.2f',
                        unit             => '%',
                        min              => 0,
                        max              => 100,
                        label_extra_instance => 1,
                        instance_use     => 'name',
                    }
                ]
            }
        },
        # Nombre de VMs sur cet hôte
        {
            label  => 'vms-count',
            nlabel => 'host.vms.count',
            set    => {
                key_values      => [ { name => 'num_vms' }, { name => 'name' } ],
                output_template => 'VMs: %d',
                perfdatas       => [
                    {
                        template         => '%d',
                        min              => 0,
                        label_extra_instance => 1,
                        instance_use     => 'name',
                    }
                ]
            }
        },
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;
    return "Host '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(
        arguments => {
            'filter-name:s' => { name => 'filter_name' },
        }
    );

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_hosts();
    my $entities = $result->{entities} // [];

    $self->{hosts} = {};
    for my $host (@{$entities}) {
        my $name = $host->{name} // $host->{uuid} // 'unknown';

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '') {
            next if $name !~ /$self->{option_results}->{filter_name}/;
        }

        # L'API v2.0 retourne des stats dans host->{stats}
        # cpu_usage_ppm = parties par million (diviser par 10000 pour avoir %)
        my $stats        = $host->{stats} // {};
        my $cpu_ppm      = $stats->{hypervisor_cpu_usage_ppm} // 0;
        my $cpu_pct      = $cpu_ppm / 10000;

        # memory_usage_ppm également en ppm
        my $mem_ppm      = $stats->{hypervisor_memory_usage_ppm} // 0;
        my $mem_pct      = $mem_ppm / 10000;

        $self->{hosts}->{$name} = {
            name             => $name,
            state            => $host->{host_in_maintenance_mode} ? 'MAINTENANCE' : 'NORMAL',
            cpu_usage_pct    => $cpu_pct,
            memory_usage_pct => $mem_pct,
            num_vms          => $host->{num_vms} // 0,
        };
    }

    if (scalar(keys %{$self->{hosts}}) == 0) {
        $self->{output}->add_option_msg(short_msg => 'No host found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Monitor Nutanix host CPU, memory usage and VM count through Prism REST API.

=over 8

=item B<--filter-name>

Filter hosts by name (regexp). Example: C<--filter-name='^AHV'>

=item B<--warning-status>

Warning threshold for host state.
Default: C<%{state} ne "NORMAL">

Variables: C<%{name}>, C<%{state}>

=item B<--critical-status>

Critical threshold for host state.

=item B<--warning-cpu-usage>

Warning threshold for CPU usage (%).

=item B<--critical-cpu-usage>

Critical threshold for CPU usage (%).

=item B<--warning-memory-usage>

Warning threshold for memory usage (%).

=item B<--critical-memory-usage>

Critical threshold for memory usage (%).

=item B<--warning-vms-count>

Warning threshold for VM count per host.

=item B<--critical-vms-count>

Critical threshold for VM count per host.

=back

=cut
