#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package os::linux::local::mode::ntp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my %state_map_ntpq = (
    '<sp>' => 'discarded due to high stratum and/or failed sanity checks',
    'x' => 'designated falsticker by the intersection algorithm',
    '.' => 'culled from the end of the candidate list',
    '-' => 'discarded by the clustering algorithm',
    '+' => 'included in the final selection set',
    '#' => 'selected for synchronization but distance exceeds maximum',
    '*' => 'selected for synchronization',
    'o' => 'selected for synchronization, PPS signal in use'
);

my %type_map_ntpq = (
    'l' => 'local',
    'u' => 'unicast',
    'm' => 'multicast',
    'b' => 'broadcast',
    '-' => 'netaddr'
);

my %state_map_chronyc = (
    'x' => 'time may be in error',
    '-' => 'not combined',
    '+' => 'combined',
    '?' => 'unreachable',
    '*' => 'current synced',
    '~' => 'time too variable'
);

my %type_map_chronyc = (
    '^' => 'server',
    '=' => 'peer',
    '#' => 'local clock'
);

my %unit_map_chronyc = (
    'ns' => 0.000001,
    'us' => 0.001,
    'ms' => 1,
    's'  => 1000
);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        '[type: %s] [reach: %s] [state: %s]',
        $self->{result_values}->{type},
        $self->{result_values}->{reach},
        $self->{result_values}->{state}
    );
}

sub custom_offset_perfdata {
    my ($self, %options) = @_;

    if ($self->{result_values}->{state} ne '*') {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            unit => 'ms',
            instances => $self->{result_values}->{display},
            value => $self->{result_values}->{offset},
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            nlabel => $self->{nlabel},
            unit => 'ms',
            instances =>  $self->{result_values}->{display},
            value => $self->{result_values}->{offset},
            warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
            min => 0
        );
    }
}

