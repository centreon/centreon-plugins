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

package apps::microsoft::hyperv::2012::local::mode::nodesnapshot;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodesnapshot;
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($node_vm_state);
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All VM snapshots are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'snapshot', set => {
                key_values => [ { name => 'snapshot' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_snapshot_output'),
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'backing', set => {
                key_values => [ { name => 'backing' }, { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_backing_output'),
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub custom_snapshot_output {
    my ($self, %options) = @_;

    return "checkpoint started " . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{snapshot}) . " ago";
}

sub custom_backing_output {
    my ($self, %options) = @_;
    
    return "backing started " . centreon::plugins::misc::change_seconds(value => $self->{result_values}->{backing}) . " ago";
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "VM '" . $options{instance_value}->{display} . "' [status = " . $options{instance_value}->{status} . '] ';
}

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
        'ps-display'        => { name => 'ps_display' },
        'filter-vm:s'       => { name => 'filter_vm' },
        'filter-note:s'     => { name => 'filter_note' },
        'filter-status:s'   => { name => 'filter_status', default => 'running' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::nodesnapshot::get_powershell();
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

    #[
    #  {
    #     "name": "ISC1-SV04404", "state": 2, "note": null,
    #     "checkpoints": [
    #         { "creation_time": 1475502921.28734, "type": "snapshot" },
    #         { "creation_time": 1475503073.81975, "type": "backing" }
    #     ]
    #  }
    #]
    $self->{vm} = {};

    my ($id, $time) = (1, time());
    foreach my $node (@$decoded) {
        my ($name, $status, $note, $content) = ($1, $2, $3, $4);

        my $checkpoint = { backing => -1, snapshot => -1 };
        my $checkpoints = (ref($node->{checkpoints}) eq 'ARRAY') ? $node->{checkpoints} : [ $node->{checkpoints} ];
        foreach my $chkpt (@$checkpoints) {
            next if (!defined($chkpt));
            $chkpt->{creation_time} =~ s/,/\./g;
            $checkpoint->{ $chkpt->{type} } = $chkpt->{creation_time} if ($chkpt->{creation_time} > 0 && ($checkpoint->{ $chkpt->{type} } == -1 || $checkpoint->{ $chkpt->{type} } > $chkpt->{creation_time}));
        }
        next if ($checkpoint->{backing} == -1 && $checkpoint->{snapshot} == -1);

        if (defined($self->{option_results}->{filter_vm}) && $self->{option_results}->{filter_vm} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_vm}/i) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_note}) && $self->{option_results}->{filter_note} ne '' &&
             defined($node->{note}) && $node->{note} !~ /$self->{option_results}->{filter_note}/i) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_status}) && $self->{option_results}->{filter_status} ne '' &&
            $node_vm_state->{ $node->{state} } !~ /$self->{option_results}->{filter_status}/i) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vm}->{$id} = {
            display => $node->{name},
            snapshot => $checkpoint->{snapshot} > 0 ? $time - $checkpoint->{snapshot} : undef,
            backing => $checkpoint->{backing} > 0 ? $time - $checkpoint->{backing} : undef,
            status => $node_vm_state->{ $node->{state} }
        };
        $id++;
    }

    if (scalar(keys %{$self->{vm}}) <= 0) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'no snapshot found'
        );
    }
}

1;

__END__

=head1 MODE

Check virtual machine snapshots on hyper-v node.

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

=item B<--filter-status>

Filter virtual machine status (can be a regexp) (Default: 'running').

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-note>

Filter by VM notes (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'snapshot' (in seconds), 'backing' (in seconds).

=item B<--critical-*>

Threshold critical.
Can be: 'snapshot' (in seconds), 'backing' (in seconds).

=back

=cut
