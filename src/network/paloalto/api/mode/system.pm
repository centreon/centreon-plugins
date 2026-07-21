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

package network::paloalto::api::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :unit_conversion);
use centreon::plugins::misc qw/convert_bytes/;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'System ' }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'uptime',
            nlabel => 'system.uptime.seconds',
            set => {
                key_values => [ { name => 'uptime' } ],
                output_template => 'uptime: %s seconds',
                perfdatas => [
                    { template => '%s', unit => 's', min => 0 }
                ]
            }
        },
        {
            label => 'certificate-status',
            type  => COUNTER_KIND_TEXT,
            critical_default => '%{cert_status} !~ /Valid/i',
            set => {
                key_values => [ { name => 'cert_status' } ],
                output_template => 'certificate status: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'operational-mode',
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'operational_mode' } ],
                output_template => 'operational mode: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'software-version', display_ok => 0,
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'sw_version' } ],
                output_template => 'software version: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'wildfire-mode', display_ok => 0,
            type  => COUNTER_KIND_TEXT,
            set => {
                key_values => [ { name => 'wildfire_mode' } ],
                output_template => 'WildFire mode: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'packet-rate', nlabel => 'system.sessions.packet.rate.persecond', set => {
                key_values => [ { name => 'packet_rate' } ],
                output_template => 'packet rate: %s p/s',
                perfdatas => [
                    { template => '%s', unit => 'p/s', min => 0 }
                ]
            }
        },

        { label => 'sessions-traffic', nlabel => 'system.sessions.throughput.bitspersecond', set => {
                key_values => [ { name => 'throughput' } ],
                output_template => 'throughput: %s %s/s',
                output_change_bytes => CONVERT_NETWORK,
                perfdatas => [
                    { template => '%s', unit => 'b/s', min => 0 }
                ]
            }
        },
        { label => 'active-sessions', nlabel => 'system.sessions.total.count', set => {
                key_values => [ { name => 'active_sessions' } ],
                output_template => 'total active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type => 'op',
        cmd  => '<show><system><info></info></system></show>'
    );

    $self->{global} = {
        uptime            => 0,
        cert_status       => 'Unknown',
        operational_mode  => 'Unknown',
        sw_version        => 'Unknown',
        wildfire_mode     => 'Unknown',
        packet_rate       => 0,
        throughput        => 0,
        active_sessions   => 0
    };

    $self->{output}->option_exit(short_msg => "No matching device !")
        unless ref $result->{system} eq 'HASH';

    my $system = $result->{system};

    # Parse uptime: "X days, HH:MM:SS" format
    # <uptime>0 days, 0:13:44</uptime>
    if ($system->{uptime}) {
        my $uptime_str = $system->{uptime};
        my $uptime_seconds = 0;

        if ($uptime_str =~ /^(\d+)\s+days?,\s+(\d+):(\d+):(\d+)$/) {
            my ($days, $hours, $minutes, $seconds) = ($1, $2, $3, $4);
            $uptime_seconds = $days * 86400 + $hours * 3600 + $minutes * 60 + $seconds;
        } elsif ($uptime_str =~ /^(\d+):(\d+):(\d+)$/) {
            my ($hours, $minutes, $seconds) = ($1, $2, $3);
            $uptime_seconds = $hours * 3600 + $minutes * 60 + $seconds;
        }

        $self->{global}->{uptime} = $uptime_seconds;
    }

    $self->{global}->{cert_status} = $system->{'device-certificate-status'}
        if $system->{'device-certificate-status'};

    $self->{global}->{operational_mode} = $system->{'operational-mode'}
        if $system->{'operational-mode'};

    $self->{global}->{sw_version} = $system->{'sw-version'}
        if $system->{'sw-version'};

    $self->{global}->{wildfire_mode} = $system->{'wildfire-rt'}
        if $system->{'wildfire-rt'};

    $result = $options{custom}->request_api(
        type => 'op',
        cmd  => '<show><session><info></info></session></show>'
    );

    return unless ref $result eq 'HASH';

    $self->{global}->{packet_rate} = $result->{pps}
        if exists $result->{pps};

    $self->{global}->{throughput} = convert_bytes(value => $result->{kbps}, unit => 'kb', network => 1)
        if exists $result->{kbps};

    $self->{global}->{active_sessions} = $result->{'num-active'}
        if exists $result->{'num-active'};
}

1;

__END__

=head1 MODE

Check Palo Alto system information and status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^uptime$'

=item B<--warning-uptime>

Warning threshold for uptime in seconds.

=item B<--critical-uptime>

Critical threshold for uptime in seconds.

=item B<--unknown-certificate-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{cert_status}

=item B<--warning-certificate-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{cert_status}

=item B<--critical-certificate-status>

Define the conditions to match for the status to be CRITICAL (default: '%{cert_status} !~ /Valid/i').
You can use the following variables: %{cert_status}

=item B<--unknown-operational-mode>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{operational_mode}

=item B<--warning-operational-mode>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{operational_mode}

=item B<--critical-operational-mode>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{operational_mode}

=item B<--unknown-software-version>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sw_version}

=item B<--warning-software-version>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sw_version}

=item B<--critical-software-version>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{sw_version}

=item B<--unknown-wildfire-mode>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{wildfire_mode}

=item B<--warning-wildfire-mode>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{wildfire_mode}

=item B<--critical-wildfire-mode>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{wildfire_mode}

=item B<--warning-active-sessions>

Threshold.

=item B<--critical-active-sessions>

Threshold.

=item B<--warning-packet-rate>

Threshold in p/s.

=item B<--critical-packet-rate>

Threshold in p/s.

=item B<--warning-sessions-traffic>

Threshold in b/s.

=item B<--critical-sessions-traffic>

Threshold in b/s.

=back

=cut
