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

package os::linux::local::mode::packeterrors;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    packets_discard_in  => { thresholds => { 
                                            warning_in_discard  =>  { label => 'warning-in-discard', exit_value => 'warning' },
                                            critical_in_discard =>  { label => 'critical-in-discard', exit_value => 'critical' }, 
                                          },
                            output_msg => 'In Discard : %.2f %% (%d)',
                            regexp => 'RX packets:\d+\s*?errors:\d+\s*?dropped:(\d+)',
                            total => 'total_in',
                          },
    packets_discard_out => { thresholds => { 
                                            warning_out_discard  =>  { label => 'warning-out-discard', exit_value => 'warning' },
                                            critical_out_discard =>  { label => 'critical-out-discard', exit_value => 'critical' }, 
                                          },
                            output_msg => 'Out Discard : %.2f %% (%d)',
                            regexp => 'TX packets:\d+\s*?errors:\d+\s*?dropped:(\d+)',
                            total => 'total_out',
                          },
    packets_error_in    => { thresholds => { 
                                            warning_in_error    =>  { label => 'warning-in-error', exit_value => 'warning' },
                                            critical_in_error   =>  { label => 'critical-in-error', exit_value => 'critical' }, 
                                          },
                            output_msg => 'In Error : %.2f %% (%d)',
                            regexp => 'RX packets:\d+\s*?errors:(\d+)',
                            total => 'total_in',
                           },
    packets_error_out   => { thresholds => { 
                                            warning_out_error   =>  { label => 'warning-out-error', exit_value => 'warning' },
                                            critical_out_error  =>  { label => 'critical-out-error', exit_value => 'critical' }, 
                                          },
                            output_msg => 'Out Error : %.2f %% (%d)',
                            regexp => 'TX packets:\d+\s*?errors:(\d+)',
                            total => 'total_out',
                          },
};

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
                                  "command:s"         => { name => 'command', default => 'ifconfig' },
                                  "command-path:s"    => { name => 'command_path', default => '/sbin' },
                                  "command-options:s" => { name => 'command_options', default => '-a 2>&1' },
                                  "filter-state:s"    => { name => 'filter_state', },
                                  "name:s"                  => { name => 'name' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "no-loopback"             => { name => 'no_loopback', },
                                  "skip"                    => { name => 'skip' },
                                });
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                                                    $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
                                                        });
        }
    }
    
    $self->{result} = {};
    $self->{hostname} = undef;
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }
    
    $self->{statefile_value}->check_options(%options);
    $self->{hostname} = $self->{option_results}->{hostname};
    if (!defined($self->{hostname})) {
        $self->{hostname} = 'me';
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
    while ($stdout =~ /^(\S+)(.*?)(\n\n|\n$)/msg) {
        my ($interface_name, $values) = ($1, $2);
        my $states = '';
        $states .= 'R' if ($values =~ /RUNNING/ms);
        $states .= 'U' if ($values =~ /UP/ms);
        
        next if (defined($self->{option_results}->{no_loopback}) && $values =~ /LOOPBACK/ms);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
                 $states !~ /$self->{option_results}->{filter_state}/);
        
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $interface_name !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $interface_name !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $interface_name ne $self->{option_results}->{name});

        $values =~ /RX packets:(\d+).*?TX packets:(\d+)/msi;
        $self->{result}->{$interface_name} = {total_in => $1, total_out => $2, state => $states};
        foreach (keys %{$maps_counters}) {
            $values =~ /$maps_counters->{$_}->{regexp}/msi;
            $self->{result}->{$interface_name}->{$_} = $1;
        }
    }
    
    if (scalar(keys %{$self->{result}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No interface found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No interface found.");
        }
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
	
    $self->manage_selection();

    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_linux_local_" . $self->{hostname}  . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All interfaces are ok.');
    }
    
    foreach my $name (sort(keys %{$self->{result}})) {

        if ($self->{result}->{$name}->{state} !~ /RU/) {
            if (!defined($self->{option_results}->{skip})) {
                $self->{output}->output_add(severity => 'CRITICAL',
                                            short_msg => "Interface '" . $name . "' is not up or/and running");
            } else {
                # Avoid getting "buffer creation..." alone
                if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp})) {
                    $self->{output}->output_add(severity => 'OK',
                                                short_msg => "Interface '" . $name . "' is not up or/and running (normal state)");
                }
                $self->{output}->output_add(long_msg => "Skip interface '" . $name . "': not up or/and running.");
            }
            next;
        }
        
        # Some interface are running but not have bytes in/out
        if (!defined($self->{result}->{$name}->{total_in})) {
            if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp})) {
                    $self->{output}->output_add(severity => 'OK',
                                                short_msg => "Interface '" . $name . "' is up and running but can't get packets (no values)");
            }
            $self->{output}->output_add(long_msg => "Skip interface '" . $name . "': can't get packets.");
            next;
        }
    
        my $old_datas = {};
        my $next = 0;
        foreach (keys %{$self->{result}->{$name}}) {
            next if ($_ eq 'state');
            $new_datas->{$_ . '_' . $name} = $self->{result}->{$name}->{$_};
            $old_datas->{$_ . '_' . $name} = $self->{statefile_value}->get(name => $_ . '_' . $name);
            if (!defined($old_datas->{$_ . '_' . $name})) {
                $next = 1;
            } elsif ($new_datas->{$_ . '_' . $name} < $old_datas->{$_ . '_' . $name}) {
                # We set 0. has reboot
                $old_datas->{$_ . '_' . $name} = 0;
            }
        }

        if (!defined($old_timestamp) || $next == 1) {
            next;
        }

        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }
        
        ############
        
        my $error_values = {};
        foreach (keys %{$maps_counters}) {
            $error_values->{$_} = {} if (!defined($error_values->{$_}));
            my $total_packets = $new_datas->{$maps_counters->{$_}->{total} . '_' . $name} - $old_datas->{$maps_counters->{$_}->{total} . '_' . $name};
            $error_values->{$_}->{per_sec} = ($new_datas->{$_ . '_' . $name} - $old_datas->{$_ . '_' . $name}) / $time_delta;
            $error_values->{$_}->{prct} = ($total_packets == 0) ? 0 : ($new_datas->{$_ . '_' . $name} - $old_datas->{$_ .'_' . $name}) * 100 / $total_packets;
        }

        ###########
        # Manage Output
        ###########
        my @exits;
        foreach (keys %{$maps_counters}) {
            foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
                push @exits, $self->{perfdata}->threshold_check(value => $error_values->{$_}->{prct}, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
            }
        }

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));

        my $str_output = "Interface '$name' Packets ";
        my $str_append = '';
        foreach (keys %{$maps_counters}) {
            $str_output .= $str_append . sprintf($maps_counters->{$_}->{output_msg}, $error_values->{$_}->{prct}, $new_datas->{$_ . '_' . $name} - $old_datas->{$_ . '_' . $name});
            $str_append = ', ';
            my ($warning, $critical);
            foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
                $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'warning');
                $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'critical');
            }
            
            $self->{output}->perfdata_add(label => $_ . $extra_label, unit => '%',
                                          value => sprintf("%.2f", $error_values->{$_}->{prct}),
                                          warning => $warning,
                                          critical => $critical,
                                          min => 0, max => 100);
        }
        $self->{output}->output_add(long_msg => $str_output);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => $str_output);
        }
    }
    
    $self->{statefile_value}->write(data => $new_datas);    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check packets errors and discards on interfaces.

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

Command to get information (Default: 'ifconfig').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: '/sbin').

=item B<--command-options>

Command options (Default: '-a 2>&1').

=item B<--warning-*>

Threshold warning in percent of total packets. Can be:
in-error, out-error, in-discard, out-discard

=item B<--critical-*>

Threshold critical in percent of total packets. Can be:
in-error, out-error, in-discard, out-discard

=item B<--name>

Set the interface name (empty means 'check all interfaces')

=item B<--regexp>

Allows to use regexp to filter storage mount point (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--filter-state>

Filter filesystem type (regexp can be used).

=item B<--skip>

Skip errors on interface status (not up and running).

=item B<--no-loopback>

Don't display loopback interfaces.

=back

=cut