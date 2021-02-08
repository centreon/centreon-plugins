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

package os::linux::local::mode::diskio;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{usage_persecond} = ($options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_sectors'} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{label_ref} . '_sectors'}) 
        * $self->{instance_mode}->{option_results}->{bytes_per_sector} / $options{delta_time};
    return 0;
}

sub custom_utils_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    my $delta_ms =
        $self->{instance_mode}->{option_results}->{interrupt_frequency} *
        (
            ($options{new_datas}->{$self->{instance} . '_cpu_idle'} - $options{old_datas}->{$self->{instance} . '_cpu_idle'}) +
            ($options{new_datas}->{$self->{instance} . '_cpu_user'} - $options{old_datas}->{$self->{instance} . '_cpu_user'}) +
            ($options{new_datas}->{$self->{instance} . '_cpu_iowait'} - $options{old_datas}->{$self->{instance} . '_cpu_iowait'}) +
            ($options{new_datas}->{$self->{instance} . '_cpu_system'} - $options{old_datas}->{$self->{instance} . '_cpu_system'})
        )
        / $options{new_datas}->{$self->{instance} . '_cpu_total'} / 100;
    $self->{result_values}->{utils} = 0;
    if ($delta_ms != 0) {
        $self->{result_values}->{utils} = 100 * ($options{new_datas}->{$self->{instance} . '_ticks'} - $options{old_datas}->{$self->{instance} . '_ticks'}) / $delta_ms;
        $self->{result_values}->{utils} = 100 if ($self->{result_values}->{utils} > 100);
    }
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'device', type => 1, cb_prefix_output => 'prefix_device_output', message_multiple => 'All devices are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{device} = [
        { label => 'read-usage', nlabel => 'device.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'read_sectors', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'read' },
                output_template => 'read I/O : %s %s/s',
                output_change_bytes => 1,
                output_use => 'usage_persecond', threshold_use => 'usage_persecond',
                perfdatas => [
                    { label => 'readio', value => 'usage_persecond', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-usage', nlabel => 'device.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'write_sectors', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_usage_calc'), closure_custom_calc_extra_options => { label_ref => 'write' },
                output_template => 'write I/O : %s %s/s',
                output_change_bytes => 1,
                output_use => 'usage_persecond', threshold_use => 'usage_persecond',
                perfdatas => [
                    { label => 'writeio', value => 'usage_persecond', template => '%d',
                      unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read-time', nlabel => 'device.io.read.time.milliseconds', set => {
                key_values => [ { name => 'read_ms', diff => 1 }, { name => 'display' } ],
                output_template => 'read time : %.2f ms',
                perfdatas => [
                    { label => 'readtime', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-time', nlabel => 'device.io.write.time.milliseconds', set => {
                key_values => [ { name => 'write_ms', diff => 1 }, { name => 'display' } ],
                output_template => 'write time : %.2f ms',
                perfdatas => [
                    { label => 'writetime', template => '%.2f',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'utils', nlabel => 'device.io.utils.percentage', set => {
                key_values => [
                    { name => 'cpu_total', diff => 1 },
                    { name => 'cpu_iowait', diff => 1 },
                    { name => 'cpu_user', diff => 1 },
                    { name => 'cpu_system', diff => 1 },
                    { name => 'cpu_idle', diff => 1 },
                    { name => 'ticks', diff => 1 },
                    { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_utils_calc'),
                output_template => '%%utils: %.2f %%',
                output_use => 'utils', threshold_use => 'utils',
                perfdatas => [
                    { label => 'utils', value => 'utils',  template => '%.2f',
                      unit => '%', min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub prefix_device_output {
    my ($self, %options) = @_;
    
    return "Device '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-partition-name:s' => { name => 'filter_partition_name' },
        'interrupt-frequency:s'   => { name => 'interrupt_frequency', default => 1000 },
        'bytes-per-sector:s'      => { name => 'bytes_per_sector', default => 512 },
        'skip'                    => { name => 'skip' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'tail',
        command_options => '-n +1 /proc/stat /proc/diskstats 2>&1'
    );
    
    $stdout =~ /\/proc\/stat(.*?)\/proc\/diskstats.*?\n(.*)/msg;
    my ($cpu_parts, $disk_parts) = ($1, $2);

    # Manage CPU Parts
    $cpu_parts =~ /^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/ms;

    my ($cpu_idle, $cpu_system, $cpu_user, $cpu_iowait) = ($4, $3, $1, $5);
    my $cpu_total = 0;
    while ($cpu_parts =~ /^cpu(\d+)/msg) {
        $cpu_total++;
    }

    $self->{device} = {};
    while ($disk_parts =~ /^\s*\S+\s+\S+\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s+(\S+)\s+\S+\s+\S+\s+(\S+)\s*/msg) {
        my ($partition_name, $read_sector, $write_sector, $read_ms, $write_ms, $ms_ticks) = ($1, $2, $4, $3, $5, $6);

        next if (defined($self->{option_results}->{filter_partition_name}) && $self->{option_results}->{filter_partition_name} ne '' &&
            $partition_name !~ /$self->{option_results}->{filter_partition_name}/);

        if (defined($self->{option_results}->{skip}) && $read_sector == 0 && $write_sector == 0) {
            $self->{output}->output_add(long_msg => "skipping device '" . $partition_name . "': no read/write IO.", debug => 1);
            next;
        }

        $self->{device}->{$partition_name} = {
            display => $partition_name,
            read_sectors => $read_sector, 
            write_sectors => $write_sector,
            read_ms => $read_ms, 
            write_ms => $write_ms, 
            ticks => $ms_ticks,
            cpu_total => $cpu_total,
            cpu_system => $cpu_system,
            cpu_idle => $cpu_idle,
            cpu_user => $cpu_user,
            cpu_iowait => $cpu_iowait
        };
    }

    if (scalar(keys %{$self->{device}}) <= 0) {
        if (defined($self->{option_results}->{name})) {
            $self->{output}->add_option_msg(short_msg => "No device found for name '" . $self->{option_results}->{name} . "'.");
        } else {
            $self->{output}->add_option_msg(short_msg => "No device found.");
        }
        $self->{output}->option_exit();
    }

    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_partition_name}) ? md5_hex($self->{option_results}->{filter_partition_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check some disk io counters:
read and writes bytes per seconds, milliseconds time spent reading and writing, %util (like iostat)

Command used: tail -n +1 /proc/stat /proc/diskstats 2>&1

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

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read-usage', 'write-usage', 'read-time', 'write-time',
'utils'.

=item B<--filter-partition-name>

Filter partition name (regexp can be used).

=item B<--bytes-per-sector>

Bytes per sector (Default: 512)

=item B<--interrupt-frequency>

Linux Kernel Timer Interrupt Frequency (Default: 1000)

=item B<--skip>

Skip partitions with 0 sectors read/write.

=back

=cut
