#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::exchange::2010::local::mode::databases;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::common::powershell::exchange::2010::databases;
use apps::exchange::2010::local::mode::resources::types qw($copystatus_contentindexstate);
use JSON::XS;

sub custom_mailflow_latency_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 's',
        instances => [$self->{result_values}->{server}, $self->{result_values}->{database}],
        value => sprintf('%.3f', $self->{result_values}->{mailflow_latency}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_space_size_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{server}, $self->{result_values}->{database}],
        value => $self->{result_values}->{size},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_space_available_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'B',
        instances => [$self->{result_values}->{server}, $self->{result_values}->{database}],
        value => $self->{result_values}->{asize},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel})
    );
}

sub custom_mapi_output {
    my ($self, %options) = @_;

    return 'mapi test connectivity is ' . $self->{result_values}->{mapi_result};
}

sub custom_mailflow_output {
    my ($self, %options) = @_;

    return 'mapi test result is ' . $self->{result_values}->{mailflow_result};
}

sub custom_copystatus_output {
    my ($self, %options) = @_;

    return sprintf(
        "copystatus state is %s [error: %s]",
        $self->{result_values}->{copystatus_indexstate},
        $self->{result_values}->{copystatus_content_index_error_message}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        '%s mounted',
        $self->{result_values}->{mounted} == 0 ? 'not' : 'is'
    );
}

sub database_long_output {
    my ($self, %options) = @_;

    return "checking database '" . $options{instance_value}->{database} . "' server '" . $options{instance_value}->{server} . "'";
}

sub prefix_database_output {
    my ($self, %options) = @_;

    return "Database '" . $options{instance_value}->{database} . "' server '" . $options{instance_value}->{server} . "'";
}

