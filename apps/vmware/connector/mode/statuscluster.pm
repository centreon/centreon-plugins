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

package apps::vmware::connector::mode::statuscluster;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status is ' . $self->{result_values}->{overall_status};
    $msg .= ' [vsan status: ' . $self->{result_values}->{vsan_status} . ']' if ($self->{result_values}->{vsan_status} ne '');
    $msg .= ' [ha enabled: ' . $self->{result_values}->{ha_enabled} . ']' if ($self->{result_values}->{ha_enabled} ne '');
    $msg .= ' [drs enabled: ' . $self->{result_values}->{drs_enabled} . ']' if ($self->{result_values}->{drs_enabled} ne '');
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cluster', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok' }
    ];
    
    $self->{maps_counters}->{cluster} = [
        {
            label => 'status', type => 2,
            unknown_default => '%{overall_status} =~ /gray/i || %{vsan_status} =~ /gray/i',
            warning_default => '%{overall_status} =~ /yellow/i || %{vsan_status} =~ /yellow/i',
            critical_default => '%{overall_status} =~ /red/i || %{vsan_status} =~ /red/i', 
            set => {
                key_values => [
                    { name => 'overall_status' },
                    { name => 'vsan_status' },
                    { name => 'ha_enabled' },
                    { name => 'drs_enabled' },
                    { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
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
        'cluster-name:s'     => { name => 'cluster_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'statuscluster'
    );

    $self->{cluster} = {};
    foreach my $cluster_id (keys %{$response->{data}}) {
        my $cluster_name = $response->{data}->{$cluster_id}->{name};
        $self->{cluster}->{$cluster_name} = {
            display => $cluster_name, 
            overall_status => $response->{data}->{$cluster_id}->{overall_status},
            vsan_status => defined($response->{data}->{$cluster_id}->{vsan_cluster_status}) ? $response->{data}->{$cluster_id}->{vsan_cluster_status} : '',
            ha_enabled => defined($response->{data}->{$cluster_id}->{ha_enabled}) ? $response->{data}->{$cluster_id}->{ha_enabled} : '',
            drs_enabled => defined($response->{data}->{$cluster_id}->{drs_enabled}) ? $response->{data}->{$cluster_id}->{drs_enabled} : ''
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
Can used special variables like: %{overall_status}, %{vsan_status}, %{drs_enabled}, %{ha_enabled}

=item B<--warning-status>

Set warning threshold for status (Default: '%{overall_status} =~ /yellow/i || %{vsan_status} =~ /yellow/i').
Can used special variables like: %{overall_status}, %{vsan_status}, %{drs_enabled}, %{ha_enabled}

=item B<--critical-status>

Set critical threshold for status (Default: '%{overall_status} =~ /red/i || %{vsan_status} =~ /red/i').
Can used special variables like: %{overall_status}, %{vsan_status}, %{drs_enabled}, %{ha_enabled}

=back

=cut
