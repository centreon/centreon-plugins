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

package storage::netapp::ontap::oncommandapi::mode::nodefailoverstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Failover state is '%s', Interconnect is '%s' [current mode: %s] [take_over_possible: %s]",
        $self->{result_values}->{state},
        $self->{result_values}->{interconnect},
        $self->{result_values}->{current_mode},
        $self->{result_values}->{take_over_possible});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_failover_state'};
    $self->{result_values}->{interconnect} = ($options{new_datas}->{$self->{instance} . '_is_interconnect_up'}) ? "up" : "down";
    $self->{result_values}->{current_mode} = $options{new_datas}->{$self->{instance} . '_current_mode'};
    $self->{result_values}->{take_over_possible} = ($options{new_datas}->{$self->{instance} . '_is_take_over_possible'}) ? "true" : "false";

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All nodes status are ok' },
    ];
    
    $self->{maps_counters}->{nodes} = [
        { label => 'status', set => {
                key_values => [ { name => 'failover_state' }, { name => 'current_mode' }, { name => 'is_interconnect_up' }, 
                    { name => 'is_take_over_possible' }, { name => 'name' } ],
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
        'filter-cluster:s'  => { name => 'filter_cluster' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{state} !~ /connected/i || %{interconnect} !~ /up/i'}
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

    if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '') {
        $clusters = $options{custom}->get_objects(path => '/clusters', key => 'key', name => 'name');
    }

    my $result = $options{custom}->get(path => '/nodes');

    foreach my $node (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_cluster}) && $self->{option_results}->{filter_cluster} ne '' &&
            defined($clusters->{$node->{cluster_key}}) && $clusters->{$node->{cluster_key}} !~ /$self->{option_results}->{filter_cluster}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{name} . "': no matching filter cluster '" . $clusters->{$node->{cluster_key}} . "'", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{key}} = {
            name => $node->{name},
            failover_state => $node->{failover_state},
            current_mode => $node->{current_mode},
            is_interconnect_up => $node->{is_interconnect_up},
            is_take_over_possible => $node->{is_take_over_possible},
        }
    }

    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp nodes status.

=over 8

=item B<--filter-*>

Filter node.
Can be: 'name', 'clusters' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{interconnect}, %{current_mode}, %{take_over_possible}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /connected/i || %{interconnect} !~ /up/i').
Can used special variables like: %{state}, %{interconnect}, %{current_mode}, %{take_over_possible}

=back

=cut
