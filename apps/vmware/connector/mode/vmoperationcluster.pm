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

package apps::vmware::connector::mode::vmoperationcluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All virtual machine operations are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{cluster} = [
        { label => 'svmotion', nlabel => 'cluster.operations.svmotion.current.count', set => {
                key_values => [ { name => 'numSVMotion', diff => 1 }, { name => 'display' } ],
                output_template => 'SVMotion %s',
                perfdatas => [
                    { label => 'svmotion', template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'vmotion', nlabel => 'cluster.operations.vmotion.current.count', set => {
                key_values => [ { name => 'numVMotion', diff => 1 }, { name => 'display' } ],
                output_template => 'VMotion %s',
                perfdatas => [
                    { label => 'vmotion', template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'clone', nlabel => 'cluster.operations.clone.current.count', set => {
                key_values => [ { name => 'numClone', diff => 1 }, { name => 'display' } ],
                output_template => 'Clone %s',
                perfdatas => [
                    { label => 'clone', template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' vm operations: ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'cluster:s'          => { name => 'cluster' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cluster} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'vmoperationcluster'
    );

    foreach my $cluster_id (keys %{$response->{data}}) {
        my $cluster_name = $response->{data}->{$cluster_id}->{name};        
        $self->{cluster}->{$cluster_name} = { 
            display => $cluster_name, 
            numVMotion => $response->{data}->{$cluster_id}->{'vmop.numVMotion.latest'},
            numClone => $response->{data}->{$cluster_id}->{'vmop.numClone.latest'},
            numSVMotion => $response->{data}->{$cluster_id}->{'vmop.numSVMotion.latest'}
        };
    }
    
    $self->{cache_name} = "cache_vmware_" . $options{custom}->get_id() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{cluster}) ? md5_hex($self->{option_results}->{cluster}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual machines operations on cluster(s).

=over 8

=item B<--cluster>

Cluster to check.
If not set, we check all clusters.

=item B<--filter>

Cluster is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: svmotion, vmotion, clone.

=item B<--critical-*>

Threshold critical.
Can be: svmotion, vmotion, clone.

=back

=cut
