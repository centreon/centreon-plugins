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

package os::linux::local::mode::process;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);
use Time::HiRes;

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $cpu_utime = $options{new_datas}->{$self->{instance} . '_cpu_utime'} - $options{old_datas}->{$self->{instance} . '_cpu_utime'};
    my $cpu_stime = $options{new_datas}->{$self->{instance} . '_cpu_stime'} - $options{old_datas}->{$self->{instance} . '_cpu_stime'};

    my $total_ticks = $options{delta_time} * $self->{instance_mode}->{option_results}->{clock_ticks};
    $self->{result_values}->{cpu_prct} = 100 * ($cpu_utime + $cpu_stime) / $total_ticks;
    $self->{instance_mode}->{global}->{cpu_prct} += $self->{result_values}->{cpu_prct};

    return 0;
}

sub custom_disks_calc {
    my ($self, %options) = @_;

    my $diff = $options{new_datas}->{$self->{instance} . '_disks_' . $options{extra_options}->{label_ref}} - 
        $options{old_datas}->{$self->{instance} . '_disks_' . $options{extra_options}->{label_ref}};
    $self->{result_values}->{'disks_' . $options{extra_options}->{label_ref}} = $diff / $options{delta_time};
    $self->{instance_mode}->{global}->{'disks_' . $options{extra_options}->{label_ref}} += $self->{result_values}->{'disks_' . $options{extra_options}->{label_ref}};

    return 0;
}

