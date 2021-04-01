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

package apps::microsoft::wsus::local::mode::updatesstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use JSON::XS;
use centreon::plugins::misc;
use centreon::common::powershell::wsus::updatesstatus;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'with-client-errors', set => {
                key_values => [ { name => 'UpdatesWithClientErrorsCount' } ],
                output_template => 'With Client Errors: %d',
                perfdatas => [
                    { label => 'updates_with_client_errors', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'with-server-errors', set => {
                key_values => [ { name => 'UpdatesWithServerErrorsCount' } ],
                output_template => 'With Server Errors: %d',
                perfdatas => [
                    { label => 'updates_with_server_errors', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'needing-files', set => {
                key_values => [ { name => 'UpdatesNeedingFilesCount' } ],
                output_template => 'Needing Files: %d',
                perfdatas => [
                    { label => 'updates_needing_files_count', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'needed-by-computers', set => {
                key_values => [ { name => 'UpdatesNeededByComputersCount' } ],
                output_template => 'Needed By Computers: %d',
                perfdatas => [
                    { label => 'updates_needed_by_computers', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'up-to-date', set => {
                key_values => [ { name => 'UpdatesUpToDateCount' } ],
                output_template => 'Up-to-date: %s',
                perfdatas => [
                    { label => 'updates_up_to_date', template => '%d', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Updates ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'         => { name => 'timeout', default => 30 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'wsus-server:s'     => { name => 'wsus_server', default => 'localhost' },
        'wsus-port:s'       => { name => 'wsus_port', default => 8530 },
        'use-ssl'           => { name => 'use_ssl' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $use_ssl = "\$false";
    $use_ssl = "\$true" if (defined($self->{option_results}->{use_ssl}));

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::wsus::updatesstatus::get_powershell(
            wsus_server => $self->{option_results}->{wsus_server},
            wsus_port => $self->{option_results}->{wsus_port},
            use_ssl => $use_ssl
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
        options => $self->{option_results},
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
        $decoded = JSON::XS->new->utf8->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    $self->{global} = { %$decoded };
}

1;

__END__

=head1 MODE

Check updates status.

=over 8

=item B<--timeout>

Set timeout time for command execution (Default: 30 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--wsus-server>

Set WSUS hostname/IP (Dafault: localhost).

=item B<--wsus-port>

Set WSUS port (Default: 8530).

=item B<--use-ssl>

Set if WSUS use ssl.

=item B<--warning-*>

Warning thresholds.
Can be: 'with-client-errors', 'with-server-errors',
'needing-files', 'needed-by-computers', 'up-to-date'.

=item B<--critical-*>

Critical thresholds.
Can be: 'with-client-errors', 'with-server-errors',
'needing-files', 'needed-by-computers', 'up-to-date'.

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='errors'

=back

=cut
