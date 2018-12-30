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

package storage::quantum::dxi::ssh::mode::systemstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{status} . "' [type = " . $self->{result_values}->{type} . "] [value = " . $self->{result_values}->{value} . "]";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Component '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All component status are ok' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'type' }, { name => 'value' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "hostname:s"          => { name => 'hostname' },
                                  "ssh-option:s@"       => { name => 'ssh_option' },
                                  "ssh-path:s"          => { name => 'ssh_path' },
                                  "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "sudo"                => { name => 'sudo' },
                                  "command:s"           => { name => 'command', default => 'syscli' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options', default => '-getstatus systemboard' },
                                  "warning-status:s"    => { name => 'warning_status' },
                                  "critical-status:s"   => { name => 'critical_status', default => '%{status} !~ /Normal/i' },
                                });
    
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    
    $instance_mode = $self;
    $self->change_macros();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(output => $self->{output},
                                                                options => $self->{option_results},
                                                                sudo => $self->{option_results}->{sudo},
                                                                command => $self->{option_results}->{command},
                                                                command_path => $self->{option_results}->{command_path},
                                                                command_options => $self->{option_results}->{command_options},
                                                                );
    # Output data:
    #   System Board Components
    #   Total count = 45
    #   [Component = 1]
    #     Name = IPMI
    #     Type = IPMI
    #     Value = NA
    #     Status = Normal
    #   [Component = 2]
    #     Name = Inlet Temperature
    #     Type = Temperature
    #     Value = 26 degrees C
    #     Status = Normal
    #   [Component = 3]
    #     Name = Exhaust Temperature
    #     Type = Temperature
    #     Value = 31 degrees C
    #     Status = Normal

    my $id;
    foreach (split(/\n/, $stdout)) {
        $id = $1 if ($_ =~ /.*\[Component\s=\s(.*)\]$/i);
        $self->{global}->{$id}->{status} = $1 if ($_ =~ /.*Status\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{name} = $1 if ($_ =~ /.*Name\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{type} = $1 if ($_ =~ /.*Type\s=\s(.*)$/i && defined($id) && $id ne '');
        $self->{global}->{$id}->{value} = $1 if ($_ =~ /.*Value\s=\s(.*)$/i && defined($id) && $id ne '');
    }
}

1;

__END__

=head1 MODE

Check system board status.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{name}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Normal/i').
Can used special variables like: %{name}, %{status}

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (Default: 'syscli').

=item B<--command-path>

Command path.

=item B<--command-options>

Command options (Default: '-getstatus systemboard').

=back

=cut
