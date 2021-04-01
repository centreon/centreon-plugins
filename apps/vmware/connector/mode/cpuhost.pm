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

package apps::vmware::connector::mode::cpuhost;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_state'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'host', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All ESX hosts are ok', 
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_cpu', cb_prefix_output => 'prefix_global_cpu_output', type => 0, skipped_code => { -10 => 1 } },
                { name => 'cpu', display_long => 0, cb_prefix_output => 'prefix_cpu_output',  message_multiple => 'All CPUs are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2, unknown_default => '%{status} !~ /^connected$/i',
            set => {
                key_values => [ { name => 'state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{global_cpu} = [
        { label => 'total-cpu', nlabel => 'host.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_average' } ],
                output_template => '%s %%',
                perfdatas => [
                    { label => 'cpu_total', template => '%s', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-cpu-mhz', nlabel => 'host.cpu.utilization.mhz', set => {
                key_values => [ { name => 'cpu_average_mhz' }, { name => 'cpu_average_mhz_max' } ],
                output_template => '%s MHz',
                perfdatas => [
                    { label => 'cpu_total_MHz', template => '%s', unit => 'MHz', 
                      min => 0, max => 'cpu_average_mhz_max', label_extra_instance => 1 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'cpu', nlabel => 'host.core.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_usage' }, { name => 'display' } ],
                output_template => 'usage : %s',
                perfdatas => [
                    { label => 'cpu', template => '%s', unit => '%', 
                      min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_host_output {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' : ";
}

sub host_long_output {
    my ($self, %options) = @_;

    return "checking host '" . $options{instance_value}->{display} . "'";
}

sub prefix_global_cpu_output {
    my ($self, %options) = @_;

    return "cpu total average : ";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "cpu '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "esx-hostname:s"        => { name => 'esx_hostname' },
        "filter"                => { name => 'filter' },
        "scope-datacenter:s"    => { name => 'scope_datacenter' },
        "scope-cluster:s"       => { name => 'scope_cluster' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'cpuhost');

    foreach my $host_id (keys %{$response->{data}}) {
        my $host_name = $response->{data}->{$host_id}->{name};
        $self->{host}->{$host_name} = { display => $host_name, 
            cpu => {}, 
            global => {
                state => $response->{data}->{$host_id}->{state},    
            },
            global_cpu => {
                cpu_average => $response->{data}->{$host_id}->{'cpu.usage.average'},
                cpu_average_mhz => $response->{data}->{$host_id}->{'cpu.usagemhz.average'},
                cpu_average_mhz_max => defined($response->{data}->{$host_id}->{numCpuCores}) ?
                   $response->{data}->{$host_id}->{numCpuCores} * $response->{data}->{$host_id}->{cpuMhz} : undef,
            }, 
        };
        
        foreach my $cpu_id (sort keys %{$response->{data}->{$host_id}->{cpu}}) {
            $self->{host}->{$host_name}->{cpu}->{$cpu_id} = { display => $cpu_id, cpu_usage => $response->{data}->{$host_id}->{cpu}->{$cpu_id} };
        }
    }
}

1;

__END__

=head1 MODE

Check ESX cpu usage.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} !~ /^connected$/i').
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{status}

=item B<--warning-*>

Threshold warning.
Can be: 'total-cpu', 'total-cpu-mhz', 'cpu'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-cpu', 'total-cpu-mhz', 'cpu'.

=back

=cut
