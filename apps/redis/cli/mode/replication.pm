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

package apps::redis::cli::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'master', type => 0, skipped_code => { -10 => 1 } },
        { name => 'slave', type => 0, skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'link_status' }, { name => 'sync_status' }, { name => 'role' }, { name => 'cluster_state' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'connected-slaves', set => {
                key_values => [ { name => 'connected_slaves' } ],
                output_template => 'Number of connected slaves: %s',
                perfdatas => [
                    { label => 'connected_slaves', value => 'connected_slaves', template => '%s', min => 0 },
                ],
            },
        },
    ];

    $self->{maps_counters}->{master} = [
        {  label => 'master-repl-offset', set => {
                key_values => [ { name => 'master_repl_offset' } ],
                output_template => 'Master replication offset: %s s',
                perfdatas => [
                    { label => 'master_repl_offset', value => 'master_repl_offset', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
    ];

    $self->{maps_counters}->{slave} = [
        {  label => 'master-last-io', set => {
                key_values => [ { name => 'master_last_io_seconds_ago' } ],
                output_template => 'Last interaction with master: %s s',
                perfdatas => [
                    { label => 'master_last_io', value => 'master_last_io_seconds_ago', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        {  label => 'slave-repl-offset', set => {
                key_values => [ { name => 'slave_repl_offset' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_repl_offset', value => 'slave_repl_offset', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        {  label => 'slave-priority', set => {
                key_values => [ { name => 'slave_priority' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_priority', value => 'slave_priority', template => '%s' },
                ],
            },
        },
        {  label => 'slave-read-only', set => {
                key_values => [ { name => 'slave_read_only' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_read_only', value => 'slave_read_only', template => '%s' },
                ],
            },
        },
    ];
}

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Node role is '%s' [cluster: %s]", $self->{result_values}->{role}, $self->{result_values}->{cluster_state});
    if ($self->{result_values}->{role} eq 'slave') {
        $msg .= sprintf(" [link status: %s] [sync status: %s]", 
            $self->{result_values}->{link_status}, $self->{result_values}->{sync_status});
    }
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{role} = $options{new_datas}->{$self->{instance} . '_role'};
    $self->{result_values}->{sync_status} = $options{new_datas}->{$self->{instance} . '_sync_status'};
    $self->{result_values}->{link_status} = $options{new_datas}->{$self->{instance} . '_link_status'};
    $self->{result_values}->{cluster_state} = $options{new_datas}->{$self->{instance} . '_cluster_state'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;


     $options{options}->add_options(arguments => 
                {
                "warning-status:s"    => { name => 'warning_status', default => '%{sync_status} =~ /in progress/i' },
                "critical-status:s"   => { name => 'critical_status', default => '%{link_status} =~ /down/i' },
                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_sync = (
    0 => 'stopped',
    1 => 'in progress',
);

my %map_cluster_state = (
    0 => 'disabled',
    1 => 'enabled',
);

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_info();
    
    $self->{global} = { 
        connected_slaves => $results->{connected_slaves},
        role => $results->{role},
        cluster_state => defined($results->{cluster_enabled}) ? $map_cluster_state{$results->{cluster_enabled}} : '-',
        link_status => defined($results->{master_link_status}) ? $results->{master_link_status} : '-',
        sync_status => defined($results->{master_sync_in_progress}) ? $map_sync{$results->{master_sync_in_progress}} : '-',
    };

    $self->{master} = { master_repl_offset => $results->{master_repl_offset} };
    $self->{slave} = {
        master_last_io_seconds_ago  => $results->{master_last_io_seconds_ago},
        slave_repl_offset           => $results->{slave_repl_offset},
        slave_priority              => $results->{slave_priority},
        slave_read_only             => $results->{slave_read_only},
    };
}

1;

__END__

=head1 MODE

Check replication status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{sync_status} =~ /in progress/i').
Can used special variables like: %{sync_status}, %{link_status}, %{cluster_state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{link_status} =~ /down/i').
Can used special variables like: %{sync_status}, %{link_status}, %{cluster_state}

=item B<--warning-*>

Threshold warning.
Can be: 'connected-slaves', 'master-repl-offset',
'master-last-io', 'slave-priority', 'slave-read-only'.

=item B<--critical-*>

Threshold critical.
Can be: 'connected-slaves', 'master-repl-offset',
'master-last-io', 'slave-priority', 'slave-read-only'.

=back

=cut
