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

package apps::pacemaker::local::mode::clustat;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use XML::Simple;

my $instance_mode;

my %map_node_state = (
    0 => 'down',
    1 => 'up',
    2 => 'clean'
);

sub custom_state_threshold {
    my ($self, %options) = @_;
    my $status = 'ok';
    my $message;

    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };

        my $label = $self->{label};
        $label =~ s/-/_/g;
        if (defined($instance_mode->{option_results}->{'critical_' . $label}) && $instance_mode->{option_results}->{'critical_' . $label} ne '' &&
            eval "$instance_mode->{option_results}->{'critical_' . $label}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{'warning_' . $label}) && $instance_mode->{option_results}->{'warning_' . $label} ne '' &&
                 eval "$instance_mode->{option_results}->{'warning_' . $label}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = sprintf("state is '%s'", $self->{result_values}->{state});
    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'nodes', type => 1, cb_prefix_output => 'prefix_node_output', message_multiple => 'All nodes are ok' },
        { name => 'groups', type => 1, cb_prefix_output => 'prefix_group_output', message_multiple => 'All groups/resources are ok' }
    ];

    $self->{maps_counters}->{nodes} = [
        { label => 'node', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_threshold_check => $self->can('custom_state_threshold'),
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
    $self->{maps_counters}->{groups} = [
        { label => 'group', threshold => 0, set => {
                key_values => [ { name => 'state' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_threshold_check => $self->can('custom_state_threshold'),
                closure_custom_perfdata => sub { return 0; },
            }
        },
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node: '" . $options{instance_value}->{display} . "' ";
}

sub prefix_group_output {
    my ($self, %options) = @_;

    return "Resource group: '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"          => { name => 'hostname' },
                                  "remote"              => { name => 'remote' },
                                  "ssh-option:s@"       => { name => 'ssh_option' },
                                  "ssh-path:s"          => { name => 'ssh_path' },
                                  "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "sudo"                => { name => 'sudo' },
                                  "command:s"           => { name => 'command', default => 'clustat' },
                                  "command-path:s"      => { name => 'command_path', default => '/usr/sbin' },
                                  "command-options:s"   => { name => 'command_options', default => ' -x 2>&1' },
                                  "warning-group:s"     => { name => 'warning_group' },
                                  "critical-group:s"    => { name => 'critical_group' },
                                  "warning-node:s"      => { name => 'warning_node' },
                                  "critical-node:s"     => { name => 'critical_node' },
                                  "filter-node:s"       => { name => 'filter_node', default => '%{state} !~ /up|clean/' },
                                  "filter-groups:s"     => { name => 'filter_groups', default => '%{state} !~ /starting|started/' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;

    $self->change_macros();

}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_group', 'critical_group', 'warning_node', 'critical_node')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});

    my $clustat_hash = XMLin($stdout);

    foreach my $node (keys %{$clustat_hash->{nodes}->{node}}) {
        if (defined($self->{option_results}->{filter_node}) && $self->{option_results}->{filter_node} ne '' &&
            $node !~ /$self->{option_results}->{filter_node}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $node . "': no matching filter.", debug => 1);
            next;
        }
        $self->{nodes}->{$node} = { state => $map_node_state{$clustat_hash->{nodes}->{node}->{$node}->{state}},
                                    display => $node };
    }

    foreach my $group_name (keys %{$clustat_hash->{groups}->{group}}) {
        if (defined($self->{option_results}->{filter_group}) && $self->{option_results}->{filter_group} ne '' &&
            $group_name !~ /$self->{option_results}->{filter_group}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $group_name . "': no matching filter.", debug => 1);
            next;
        }
        $self->{groups}->{$group_name} = { state => $clustat_hash->{groups}->{group}->{$group_name}->{state_str},
                                           display => $group_name };
    }

}

1;

__END__

=head1 MODE

Check Cluster Resource Manager (need 'clustat' command).
Should be executed on a cluster node.

=over 8

=item B<--warning-*>

Can be ('group','node')
Warning threshold for status.

=item B<--critical-*>

Can be ('group','node')
Critical threshold for status. (Default: --critical-node '%{state} !~ /up|clean/' --critical-group '%{state} !~ /started|starting/')

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine" --ssh-option='-p=52").

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'crm_mon').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/usr/sbin').

=item B<--command-options>

Command options (Default: ' -x 2>&1').

=back

=cut
