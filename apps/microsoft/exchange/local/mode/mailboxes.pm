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

package apps::microsoft::exchange::local::mode::mailboxes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::mailboxes;
use JSON::XS;

sub prefix_users_output {
    my ($self, %options) = @_;

    return 'Users mailbox ';
}

sub prefix_folders_output {
    my ($self, %options) = @_;

    return 'Public folders mailbox ';
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'users', type => 0, cb_prefix_output => 'prefix_users_output',  skipped_code => { -10 => 1 } },
        { name => 'publicfolders', type => 0, cb_prefix_output => 'prefix_folders_output',  skipped_code => { -10 => 1 } },
        { name => 'databases', type => 1, cb_prefix_output => 'prefix_database_output', message_multiple => 'All databases are ok' }
    ];

    foreach (('users', 'publicfolders')) {
        $self->{maps_counters}->{$_} = [
            { label => $_ . '-soft-limit', nlabel => 'mailboxes.' . $_ . '.soft.limit.count', set => {
                    key_values => [ { name => 'soft_limit' } ],
                    output_template => 'over soft limit: %s',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            },
            { label => $_ . '-hard-limit', nlabel => 'mailboxes.' . $_ . '.hard.limit.count', set => {
                    key_values => [ { name => 'hard_limit' } ],
                    output_template => 'over hard limit: %s',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            },
            { label => $_ . '-quota-unlimited', nlabel => 'mailboxes.' . $_ . '.quota.unlimited.count', set => {
                    key_values => [ { name => 'unlimited' } ],
                    output_template => 'unlimited quota: %s',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            },
            { label => $_ . '-total', nlabel => 'mailboxes.' . $_ . '.total.count', set => {
                    key_values => [ { name => 'total' } ],
                    output_template => 'total: %s',
                    perfdatas => [
                        { template => '%d', min => 0 }
                    ]
                }
            }
        ];
    }

    $self->{maps_counters}->{databases} = [
        { label => 'database-mailboxes-total', nlabel => 'database.mailboxes.total.count', set => {
                key_values => [ { name => 'mailboxes' } ],
                output_template => 'total mailboxes: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
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
        'remote-host:s'     => { name => 'remote_host' },
        'remote-user:s'     => { name => 'remote_user' },
        'remote-password:s' => { name => 'remote_password' },
        'no-ps'             => { name => 'no_ps' },
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'ps-server:s'         => { name => 'ps_server' },
        'ps-database:s'       => { name => 'ps_database' },
        'ps-match-database:s' => { name => 'ps_match_database' },
        'ps-match-server:s'   => { name => 'ps_match_server' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::exchange::mailboxes::get_powershell(
            remote_host => $self->{option_results}->{remote_host},
            remote_user => $self->{option_results}->{remote_user},
            remote_password => $self->{option_results}->{remote_password},
            ps_server => $self->{option_results}->{ps_server},
            ps_database => $self->{option_results}->{ps_database},
            ps_match_database => $self->{option_results}->{ps_match_database},
            ps_match_server => $self->{option_results}->{ps_match_server}
        );
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => { timeout => $self->{option_results}->{timeout} },
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->{users} = {
        total => $decoded->{users}->{total},
        soft_limit => $decoded->{users}->{warning_quota},
        hard_limit => $decoded->{users}->{over_quota},
        unlimited => $decoded->{users}->{unlimited}
    };
    $self->{publicfolders} = {
        total => $decoded->{public_folders}->{total},
        soft_limit => $decoded->{public_folders}->{warning_quota},
        hard_limit => $decoded->{public_folders}->{over_quota},
        unlimited => $decoded->{public_folders}->{unlimited}
    };

    $self->{databases} = {};
    foreach my $name (keys %{$decoded->{group_by_databases}}) {
        $self->{databases}->{$name} = {
            name => $name,
            mailboxes => $decoded->{group_by_databases}->{$name}
        };
    }
}

1;

__END__

=head1 MODE

Check mailboxes (quota and user mailboxes by database).

=over 8

=item B<--remote-host>

Open a session to the remote-host (fully qualified host name). --remote-user and --remote-password are optional

=item B<--remote-user>

Open a session to the remote-host with authentication. This also needs --remote-host and --remote-password.

=item B<--remote-password>

Open a session to the remote-host with authentication. This also needs --remote-user and --remote-host.

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-exec-only>

Print powershell output.

=item B<--ps-display>

Display powershell script.

=item B<--ps-match-server>

Filter mailboxes by server name (regexp can be used. In Powershell).

=item B<--ps-match-database>

Filter mailboxes by database name (regexp can be used. In Powershell).

=item B<--ps-server>

Select mailboxes by an uniq server name (In Powershell).

=item B<--ps-database>

Select mailboxes by an uniq database name (In Powershell).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'users-soft-limit', 'users-hard-limit', 'users-quota-unlimited', 'users-total',
'publicfolders-soft-limit', 'publicfolders-hard-limit', 'publicfolders-quota-unlimited', 'publicfolders-total'
'database-mailboxes-total'.

=back

=cut
