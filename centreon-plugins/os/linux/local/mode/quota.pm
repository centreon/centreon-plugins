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

package os::linux::local::mode::quota;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($extra_label, $unit) = ('', '');
    $unit = 'B' if ($self->{result_values}->{label_ref} eq 'data');
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(label => $self->{result_values}->{label_ref} . '_used' . $extra_label, unit => $unit,
                                  value => $self->{result_values}->{used},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{warn_label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{crit_label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0);
}

sub custom_usage_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{used}, 
        threshold => [ { label => 'critical-' . $self->{result_values}->{crit_label}, exit_litteral => 'critical' }, 
                       { label => 'warning-' . $self->{result_values}->{warn_label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my $value = $self->{result_values}->{used} . ' files';
    if ($self->{result_values}->{label_ref} eq 'data') {
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        $value = $total_used_value . " " . $total_used_unit;
    }
    my ($limit_soft, $limit_hard) = ('', '');
    if (defined($self->{result_values}->{warn_limit}) && $self->{result_values}->{warn_limit} > 0) {
        $limit_soft = sprintf(" (%.2f %% of soft limit)", $self->{result_values}->{used} * 100 / $self->{result_values}->{warn_limit});
    }
    if (defined($self->{result_values}->{crit_limit}) && $self->{result_values}->{crit_limit} > 0) {
        $limit_hard = sprintf(" (%.2f %% of hard limit)", $self->{result_values}->{used} * 100 / $self->{result_values}->{crit_limit});
    }

    my $msg = sprintf("%s Used: %s%s%s",
                      ucfirst($self->{result_values}->{label_ref}),
                      $value,
                      $limit_soft, $limit_hard);
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{label_ref} = $options{extra_options}->{label_ref};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref} . '_used'};
    
    $self->{result_values}->{warn_label} = $self->{label};
    if (defined($instance_mode->{option_results}->{'warning-' . $self->{label}}) && $instance_mode->{option_results}->{'warning-' . $self->{label}} ne '') {
        $self->{result_values}->{warn_limit} = $instance_mode->{option_results}->{'warning-' . $self->{label}};
    } elsif ($options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref} . '_soft'} > 0) {
        $self->{result_values}->{warn_limit} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref} . '_soft'};
        $self->{perfdata}->threshold_validate(label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display}, value => $self->{result_values}->{warn_limit});
        $self->{result_values}->{warn_label} = $self->{label} . '_' . $self->{result_values}->{display};
    }

    $self->{result_values}->{crit_label} = $self->{label};
    if (defined($instance_mode->{option_results}->{'critical-' . $self->{label}}) && $instance_mode->{option_results}->{'critical-' . $self->{label}} ne '') {
        $self->{result_values}->{crit_limit} = $instance_mode->{option_results}->{'critical-' . $self->{label}};
    } elsif ($options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref} . '_hard'} > 0) {
        $self->{result_values}->{crit_limit} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label_ref} . '_hard'} - 1;
        $self->{perfdata}->threshold_validate(label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display}, value => $self->{result_values}->{crit_limit});
        $self->{result_values}->{crit_label} = $self->{label} . '_' . $self->{result_values}->{display};
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'quota', type => 1, cb_prefix_output => 'prefix_quota_output', message_multiple => 'All quotas are ok' }
    ];
    
    $self->{maps_counters}->{quota} = [
        { label => 'data-usage', set => {
                key_values => [ { name => 'display' }, { name => 'data_used' }, { name => 'data_soft' }, { name => 'data_hard' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'data' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'inode-usage', set => {
                key_values => [ { name => 'display' }, { name => 'inode_used' }, { name => 'inode_soft' }, { name => 'inode_hard' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'inode' },
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_quota_output {
    my ($self, %options) = @_;
    
    return "Quota '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command:s"         => { name => 'command', default => 'repquota' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "command-options:s" => { name => 'command_options', default => '-a -i 2>&1' },
                                  "filter-user:s"     => { name => 'filter_user', },
                                  "filter-fs:s"       => { name => 'filter_fs', },
                                });
    $self->{result} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $instance_mode = $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout, $exit_code) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        sudo => $self->{option_results}->{sudo},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options},
        no_quit => 1
    );
    
    #*** Report for user quotas on device /dev/xxxx
    #Block grace time: 7days; Inode grace time: 7days
    #                   Block limits                File limits
    #User            used    soft    hard  grace    used  soft  hard  grace
    #----------------------------------------------------------------------
    #root      -- 20779412       0       0              5     0     0
    #apache    -- 5721908       0       0          67076     0     0
    
    $self->{quota} = {};
    while ($stdout =~ /^\*\*\*.*?(\S+?)\n(.*?)(?=\*\*\*|\z)/msig) {
        my ($fs, $data) = ($1, $2);
        
        while ($data =~ /^(\S+)\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\n/msig) {
            my ($user, $grace_on, $data_used, $data_soft, $data_hard, $usage) = ($1, $2, $3 * 1024, $4 * 1024, $5 * 1024, $6);
            my @values = split /\s+/, $usage;
                        
            shift @values if ($usage =~ /^\+/);
            my ($inode_used, $inode_soft, $inode_hard) = (shift @values, shift @values, shift @values);
            
            my $name = $user . '.' . $fs;
            if (defined($self->{option_results}->{filter_user}) && $self->{option_results}->{filter_user} ne '' &&
                $user !~ /$self->{option_results}->{filter_user}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            if (defined($self->{option_results}->{filter_fs}) && $self->{option_results}->{filter_fs} ne '' &&
                $fs !~ /$self->{option_results}->{filter_fs}/) {
                $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{quota}->{$name} = { display => $name,
                data_used => $data_used, data_soft => $data_soft, data_hard => $data_hard,
                inode_used => $inode_used, inode_soft => $inode_soft, inode_hard => $inode_hard,
            };
        }
    }

    if (scalar(keys %{$self->{quota}}) <= 0) {
        if ($exit_code != 0) {
            $self->{output}->output_add(long_msg => "command output:" . $stdout);
        }
        $self->{output}->add_option_msg(short_msg => "No quota found (filters or command issue)");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check quota usage on partitions.

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

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

Command to get information (Default: 'repquota').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-a -i 2>&1').

=item B<--warning-*>

Threshold warning.
Can be: 'inode-usage', 'data-usage'.

=item B<--critical-*>

Threshold critical.
Can be: 'inode-usage', 'data-usage'.

=item B<--filter-user>

Filter username (regexp can be used).

=item B<--filter-fs>

Filter filesystem (regexp can be used).

=back

=cut
