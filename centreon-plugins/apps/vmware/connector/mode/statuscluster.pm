#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::statuscluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status is ' . $self->{result_values}->{overall_status};
    if ($self->{result_values}->{vsan_status} ne '') {
        $msg .= ' [vsan status: ' . $self->{result_values}->{vsan_status} . ']';
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok' },
    ];
    
    $self->{maps_counters}->{cluster} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'overall_status' }, { name => 'vsan_status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_cluster_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'cluster-name:s'        => { name => 'cluster_name' },
        'filter'                => { name => 'filter' },
        'scope-datacenter:s'    => { name => 'scope_datacenter' },
        'unknown-status:s'      => { name => 'unknown_status', default => '%{overall_status} =~ /gray/i || %{vsan_status} =~ /gray/i' },
        'warning-status:s'      => { name => 'warning_status', default => '%{overall_status} =~ /yellow/i || %{vsan_status} =~ /yellow/i' },
        'critical-status:s'     => { name => 'critical_status', default => '%{overall_status} =~ /red/i || %{vsan_status} =~ /red/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cluster} = {};
    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'statuscluster'
    );

    foreach my $cluster_id (keys %{$response->{data}}) {
        my $cluster_name = $response->{data}->{$cluster_id}->{name};
        $self->{cluster}->{$cluster_name} = {
            display => $cluster_name, 
            overall_status => $response->{data}->{$cluster_id}->{overall_status},
            vsan_status => defined($response->{data}->{$cluster_id}->{vsan_cluster_status}) ? $response->{data}->{$cluster_id}->{vsan_cluster_status} : '',
        };
    }    
}

1;

__END__

=head1 MODE

Check cluster status (also vsan status).

=over 8

=item B<--cluster-name>

cluster to check.
If not set, we check all clusters.

=item B<--filter>

Cluster name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{overall_status} =~ /gray/i || %{vsan_status} =~ /gray/i').
Can used special variables like: %{overall_status}, %{vsan_status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{overall_status} =~ /yellow/i || %{vsan_status} =~ /yellow/i').
Can used special variables like: %{overall_status}, %{vsan_status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{overall_status} =~ /red/i || %{vsan_status} =~ /red/i').
Can used special variables like: %{overall_status}, %{vsan_status}

=back

=cut
