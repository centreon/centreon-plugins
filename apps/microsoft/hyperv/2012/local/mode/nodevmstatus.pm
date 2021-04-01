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

package apps::microsoft::hyperv::2012::local::mode::nodevmstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::hyperv::2012::nodevmstatus;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use apps::microsoft::hyperv::2012::local::mode::resources::types qw($node_vm_state);
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;
    
    return 'status: ' . $self->{result_values}->{status} . " (state: " . $self->{result_values}->{state} . ", is clustered: " . $self->{result_values}->{is_clustered} . ")";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' },
    ];
    $self->{maps_counters}->{vm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'vm' }, { name => 'state' }, { name => 'status' }, { name => 'is_clustered' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;
    
    return "VM '" . $options{instance_value}->{vm} . "' ";
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
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /Operating normally/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);  

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::hyperv::2012::nodevmstatus::get_powershell();
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
    #   { "name": "XXXX1", "state": 2, "status": "Operating normally", "is_clustered": true, "note": null },
    #   { "name": "XXXX2", "state": 2, "status": "Operating normally", "is_clustered": false, "note": null },
    #   { "name": "XXXX3", "state": 2, "status": "Operating normally", "is_clustered": true, "note": null }
    #]
    $self->{vm} = {};

    my $id = 1;
    foreach my $node (@$decoded) {
        my ($name, $state, $status, $is_clustered, $note) = ($1, $2, $3, $4, $5);

        if (defined($self->{option_results}->{filter_vm}) && $self->{option_results}->{filter_vm} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_vm}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_note}) && $self->{option_results}->{filter_note} ne '' &&
            defined($node->{note}) && $node->{note} !~ /$self->{option_results}->{filter_note}/i) {
            $self->{output}->output_add(long_msg => "skipping  '" . $node->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vm}->{$id} = {
            vm => $node->{name},
            status => $node->{status},
            state => $node_vm_state->{ $node->{state} },
            is_clustered => $node->{is_clustered} =~ /True|1/i ? 1 : 0
        };
        $id++;
    }

    if (scalar(keys %{$self->{vm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual machine found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check virtual machine status on hyper-v node.

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

=item B<--filter-vm>

Filter virtual machines (can be a regexp).

=item B<--filter-note>

Filter by VM notes (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{vm}, %{state}, %{status}, %{is_clustered}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Operating normally/i').
Can used special variables like: %{vm}, %{state}, %{status}, %{is_clustered}

=back

=cut
