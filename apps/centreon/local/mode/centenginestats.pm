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

package apps::centreon::local::mode::centenginestats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_hosts_execution_time_output {
    my ($self, %options) = @_;

    return sprintf(
        'hosts active execution time (avg/min/max): %.3f/%.3f/%.3f sec',
        $self->{result_values}->{avg},
        $self->{result_values}->{min},
        $self->{result_values}->{max}
    );
}

sub custom_services_execution_time_output {
    my ($self, %options) = @_;

    return sprintf(
        'services active execution time (avg/min/max): %.3f/%.3f/%.3f sec',
        $self->{result_values}->{avg},
        $self->{result_values}->{min},
        $self->{result_values}->{max}
    );
}

sub custom_hosts_checked_output {
    my ($self, %options) = @_;

    return sprintf(
        'hosts active checked last 1/5/15/60 min: %d/%d/%d/%d',
        $self->{result_values}->{last1min},
        $self->{result_values}->{last5min},
        $self->{result_values}->{last15min},
        $self->{result_values}->{last60min},
    );
}

sub custom_services_checked_output {
    my ($self, %options) = @_;

    return sprintf(
        'services active checked last 1/5/15/60 min: %d/%d/%d/%d',
        $self->{result_values}->{last1min},
        $self->{result_values}->{last5min},
        $self->{result_values}->{last15min},
        $self->{result_values}->{last60min},
    );
}

sub custom_hosts_latency_output {
    my ($self, %options) = @_;

    return sprintf(
        'hosts active latency (avg/min/max): %.3f/%.3f/%.3f sec',
        $self->{result_values}->{avg},
        $self->{result_values}->{min},
        $self->{result_values}->{max}
    );
}

sub custom_services_latency_output {
    my ($self, %options) = @_;

    return sprintf(
        'services active latency (avg/min/max): %.3f/%.3f/%.3f sec',
        $self->{result_values}->{avg},
        $self->{result_values}->{min},
        $self->{result_values}->{max}
    );
}

sub custom_hosts_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'hosts status up/down/unreach: %d/%d/%d',
        $self->{result_values}->{up},
        $self->{result_values}->{down},
        $self->{result_values}->{unreach}
    );
}

sub custom_services_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'services status ok/warn/unk/crit: %d/%d/%d/%d',
        $self->{result_values}->{ok},
        $self->{result_values}->{warn},
        $self->{result_values}->{unk},
        $self->{result_values}->{crit}
    );
}

