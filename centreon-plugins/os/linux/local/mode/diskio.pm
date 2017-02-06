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

package os::linux::local::mode::diskio;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

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
                                  "command:s"         => { name => 'command', default => 'tail' },
                                  "command-path:s"    => { name => 'command_path', },
                                  "command-options:s" => { name => 'command_options', default => '-n +1 /proc/stat /proc/diskstats 2>&1' },
                                  "warning-bytes-read:s"    => { name => 'warning_bytes_read' },
                                  "critical-bytes-read:s"   => { name => 'critical_bytes_read' },
                                  "warning-bytes-write:s"   => { name => 'warning_bytes_write' },
                                  "critical-bytes-write:s"  => { name => 'critical_bytes_write' },
                                  "warning-utils:s"         => { name => 'warning_utils' },
                                  "critical-utils:s"        => { name => 'critical_utils' },
                                  "name:s"                  => { name => 'name' },
                                  "regexp"                  => { name => 'use_regexp' },
                                  "regexp-isensitive"       => { name => 'use_regexpi' },
                                  "interrupt-frequency:s"   => { name => 'interrupt_frequency', default => 1000 },
                                  "bytes_per_sector:s"      => { name => 'bytes_per_sector', default => 512 },
                                  "skip"                    => { name => 'skip', },
                                });
    $self->{result} = { cpu => {}, total_cpu => 0, disks => {} };
    $self->{hostname} = undef;
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning-bytes-read', value => $self->{option_results}->{warning_bytes_read})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bytes-read threshold '" . $self->{option_results}->{warning_bytes_read} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-bytes-read', value => $self->{option_results}->{critical_bytes_read})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bytes-read threshold '" . $self->{option_results}->{critical_bytes_read} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-bytes-write', value => $self->{option_results}->{warning_bytes_write})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-bytes-write threshold '" . $self->{option_results}->{warning_bytes_write} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-bytes-write', value => $self->{option_results}->{critical_bytes_write})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-bytes-write threshold '" . $self->{option_results}->{critical_bytes_writes} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-utils', value => $self->{option_results}->{warning_utils})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-utils threshold '" . $self->{option_results}->{warning_utils} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-utils', value => $self->{option_results}->{critical_utils})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-utils threshold '" . $self->{option_results}->{critical_utils} . "'.");
        $self->{output}->option_exit();
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
    
    $stdout =~ /\/proc\/stat(.*)\/proc\/diskstats(.*)/msg;
    my ($cpu_parts, $disk_parts) = ($1, $2);
    
    # Manage CPU Parts
    $cpu_parts =~ /^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ms;
    $self->{result}->{cpu}->{idle} = $4;
    $self->{result}->{cpu}->{system} = $3;
    $self->{result}->{cpu}->{user} = $1;
    $self->{result}->{cpu}->{iowait} = $5;
    
    while ($cpu_parts =~ /^cpu(\d+)/msg) {
        $self->{result}->{total_cpu}++;
    }
    
    # Manage Disk Parts
    while ($disk_parts =~ /^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+/msg) {
        my ($partition_name, $read_sector, $write_sector, $read_ms, $write_ms, $ms_ticks) = ($3, $6, $10, $7, $11, $13);
        
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && defined($self->{option_results}->{use_regexpi}) 
            && $partition_name !~ /$self->{option_results}->{name}/i);
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi}) 
            && $partition_name !~ /$self->{option_results}->{name}/);
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && !defined($self->{option_results}->{use_regexpi})
            && $partition_name ne $self->{option_results}->{name});

        if (defined($self->{option_results}->{skip}) && $read_sector == 0 && $write_sector == 0) {
            $self->{output}->output_add(long_msg => "Skipping partition '" . $partition_name . "': no read/write IO.");
            next;
        }
            
        $self->{result}->{disks}->{$partition_name} = { read_sectors => $read_sector, write_sectors => $write_sector,
                                                        read_ms => $read_ms, write_ms => $write_ms, ticks => $ms_ticks};
    }
    
    if (scalar(keys %{$self->{result}->{disks}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No partition found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No partition found.");
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
                                    short_msg => 'All partitions are ok.');
    }
    
    foreach my $name (sort(keys %{$self->{result}->{disks}})) {
 
        my $old_datas = {};
        my $next = 0;
        foreach (keys %{$self->{result}->{disks}->{$name}}) {
            $new_datas->{$_ . '_' . $name} = $self->{result}->{disks}->{$name}->{$_};
            $old_datas->{$_ . '_' . $name} = $self->{statefile_value}->get(name => $_ . '_' . $name);
            if (!defined($old_datas->{$_ . '_' . $name})) {
                $next = 1;
            } elsif ($new_datas->{$_ . '_' . $name} < $old_datas->{$_ . '_' . $name}) {
                # We set 0. has reboot
                $old_datas->{$_ . '_' . $name} = 0;
            }
        }
        foreach (keys %{$self->{result}->{cpu}}) {
            $new_datas->{'cpu_' . $_} = $self->{result}->{cpu}->{$_};
            $old_datas->{'cpu_' . $_} = $self->{statefile_value}->get(name => 'cpu_' . $_);
            if (!defined($old_datas->{'cpu_' . $_})) {
                $next = 1;
            } elsif ($new_datas->{'cpu_' . $_} < $old_datas->{'cpu_' . $_}) {
                # We set 0. has reboot
                $old_datas->{'cpu_' . $_} = 0;
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

        # Do calc
        my $read_bytes_per_seconds = ($new_datas->{'read_sectors_' . $name} - $old_datas->{'read_sectors_' . $name}) * $self->{option_results}->{bytes_per_sector} / $time_delta;
        my $write_bytes_per_seconds = ($new_datas->{'write_sectors_' . $name} - $old_datas->{'write_sectors_' . $name}) * $self->{option_results}->{bytes_per_sector} / $time_delta;
        my $read_ms = $new_datas->{'read_ms_' . $name} - $old_datas->{'read_ms_' . $name};
        my $write_ms = $new_datas->{'write_ms_' . $name} - $old_datas->{'write_ms_' . $name};
        my $delta_ms = $self->{option_results}->{interrupt_frequency} * (($new_datas->{cpu_idle} + $new_datas->{cpu_iowait} + $new_datas->{cpu_user} + $new_datas->{cpu_system}) 
                                                                          - 
                                                                         ($old_datas->{cpu_idle} + $old_datas->{cpu_iowait} + $old_datas->{cpu_user} + $old_datas->{cpu_system})) 
                        / $self->{result}->{total_cpu} / 100;
        my $utils = 100 * ($new_datas->{'ticks_' . $name} - $old_datas->{'ticks_' . $name}) / $delta_ms;
        if ($utils > 100) {
            $utils = 100;
        }
       
        ###########
        # Manage Output
        ###########
        
        my $exit1 = $self->{perfdata}->threshold_check(value => $read_bytes_per_seconds, threshold => [ { label => 'critical-bytes-read', 'exit_litteral' => 'critical' }, { label => 'warning-bytes-read', exit_litteral => 'warning' } ]);
        my $exit2 = $self->{perfdata}->threshold_check(value => $write_bytes_per_seconds, threshold => [ { label => 'critical-bytes-write', 'exit_litteral' => 'critical' }, { label => 'warning-bytes-write', exit_litteral => 'warning' } ]);
        my $exit3 = $self->{perfdata}->threshold_check(value => $utils, threshold => [ { label => 'critical-utils', 'exit_litteral' => 'critical' }, { label => 'warning-utils', exit_litteral => 'warning' } ]);

        my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2, $exit3 ]);
        
        my ($read_value, $read_unit) = $self->{perfdata}->change_bytes(value => $read_bytes_per_seconds);
        my ($write_value, $write_unit) = $self->{perfdata}->change_bytes(value => $write_bytes_per_seconds);
        
        $self->{output}->output_add(long_msg => sprintf("Partition '%s' Read I/O : %s/s, Write I/O : %s/s, Write Time : %s ms, Read Time : %s ms, %%Utils: %.2f %%", $name,
                                                        $read_value . $read_unit,
                                                        $write_value . $write_unit,
                                                        $read_ms, $write_ms, $utils
                                                        ));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Partition '%s' Read I/O : %s/s, Write I/O : %s/s, Write Time : %s ms, Read Time : %s ms, %%Utils: %.2f %%", $name,
                                                        $read_value . $read_unit,
                                                        $write_value . $write_unit,
                                                        $read_ms, $write_ms, $utils
                                                        ));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'readio' . $extra_label, unit => 'B/s',
                                      value => sprintf("%.2f", $read_bytes_per_seconds),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-bytes-read'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-bytes-read'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'writeio' . $extra_label, unit => 'B/s',
                                      value => sprintf("%.2f", $write_bytes_per_seconds),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-bytes-write'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-bytes-write'),
                                      min => 0);
        $self->{output}->perfdata_add(label => 'readtime' . $extra_label, unit => 'ms',
                                      value => $read_ms,
                                      min => 0);
        $self->{output}->perfdata_add(label => 'writetime' . $extra_label, unit => 'ms',
                                      value => $write_ms,
                                      min => 0);
        $self->{output}->perfdata_add(label => 'utils' . $extra_label, unit => '%',
                                      value => sprintf("%.2f", $utils),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-utils'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-util'),
                                      min => 0, max => 100);
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

Check some disk io counters:
read and writes bytes per seconds, milliseconds time spent reading and writing, %util (like iostat) 

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

Command to get information (Default: 'tail').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-n +1 /proc/stat /proc/diskstats 2>&1').

=item B<--warning-bytes-read>

Threshold warning in bytes per seconds read.

=item B<--critical-bytes-read>

Threshold critical in bytes per seconds read.

=item B<--warning-bytes-write>

Threshold warning in bytes per seconds write.

=item B<--critical-bytes-write>

Threshold critical in bytes per seconds write.

=item B<--warning-utils>

Threshold warning in %utils.

=item B<--critical-utils>

Threshold critical in %utils.

=item B<--name>

Set the partition name (empty means 'check all partitions')

=item B<--regexp>

Allows to use regexp to filter partition name (with option --name).

=item B<--regexp-isensitive>

Allows to use regexp non case-sensitive (with --regexp).

=item B<--bytes-per-sector>

Bytes per sector (Default: 512)

=item B<--interrupt-frequency>

Linux Kernel Timer Interrupt Frequency (Default: 1000)

=item B<--skip>

Skip partitions with 0 sectors read/write.

=back

=cut