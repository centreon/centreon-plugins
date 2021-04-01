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

package apps::backup::commvault::commserve::restapi::mode::mediaagents;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_device_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [is maintenance: %s][offline reason: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{is_maintenance},
        $self->{result_values}->{offline_reason}
    );
}

sub prefix_media_output {
    my ($self, %options) = @_;

    return "Media agent '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'medias', type => 1, cb_prefix_output => 'prefix_media_output', message_multiple => 'All media agents are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'media-agents-total', nlabel => 'media.agents.total.count', display_ok => 0, set => {
                key_values => [ { name => 'agents_total' } ],
                output_template => 'media agents total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{medias} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{is_maintenance} eq "no" and %{status} eq "offline"',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'name' },
                    { name => 'is_maintenance' }, { name => 'offline_reason' }
                ],
                closure_custom_output => $self->can('custom_device_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-media-agent-id:s'   => { name => 'filter_media_agent_id' },
        'filter-media-agent-name:s' => { name => 'filter_media_agent_name' }
    });

    return $self;
}

my $map_status = { 1 => 'online', 0 => 'offline' };
my $map_offline_reason = {
    0 => 'default', 1 => 'connectFail', 2 => 'versionMismatch', 3 => 'markedDisabled',
    4 => 'olderVersionAndPastGraceperiod', 5 => 'initializing', 6 => 'migrated',
    7 => 'powerManagedVm', 8 => 'nodeRefreshError', 9 => 'smartStateManagement',
    10 => 'cvfwdDetectedOffline'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request(
        endpoint => '/v2/MediaAgents'
    );

    $self->{global} = { agents_total => 0 };
    $self->{medias} = {};
    foreach (@{$results->{mediaAgentList}}) {
        if (defined($self->{option_results}->{filter_media_agent_id}) && $self->{option_results}->{filter_media_agent_id} ne '' &&
            $_->{mediaAgent}->{mediaAgentId} !~ /$self->{option_results}->{filter_media_agent_id}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{mediaAgent}->{mediaAgentName} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_media_agent_name}) && $self->{option_results}->{filter_media_agent_name} ne '' &&
            $_->{mediaAgent}->{mediaAgentName} !~ /$self->{option_results}->{filter_media_agent_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $_->{mediaAgent}->{mediaAgentName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{medias}->{ $_->{mediaAgent}->{mediaAgentName} } = {
            name => $_->{mediaAgent}->{mediaAgentName},
            status => $map_status->{ $_->{status} },
            is_maintenance => defined($_->{mediaAgentProps}->{markMAOfflineForMaintenance}) && $_->{mediaAgentProps}->{markMAOfflineForMaintenance} =~ /True|1/i ? 'yes' : 'no',
            offline_reason => $map_offline_reason->{ $_->{offlineReason} }
        };

        $self->{global}->{agents_total}++;
    }
}

1;

__END__

=head1 MODE

Check media agents.

=over 8

=item B<--filter-media-agent-id>

Filter media agents by id (Can be a regexp).

=item B<--filter-media-agent-name>

Filter media agents by name (Can be a regexp).

=item B<--unknown-device-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{is_maintenance}, %{offline_reason}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{is_maintenance} eq "no" and %{status} eq "offline"').
Can used special variables like: %{status}, %{is_maintenance}, %{offline_reason}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'media-agents-total'.

=back

=cut
