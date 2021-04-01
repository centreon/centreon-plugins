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

package storage::synology::snmp::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "cluster status is '%s' [heartbeat status: %s] [active node: %s] [passive node: %s]",
        $self->{result_values}->{cluster_status},
        $self->{result_values}->{heartbeat_status},
        $self->{result_values}->{active_node_name},
        $self->{result_values}->{passive_node_name}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
        
    $self->{maps_counters}->{global} = [
         { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'cluster_status' }, { name => 'heartbeat_status' },
                    { name => 'active_node_name' }, { name => 'passive_node_name' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'heartbeat-latency', nlabel => 'ha.heartbeat.latency.microseconds', display_ok => 0, set => {
                key_values => [ { name => 'heartbeat_latency' } ],
                output_template => 'heartbeat latency: %s us',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'us' }
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
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{cluster_status} =~ /warning/i || %{heartbeat_status} =~ /abnormal/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{cluster_status} =~ /critical/i || %{heartbeat_status} =~ /disconnected/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $map_cluster_status = {
    0 => 'normal', 1 => 'warning', 2 => 'critical', 3 => 'upgrading', 4 => 'processing'
};
my $map_heartbeat_status = {
    0 => 'normal', 1 => 'abnormal', 2 => 'disconnected', 3 => 'empty'
};

my $mapping = {
    active_node_name  => { oid => '.1.3.6.1.4.1.6574.106.1' }, # activeNodeName
    passive_node_name => { oid => '.1.3.6.1.4.1.6574.106.2' }, # passiveNodeName
    cluster_status    => { oid => '.1.3.6.1.4.1.6574.106.5', map => $map_cluster_status }, # clusterStatus
    heartbeat_status  => { oid => '.1.3.6.1.4.1.6574.106.6', map => $map_heartbeat_status }, # heartbeatStatus
    heartbeat_latency => { oid => '.1.3.6.1.4.1.6574.106.8' } # microseconds
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
}

1;

__END__

=head1 MODE

Check high availability.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{cluster_status}, %{heartbeat_status}, %{active_node_name}, %{passive_node_name}

=item B<--warning-status>

Set warning threshold for status (Default: '%{cluster_status} =~ /warning/i || %{heartbeat_status} =~ /abnormal/i').
Can used special variables like: %{cluster_status}, %{heartbeat_status}, %{active_node_name}, %{passive_node_name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{cluster_status} =~ /critical/i || %{heartbeat_status} =~ /disconnected/i').
Can used special variables like: %{cluster_status}, %{heartbeat_status}, %{active_node_name}, %{passive_node_name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'heartbeat-latency'.

=back

=cut
