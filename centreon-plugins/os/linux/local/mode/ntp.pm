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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

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

    my $msg = sprintf("[type: %s] [reach: %s] [state: %s]",
        $self->{result_values}->{type},
        $self->{result_values}->{reach},
        $self->{result_values}->{state}
    );
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{rawtype} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{rawstate} = $options{new_datas}->{$self->{instance} . '_state'};
    if ($self->{instance_mode}->{option_results}->{command} eq 'ntpq') {
        $self->{result_values}->{type} = $type_map_ntpq{$options{new_datas}->{$self->{instance} . '_type'}};
    } else {
        $self->{result_values}->{type} = $type_map_chronyc{$options{new_datas}->{$self->{instance} . '_type'}};
    }
    $self->{result_values}->{reach} = $options{new_datas}->{$self->{instance} . '_reach'};
    if ($self->{instance_mode}->{option_results}->{command} eq 'ntpq') {
        $self->{result_values}->{state} = $state_map_ntpq{$options{new_datas}->{$self->{instance} . '_state'}};
    } else {
        $self->{result_values}->{state} = $state_map_chronyc{$options{new_datas}->{$self->{instance} . '_state'}};
    }
    return 0;
}

sub custom_offset_perfdata {
    my ($self, %options) = @_;

    if ($self->{result_values}->{state} ne '*') {
        $self->{output}->perfdata_add(
            label => 'offset', unit => 'ms',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
            value => $self->{result_values}->{offset},
            min => 0
        );
    } else {
        $self->{output}->perfdata_add(
            label => 'offset', unit => 'ms',
            instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'peers', type => 1, cb_prefix_output => 'prefix_peer_output', message_multiple => 'All peers are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'peers', set => {
                key_values => [ { name => 'peers' } ],
                output_template => 'Number of ntp peers : %d',
                perfdatas => [
                    { label => 'peers', value => 'peers', template => '%d',
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{peers} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'type' }, { name => 'reach' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'offset', display_ok => 0, set => {
                key_values => [ { name => 'offset' }, { name => 'state' }, { name => 'display' } ],
                output_template => 'Offset : %s ms',
                closure_custom_threshold_check => $self->can('custom_offset_threshold'),
                closure_custom_perfdata => $self->can('custom_offset_perfdata'),
                perfdatas => [
                    { label => 'offset', value => 'offset', template => '%s',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'stratum', display_ok => 0, set => {
                key_values => [ { name => 'stratum' }, { name => 'display' } ],
                output_template => 'Stratum : %s',
                perfdatas => [
                    { label => 'stratum', value => 'stratum', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_peer_output {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname' },
        "remote"            => { name => 'remote' },
        "ssh-option:s@"     => { name => 'ssh_option' },
        "ssh-path:s"        => { name => 'ssh_path' },
        "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"         => { name => 'timeout', default => 30 },
        "sudo"              => { name => 'sudo' },
        "command:s"         => { name => 'command', default => 'ntpq' },
        "command-path:s"    => { name => 'command_path' },
        "command-options:s" => { name => 'command_options', default => '' },
        "filter-name:s"     => { name => 'filter_name' },
        "filter-state:s"    => { name => 'filter_state' },
        "unknown-status:s"  => { name => 'unknown_status', default => '' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{command} eq 'ntpq') {
        $self->{regex} = '^(\+|\*|\.|\-|\#|x|\<sp\>|o)(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)';
        $self->{option_results}->{command_options} = '-p -n 2>&1';
    } elsif ($self->{option_results}->{command} eq 'chronyc') {
        $self->{regex} = '^(.)(\+|\*|\.|\-|\#|x|\<sp\>)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.*?)(\d+)(\w+)$';
        $self->{option_results}->{command_options} = '-n sources 2>&1';
    } else {
        $self->{output}->add_option_msg(short_msg => "command '" . $self->{option_results}->{command} . "' not implemented" );
        $self->{output}->option_exit();
    }
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $stdout = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
    );
    
    $self->{global} = { peers => 0 };
    $self->{peers} = {};

    my @lines = split /\n/, $stdout;
    foreach my $line (@lines) {
        if ($line =~ /Connection refused/) {
            $self->{output}->add_option_msg(short_msg => "check ntp.conf and ntp daemon" );
            $self->{output}->option_exit();
        }
        next if ($line !~ /$self->{regex}/);
        
        my ($remote_peer, $peer_fate) = (centreon::plugins::misc::trim($2), centreon::plugins::misc::trim($1));
        if ($self->{option_results}->{command} eq 'chronyc') {
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
        
        if ($self->{option_results}->{command} eq 'ntpq') {
            my ($refid, $stratum, $type, $last_time, $polling_intervall, $reach, $delay, $offset, $jitter) = ($3, $4, $5, $6, $7, $8, $9, $10, $11);
            $self->{peers}->{$remote_peer} = {
                display => $remote_peer,
                state   => $peer_fate,
                stratum => centreon::plugins::misc::trim($stratum),
                type    => centreon::plugins::misc::trim($type),
                reach   => centreon::plugins::misc::trim($reach),
                offset  => centreon::plugins::misc::trim($offset)
            };
        } elsif ($self->{option_results}->{command} eq 'chronyc') {
            #210 Number of sources = 4
            #MS Name/IP address         Stratum Poll Reach LastRx Last sample               
            #===============================================================================
            #^+ 212.83.187.62                 2   9   377   179   -715us[ -731us] +/-   50ms
            #^- 129.250.35.251                2   8   377    15    -82us[  -99us] +/-   96ms

            my ($type, $stratum, $poll, $reach, $lastRX, $offset) = ($1, $4, $5, $6, $7, $9);
            $self->{peers}->{$remote_peer} = {
                display     => $remote_peer,
                state       => $peer_fate,
                stratum     => centreon::plugins::misc::trim($stratum),
                type        => centreon::plugins::misc::trim($type),
                reach       => centreon::plugins::misc::trim($reach),
                offset      => centreon::plugins::misc::trim($offset) * $unit_map_chronyc{centreon::plugins::misc::trim($10)},
            };
        }
        
        $self->{global}->{peers}++;
    }
}

1;

__END__

=head1 MODE

Check ntp daemons.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'ntpq').
Can also be 'chronyc'.

=item B<--command-path>

Command path (Default: none).

=item B<--filter-name>

Filter peer name (can be a regexp).

=item B<--filter-name>

Filter peer state (can be a regexp).

=item B<--warning-peers>

Threshold warning minimum Amount of NTP-Server

=item B<--critical-peers>

Threshold critical minimum Amount of NTP-Server

=item B<--warning-offset>

Threshold warning Offset deviation value in milliseconds

=item B<--critical-offset>

Threshold critical Offset deviation value in milliseconds

=item B<--warning-stratum>

Threshold warning.

=item B<--critical-stratum>

Threshold critical.

=item B<--unknown-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{state}, %{rawstate}, %{type}, %{rawtype}, %{reach}, %{display}

=back

=cut