sub custom_offset_threshold {
    my ($self, %options) = @_;

    if ($self->{result_values}->{state} ne '*') {
        return 'ok';
    }
    return $self->{perfdata}->threshold_check(value => $self->{result_values}->{offset}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All peers are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'peers', nlabel => 'peers.detected.count', set => {
                key_values => [ { name => 'peers' } ],
                output_template => 'Number of ntp peers: %d',
                perfdatas => [
                    { label => 'peers', template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', type => 2, set => {
                key_values => [
                    { name => 'rawstate' }, { name => 'rawtype' },
                    { name => 'state' }, { name => 'type' },
                    { name => 'reach' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'offset', nlabel => 'peer.time.offset.milliseconds', display_ok => 0, set => {
                key_values => [ { name => 'offset' }, { name => 'state' }, { name => 'display' } ],
                output_template => 'offset: %s ms',
                closure_custom_threshold_check => $self->can('custom_offset_threshold'),
                closure_custom_perfdata => $self->can('custom_offset_perfdata'),
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'stratum', nlabel => 'peer.stratum.count', display_ok => 0, set => {
                key_values => [ { name => 'stratum' }, { name => 'display' } ],
                output_template => 'stratum: %s',
                perfdatas => [
                    { label => 'stratum', template => '%s', min => 0, label_extra_instance => 1, instance_use => 'display' }
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
        'ntp-mode:s'     => { name => 'ntp_mode', default => 'ntpq' },
        'filter-name:s'  => { name => 'filter_name' },
        'filter-state:s' => { name => 'filter_state' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{ntp_mode} !~ /^(?:ntpq|chronyc|all)$/) {
        $self->{output}->add_option_msg(short_msg => "ntp mode '" . $self->{option_results}->{ntp_mode} . "' not implemented" );
        $self->{output}->option_exit();
    }
}

sub get_ntp_modes {
    my ($self, %options) = @_;

    my $modes = {
        ntpq => {
            regexp => '^(\+|\*|\.|\-|\#|x|\<sp\>|o)(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)',
            command => 'ntpq',
            command_options => '-p -n 2>&1',
            type => 'ntpq'
        },
        chronyc => {
            regexp => '^(.)(\+|\*|\.|\-|\#|x|\<sp\>)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*?)(\d+)(\w+)$',
            command => 'chronyc',
            command_options => '-n sources 2>&1',
            type => 'chronyc'
        }
    };

    if ($self->{option_results}->{ntp_mode} eq 'ntpq') {
        return [ $modes->{ntpq} ];
    } elsif ($self->{option_results}->{ntp_mode} eq 'chronyc') {
        return [ $modes->{chronyc} ];
    }

    return [ $modes->{chronyc}, $modes->{ntpq} ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my $modes = $self->get_ntp_modes();

    $self->{global} = { peers => 0 };
    $self->{peers} = {};
    foreach my $mode (@$modes) {
        my ($stdout) = $options{custom}->execute_command(
            command => $mode->{command},
            command_options => $mode->{command_options},
            no_quit => $self->{option_results}->{ntp_mode} eq 'all' ? 1 : undef
        );

        my @lines = split(/\n/, $stdout);
        foreach my $line (@lines) {
            if ($self->{option_results}->{ntp_mode} ne 'all' && $line =~ /Connection refused/) {
                $self->{output}->add_option_msg(short_msg => "check ntp.conf and ntp daemon" );
                $self->{output}->option_exit();
            }
            next if ($line !~ /$mode->{regexp}/);

            my ($remote_peer, $peer_fate) = (centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($1));
            if ($mode->{type} eq 'chronyc') {
                $remote_peer = centreon::plugins::misc::trim($3);
                $peer_fate = centreon::plugins::misc::trim($2);
            }
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $remote_peer !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $remote_peer . "': no matching filter peer name.", debug => 1);
                next;
            }
            if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                $peer_fate !~ /$self->{option_results}->{filter_state}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $remote_peer . "': no matching filter peer state.", debug => 1);
                next;
            }

            if ($mode->{type} eq 'ntpq') {
                my ($refid, $stratum, $type, $last_time, $polling_intervall, $reach, $delay, $offset, $jitter) = ($3, $4, $5, $6, $7, $8, $9, $10, $11);
                $self->{peers}->{$remote_peer} = {
                    display  => $remote_peer,
                    rawstate => $peer_fate,
                    state    => $state_map_ntpq{$peer_fate},
                    stratum  => centreon::plugins::misc::trim($stratum),
                    rawtype  => centreon::plugins::misc::trim($type),
                    type     => $type_map_ntpq{centreon::plugins::misc::trim($type)},
                    reach    => centreon::plugins::misc::trim($reach),
                    offset   => centreon::plugins::misc::trim($offset)
                };
            } elsif ($mode->{type} eq 'chronyc') {
                #210 Number of sources = 4
                #MS Name/IP address         Stratum Poll Reach LastRx Last sample               
                #===============================================================================
                #^+ 212.83.187.62                 2   9   377   179   -715us[ -731us] +/-   50ms
                #^- 129.250.35.251                2   8   377    15    -82us[  -99us] +/-   96ms

                my ($type, $stratum, $poll, $reach, $lastRX, $offset) = ($1, $4, $5, $6, $7, $9);
                $self->{peers}->{$remote_peer} = {
                    display  => $remote_peer,
                    rawstate => $peer_fate,
                    state    => $state_map_chronyc{$peer_fate},
                    stratum  => centreon::plugins::misc::trim($stratum),
                    rawtype  => centreon::plugins::misc::trim($type),
                    type     => $type_map_chronyc{centreon::plugins::misc::trim($type)},
                    reach    => centreon::plugins::misc::trim($reach),
                    offset   => centreon::plugins::misc::trim($offset) * $unit_map_chronyc{centreon::plugins::misc::trim($10)},
                };
            }

            $self->{global}->{peers}++;
        }
    }
}

1;

__END__

=head1 MODE

Check ntp daemons.

Command used: 'ntpq -p -n 2>&1' or 'chronyc -n sources 2>&1'

=over 8

=item B<--ntp-mode>

Default mode for parsing and command: 'ntpq' (default), 'chronyc' or 'all'.

=item B<--filter-name>

Filter peer name (can be a regexp).

=item B<--filter-state>

Filter peer state (can be a regexp).

=item B<--warning-peers>

Threshold warning minimum amount of NTP-Server

=item B<--critical-peers>

Threshold critical minimum amount of NTP-Server

=item B<--warning-offset>

Threshold warning offset deviation value in milliseconds

=item B<--critical-offset>

Threshold critical offset deviation value in milliseconds

=item B<--warning-stratum>

Threshold warning.

=item B<--critical-stratum>

Threshold critical.

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=back

=cut
