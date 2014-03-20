################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

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

        $self->{result}->{disks}->{$partition_name} = { read_sectors => $read_sector, write_sectors => $write_sector,
                                                        read_ms => $read_ms, write_ms => $write_ms, ticks => $ms_ticks};
    }
    
    if (scalar(keys %{$self->{result}}) <= 0) {
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

    use Data::Dumper;
    print Data::Dumper::Dumper($self->{result});
    exit(1);
    
    my $new_datas = {};
    $self->{statefile_value}->read(statefile => "cache_linux_local_" . $self->{hostname}  . '_' . $self->{mode} . '_' . (defined($self->{option_results}->{name}) ? md5_hex($self->{option_results}->{name}) : md5_hex('all')));
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');
    
    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All traffic are ok.');
    }
    
    foreach my $name (sort(keys %{$self->{result}})) {
 
        $new_datas->{'in_' . $name} = $self->{result}->{$name}->{in} * 8;
        $new_datas->{'out_' . $name} = $self->{result}->{$name}->{out} * 8;
        
        my $old_in = $self->{statefile_value}->get(name => 'in_' . $name);
        my $old_out = $self->{statefile_value}->get(name => 'out_' . $name);
        if (!defined($old_timestamp) || !defined($old_in) || !defined($old_out)) {
            next;
        }
        if ($new_datas->{'in_' . $name} < $old_in) {
            # We set 0. Has reboot.
            $old_in = 0;
        }
        if ($new_datas->{'out_' . $name} < $old_out) {
            # We set 0. Has reboot.
            $old_out = 0;
        }

        my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
        }
        my $in_absolute_per_sec = ($new_datas->{'in_' . $name} - $old_in) / $time_delta;
        my $out_absolute_per_sec = ($new_datas->{'out_' . $name} - $old_out) / $time_delta;
        
        my ($exit, $interface_speed, $in_prct, $out_prct);
        if (defined($self->{option_results}->{speed}) && $self->{option_results}->{speed} ne '') {
            $interface_speed = $self->{option_results}->{speed} * 1000000;
            $in_prct = $in_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            $out_prct = $out_absolute_per_sec * 100 / ($self->{option_results}->{speed} * 1000000);
            if ($self->{option_results}->{units} eq '%') {
                my $exit1 = $self->{perfdata}->threshold_check(value => $in_prct, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
                my $exit2 = $self->{perfdata}->threshold_check(value => $out_prct, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
                $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            }
            $in_prct = sprintf("%.2f", $in_prct);
            $out_prct = sprintf("%.2f", $out_prct);
        } else {
            my $exit1 = $self->{perfdata}->threshold_check(value => $in_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
            my $exit2 = $self->{perfdata}->threshold_check(value => $out_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);
            $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
            $in_prct = '-';
            $out_prct = '-';
        }
       
        ###########
        # Manage Output
        ###########
        
        my ($in_value, $in_unit) = $self->{perfdata}->change_bytes(value => $in_absolute_per_sec, network => 1);
        my ($out_value, $out_unit) = $self->{perfdata}->change_bytes(value => $out_absolute_per_sec, network => 1);
        $self->{output}->output_add(long_msg => sprintf("Interface '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                       $in_value . $in_unit, $in_prct,
                                       $out_value . $out_unit, $out_prct));
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1) || (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Interface '%s' Traffic In : %s/s (%s %%), Out : %s/s (%s %%) ", $name,
                                            $in_value . $in_unit, $in_prct,
                                            $out_value . $out_unit, $out_prct));
        }

        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'traffic_in' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $in_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in', total => $interface_speed),
                                      min => 0, max => $interface_speed);
        $self->{output}->perfdata_add(label => 'traffic_out' . $extra_label, unit => 'b/s',
                                      value => sprintf("%.2f", $out_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out', total => $interface_speed),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out', total => $interface_speed),
                                      min => 0, max => $interface_speed);
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

=back

=cut