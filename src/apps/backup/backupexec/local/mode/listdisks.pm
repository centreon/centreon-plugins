#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::backup::backupexec::local::mode::listdisks;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use apps::backup::backupexec::local::mode::resources::types qw($storage_type);
use centreon::common::powershell::backupexec::disks;
use centreon::plugins::misc;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'bemcli-file'       => { name => 'bemcli_file' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    centreon::plugins::misc::check_security_command(
        output => $self->{output},
        command => $self->{option_results}->{command},
        command_options => $self->{option_results}->{command_options},
        command_path => $self->{option_results}->{command_path}
    );

    $self->{option_results}->{command} = 'powershell.exe'
        if (!defined($self->{option_results}->{command}) || $self->{option_results}->{command} eq '');
    $self->{option_results}->{command_options} = '-InputFormat none -NoLogo -EncodedCommand'
        if (!defined($self->{option_results}->{command_options}) || $self->{option_results}->{command_options} eq '');
}

sub run {
    my ($self, %options) = @_;

    my $disks = $self->manage_selection(%options);
    foreach (@$disks) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name: %s][type: %s][status: %s][totalSpace: %s]',
                $_->{name},
                $_->{type},
                $_->{status},
                $_->{totalSpace}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List disks:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'type', 'status', 'totalSpace']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $disks = $self->manage_selection(%options);
    foreach (@$disks) {
        $self->{output}->add_disco_entry(%$_);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::backupexec::disks::get_powershell(
            bemcli_file => $self->{option_results}->{bemcli_file}
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
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    my $disks = [];
    foreach (@$decoded) {
        push @$disks, {
            name => $_->{name},
            type => defined($storage_type->{ $_->{type} }) ? $storage_type->{ $_->{type} } : 'unknown',
            status => $_->{disabled} =~ /True|1/i ? 'disabled' : 'enabled',
            totalSpace => $_->{totalSpace}
        };
    }

    return $disks;
}

1;

__END__

=head1 MODE

List disks.

=over 8

=item B<--timeout>

Set timeout time for command execution (default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (default: none).

=item B<--command-options>

Command options (default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--bemcli-file>

Set powershell module file (default: 'C:/Program Files/Veritas/Backup Exec/Modules/BEMCLI/bemcli').

=back

=cut
