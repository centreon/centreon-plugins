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

my %unit_map_timedatectl = (
    'us' => 0.001,
    'ms' => 1,
    's'  => 1000,
    'min' => 60 * 1000,
    'h' => 60 * 60 * 1000,
    'd' => 24 * 60 *60 * 1000
);

my %state_map_timedatectl = (
    'synchronized' => 'currently active and fully synchronized',
    'syncing' => 'currently active and synchronizing',
    'available' => 'configured and available for use',
    'unused' => 'configured as fallback but not used',
    'inactive' => 'not used because NTP service is inactive'
);

my %type_map_timedatectl = (
    'primary' => 'Primary NTP Server',
    'fallback' => 'Fallback NTP Server'
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

    if ($self->{result_values}->{rawstate} !~ /(\*|synchronized)/) {
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

    return 'ok' if $self->{result_values}->{rawstate} !~ /^(\*|synchronized)$/;

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
                key_values => [ { name => 'offset' }, { name => 'rawstate' }, { name => 'display' } ],
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
        'ntp-mode:s'      => { name => 'ntp_mode', default => 'auto' },
        'filter-name:s'   => { name => 'filter_name', default => '' },
        'exclude-name:s'  => { name => 'exclude_name', default => '' },
        'filter-state:s'  => { name => 'filter_state', default => '' },
        'exclude-state:s' => { name => 'exclude_state', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{ntp_mode} !~ /^(ntpq|chronyc|timedatectl|all|auto)$/) {
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
        },
        timedatectl => {
            regexp => '',
            command => '',
            command_options => '',
            type => 'timedatectl'
        }
    };

    # Returns the selected mode or all modes
    return [ $modes->{$self->{option_results}->{ntp_mode}} ?
                $modes->{$self->{option_results}->{ntp_mode}} :
                ( $modes->{timedatectl}, $modes->{chronyc}, $modes->{ntpq} ) ];
}

sub skip_record {
    my ($self, %options) = @_;

    my $name = $options{display} // '';
    my $address = $options{address} // '';
    my $rawstate = $options{rawstate} // '';
    my $state = $options{state} // '';

    # filter_name includes name and address
    if ($self->{option_results}->{filter_name} ne '' && $name !~ /$self->{option_results}->{filter_name}/ && $address !~ /$self->{option_results}->{filter_name}/) {
        $self->{output}->output_add(long_msg => "skipping '$name': no matching filter peer name.", debug => 1);
        return 1;
    }
    if ($self->{option_results}->{exclude_name} ne '' && ($name =~ /$self->{option_results}->{exclude_name}/ || $address =~ /$self->{option_results}->{exclude_name}/)) {
        $self->{output}->output_add(long_msg => "skipping '$name': excluded peer name.", debug => 1);
        return 1;
    }

    if ($self->{option_results}->{filter_state} ne '' && $state !~ /$self->{option_results}->{filter_state}/ && $rawstate !~ /$self->{option_results}->{filter_state}/) {
        $self->{output}->output_add(long_msg => "skipping '$name': no matching filter peer state.", debug => 1);
        return 1;
    }
    if ($self->{option_results}->{exclude_state} ne '' && ($state =~ /$self->{option_results}->{exclude_state}/ || $rawstate =~ /$self->{option_results}->{exclude_state}/)) {
        $self->{output}->output_add(long_msg => "skipping '$name': excluded peer state.", debug => 1);
        return 1;
    }

    return 0;
}

