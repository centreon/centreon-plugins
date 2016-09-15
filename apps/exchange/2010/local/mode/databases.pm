#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::2010::databases;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "remote-host:s"     => { name => 'remote_host', },
                                  "remote-user:s"     => { name => 'remote_user', },
                                  "remote-password:s" => { name => 'remote_password', },
                                  "no-ps"             => { name => 'no_ps', },
                                  "no-mailflow"       => { name => 'no_mailflow', },
                                  "no-mapi"           => { name => 'no_mapi', },
                                  "no-copystatus"     => { name => 'no_copystatus', },
                                  "timeout:s"         => { name => 'timeout', default => 50 },
                                  "command:s"         => { name => 'command', default => 'powershell.exe' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s"         => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
                                  "ps-exec-only"              => { name => 'ps_exec_only', },
                                  "ps-database-filter:s"      => { name => 'ps_database_filter', },
                                  "ps-database-test-filter:s" => { name => 'ps_database_test_filter', },
                                  "warning-mapi:s"            => { name => 'warning_mapi', },
                                  "critical-mapi:s"           => { name => 'critical_mapi', default => '%{mapi_result} !~ /Success/i' },
                                  "warning-mailflow:s"        => { name => 'warning_mailflow', },
                                  "critical-mailflow:s"       => { name => 'critical_mailflow', default => '%{mailflow_result} !~ /Success/i' },
                                  "warning-copystatus:s"        => { name => 'warning_copystatus', },
                                  "critical-copystatus:s"       => { name => 'critical_copystatus', default => '%{copystatus_indexstate} !~ /Healthy/i' },
                                });
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_mapi', 'critical_mapi', 'warning_mailflow', 'critical_mailflow', 'warning_copystatus', 'critical_copystatus')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{data}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    $self->change_macros();
}

sub run {
    my ($self, %options) = @_;
    
    my $ps = centreon::common::powershell::exchange::2010::databases::get_powershell(remote_host => $self->{option_results}->{remote_host},
                                                                                     remote_user => $self->{option_results}->{remote_user},
                                                                                     remote_password => $self->{option_results}->{remote_password},
                                                                                     no_mailflow => $self->{option_results}->{no_mailflow},
                                                                                     no_ps => $self->{option_results}->{no_ps},
                                                                                     no_mapi => $self->{option_results}->{no_mapi},
                                                                                     no_copystatus => $self->{option_results}->{no_copystatus},
                                                                                     filter_database => $self->{option_results}->{ps_database_filter},
                                                                                     filter_database_test => $self->{option_results}->{ps_database_test_filter});
    $self->{option_results}->{command_options} .= " " . $ps;
    my ($stdout) = centreon::plugins::misc::windows_execute(output => $self->{output},
                                                            timeout => $self->{option_results}->{timeout},
                                                            command => $self->{option_results}->{command},
                                                            command_path => $self->{option_results}->{command_path},
                                                            command_options => $self->{option_results}->{command_options});
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $stdout);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }
    centreon::common::powershell::exchange::2010::databases::check($self, stdout => $stdout);
    
    $self->{output}->display();
    $self->{output}->exit();
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

=item B<--ps-database-filter>

Filter database (only wilcard '*' can be used. In Powershell).

=item B<--ps-database-test-filter>

Skip mapi/mailflow test (regexp can be used. In Powershell).

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