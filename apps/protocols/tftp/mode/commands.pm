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

package apps::protocols::tftp::mode::commands;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Net::TFTP;
use Time::HiRes qw(gettimeofday tv_interval);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
     
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'command', type => 1, cb_prefix_output => 'prefix_command_output', message_multiple => 'All commands are ok' }
    ];
    
    $self->{maps_counters}->{command} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'time', display_ok => 0, set => {
                key_values => [ { name => 'timeelapsed' }, { name => 'display' } ],
                output_template => 'response time %.3fs',
                perfdatas => [
                    { label => 'time', value => 'timeelapsed', template => '%.3f', 
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "hostname:s"        => { name => 'hostname' },
        "port:s"            => { name => 'port', default => 69 },
        "timeout:s"         => { name => 'timeout', default => 5 },
        "retries:s"         => { name => 'retries', default => 5 },
        "block-size:s"      => { name => 'block_size', default => 512 },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{status} ne "ok"' },
        "command:s@"        => { name => 'command' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
    
    if (!defined($self->{option_results}->{hostname}) || $self->{option_results}->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Please set the --hostname option");
        $self->{output}->option_exit();
    }
    
    $self->{option_results}->{command} = []
        if (!defined($self->{option_results}->{command}));
}

sub prefix_command_output {
    my ($self, %options) = @_;
    
    return "Command '" . $options{instance_value}->{display} . "' ";
}

sub put_command {
    my ($self, %options) = @_;
    
    my $status = 'ok';
    if (!$options{tftp}->put($options{localfile}, $options{remotefile})) {
        $status = $options{tftp}->error;
    }
    
    return $status;
}

sub get_command {
    my ($self, %options) = @_;
    
    my ($status, $stdout);
    {
        local *STDOUT;
        open STDOUT, '>', \$stdout;
        
        if (!$options{tftp}->get($options{remotefile}, \*STDOUT)) {
            $status = $options{tftp}->error;
        } else {
            $status = 'ok';
        }
    }
    
    return $status;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $tftp = Net::TFTP->new(
        $self->{option_results}->{hostname}, 
        Timeout => $self->{option_results}->{timeout},
        Retries => $self->{option_results}->{retries},
        Port => $self->{option_results}->{port},
        BlockSize => $self->{option_results}->{block_size},
    );

    $self->{command} = {};
    my $i = 0;
    foreach (@{$self->{option_results}->{command}}) {
        my ($label, $command, $arg1, $arg2) = split /,/;
        
        if (!defined($command) || $command !~ /(put|get)/) {
            $self->{output}->add_option_msg(short_msg => "Unknown command. Please use 'get' or 'put' command name");
            $self->{output}->option_exit();
        }
        
        $i++;
        $command = $1;
        $label = $i
            if (!defined($label) || $label eq '');
        if (!defined($arg1) || $arg1 eq '') {
            $self->{output}->add_option_msg(short_msg => "Unknown first argument. first argument is required.");
            $self->{output}->option_exit();
        }
        
        if ($command eq 'put' && (!defined($arg2) || $arg2 eq '')) {
            $self->{output}->add_option_msg(short_msg => "Unknown second argument. second argument is required for 'put' command.");
            $self->{output}->option_exit();
        }

        my $status;
        my $timing0 = [gettimeofday];
        if ($command eq 'put') {
            $status = $self->put_command(tftp => $tftp, localfile => $arg1, remotefile => $arg2);
        } else {
            $status = $self->get_command(tftp => $tftp, remotefile => $arg1);
        }
        my $timeelapsed = tv_interval($timing0, [gettimeofday]);
        
        $self->{command}->{$i} = {
            display => $label,
            status => $status,
            timeelapsed => $timeelapsed,
        };
    }
    
    if (scalar(keys %{$self->{command}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No command found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check tftp commands.

=over 8

=item B<--hostname>

TFTP server name (required).

=item B<--port>

TFTP port (Default: 69).

=item B<--timeout>

TFTP timeout in seconds (Default: 5).

=item B<--retries>

TFTP number of retries (Default: 5).

=item B<--block-size>

TFTP size of blocks to use in the transfer (Default: 512).

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} ne "ok"').
Can used special variables like: %{status}, %{display}

=item B<--warning-time>

Threshold warning.

=item B<--critical-time>

Threshold critical.

=item B<--command>

TFP command.
Example: --command='labeldisplay,get,remotefile' --command='labeldisplay2,put,localfile,remotefile"

=back

=cut