sub manage_timedatectl {
    my ($self, %options) = @_;

    # With timedatectl three calls are required to retrieve all information
    #
    # timedatectl status to retrieve 'NTP service' and 'System clock synchronized'
    # Output snippet:
    #    System clock synchronized: yes
    #                  NTP service: active
    #
    # timedatectl timesync-status to retrieve 'Offset', 'Stratum' and 'Packet count'
    # Output snippet:
    #       Version: 4
    #       Stratum: 2
    #        Offset: -398us
    #        Jitter: 150us
    #  Packet count: 2
    #
    # timedatectl show-timesync to retrieve 'SystemNTPServers', 'FallbackNTPServers', 'ServerAddress' and 'ServerName'
    # Output snippet:
    # SystemNTPServers=0.pool.ntp.org 1.pool.ntp.org 2.pool.ntp.org
    # FallbackNTPServers=3.pool.ntp.org 4.pool.ntp.org
    # ServerName=0.pool.ntp.org
    # ServerAddress=188.125.64.7
    # PollIntervalUSec=4min 16s
    # NTPMessage={ Leap=0, Version=4, Mode=4, Stratum=2, Precision=-25, RootDelay=79.940ms, RootDispersion=1.358ms, Reference=628B853E, OriginateTimestamp=Thu 2025-08-28 14:31:58 CEST, ReceiveTimestamp=Thu 2025-08-28 14:31:58 CEST, TransmitTimestamp=Thu 2025-08-28 14:31:58 CEST, DestinationTimestamp=Thu 2025-08-28 14:31:58 CEST, Ignored=no PacketCount=3, Jitter=573us }

    my ($stdout_status) = $options{custom}->execute_command(    command => 'timedatectl',
                                                                command_options => 'status 2>&1',
                                                                no_quit => 1, );
    my ($stdout_timesync) = $options{custom}->execute_command(  command => 'timedatectl',
                                                                command_options => 'timesync-status 2>&1',
                                                                no_quit => 1, );
    my ($stdout_show) = $options{custom}->execute_command(      command => 'timedatectl',
                                                                command_options => 'show-timesync 2>&1',
                                                                no_quit => 1, );

    my %values = ( ( map { /^\s*(.+?): (.+)$/ } split /\n/, $stdout_timesync ),
                   ( map { /^(.+?)=(.+)$/ } split /\n/, $stdout_show ),
                   ( map { /^\s*(.+?): (.+)$/ } split /\n/, $stdout_status ) );

    return "timedatectl not available" unless $values{'NTP service'};

    $values{$_}//='' foreach ('SystemNTPServers', 'FallbackNTPServers', 'ServerAddress', 'ServerName', 'Offset', 'Stratum', 'Packet count', 'System clock synchronized');

    my $active_is_fallback = 0;

    # Primary and fallback servers are initialized, the active server is excluded as it will be initialized later with additional information
    # A server has either the type 'primary' or 'fallback'
    # A 'primary' server can have the states 'available', 'synchronized', 'syncing' or 'inactive'
    # A 'fallback' server can have the states 'unused', synchronized', 'syncing' or 'inactive'
    foreach my $srv (split /\s/, $values{SystemNTPServers}) {
        next if $values{ServerAddress} && ($srv eq $values{ServerAddress} || $srv eq $values{ServerName});

        $self->{peers}->{$srv} = { display => $srv, rawstate => 'available', stratum => 0, rawtype => 'primary', reach => 0, offset => 0 };
        $self->{global}->{peers}++
    }
    foreach my $srv (split /\s/, $values{FallbackNTPServers}) {
        if ($values{ServerAddress} && ($srv eq $values{ServerAddress} || $srv eq $values{ServerName})) {
            $active_is_fallback = 1;
            next
        }
        $self->{peers}->{$srv} = { display => $srv, rawstate => 'unused', stratum => 0, rawtype => 'fallback', reach => 0, offset => 0 };
        $self->{global}->{peers}++
    }

    if ($values{ServerAddress} ne '') {
        # If there is an active server it is initialized here with all information
        $values{ServerName} = $values{ServerAddress} if $values{ServerName} eq '';
        $values{'Offset'} = $1 * $unit_map_timedatectl{$2} if $values{'Offset'} =~ /^(.*?)([a-z]+)$/ && $unit_map_timedatectl{$2};

        $self->{peers}->{$values{ServerAddress}} = { display => $values{ServerName},
                                                     address => $values{ServerAddress},
                                                     rawstate => $values{'System clock synchronized'} eq 'yes' ? 'synchronized' : 'syncing',
                                                     rawtype => $active_is_fallback ? 'fallback' : 'primary',
                                                     stratum => $values{Stratum},
                                                     reach => $values{'Packet count'},
                                                     offset => $values{'Offset'} };
        $self->{global}->{peers}++;
    }

    foreach my $peer (keys %{$self->{peers}}) {
        $self->{peers}->{$peer}->{rawstate} = 'inactive' if $values{'NTP service'} ne 'active';
        $self->{peers}->{$peer}->{state} = $state_map_timedatectl{$self->{peers}->{$peer}->{rawstate}};
        $self->{peers}->{$peer}->{type} = $type_map_timedatectl{$self->{peers}->{$peer}->{rawtype}};

        # Data is only filtered here becase all states must be initialized first
        if ($self->skip_record(%{$self->{peers}->{$peer}})) {
            delete $self->{peers}->{$peer};
            $self->{global}->{peers}--;
            next
        }
    }

    undef;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $request_mode = $self->{option_results}->{ntp_mode};
    my $no_quit = $self->{option_results}->{ntp_mode} =~ /^(all|auto)$/;
    my $modes = $self->get_ntp_modes();

    $self->{global} = { peers => 0 };
    $self->{peers} = {};

    foreach my $mode (@$modes) {
        # Exit if we are in auto mode and the previous mode has already found peers
        last if $self->{global}->{peers} && $request_mode eq 'auto';

        if ($mode->{type} eq 'timedatectl') {
            # timedatectl differs from other modes so it is handled in its own function
            my $error = $self->manage_timedatectl( custom => $options{custom} );

            if ($no_quit == 0 && $error) {
                $self->{output}->add_option_msg(short_msg => $error);
                $self->{output}->option_exit();
            }
            next
        }

        my ($stdout) = $options{custom}->execute_command(
            command => $mode->{command},
            command_options => $mode->{command_options},
            no_quit => $no_quit
        );

        my @lines = split /\n/, $stdout;
        foreach my $line (@lines) {
            if ($no_quit == 0 && $line =~ /Connection refused/) {
                $self->{output}->add_option_msg(short_msg => "check ntp.conf and ntp daemon" );
                $self->{output}->option_exit();
            }
            next if $line !~ /$mode->{regexp}/;

            my $entry = {};
            my ($remote_peer, $peer_fate) = (centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($1));
            if ($mode->{type} eq 'chronyc') {
                $remote_peer = centreon::plugins::misc::trim($3);
                $peer_fate = centreon::plugins::misc::trim($2);
                my ($type, $stratum, $poll, $reach, $lastRX, $offset) = ($1, $4, $5, $6, $7, $9);
                $entry = {
                    display  => $remote_peer,
                    rawstate => $peer_fate,
                    state    => $state_map_chronyc{$peer_fate},
                    stratum  => centreon::plugins::misc::trim($stratum),
                    rawtype  => centreon::plugins::misc::trim($type),
                    type     => $type_map_chronyc{centreon::plugins::misc::trim($type)},
                    reach    => centreon::plugins::misc::trim($reach),
                    offset   => centreon::plugins::misc::trim($offset) * $unit_map_chronyc{centreon::plugins::misc::trim($10)},
                };
            } else {
                my ($refid, $stratum, $type, $last_time, $polling_intervall, $reach, $delay, $offset, $jitter) = ($3, $4, $5, $6, $7, $8, $9, $10, $11);
                $entry = {
                    display  => $remote_peer,
                    rawstate => $peer_fate,
                    state    => $state_map_ntpq{$peer_fate},
                    stratum  => centreon::plugins::misc::trim($stratum),
                    rawtype  => centreon::plugins::misc::trim($type),
                    type     => $type_map_ntpq{centreon::plugins::misc::trim($type)},
                    reach    => centreon::plugins::misc::trim($reach),
                    offset   => centreon::plugins::misc::trim($offset)
                };
            }

            next if $self->skip_record(%$entry);

            if ($mode->{type} eq 'ntpq') {
                my ($refid, $stratum, $type, $last_time, $polling_intervall, $reach, $delay, $offset, $jitter) = ($3, $4, $5, $6, $7, $8, $9, $10, $11);
                $self->{peers}->{$remote_peer} = $entry;
            } elsif ($mode->{type} eq 'chronyc') {
                #210 Number of sources = 4
                #MS Name/IP address         Stratum Poll Reach LastRx Last sample               
                #===============================================================================
                #^+ 212.83.187.62                 2   9   377   179   -715us[ -731us] +/-   50ms
                #^- 129.250.35.251                2   8   377    15    -82us[  -99us] +/-   96ms

                $self->{peers}->{$remote_peer} = $entry;
            }
            
            $self->{global}->{peers}++;
        }
    }
}

1;

__END__

=head1 MODE

Check NTP daemons.

Command used: C<timedatectl status ; timedatectl timesync-status ; timedatectl show-timesync> or C<ntpq -p -n> or C<chronyc -n sources>

=over 8

=item B<--ntp-mode>

Default mode for parsing and command: C<auto> (default), C<timedatectl>, C<ntpq>, C<chronyc> or C<all>.
In 'auto' mode the data is taken from the first working mode (in order).
In 'all' mode the data is taken and aggregated from all working mode.

=item B<--filter-name>

Filter peer name (can be a regexp).

=item B<--exclude-name>

Exclude by peer name (can be a regexp).

=item B<--filter-state>

Filter peer state (can be a regexp).

=item B<--exclude-state>

Exclude by peer state (can be a regexp).

=item B<--warning-peers>

Warning threshold minimum amount of NTP-Server

=item B<--critical-peers>

Critical threshold minimum amount of NTP-Server

=item B<--warning-offset>

Warning threshold offset deviation value in milliseconds

=item B<--critical-offset>

Critical threshold offset deviation value in milliseconds

=item B<--warning-stratum>

Warning threshold.

=item B<--critical-stratum>

Critical threshold.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=back

=cut
