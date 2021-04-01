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

package storage::netapp::ontap::oncommandapi::mode::clusterio;

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
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All clusters IOs are ok' },
    ];
    
    $self->{maps_counters}->{clusters} = [
        { label => 'total-throughput', set => {
                key_values => [ { name => 'total_throughput' }, { name => 'name' } ],
                output_template => 'Total throughput: %.2f %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'total_throughput', value => 'total_throughput', template => '%.2f',
                      min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'name' },
                ],
            }
        },
        { label => 'total-ops', set => {
                key_values => [ { name => 'total_ops' }, { name => 'name' } ],
                output_template => 'Total IOPS: %.2f ops/s',
                perfdatas => [
                    { label => 'total_ops', value => 'total_ops', template => '%.2f',
                      min => 0, unit => 'ops/s', label_extra_instance => 1, instance_use => 'name' },
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
    foreach my $metric ('total_ops', 'total_throughput') {
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
            $self->{clusters}->{$cluster->{resource_key}}->{total_ops} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'total_ops');
            $self->{clusters}->{$cluster->{resource_key}}->{total_throughput} = ${$metric->{samples}}[0]->{value} if ($metric->{name} eq 'total_throughput');
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

Check NetApp clusters IOs.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total-throughput', 'total-ops'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-throughput', 'total-ops'.

=back

=cut
