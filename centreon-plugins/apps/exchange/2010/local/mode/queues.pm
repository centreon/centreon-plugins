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

package apps::exchange::2010::local::mode::queues;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::common::powershell::exchange::2010::queues;
use apps::exchange::2010::local::mode::resources::types qw($queue_status $queue_delivery_type);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [last error: %s] [delivery type: %s] [identity: %s] [message count: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{last_error},
        $self->{result_values}->{delivery_type},
        $self->{result_values}->{identity},
        $self->{result_values}->{message_count}
    );
}

sub prefix_queue_output {
    my ($self, %options) = @_;

    return "Queue '" . $options{instance_value}->{nexthopdomain} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'queues', type => 1, cb_prefix_output => 'prefix_queue_output', message_multiple => 'All queues are ok', skipped_code => { -11 => 1 } }
    ];

    $self->{maps_counters}->{queues} = [
         { label => 'status', type => 2, critical_default => '%{status} !~ /Ready|Active/i', set => {
                key_values => [
                    { name => 'nexthopdomain' }, { name => 'identity' },
                    { name => 'is_valid' }, { name => 'isvalid' },
                    { name => 'delivery_type' }, { name => 'deliverytype' },
                    { name => 'message_count' }, { name => 'messagecount' },
                    { name => 'status' }, { name => 'last_error' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
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
        'ps-display'        => { name => 'ps_display' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::exchange::2010::queues::get_powershell(
            remote_host => $self->{option_results}->{remote_host},
            remote_user => $self->{option_results}->{remote_user},
            remote_password => $self->{option_results}->{remote_password}
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

    my $perfdatas_queues = {};

    $self->{queues} = {};
    foreach my $queue (@$decoded) {
        $queue->{is_valid} = $queue->{is_valid} =~ /True|1/i ? 1 : 0;
        $queue->{status} = $queue_status->{ $queue->{status} }
            if (defined($queue->{status}));
        $queue->{delivery_type} = $queue_delivery_type->{ $queue->{delivery_type} }
            if (defined($queue->{delivery_type}));

        $self->{queues}->{ $queue->{identity} } = {
            %$queue,
            deliverytype => $queue->{delivery_type},
            isvalid => $queue->{is_valid},
            messagecount => $queue->{message_count}
        };

        if ($queue->{message_count} =~ /^(\d+)/) {
            my $num = $1;
            my $identity = $queue->{identity};

            $identity = $1 if ($queue->{identity} =~ /^(.*\/)[0-9]+$/);
            $perfdatas_queues->{$identity} = 0 if (!defined($perfdatas_queues->{$identity})); 
            $perfdatas_queues->{$identity} += $num;
        }
    }

    foreach (keys %$perfdatas_queues) {
        $self->{output}->perfdata_add(
            nlabel => 'queue.length.count',
            instances => $_,
            value => $perfdatas_queues->{$_},
            min => 0
        );
    }
}

1;

__END__

=head1 MODE

Check queues status.

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

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--warning-status>

Set warning threshold.
Can used special variables like: %{status}, %{identity}, %{is_valid}, %{delivery_type}, %{message_count}

=item B<--critical-status>

Set critical threshold (Default: '%{status} !~ /Ready|Active/i').
Can used special variables like: %{status}, %{identity}, %{is_valid}, %{delivery_type}, %{message_count}

=back

=cut