sub prefix_process_output {
    my ($self, %options) = @_;

    return sprintf(
        'Process: [command => %s] [arg => %s] [state => %s] ',
        $options{instance_value}->{cmd},
        $options{instance_value}->{args},
        $options{instance_value}->{state}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'processes', type => 1, cb_prefix_output => 'prefix_process_output', skipped_code => { -10 => 1, -1 => 1 } },
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'processes.total.count', set => {
                key_values => [ { name => 'processes' } ],
                output_template => 'Number of current processes: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-memory-usage', nlabel => 'processes.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'memory used: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'total-cpu-utilization', nlabel => 'processes.cpu.utilization.percentage', set => {
                key_values => [ { name => 'cpu_prct' } ],
                output_template => 'cpu usage: %.2f %%',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0 }
                ]
            }
        },
        { label => 'total-disks-read', nlabel => 'processes.disks.io.read.usage.bytespersecond', set => {
                key_values => [ { name => 'disks_read' } ],
                output_template => 'disks read: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        },
        { label => 'total-disks-write', nlabel => 'processes.disks.io.write.usage.bytespersecond', set => {
                key_values => [ { name => 'disks_write' } ],
                output_template => 'disks write: %s %s/s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', unit => 'B/s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{processes} = [
        { label => 'time', set => {
                key_values => [ { name => 'duration_seconds' }, { name => 'duration_human' } ],
                output_template => 'duration: %s',
                output_use => 'duration_human',
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'memory-usage', set => {
                key_values => [ { name => 'memory_used' } ],
                output_template => 'memory used: %s %s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'cpu-utilization', set => {
                key_values => [ { name => 'cpu_utime', diff => 1 }, { name => 'cpu_stime', diff => 1 } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_template => 'cpu usage: %.2f %%',
                output_use => 'cpu_prct',
                threshold_use => 'cpu_prct',
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'disks-read', set => {
                key_values => [ { name => 'disks_read', diff => 1 } ],
                closure_custom_calc => $self->can('custom_disks_calc'), closure_custom_calc_extra_options => { label_ref => 'read' },
                output_template => 'disks read: %s %s/s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub { return 0; }
            }
        },
        { label => 'disks-write', set => {
                key_values => [ { name => 'disks_write', diff => 1 } ],
                closure_custom_calc => $self->can('custom_disks_calc'), closure_custom_calc_extra_options => { label_ref => 'write' },
                output_template => 'disks write: %s %s/s',
                output_change_bytes => 1,
                closure_custom_perfdata => sub { return 0; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-command:s' => { name => 'filter_command' },
        'filter-arg:s'     => { name => 'filter_arg' },
        'filter-state:s'   => { name => 'filter_state' },
        'filter-ppid:s'	   => { name => 'filter_ppid' },
        'add-cpu'          => { name => 'add_cpu' },
        'add-memory'       => { name => 'add_memory' },
        'add-disk-io'      => { name => 'add_disk_io' },
        'page-size:s'      => { name => 'page_size', default => 4096 },
        'clock-ticks:s'    => { name => 'clock_ticks', default => 100 }
    });

    return $self;
}

my $state_map = {
    Z => 'zombie',
    X => 'dead',
    W => 'paging',
    T => 'stopped',
    S => 'InterruptibleSleep',
    R => 'running',
    D => 'UninterrupibleSleep',
    I => 'IdleKernelThread'
};

sub parse_output {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'ps',
        command_options => '-e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a  -w 2>&1'
    );

    $self->{global} = { processes => 0 };
    $self->{processes} = {};

    my @lines = split /\n/, $stdout;
    my $line = shift @lines;
    foreach my $line (@lines) {
        next if ($line !~ /^(.*?)===(.*?)===(.*?)===(.*?)===(.*?)===(.*)$/);
        my ($state, $elapsed, $pid, $ppid, $cmd, $args) = (
            centreon::plugins::misc::trim($1),
            centreon::plugins::misc::trim($2),
            centreon::plugins::misc::trim($3),
            centreon::plugins::misc::trim($4),
            centreon::plugins::misc::trim($5),
            centreon::plugins::misc::trim($6)
        );

        next if (defined($self->{option_results}->{filter_command}) && $self->{option_results}->{filter_command} ne '' &&
            $cmd !~ /$self->{option_results}->{filter_command}/);
        next if (defined($self->{option_results}->{filter_arg}) && $self->{option_results}->{filter_arg} ne '' &&
            $args !~ /$self->{option_results}->{filter_arg}/);
        next if (defined($self->{option_results}->{filter_state}) && $self->{option_results}->{filter_state} ne '' &&
            $state_map->{$state} !~ /$self->{option_results}->{filter_state}/i);
        next if (defined($self->{option_results}->{filter_ppid}) && $self->{option_results}->{filter_ppid} ne '' &&
            $ppid !~ /$self->{option_results}->{filter_ppid}/);

        $args =~ s/\|//g;
        my $duration_seconds = $self->get_duration(elapsed => $elapsed);

        $self->{processes}->{$pid} = {
            ppid => $ppid, 
            state => $state,
            duration_seconds => $duration_seconds,
            duration_human => centreon::plugins::misc::change_seconds(value => $duration_seconds),
            cmd => $cmd, 
            args => $args
        };
        $self->{global}->{processes}++;
    }
}

sub get_duration {
    my ($self, %options) = @_;

    # Format: [[dd-]hh:]mm:ss
    $options{elapsed} =~ /(?:(\d+)-)?(?:(\d+):)?(\d+):(\d+)/;
    my ($day, $hour, $min, $sec) = ($1, $2, $3, $4);
    my $total_seconds_elapsed = $sec + ($min * 60);
    if (defined($hour)) {
        $total_seconds_elapsed += ($hour * 60 * 60);
    }
    if (defined($day)) {
        $total_seconds_elapsed += ($day * 86400);
    }

    return $total_seconds_elapsed;
}

sub add_cpu {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_cpu}));

    $self->{global}->{cpu_prct} = 0;
    # /stat
    #   utime (14) Amount of time that this process has been scheduled in user mode, measured in clock ticks (divide by sysconf(_SC_CLK_TCK))
    #   stime (15) Amount of time that this process has been scheduled in kernel mode, measured in clock ticks
    foreach my $pid (keys %{$self->{processes}}) {
        next if ($options{content} !~ /==>\s*\/proc\/$pid\/stat\s+.*?\n(.*?)(?:==>|\Z)/ms);
        my @values = split(/\s+/, $1);

        $self->{processes}->{$pid}->{cpu_utime} = $values[13];
        $self->{processes}->{$pid}->{cpu_stime} = $values[14];
    }
}

sub add_memory {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_memory}));

    $self->{global}->{memory_used} = 0;
    # statm
    #   resident (2) resident set size (inaccurate; same as VmRSS in /proc/[pid]/status)
    #   data     (6) data + stack
    # measured in page (default: 4096). can get with: getconf PAGESIZE
    foreach my $pid (keys %{$self->{processes}}) {
        next if ($options{content} !~ /==>\s*\/proc\/$pid\/statm.*?\n(.*?)(?:==>|\Z)/ms);
        my @values = split(/\s+/, $1);

        my $memory_used = ($values[1] * $self->{option_results}->{page_size}) + ($values[5] * $self->{option_results}->{page_size});
        $self->{processes}->{$pid}->{memory_used} = $memory_used;
        $self->{global}->{memory_used} += $memory_used;
    }
}

