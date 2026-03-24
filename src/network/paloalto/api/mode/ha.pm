#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::ha;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ha', type => COUNTER_TYPE_GLOBAL, cb_prefix_output => 'prefix_ha_output' }
    ];

    $self->{maps_counters}->{ha} = [
        {
            label => 'local-state',
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'local_state_priority' } ],
                output_template => '%s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'peer-state',
            type  => COUNTER_KIND_TEXT,
            warning_default => '%{peer_state_priority} =~ /suspicious/i',
            critical_default => '%{peer_state_priority} !~ /active|passive/i || %{peer_state_priority} !~ /up/i',
            set => {
                key_values => [ { name => 'peer_state_priority' } ],
                output_template => '%s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'state-sync',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{state_sync} !~ /^synchronized|complete$/i',
            set => {
                key_values => [ { name => 'state_sync' } ],
                output_template => 'state sync: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'ha1-link-status',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{ha1_status} ne "up"',
            set => {
                key_values => [ { name => 'ha1_status' } ],
                output_template => 'HA1 link: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'ha2-link-status',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{ha2_status} ne "up"',
            set => {
                key_values => [ { name => 'ha2_status' } ],
                output_template => 'HA2 link: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'ha-mode',
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'ha_mode' } ],
                output_template => 'HA mode: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'build-compat',
            type  => COUNTER_KIND_TEXT,
            warning_default => '%{build_compat} ne "Match"',
            set => {
                key_values => [ { name => 'build_compat' } ],
                output_template => 'build compatibility: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_ha_output {
    my ($self, %options) = @_;
    my $model = $options{instance_value}->{platform_model} // 'HA';
    return "$model status: ";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><high-availability><state></state></high-availability></show>'
    );

    my $group = $result->{group} // {};
    my $local = $group->{'local-info'} // {};
    my $peer = $group->{'peer-info'} // {};

    my $local_state = lc($local->{state} //'');
    my $peer_state = lc($peer->{state} // '');
    my $ha_mode = lc($group->{mode} // '');
    my $platform_model = $local->{'platform-model'} // '';

    $self->{ha} = {
        platform_model       => $platform_model,
        local_state_priority => "local state: $local_state (priority: " . $local->{priority} . ")",
        peer_state_priority  => "peer state: $peer_state (priority: " . $peer->{priority} . ", conn: " . lc($peer->{'conn-status'}) . ")",
        state_sync           => lc($group->{'running-sync'}),
        ha1_status           => lc($peer->{'conn-ha1'}->{'conn-status'}),
        ha2_status           => lc($peer->{'conn-ha2'}->{'conn-status'}),
        ha_mode              => $ha_mode,
        build_compat         => $peer->{'build-compat'} || $local->{'build-compat'}
    };
}

1;

__END__

=head1 MODE

Check Palo Alto High Availability (HA) status.

=over 8

=item B<--unknown-local-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{local_state}, %{local_priority}

=item B<--warning-local-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{local_state}, %{local_priority}

=item B<--critical-local-state>

Define the conditions to match for the status to be CRITICAL (default: '%{local_state} !~ /^(?:active|passive)$/i').
You can use the following variables: %{local_state}, %{local_priority}

=item B<--unknown-peer-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{peer_state}, %{peer_priority}, %{peer_conn_status}

=item B<--warning-peer-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{peer_state}, %{peer_priority}, %{peer_conn_status}

=item B<--critical-peer-state>

Define the conditions to match for the status to be CRITICAL (default: '%{peer_state} !~ /^(?:active|passive|unknown)$/i || %{peer_conn_status} ne "up"').
You can use the following variables: %{peer_state}, %{peer_priority}, %{peer_conn_status}

=item B<--unknown-state-sync>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state_sync}

=item B<--warning-state-sync>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state_sync}

=item B<--critical-state-sync>

Define the conditions to match for the status to be CRITICAL (default: '%{state_sync} !~ /^synchronized|complete$/i').
You can use the following variables: %{state_sync}

=item B<--unknown-ha1-link-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{ha1_status}

=item B<--warning-ha1-link-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{ha1_status}

=item B<--critical-ha1-link-status>

Define the conditions to match for the status to be CRITICAL (default: '%{ha1_status} ne "up"').
You can use the following variables: %{ha1_status}

=item B<--unknown-ha2-link-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{ha2_status}

=item B<--warning-ha2-link-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{ha2_status}

=item B<--critical-ha2-link-status>

Define the conditions to match for the status to be CRITICAL (default: '%{ha2_status} ne "up"').
You can use the following variables: %{ha2_status}

=item B<--unknown-build-compat>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{build_compat}

=item B<--warning-build-compat>

Define the conditions to match for the status to be WARNING (default: '%{build_compat} ne "Match"').
You can use the following variables: %{build_compat}

=item B<--critical-build-compat>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{build_compat}

=back

=cut
