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

package apps::vmware::connector::mode::cpucluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance} . "' : ";
}

sub cluster_long_output {
    my ($self, %options) = @_;

    return "checking cluster '" . $options{instance} . "'";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return "cpu total average: ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'clusters', type => 3, cb_prefix_output => 'prefix_cluster_output', cb_long_output => 'cluster_long_output', indent_long_output => '    ', message_multiple => 'All clusters are ok', 
            group => [
                { name => 'cpu', cb_prefix_output => 'prefix_cpu_output', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'total-cpu', nlabel => 'cluster.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_average' } ],
                output_template => '%s %%',
                perfdatas => [
                    { template => '%s', unit => '%', min => 0, max => 100, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'total-cpu-mhz', nlabel => 'cluster.cpu.utilization.mhz', set => {
                key_values => [ { name => 'cpu_average_mhz' } ],
                output_template => '%s MHz',
                perfdatas => [
                    { template => '%s', unit => 'MHz', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'cluster-name:s'     => { name => 'cluster_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{host} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'cpucluster'
    );

    $self->{clusters} = {};
    foreach my $cluster_id (keys %{$response->{data}}) {
        my $cluster_name = $response->{data}->{$cluster_id}->{name};
        $self->{clusters}->{$cluster_name} = {
            cpu => {
                cpu_average => $response->{data}->{$cluster_id}->{'cpu.usage.average'},
                cpu_average_mhz => $response->{data}->{$cluster_id}->{'cpu.usagemhz.average'}
            }
        };
    }
}

1;

__END__

=head1 MODE

Check cluster cpu usage.

=over 8

=item B<--cluster-name>

cluster to check.
If not set, we check all clusters.

=item B<--filter>

Cluster name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-cpu', 'total-cpu-mhz'.

=back

=cut
