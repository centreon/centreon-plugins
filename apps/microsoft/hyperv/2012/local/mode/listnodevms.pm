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

package apps::microsoft::hyperv::2012::local::mode::listnodevms;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::listnodevms;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($node_vm_state);
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {                                  
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    #[
    #   { "name": "XXXX1", "state": 2, "status": "Operating normally", "is_clustered": true, "note": null },
    #   { "name": "XXXX2", "state": 2, "status": "Operating normally", "is_clustered": false, "note": null },
    #   { "name": "XXXX3", "state": 2, "status": "Operating normally", "is_clustered": true, "note": null }
    #]
    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($options{stdout});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }
    return $decoded;
}

sub run {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::listnodevms::get_powershell();
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
    } else {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'List virtual machines:'
        );

        my $decoded = $self->manage_selection(stdout => $stdout);
        foreach my $node (@$decoded) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "'%s' [state = %s] [status = %s]",
                    $node->{name},
                    $node_vm_state->{ $node->{state} },
                    $node->{status}
                )
            );
        }
    }

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'state', 'status', 'is_clustered', 'note']);
}

sub disco_show {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::listnodevms::get_powershell();
        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    
    my $decoded = $self->manage_selection(stdout => $stdout);
    
    foreach my $node (@$decoded) {
        $self->{output}->add_disco_entry(
            name => $node->{name},
            state => $node_vm_state->{ $node->{state} },
            status => $node->{status},
            is_clustered => $node->{is_clustered} =~ /True|1/i ? 1 : 0,
            note => defined($node->{note}) ? $node->{note} : ''
        );
    }
}

1;

__END__

=head1 MODE

List virtual machines on hyper-v node.

=over 8

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

=back

=cut
