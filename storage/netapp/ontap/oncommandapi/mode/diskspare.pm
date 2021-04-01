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

package storage::netapp::ontap::oncommandapi::mode::diskspare;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'disks', type => 0},
    ];
    
    $self->{maps_counters}->{disks} = [
        { label => 'spare', set => {
                key_values => [ { name => 'spare' } ],
                output_template => 'Spare disks: %d',
                perfdatas => [
                    { label => 'spare', value => 'spare', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'zeroed', set => {
                key_values => [ { name => 'zeroed' } ],
                output_template => 'Zeroed disks: %d',
                perfdatas => [
                    { label => 'zeroed', value => 'zeroed', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'not-zeroed', set => {
                key_values => [ { name => 'not_zeroed' } ],
                output_template => 'Not zeroed disks: %d',
                perfdatas => [
                    { label => 'not_zeroed', value => 'not_zeroed', template => '%d',
                      min => 0 },
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
        'filter-node:s'    => { name => 'filter_node' },
        'filter-cluster:s' => { name => 'filter_cluster' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $clusters;
    my $nodes;

    if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '') {
        $clusters = $options{custom}->get_objects(path => '/clusters', key => 'key', name => 'name');
    }

    if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '') {
        $nodes = $options{custom}->get_objects(path => '/nodes', key => 'key', name => 'name');
    }

    my $result = $options{custom}->get(path => '/disks');

    $self->{disks}->{spare} = 0;
    $self->{disks}->{zeroed} = 0;
    $self->{disks}->{not_zeroed} = 0;
    
    foreach my $disk (@{$result}) {
        next if ($disk->{container_type} !~ /spare/i);

        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            defined($nodes->{$disk->{owner_node_key}}) && $nodes->{$disk->{owner_node_key}} !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $disk->{name} . "': no matching filter node '" . $nodes->{$disk->{owner_node_key}} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            defined($clusters->{$disk->{cluster_key}}) && $clusters->{$disk->{cluster_key}} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $disk->{name} . "': no matching filter cluster '" . $clusters->{$disk->{cluster_key}} . "'", debug => 1);
            next;
        }

        $self->{disks}->{spare}++;
        $self->{disks}->{zeroed}++ if ($disk->{is_zeroed});
        if (!$disk->{is_zeroed}) {
            $self->{disks}->{not_zeroed}++;

            my $long_msg = "Spare disk '" . $disk->{name} . "' is not in 'zeroed' state [shelf: " . $disk->{shelf} . "]";
            $long_msg .= " [node: " . $nodes->{$disk->{owner_node_key}} . "]" if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '');
            $long_msg .= " [cluster: " . $clusters->{$disk->{cluster_key}} . "]" if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '');
            $self->{output}->output_add(long_msg => $long_msg);
        }
    }
}

1;

__END__

=head1 MODE

Check NetApp spare disks.

=over 8

=item B<--filter-*>

Filter disk.
Can be: 'node', 'cluster' (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'spare', 'zeroed', 'not-zeroed'.

=item B<--critical-*>

Threshold critical.
Can be: 'spare', 'zeroed', 'not-zeroed'.

=back

=cut
