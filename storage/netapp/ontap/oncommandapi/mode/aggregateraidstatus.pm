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

package storage::netapp::ontap::oncommandapi::mode::aggregateraidstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Raid status is '%s' [type: %s] [size: %s]",
        $self->{result_values}->{status}, $self->{result_values}->{type}, $self->{result_values}->{size});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_raid_status'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_raid_type'};
    $self->{result_values}->{size} = $options{new_datas}->{$self->{instance} . '_raid_size'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Aggregate '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'aggregates', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All aggregates raid status are ok' },
    ];
    
    $self->{maps_counters}->{aggregates} = [
        { label => 'status', set => {
                key_values => [ { name => 'raid_status' }, { name => 'raid_type' }, { name => 'raid_size' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'filter-node:s'     => { name => 'filter_node' },
        'filter-cluster:s'  => { name => 'filter_cluster' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /normal/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
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

    my $result = $options{custom}->get(path => '/aggregates');

    foreach my $aggregate (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $aggregate->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $aggregate->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            defined($nodes->{$aggregate->{node_key}}) && $nodes->{$aggregate->{node_key}} !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $aggregate->{name} . "': no matching filter node '" . $nodes->{$aggregate->{node_key}} . "'", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            defined($clusters->{$aggregate->{cluster_key}}) && $clusters->{$aggregate->{cluster_key}} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $aggregate->{name} . "': no matching filter cluster '" . $clusters->{$aggregate->{cluster_key}} . "'", debug => 1);
            next;
        }

        $self->{aggregates}->{$aggregate->{key}} = {
            name => $aggregate->{name},
            raid_status => $aggregate->{raid_status},
            raid_type => $aggregate->{raid_type},
            raid_size => $aggregate->{raid_size},
        }
    }

    if (scalar(keys %{$self->{aggregates}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp aggregates raid status.

=over 8

=item B<--filter-*>

Filter volume.
Can be: 'name', 'node', 'cluster' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{type}, %{size}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /normal/i').
Can used special variables like: %{status}, %{type}, %{size}

=back

=cut