sub add_disk_io {
    my ($self, %options) = @_;

    return if (!defined($self->{option_results}->{add_disk_io}));

    $self->{global}->{disks_read} = 0;
    $self->{global}->{disks_write} = 0;
    # /io
    #   read_bytes: 2256896
    #   write_bytes: 0
    foreach my $pid (keys %{$self->{processes}}) {
        next if ($options{content} !~ /==>\s*\/proc\/$pid\/io\s+.*?\n(.*?)(?:==>|\Z)/ms);
        my $entries = $1;
        next if ($entries !~ /read_bytes:\s*(\d+)/m);
        $self->{processes}->{$pid}->{disks_read} = $1;

        next if ($entries !~ /write_bytes:\s*(\d+)/m);
        $self->{processes}->{$pid}->{disks_write} = $1;
    }
}

sub add_extra_metrics {
    my ($self, %options) = @_;

    my $files = [];
    push @$files, 'stat' if (defined($self->{option_results}->{add_cpu}));
    push @$files, 'statm' if (defined($self->{option_results}->{add_memory}));
    push @$files, 'io' if (defined($self->{option_results}->{add_disk_io}));

    my ($num_files, $files_arg) = (scalar(@$files), '');
    return if ($num_files <= 0);
    $files_arg = $files->[0] if ($num_files == 1);
    $files_arg = '{' . join(',', @$files) . '}' if ($num_files > 1);
    
    my ($num_proc, $proc_arg) = (scalar(keys %{$self->{processes}}), '');
    return if ($num_proc <= 0);
    $proc_arg = join(',', keys %{$self->{processes}}) if ($num_proc == 1);
    $proc_arg = '{' . join(',', keys %{$self->{processes}}) . '}' if ($num_proc > 1);

    $self->set_timestamp(timestamp => Time::HiRes::time());
    my ($content) = $options{custom}->execute_command(
        command => 'bash',
        command_options => "-c 'tail -n +1 /proc/$proc_arg/$files_arg'",
        no_quit => 1
    );

    $self->add_cpu(content => $content);
    $self->add_memory(content => $content);
    $self->add_disk_io(content => $content);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_command}) ? md5_hex($self->{option_results}->{filter_command}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_arg}) ? md5_hex($self->{option_results}->{filter_arg}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_state}) ? md5_hex($self->{option_results}->{filter_state}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_ppid}) ? md5_hex($self->{option_results}->{filter_ppid}) : md5_hex('all'));
    $self->parse_output(custom => $options{custom});
    $self->add_extra_metrics(custom => $options{custom});
}

1;

__END__

=head1 MODE

Check linux processes.

Command used:

ps -e -o state -o ===%t===%p===%P=== -o comm:50 -o ===%a  -w 2>&1
bash -c 'tail -n +1 /proc/{pid1,pid2,...}/{statm,stat,io}'

=over 8

=item B<--add-cpu>

Monitor cpu usage.

=item B<--add-memory>

Monitor memory usage. It's inaccurate but it provides a trend.

=item B<--add-disk-io>

Monitor disk I/O.

=item B<--filter-command>

Filter process commands (regexp can be used).

=item B<--filter-arg>

Filter process arguments (regexp can be used).

=item B<--filter-ppid>

Filter process ppid (regexp can be used).

=item B<--filter-state>

Filter process states (regexp can be used).
You can use: 'zombie', 'dead', 'paging', 'stopped',
'InterrupibleSleep', 'running', 'UninterrupibleSleep'.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'total-memory-usage', 'total-cpu-utilization', 'total-disks-read',
'total-disks-write', 'time', 'memory-usage', 'cpu-utilization', 'disks-read', 'disks-write'. 

=back

=cut
