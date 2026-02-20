#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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
use centreon::plugins::misc qw/trim is_excluded change_seconds/;
use centreon::plugins::constants qw(:values :counters);
use Digest::MD5 qw(md5_hex);
use Time::HiRes;
use FindBin;

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

sub prefix_process_open_files_output {
    my ($self, %options) = @_;
    return sprintf(
        'open files: %s/%s (%.2f%%)',
        $self->{result_values}->{open_files},
        $self->{result_values}->{open_files_limit},
        $self->{result_values}->{open_files_prct}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'processes', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_process_output', skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } },
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } }
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
        },
        {   label => 'open-files',
            set => {
                key_values => [ { name => 'open_files' }, { name => 'open_files_limit' }, { name => 'open_files_prct' } ],
                closure_custom_output => $self->can('prefix_process_open_files_output'),
                closure_custom_perfdata => sub { return 0; }
            }
        },
        {   label => 'open-files-prct', display_ok => 0,
            set => {
                key_values => [ { name => 'open_files_prct' }, {  name => 'open_files' }, { name => 'open_files_limit' } ],
                closure_custom_output => $self->can('prefix_process_open_files_output'),
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
        'filter-command:s'  => { name => 'filter_command',  default => '' },
        'exclude-command:s' => { name => 'exclude_command', default => '' },
        'filter-arg:s'      => { name => 'filter_arg',      default => '' },
        'exclude-arg:s'     => { name => 'exclude_arg',     default => '' },
        'filter-state:s'    => { name => 'filter_state',    default => '' },
        'filter-ppid:s'     => { name => 'filter_ppid',     default => '' },
        'add-cpu'           => { name => 'add_cpu' },
        'add-memory'        => { name => 'add_memory' },
        'add-disk-io'       => { name => 'add_disk_io' },
        'add-open-files'    => { name => 'add_open_files' },
        'page-size:s'       => { name => 'page_size',       default => 4096 },
        'clock-ticks:s'     => { name => 'clock_ticks',     default => 100 }
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
        command_options => '-e -o state -o etime:15 -o pid:10 -o ppid:10 -o comm:50 -o args -w 2>&1'
    );

    $self->{global} = { processes => 0 };
    $self->{processes} = {};

    my @lines = split(/\n/, $stdout);
    my $line = shift(@lines);
    foreach my $line (@lines) {
        next if ($line !~ /^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(.{50})\s+(.*)$/);
        my ($state, $elapsed, $pid, $ppid, $cmd, $args) = map trim($_), ($1, $2, $3, $4, $5, $6);

        next if is_excluded($cmd, $self->{option_results}->{filter_command});
        next if is_excluded($cmd, $self->{option_results}->{exclude_command});
        next if is_excluded($args, $self->{option_results}->{filter_arg});
        next if is_excluded($args, $self->{option_results}->{exclude_arg});
        next if exists $state_map->{$state} && is_excluded($state_map->{$state}, $self->{option_results}->{filter_state});
        next if is_excluded($ppid, $self->{option_results}->{filter_ppid});

        $args =~ s/\|//g;
        my $duration_seconds = $self->get_duration(elapsed => $elapsed);

        $self->{processes}->{$pid} = {
            ppid => $ppid, 
            state => $state,
            duration_seconds => $duration_seconds,
            duration_human => change_seconds(value => $duration_seconds),
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
    $total_seconds_elapsed += ($hour * 60 * 60)
        if defined $hour;
    $total_seconds_elapsed += ($day * 86400)
        if defined $day;

    return $total_seconds_elapsed;
}

sub add_cpu {
    my ($self, %options) = @_;

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

    $self->{global}->{memory_used} = 0;
    # statm
    #   resident (2) resident set size (inaccurate; same as VmRSS in /proc/[pid]/status)
    #   data     (6) data + stack
    # measured in page (default: 4096). can get with: getconf PAGESIZE
    foreach my $pid (keys %{$self->{processes}}) {
        next if ($options{content} !~ /==>\s*\/proc\/$pid\/statm.*?\n(.*?)(?:==>|\Z)/ms);
        my @values = split(/\s+/, $1);

        my $memory_used = ($values[1] * $self->{option_results}->{page_size});
        $self->{processes}->{$pid}->{memory_used} = $memory_used;
        $self->{global}->{memory_used} += $memory_used;
    }
}

sub add_disk_io {
    my ($self, %options) = @_;

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

sub add_open_files {
    my ($self, %options) = @_;
    use Data::Dumper;
    #die Dumper($options{content})."\n";
    my @pids;
    foreach my $pid (keys %{$self->{processes}}) {
        # ==> /proc/121212/limits <==
        # Limit                     Soft Limit           Hard Limit           Units
        # Max cpu time              unlimited            unlimited            seconds
        # Max file size             unlimited            unlimited            bytes
        # Max open files            1024                 1048576              files
        next unless $options{content} =~ /==>\s*\/proc\/$pid\/limits\s.+?Max open files\s+(\d+).+(?:==>|\Z)/ms;

        $self->{processes}->{$pid}->{open_files_limit} = $1;
        $self->{processes}->{$pid}->{open_files} = 0;
        $self->{processes}->{$pid}->{open_files_prct} = 0;

        push @pids, $pid;
    }

    return unless @pids;

    # Get the path to centreon_plugin_local_process.pl from the location of plugin.pm
    my $external_process = [ map "$FindBin::Bin/$_", grep /\/plugin.pm$/, keys %INC ];
    $external_process = $external_process->[0] =~ s/\/plugin\.pm$/\/centreon_linux_local_process.pl/r
        if $external_process;

    $self->{output}->option_exit(short_msg => "Missing $external_process, please install the 'centreon-plugin-Operatingsystems-Linux-Local-Process' package to monitor open files usage")
        unless $external_process && -x $external_process;

    my $cmd = "$external_process ".join ' ', @pids;
    $self->{output}->output_add(long_msg => "Launch [$cmd]", debug => 1);
    $self->{output}->option_exit(short_msg => "Cannot launch $cmd: $!\n")
        unless open(my $fh, "$cmd |");

    while (my $response = <$fh>) {
        next unless $response =~ /^(\d+)\s+(\d+)/;
        $self->{processes}->{$1}->{open_files} = $2;

        $self->{processes}->{$1}->{open_files_prct} = $self->{processes}->{$1}->{open_files_limit} ?
                                                            100 * $2 / $self->{processes}->{$1}->{open_files_limit} :
                                                            100;
    }

    close($fh);
}

sub add_extra_metrics {
    my ($self, %options) = @_;

    my $files = [];
    push @$files, 'stat' if $self->{option_results}->{add_cpu};
    push @$files, 'statm' if $self->{option_results}->{add_memory};
    push @$files, 'io' if $self->{option_results}->{add_disk_io};
    push @$files, 'limits' if $self->{option_results}->{add_open_files};

    my ($num_files, $files_arg) = (scalar(@$files), '');
    return if ($num_files <= 0);
    $files_arg = $files->[0] if $num_files == 1;
    $files_arg = '{' . join(',', @$files) . '}' if $num_files > 1;
    my ($num_proc, $proc_arg) = (scalar(keys %{$self->{processes}}), '');

    return unless $num_proc;
    $proc_arg = join(',', keys %{$self->{processes}}) if $num_proc == 1;
    $proc_arg = '{' . join(',', keys %{$self->{processes}}) . '}' if $num_proc > 1;
    $self->set_timestamp(timestamp => Time::HiRes::time());

    my ($content) = $options{custom}->execute_command(
        command => 'bash',
        command_options => "-c 'tail -vn +1 /proc/$proc_arg/$files_arg'",
        no_quit => 1
    );

    $self->add_cpu(content => $content) if $self->{option_results}->{add_cpu};
    $self->add_memory(content => $content) if $self->{option_results}->{add_memory};
    $self->add_disk_io(content => $content) if $self->{option_results}->{add_disk_io};
    $self->add_open_files(content => $content) if $self->{option_results}->{add_open_files};
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        join '_', map { md5_hex($self->{option_results}->{$_}  || 'all') } qw(filter_counters filter_command filter_arg filter_state filter_ppid);
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

Monitor CPU usage.

=item B<--add-memory>

Monitor memory usage. It's inaccurate but it provides a trend.

=item B<--add-disk-io>

Monitor disk I/O.

=item B<--add-open-files

Monitor open file usage per process.

=item B<--filter-command>

Define which processes should be included based on the name of the executable.
This option will be treated as a regular expression.

=item B<--exclude-command>

Define which processes should be excluded based on the name of the executable.
This option will be treated as a regular expression.

=item B<--filter-arg>

Define which processes should be included based on the arguments of the executable.
This option will be treated as a regular expression.

=item B<--exclude-arg>

Define which processes should be excluded based on the arguments of the executable.
This option will be treated as a regular expression.

=item B<--filter-ppid>

Define which processes should be excluded based on the process's parent process ID (PPID).
This option will be treated as a regular expression.


=item B<--filter-state>

Define which processes should be excluded based on the process state.
This option will be treated as a regular expression.
You can use: 'zombie', 'dead', 'paging', 'stopped',
'InterrupibleSleep', 'running', 'UninterrupibleSleep'.

=item B<--warning-total>

Thresholds.

=item B<--critical-total>

Thresholds.

=item B<--warning-total-memory-usage>

Thresholds.

=item B<--critical-total-memory-usage>

Thresholds.

=item B<--warning-total-cpu-utilization>

Thresholds.

=item B<--critical-total-cpu-utilization>

Thresholds.

=item B<--warning-total-disks-read>

Thresholds.

=item B<--critical-total-disks-read>

Thresholds.

=item B<--warning-total-disks-write>

Thresholds.

=item B<--critical-total-disks-write>

Thresholds.

=item B<--warning-time>

Thresholds.

=item B<--critical-time>

Thresholds.

=item B<--warning-memory-usage>

Thresholds.

=item B<--critical-memory-usage>

Thresholds.

=item B<--warning-cpu-utilization>

Thresholds.

=item B<--critical-cpu-utilization>

Thresholds.

=item B<--warning-disks-read>

Thresholds.

=item B<--critical-disks-read>

Thresholds.

=item B<--warning-disks-write>

Thresholds.

=item B<--critical-disks-write>

Thresholds.

=item B<--warning-open-files>

Thresholds.

=item B<--critical-open-files>

Thresholds.

=item B<--warning-open-files-prct>

Thresholds in percentage.

=item B<--critical-open-files-prct>

Thresholds in percentage.

=back

=cut