sub prefix_mailflow_output {
    my ($self, %options) = @_;

    return 'mailflow ';
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Databases ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output',  skipped_code => { -10 => 1 } },
        { name => 'databases', type => 3, cb_prefix_output => 'prefix_database_output', cb_long_output => 'database_long_output', indent_long_output => '    ', message_multiple => 'All databases are ok',
            group => [
                { name => 'db_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'space', type => 0, skipped_code => { -10 => 1 } },
                { name => 'mapi', type => 0, skipped_code => { -10 => 1 } },
                { name => 'mailflow', type => 0, cb_prefix_output => 'prefix_mailflow_output', skipped_code => { -10 => 1 } },
                { name => 'copystatus', type => 0, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'databases-space-size', nlabel => 'databases.space.size.bytes', set => {
                key_values => [ { name => 'size' } ],
                output_template => 'space size: %s %s',
                output_change_bytes => 1,
                 perfdatas => [
                    { template => '%d', unit => 'B', min => 0 }
                ]
            }
        },
        { label => 'databases-space-available', nlabel => 'databases.space.available.bytes', set => {
                key_values => [ { name => 'asize' } ],
                output_template => 'space available: %s %s',
                output_change_bytes => 1,
                 perfdatas => [
                    { template => '%d', unit => 'B', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{db_global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{mounted} == 0',
            set => {
                key_values => [
                    { name => 'mounted' }, { name => 'database' }, { name => 'server' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{space} = [
        { label => 'database-space-size', nlabel => 'database.space.size.bytes', set => {
                key_values => [ { name => 'size' }, { name => 'database' }, { name => 'server' } ],
                output_template => 'space size: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_space_size_perfdata')
            }
        },
        { label => 'database-space-available', nlabel => 'database.space.available.bytes', set => {
                key_values => [ { name => 'asize' }, { name => 'database' }, { name => 'server' } ],
                output_template => 'space available: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => $self->can('custom_space_asize_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{mapi} = [
        {
            label => 'mapi',
            type => 2,
            critical_default => '%{mapi_result} !~ /Success/i',
            set => {
                key_values => [
                    { name => 'mapi_result' }, { name => 'database' }, { name => 'server' }
                ],
                closure_custom_output => $self->can('custom_mapi_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{mailflow} = [
        {
            label => 'mailflow',
            type => 2,
            critical_default => '%{mailflow_result} !~ /Success/i',
            set => {
                key_values => [
                    { name => 'mailflow_result' }, { name => 'database' }, { name => 'server' }
                ],
                closure_custom_output => $self->can('custom_mailflow_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'mailflow-latency', nlabel => 'database.mailflow.latency.seconds', display_ok => 0, set => {
                key_values => [ { name => 'mailflow_latency' }, { name => 'database' }, { name => 'server' } ],
                output_template => 'latency: %.3f %%',
                closure_custom_perfdata => $self->can('custom_mailflow_latency_perfdata')
            }
        }
    ];

    $self->{maps_counters}->{copystatus} = [
        {
            label => 'copystatus',
            type => 2,
            critical_default => '%{copystatus_indexstate} !~ /Healthy/i',
            set => {
                key_values => [
                    { name => 'copystatus_indexstate' }, { name => 'copystatus_content_index_error_message' },
                    { name => 'database' }, { name => 'server' }
                ],
                closure_custom_output => $self->can('custom_copystatus_output'),
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
        'remote-host:s'     => { name => 'remote_host' },
        'remote-user:s'     => { name => 'remote_user' },
        'remote-password:s' => { name => 'remote_password' },
        'no-ps'             => { name => 'no_ps' },
        'no-mailflow'       => { name => 'no_mailflow' },
        'no-mapi'           => { name => 'no_mapi' },
        'no-copystatus'     => { name => 'no_copystatus' },
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'ps-database-filter:s'      => { name => 'ps_database_filter' },
        'ps-database-test-filter:s' => { name => 'ps_database_test_filter' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::exchange::2010::databases::get_powershell(
            remote_host => $self->{option_results}->{remote_host},
            remote_user => $self->{option_results}->{remote_user},
            remote_password => $self->{option_results}->{remote_password},
            no_mailflow => $self->{option_results}->{no_mailflow},
            no_mapi => $self->{option_results}->{no_mapi},
            no_copystatus => $self->{option_results}->{no_copystatus},
            filter_database => $self->{option_results}->{ps_database_filter},
            filter_database_test => $self->{option_results}->{ps_database_test_filter}
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

    my ($stdout) = centreon::plugins::misc::windows_execute(
        output => $self->{output},
        timeout => $self->{option_results}->{timeout},
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

    $self->{global} = { size => 0, asize => 0 };
    $self->{databases} = {};
    foreach my $db (@$decoded) {
        $db->{mounted} = $db->{mounted} =~ /True|1/i ? 1 : 0;
        $db->{copystatus_indexstate} = $copystatus_contentindexstate->{ $db->{copystatus_indexstate} }
            if (defined($db->{copystatus_indexstate}));

        $self->{databases}->{ $db->{database} . ':' . $db->{server} } = {
            database => $db->{database},
            server => $db->{server},
            db_global => $db,
            space => $db,
            mapi => $db,
            mailflow => $db,
            copystatus => $db
        };
        $self->{global}->{size} += $db->{size};
        $self->{global}->{asize} += $db->{asize};
    }
}

1;

__END__

=head1 MODE

Check: Exchange Databases are Mounted, Mapi/Mailflow Connectivity to all databases are working and CopyStatus.

=over 8

=item B<--remote-host>

Open a session to the remote-host (fully qualified host name). --remote-user and --remote-password are optional

=item B<--remote-user>

Open a session to the remote-host with authentication. This also needs --remote-host and --remote-password.

=item B<--remote-password>

Open a session to the remote-host with authentication. This also needs --remote-user and --remote-host.

=item B<--no-mailflow>

Don't check mailflow connectivity.

=item B<--no-mapi>

Don't check mapi connectivity.

=item B<--no-copystatus>

Don't check copy status.

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

=item B<--ps-database-filter>

Filter database (only wilcard '*' can be used. In Powershell).

=item B<--ps-database-test-filter>

Skip mapi/mailflow test (regexp can be used. In Powershell).

=item B<--warning-status>

Set warning threshold.
Can used special variables like: %{mounted}, %{database}, %{server}

=item B<--critical-status>

Set critical threshold (Default: '%{mounted} == 0').
Can used special variables like: %{mounted}, %{database}, %{server}

=item B<--warning-mapi>

Set warning threshold.
Can used special variables like: %{mapi_result}, %{database}, %{server}

=item B<--critical-mapi>

Set critical threshold (Default: '%{mapi_result} !~ /Success/i').
Can used special variables like: %{mapi_result}, %{database}, %{server}

=item B<--warning-mailflow>

Set warning threshold.
Can used special variables like: %{mailflow_result}, %{database}, %{server}

=item B<--critical-mailflow>

Set critical threshold (Default: '%{mailflow_result} !~ /Success/i').
Can used special variables like: %{mailflow_result}, %{database}, %{server}

=item B<--warning-copystatus>

Set warning threshold.
Can used special variables like: %{mailflow_result}, %{database}, %{server}

=item B<--critical-copystatus>

Set critical threshold (Default: '%{contentindexstate} !~ /Healthy/i').
Can used special variables like: %{copystatus_indexstate}, %{database}, %{server}

=back

=cut