sub custom_commands_buffer_output {
    my ($self, %options) = @_;

    return sprintf(
        'commands buffer current/max: %d/%d',
        $self->{result_values}->{current},
        $self->{result_values}->{max}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'stats', type => 3, indent_long_output => '    ', message_multiple => 'All centengine stats are ok',
            group => [
                { name => 'hosts_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'hosts_active_execution_time', type => 0, skipped_code => { -10 => 1 } },
                { name => 'hosts_active_checked', type => 0, skipped_code => { -10 => 1 } },
                { name => 'hosts_active_latency', type => 0, skipped_code => { -10 => 1 } },
                { name => 'services_active_execution_time', type => 0, skipped_code => { -10 => 1 } },
                { name => 'services_active_checked', type => 0, skipped_code => { -10 => 1 } },
                { name => 'services_active_latency', type => 0, skipped_code => { -10 => 1 } },
                { name => 'services_status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'commands_buffer', type => 0, skipped_code => { -10 => 1 } },
            ],
        },
    ];

    foreach my $type ('hosts', 'services') {

        $self->{maps_counters}->{$type . '_active_execution_time'} = [];
        foreach ((['avg', 'average', 1], ['min', 'minimum', 0], ['max', 'maximum', 0])) {
            push @{$self->{maps_counters}->{$type . '_active_execution_time'}}, 
                {
                    label => $type . '-active-execution-time-' . $_->[1],
                    nlabel => $type . '.active.execution.time.' . $_->[1] . '.seconds',
                    display_ok => $_->[2],
                    set => {
                        key_values => [
                            { name => 'avg' }, { name => 'max' }, { name => 'min' }
                        ],
                        threshold_use => $_->[0] ,
                        closure_custom_output => $self->can('custom_' . $type . '_execution_time_output'),
                        perfdatas => [
                            { value => $_->[0] , template => '%.3f', min => 0, unit => 's' },
                        ],
                    }
                }
            ;
        }

        $self->{maps_counters}->{$type . '_active_checked'} = [];
        foreach ((['last1min', 'last1min', 1], ['last5min', 'last5min', 0], ['last15min', 'last15min', 0], ['last60min', 'last60min', 0])) {
            push @{$self->{maps_counters}->{$type . '_active_checked'}}, 
                {
                    label => $type . '-active-checked-' . $_->[1],
                    nlabel => $type . '.active.checked.' . $_->[1] . '.count',
                    display_ok => $_->[2],
                    set => {
                        key_values => [
                            { name => 'last1min' }, { name => 'last5min' }, { name => 'last15min' }, { name => 'last60min' }
                        ],
                        threshold_use => $_->[0] ,
                        closure_custom_output => $self->can('custom_' . $type . '_checked_output'),
                        perfdatas => [
                            { value => $_->[0] , template => '%d', min => 0 },
                        ],
                    }
                }
            ;
        }

        $self->{maps_counters}->{$type . '_active_latency'} = [];
        foreach ((['avg', 'average', 1], ['min', 'minimum', 0], ['max', 'maximum', 0])) {
            push @{$self->{maps_counters}->{$type . '_active_latency'}}, 
                {
                    label => $type . '-active-latency-' . $_->[1],
                    nlabel => $type . '.active.latency.' . $_->[1] . '.seconds',
                    display_ok => $_->[2],
                    set => {
                        key_values => [
                            { name => 'avg' }, { name => 'max' }, { name => 'min' }
                        ],
                        threshold_use => $_->[0] ,
                        closure_custom_output => $self->can('custom_' . $type . '_latency_output'),
                        perfdatas => [
                            { value => $_->[0] , template => '%.3f', min => 0, unit => 's' },
                        ],
                    }
                }
            ;
        }
    }

    $self->{maps_counters}->{hosts_status} = [];
    foreach ((['up', 'up', 1], ['down', 'down', 0], ['unreach', 'unreachable', 0])) {
        push @{$self->{maps_counters}->{hosts_status}}, 
            {
                label => 'hosts-status-' . $_->[1],
                nlabel => 'hosts.status.' . $_->[1] . '.count',
                display_ok => $_->[2],
                set => {
                    key_values => [
                        { name => 'up' }, { name => 'down' }, { name => 'unreach' }
                    ],
                    threshold_use => $_->[0] ,
                    closure_custom_output => $self->can('custom_hosts_status_output'),
                    perfdatas => [
                        { value => $_->[0] , template => '%s', min => 0, max => 'total' },
                    ],
                }
            }
        ;
    }

    $self->{maps_counters}->{services_status} = [];
    foreach ((['ok', 'ok', 1], ['warn', 'warning', 0], ['crit', 'critical', 0], ['unk', 'unknown', 0])) {
        push @{$self->{maps_counters}->{services_status}}, 
            {
                label => 'services-status-' . $_->[1],
                nlabel => 'services.status.' . $_->[1] . '.count',
                display_ok => $_->[2],
                set => {
                    key_values => [
                        { name => 'ok' }, { name => 'warn' }, { name => 'unk' }, { name => 'crit' }, { name => 'total' }
                    ],
                    threshold_use => $_->[0] ,
                    closure_custom_output => $self->can('custom_services_status_output'),
                    perfdatas => [
                        { value => $_->[0] , template => '%s', min => 0, max => 'total' },
                    ],
                }
            }
        ;
    }

    $self->{maps_counters}->{commands_buffer} = [];
    foreach ((['current', 'current', 1], ['max', 'maximum', 0])) {
        push @{$self->{maps_counters}->{commands_buffer}}, 
            {
                label => 'commands-buffer-' . $_->[1],
                nlabel => 'commands.buffer.' . $_->[1] . '.count',
                display_ok => $_->[2],
                set => {
                    key_values => [
                        { name => 'current' }, { name => 'max' }, { name => 'total' }
                    ],
                    threshold_use => $_->[0] ,
                    closure_custom_output => $self->can('custom_commands_buffer_output'),
                    perfdatas => [
                        { value => $_->[0] , template => '%s', min => 0, max => 'total' },
                    ],
                }
            }
        ;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'command:s'         => { name => 'command', default => 'centenginestats' },
        'command-path:s'    => { name => 'command_path', default => '/usr/sbin' },
        'command-options:s' => { name => 'command_options', default => '2>&1' },
        'hostname:s'        => { name => 'hostname' },
        'remote'            => { name => 'remote' },
        'ssh-option:s@'     => { name => 'ssh_option' },
        'ssh-path:s'        => { name => 'ssh_path' },
        'ssh-command:s'     => { name => 'ssh_command', default => 'ssh' },
        'timeout:s'         => { name => 'timeout', default => 30 },
        'sudo'              => { name => 'sudo' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );

    $self->{stats} = {};

    if ($stdout =~ /^Active\s+Host\s+Execution\s+Time\s*:\s*(\S+)\s*\/\s*(\S+)\s*\/\s*(\S+)/mi) {
        $self->{stats}->{0} = { hosts_active_execution_time => { min => $1, max => $2, avg => $3 } };
    }
    if ($stdout =~ /^Active\s+Hosts\s+Last\s+1\/5\/15\/60\s+min:\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)/mi) {
        $self->{stats}->{1} = { hosts_active_checked => { last1min => $1, last5min => $2, last15min => $3, last60min => $4 } };
    }
    if ($stdout =~ /^Active\s+Host\s+Latency\s*:\s*(\S+)\s*\/\s*(\S+)\s*\/\s*(\S+)/mi) {
        $self->{stats}->{2} = { hosts_active_latency => { min => $1, max => $2, avg => $3 } };
    }
    if ($stdout =~ /^Hosts\s+Up\/Down\/Unreach\s*:\s*(\S+)\s*\/\s*(\S+)\s*\/\s*(\S+)/mi) {
        $self->{stats}->{3} = { hosts_status => { up => $1, down => $2, unreach => $3 } };
        $self->{stats}->{3}->{hosts_status}->{total} = $1 if ($stdout =~ /^Total\s+Hosts\s*:\s*(\d+)/mi);
    }

    if ($stdout =~ /^Active\s+Service\s+Execution\s+Time\s*:\s*(\S+)\s*\/\s*(\S+)\s*\/\s*(\S+)/mi) {
        $self->{stats}->{5} = { services_active_execution_time => { min => $1, max => $2, avg => $3 } };
    }
    if ($stdout =~ /^Active\s+Services\s+Last\s+1\/5\/15\/60\s+min:\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)/mi) {
        $self->{stats}->{6} = { services_active_checked => { last1min => $1, last5min => $2, last15min => $3, last60min => $4 } };
    }
    if ($stdout =~ /^Active\s+Service\s+Latency\s*:\s*(\S+)\s*\/\s*(\S+)\s*\/\s*(\S+)/mi) {
        $self->{stats}->{7} = { services_active_latency => { min => $1, max => $2, avg => $3 } };
    }
    if ($stdout =~ /^Services\s+Ok\/Warn\/Unk\/Crit\s*:\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)/mi) {
        $self->{stats}->{8} = { services_status => { ok => $1, warn => $2, unk => $3, crit => $4 } };
        $self->{stats}->{8}->{services_status}->{total} = $1 if ($stdout =~ /^Total\s+Services\s*:\s*(\d+)/mi);
    }

    if ($stdout =~ /^Used\/High\/Total\s+Command\s+Buffers\s*:\s*(\d+)\s*\/\s*(\d+)\s*\/\s*(\d+)/mi) {
        $self->{stats}->{9} = { commands_buffer => { current => $1, max => $2, total => $3 } };
    }
}

1;

__END__

=head1 MODE

Check centengine statistics.

=over 8

=item B<--command>

Command to get information (Default: 'centenginestats').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: '2>&1').

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

=item B<--warning-*> B<--critical-*>

Thresholds. please use --list-counters to display.

=back

=cut
