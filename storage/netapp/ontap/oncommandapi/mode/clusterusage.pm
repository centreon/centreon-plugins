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

package storage::netapp::ontap::oncommandapi::mode::clusterusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All clusters usage are ok' },
    ];
    
    $self->{maps_counters}->{clusters} = [
        { label => 'max-node-utilization', set => {
                key_values => [ { name => 'max_node_utilization' }, { name => 'name' } ],
                output_template => 'Node utilization: %.2f %%',
                perfdatas => [
                    { label => 'max_node_utilization', value => 'max_node_utilization', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'max-aggregate-utilization', set => {
                key_values => [ { name => 'max_aggregate_utilization' }, { name => 'name' } ],
                output_template => 'Aggregate utilization: %.2f %%',
                perfdatas => [
                    { label => 'max_aggregate_utilization', value => 'max_aggregate_utilization', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });
   
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %names_hash;
    my $names = $options{custom}->get(path => '/clusters');
    foreach my $cluster (@{$names}) {
        $names_hash{$cluster->{key}} = {
            name => $cluster->{name},
        };
    }

    my $args = '';
    my $append = '';
    foreach my $metric ('max_node_utilization', 'max_aggregate_utilization') {
        $args .= $append . 'name=' . $metric;
        $append = '&';
    }

    my $result = $options{custom}->get(path => '/clusters/metrics', args => $args);

    foreach my $cluster (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            defined($names_hash{$cluster->{resource_key}}) && $names_hash{$cluster->{resource_key}}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $names_hash{$cluster->{resource_key}}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        foreach my $metric (@{$cluster->{metrics}}) {
            $self->{clusters}->{$cluster->{resource_key}}->{name} = $names_hash{$cluster->{resource_key}}->{name};
            $self->{clusters}->{$cluster->{resource_key}}->{max_node_utilization} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'max_node_utilization');
            $self->{clusters}->{$cluster->{resource_key}}->{max_aggregate_utilization} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'max_aggregate_utilization');
        }
    }

    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp clusters usage.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'max-node-utilization', 'max-aggregate-utilization'.

=item B<--critical-*>

Threshold critical.
Can be: 'max-node-utilization', 'max-aggregate-utilization'.

=back

=cut
