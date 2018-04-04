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

package database::mssql::mode::blockedprocesses;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'processwaittime', type => 1, message_multiple => 'No processes have been waiting for longer than thresholds' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'There are %s blocked processes',
                perfdatas => [
                    { label => 'total_blocked_processes', value => 'total_absolute', template => '%s',
                      unit => '', min => 0 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{processwaittime} = [
        { label => 'processwaittime', set => {
                key_values => [ { name => 'waittime' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_processwaittime_output'),
            }
        },
    ];
}

sub custom_processwaittime_output {
    my ($self, %options) = @_;
    return 'Wait time too long for ' . $self->{instance};
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "filter-program:s" => { name => 'filter_program' },
                                "filter-command:s" => { name => 'filter_command' },
                                });
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $options{sql}->connect();
    $options{sql}->query(query => "SELECT spid, trim(program_name), trim(cmd), trim(status), waittime FROM master.dbo.sysprocesses WHERE blocked <> '0'");
    my $result = $options{sql}->fetchall_arrayref();

    $self->{global} = { total => 0 };
    $self->{processwaittime} = {};

    foreach my $row (@$result) {
        my ($proc_spid, $proc_program_name, $proc_cmd, $proc_status, $proc_waittime) = @$row;
        my $proc_identity_verbose = "spid=".$proc_spid." program_name='".$proc_program_name."' cmd='".$proc_cmd."' status='".$proc_status."'";
        my $proc_identity = 'spid_'.$proc_spid;

        # waittime is given in milliseconds, so we convert it to seconds
        $proc_waittime = $proc_waittime / 1000;

        # we 
        $self->{output}->output_add(long_msg => "Process having " . $proc_identity_verbose . " waited for " . $proc_waittime . "s");

        if (defined($self->{option_results}->{filter_program}) && $self->{option_results}->{filter_program} ne '' &&
            $$row[1] !~ /$self->{option_results}->{filter_program}/) {
            $self->{output}->output_add(long_msg => "Skipping process having " . $proc_identity_verbose . ": because program is not matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
            $$row[2] !~ /$self->{option_results}->{filter_command}/) {
            $self->{output}->output_add(long_msg => "Skipping process having " . $proc_identity_verbose . " because command is not matching filter.", debug => 1);
            next
        }

        # We increment the total number of blocked processes
        $self->{global}->{total} += 1;

        $self->{processwaittime}->{$proc_identity} = { waittime => $proc_waittime, display => $proc_identity_verbose };
    }
}

1;

__END__

=head1 MODE

Checks if some processes are in a blocked state on a MSSQL Server instance.

=over 8

=item B<--filter-program>

Filter results based on the program (client) name  (can be a regexp).

=item B<--filter-command>

Filter results based on the command name (can be a regexp).

=item B<--warning-*>

Set warning threshold for number of user. Can be : 'total', 'processwaittime'

=item B<--critical-*>

Set critical threshold for number of user. Can be : 'total', 'processwaittime'

=back

=cut
