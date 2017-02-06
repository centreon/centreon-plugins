#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::ibm::hmc::ssh::mode::ledstatus;

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
        
        if (defined($instance_mode->{option_results}->{'critical_' . $self->{result_values}->{label}}) && $instance_mode->{option_results}->{'critical_'  . $self->{result_values}->{label}} ne '' &&
            eval "$instance_mode->{option_results}->{'critical_' . $self->{result_values}->{label}}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{'warning_' . $self->{result_values}->{label}}) && $instance_mode->{option_results}->{'warning_'  . $self->{result_values}->{label}} ne '' &&
                 eval "$instance_mode->{option_results}->{'warning_' . $self->{result_values}->{label}}") {
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
    
    my $msg = 'led state : ' . $self->{result_values}->{ledstate};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{label} = $options{extra_options}->{label_ref};
    $self->{result_values}->{ledstate} = $options{new_datas}->{$self->{instance} . '_ledstate'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'physical', type => 1, cb_prefix_output => 'prefix_physical_output', message_multiple => 'All physical status are ok' },
        { name => 'virtuallpar', type => 1, cb_prefix_output => 'prefix_virtuallpar_output', message_multiple => 'All virtual partition status are ok' }
    ];
    
    $self->{maps_counters}->{physical} = [
        { label => 'physical-status', threshold => 0, set => {
                key_values => [ { name => 'ledstate' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => 'physical_status' },
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
    $self->{maps_counters}->{virtuallpar} = [
        { label => 'virtuallpar-status', threshold => 0, set => {
                key_values => [ { name => 'ledstate' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'), closure_custom_calc_extra_options => { label_ref => 'virtuallpar_status' },
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
                                  "filter-name:s"                   => { name => 'filter_name' },
                                  "warning-physical-status:s"       => { name => 'warning_physical_status', default => '' },
                                  "critical-physical-status:s"      => { name => 'critical_physical_status', default => '%{ledstate} =~ /on/' },
                                  "warning-virtuallpar-status:s"    => { name => 'warning_virtuallpar_status', default => '' },
                                  "critical-virtuallpar-status:s"   => { name => 'critical_virtuallpar_status', default => '%{ledstate} =~ /on/' },
                                  
                                  "hostname:s"          => { name => 'hostname' },
                                  "ssh-option:s@"       => { name => 'ssh_option' },
                                  "ssh-path:s"          => { name => 'ssh_path' },
                                  "ssh-command:s"       => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"           => { name => 'timeout', default => 30 },
                                  "command:s"           => { name => 'command' },
                                  "command-path:s"      => { name => 'command_path' },
                                  "command-options:s"   => { name => 'command_options' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }
    $self->{default_hmc_cmd} = 'while read system ; do echo "system: $system"; echo -n "  phys led: "; lsled -r sa -m "$system" -t "phys" ; while read lpar; do echo -n "  lpar [$lpar] led: "; lsled -m "$system" -r sa -t virtuallpar --filter "lpar_names=$lpar" -F state ; done < <(lssyscfg -m "$system" -r lpar -F name) ; done < <(lssyscfg -r sys -F "name")
';
    $instance_mode = $self;
    $self->change_macros();
}

sub prefix_physical_output {
    my ($self, %options) = @_;
    
    return "System '" . $options{instance_value}->{display} . "' physical ";
}

sub prefix_virtuallpar_output {
    my ($self, %options) = @_;
    
    return "Virtual partition '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (('warning_physical_status', 'critical_physical_status', 'warning_virtuallpar_status', 'critical_virtuallpar_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    #system: Server-8203-E4A-SN06DF9A5
    #  phys led: state=on
    #  lpar [LPAR1] led: off
    my $content = centreon::plugins::misc::execute(output => $self->{output},
                                                   options => $self->{option_results},
                                                   command => defined($self->{option_results}->{command}) && $self->{option_results}->{command} ne '' ? $self->{option_results}->{command} : $self->{default_hmc_cmd},
                                                   command_path => $self->{option_results}->{command_path},
                                                   command_options => defined($self->{option_results}->{command_options}) && $self->{option_results}->{command_options} ne '' ? $self->{option_results}->{command_options} : undef);
    
    $self->{physical} = {};
    $self->{virtuallpar} = {};
    
    while ($content =~ /^system:\s+(.*?)\n(.*?)(?:system:|\Z)/msg) {
        my ($system_name, $subcontent) = ($1, $2);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $system_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $system_name . "': no matching filter.", debug => 1);
            next;
        }
        
        $subcontent =~ /phys\s+led:\s+state=(\S+)/;
        my $system_ledstate = $1;
        while ($subcontent =~ /lpar\s+\[(.*?)\]\s+led:\s+(\S+)/msg) {
            my ($lpar_name, $lpar_ledstate) = ($system_name . ':' . $1, $2);
            
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $lpar_name !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $lpar_name . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{virtuallpar}->{$lpar_name} = { display => $lpar_name, ledstate => $lpar_ledstate };
        }
        
        $self->{physical}->{$system_name} = { display => $system_name, ledstate => $system_ledstate };        
    }
    
    if (scalar(keys %{$self->{physical}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No managed system found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check LED status for managed systems.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^physical-status$'

=item B<--filter-name>

Filter name (can be a regexp).
Format of names: systemname[:lparname]

=item B<--warning-physical-status>

Set warning threshold (Default: '').
Can used special variables like: %{ledstate}, %{display}

=item B<--critical-physical-status>

Set critical threshold (Default: '%{ledstate} =~ /on/').
Can used special variables like: %{ledstate}, %{display}

=item B<--warning-virtuallpar-status>

Set warning threshold (Default: '').
Can used special variables like: %{ledstate}, %{display}

=item B<--critical-virtuallpar-status>

Set critical threshold (Default: '%{ledstate} =~ /on/').
Can used special variables like: %{ledstate}, %{display}

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

Command to get information. Used it you have output in a file.

=item B<--command-path>

Command path.

=item B<--command-options>

Command options.

=back

=cut
