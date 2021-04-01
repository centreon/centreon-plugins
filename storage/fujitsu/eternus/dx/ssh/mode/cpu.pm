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

package storage::fujitsu::eternus::dx::ssh::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cpu', type => 1, cb_prefix_output => 'prefix_cpu_output', message_multiple => 'All CPUs are ok' }
    ];
    
    $self->{maps_counters}->{cpu} = [
        { label => 'usage', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage' }, { name => 'display' } ],
                output_template => 'Usage : %d %%',
                perfdatas => [
                    { label => 'cpu', value => 'usage', template => '%d',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_cpu_output {
    my ($self, %options) = @_;
    
    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "hostname:s"              => { name => 'hostname' },
        "ssh-option:s@"           => { name => 'ssh_option' },
        "ssh-path:s"              => { name => 'ssh_path' },
        "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"               => { name => 'timeout', default => 30 },
        "command:s"               => { name => 'command', default => 'show' },
        "command-path:s"          => { name => 'command_path' },
        "command-options:s"       => { name => 'command_options', default => 'performance -type cm' },
        "filter-name:s"           => { name => 'filter_name' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        ssh_pipe => 1,
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    # Can have 4 columns also.
    
    #Location              Busy Rate(%) Copy Residual Quantity(MB)
    #--------------------- ------------ --------------------------
    #CM#0                            56                   55191552
    #CM#0 CPU Core#0                 66                          -
    #CM#0 CPU Core#1                 46                          -
    #CM#1                            52                   55191552
    #CM#1 CPU Core#0                 62                          -
    #CM#1 CPU Core#1                 42                          -
    
    $self->{cpu} = {};
    foreach (split /\n/, $stdout) {
        next if ($_ !~ /^(CM.*?)\s{2,}(\d+)\s+\S+/);
        my ($cpu_name, $cpu_value) = ($1, $2);
            
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cpu_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $cpu_name . "': no matching filter name.");
            next;
        }
        
        $self->{cpu}->{$cpu_name} = { display => $cpu_name, usage => $cpu_value };
    }

    if (scalar(keys %{$self->{cpu}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No component found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CPUs usage.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'show').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'performance -type cm').

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
