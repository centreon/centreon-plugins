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

package database::mssql::mode::blockedprocesses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX qw/floor/;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'processes', type => 1 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'blocked-processes', set => {
                key_values => [ { name => 'blocked_processes' } ],
                output_template => 'Number of blocked processes : %s',
                perfdatas => [
                    { label => 'blocked_processes', value => 'blocked_processes', template => '%s',
                      unit => '', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{processes} = [
        { label => 'wait-time', set => {
                key_values => [ { name => 'spid' }, { name => 'blocked' }, { name => 'status' },
                    { name => 'waittime' }, { name => 'program' }, { name => 'cmd' } ],
                closure_custom_calc => $self->can('custom_processes_calc'),
                closure_custom_output => $self->can('custom_processes_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_processes_threshold'),
            }
        },
    ];
}

sub custom_processes_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{waittime},
                                                  threshold => [ { label => 'critical-wait-time', exit_litteral => 'critical' },
                                                                 { label => 'warning-wait-time', exit_litteral => 'warning' } ]);
    
    return $exit;
}

sub custom_processes_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Process ID '%s' is blocked by process ID '%s' for %s [status: %s] [program: %s] [command: %s]",
        $self->{result_values}->{spid},
        $self->{result_values}->{blocked},
        ($self->{result_values}->{waittime} > 0) ? centreon::plugins::misc::change_seconds(value => $self->{result_values}->{waittime}) : "0s",
        $self->{result_values}->{status},
        $self->{result_values}->{program},
        $self->{result_values}->{cmd});

    return $msg;
}

sub custom_processes_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{spid} = $options{new_datas}->{$self->{instance} . '_spid'};
    $self->{result_values}->{blocked} = $options{new_datas}->{$self->{instance} . '_blocked'};
    $self->{result_values}->{waittime} = (defined($options{new_datas}->{$self->{instance} . '_waittime'}) &&
        $options{new_datas}->{$self->{instance} . '_waittime'} ne '') ?
            floor($options{new_datas}->{$self->{instance} . '_waittime'} / 1000) : '0';
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{program} = $options{new_datas}->{$self->{instance} . '_program'};
    $self->{result_values}->{cmd} = $options{new_datas}->{$self->{instance} . '_cmd'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "filter-status:s" => { name => 'filter_status' },
                                    "filter-program:s" => { name => 'filter_program' },
                                    "filter-command:s" => { name => 'filter_command' },
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => q{SELECT spid, blocked, waittime, status, program_name, cmd FROM master.dbo.sysprocesses WHERE blocked <> '0'});

    $self->{global} = { blocked_processes => 0 };
    $self->{processes} = {};

    while (my $row = $options{sql}->fetchrow_hashref()) {
        my $status = centreon::plugins::misc::trim($row->{status});
        my $program = centreon::plugins::misc::trim($row->{program_name});
        my $cmd = centreon::plugins::misc::trim($row->{cmd});

        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $status !~ /$self->{option_results}->{filter_status}/) {
            $self->{output}->output_add(debug => 1, long_msg => "Skipping process " . $row->{spid} . ": because status is not matching filter.");
            next;
        }
        if (defined($self->{option_results}->{filter_program}) && $self->{option_results}->{filter_program} ne '' &&
            $program !~ /$self->{option_results}->{filter_program}/) {
            $self->{output}->output_add(debug => 1, long_msg => "Skipping process " . $row->{spid} . ": because program is not matching filter.");
            next;
        }
        if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
            $cmd !~ /$self->{option_results}->{filter_command}/) {
            $self->{output}->output_add(debug => 1, long_msg => "Skipping process " . $row->{spid} . ": because command is not matching filter.");
            next
        }

        $self->{processes}->{$row->{spid}} = {
            waittime => $row->{waittime},
            spid => $row->{spid},
            blocked => $row->{blocked},
            status => $status,
            program => $program,
            cmd => $cmd,
        };

        $self->{global}->{blocked_processes}++;
    }
}

1;

__END__

=head1 MODE

Checks if some processes are in a blocked state.

=over 8

=item B<--filter-status>

Filter results based on the status (can be a regexp).

=item B<--filter-program>

Filter results based on the program (client) name  (can be a regexp).

=item B<--filter-command>

Filter results based on the command name (can be a regexp).

=item B<--warning-blocked-processes>

Threshold warning for total number of blocked processes.

=item B<--critical-blocked-processes>

Threshold critical for total number of blocked processes.

=item B<--warning-wait-time>

Threshold warning for blocked wait time.

=item B<--critical-wait-time>

Threshold critical for blocked wait time.

=back

=cut
