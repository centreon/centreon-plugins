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

package snmp_standard::mode::processcount;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my %map_process_status = (
    1 => 'running', 
    2 => 'runnable', 
    3 => 'notRunnable', 
    4 => 'invalid',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'process-status:s'        => { name => 'process_status', default => 'running|runnable' },
        'process-name:s'          => { name => 'process_name' },
        'regexp-name'             => { name => 'regexp_name' },
        'process-path:s'          => { name => 'process_path' },
        'regexp-path'             => { name => 'regexp_path' },
        'process-args:s'          => { name => 'process_args' },
        'regexp-args'             => { name => 'regexp_args' },
        'warning:s'               => { name => 'warning' },
        'critical:s'              => { name => 'critical' },
        'memory'                  => { name => 'memory' },
        'warning-mem-each:s'      => { name => 'warning_mem_each' },
        'critical-mem-each:s'     => { name => 'critical_mem_each' },
        'warning-mem-total:s'     => { name => 'warning_mem_total' },
        'critical-mem-total:s'    => { name => 'critical_mem_total' },
        'warning-mem-avg:s'       => { name => 'warning_mem_avg' },
        'critical-mem-avg:s'      => { name => 'critical_mem_avg' },
        'cpu'                     => { name => 'cpu' },
        'warning-cpu-total:s'     => { name => 'warning_cpu_total' },
        'critical-cpu-total:s'    => { name => 'critical_cpu_total' },
        'top'                     => { name => 'top' },
        'top-num:s'               => { name => 'top_num', default => 5 },
        'top-size:s'              => { name => 'top_size', default => 52428800 }, # 50MB
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    $self->{filter4md5} = '';
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-mem-each', value => $self->{option_results}->{warning_mem_each})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-mem-each threshold '" . $self->{warning_mem_each} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-mem-each', value => $self->{option_results}->{critical_mem_each})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-mem-each threshold '" . $self->{critical_mem_each} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-mem-total', value => $self->{option_results}->{warning_mem_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-mem-total threshold '" . $self->{warning_mem_total} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-mem-total', value => $self->{option_results}->{critical_mem_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-mem-total threshold '" . $self->{critical_mem_total} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-mem-avg', value => $self->{option_results}->{warning_mem_avg})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-mem-avg threshold '" . $self->{warning_mem_avg} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-mem-avg', value => $self->{option_results}->{critical_mem_avg})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-mem-avg threshold '" . $self->{critical_mem_avg} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-cpu-total', value => $self->{option_results}->{warning_cpu_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-cpu-total threshold '" . $self->{warning_cpu_total} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-cpu-total', value => $self->{option_results}->{critical_cpu_total})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-cpu-total threshold '" . $self->{critical_cpu_total} . "'.");
        $self->{output}->option_exit();
    }
    
    if (defined($self->{option_results}->{cpu})) {
        $self->{statefile_cache}->check_options(%options);
        # Construct filter for file cache (avoid one check erase one other)
        my @labels = ('process_name', 'regexp_name', 'process_path', 'regexp_path', 'process_args', 'regexp_args', 'process_status');
        foreach (@labels) {
            if (defined($self->{option_results}->{$_})) {
                $self->{filter4md5} .= ',' . $self->{option_results}->{$_};
            }
        }
    }
}

my $filters = {
    status => { oid => '.1.3.6.1.2.1.25.4.2.1.7', default => 1, value => '', regexp => 1 }, # hrSWRunStatus
    name => { oid => '.1.3.6.1.2.1.25.4.2.1.2', default => 0, value => '' }, # hrSWRunName (Warning: it's truncated. (15 characters))
    path => { oid => '.1.3.6.1.2.1.25.4.2.1.4', default => 0, value => '' }, # hrSWRunPath 
    args => { oid => '.1.3.6.1.2.1.25.4.2.1.5', default => 0, value => '' }, # hrSWRunParameters (Warning: it's truncated. (128 characters))
};

my $oid_hrSWRunName = '.1.3.6.1.2.1.25.4.2.1.2';
my $oid_hrSWRunStatus = '.1.3.6.1.2.1.25.4.2.1.7';
my $oid_hrSWRunPerfMem = '.1.3.6.1.2.1.25.5.1.1.2';
my $oid_hrSWRunPerfCPU = '.1.3.6.1.2.1.25.5.1.1.1';

sub check_top { 
    my ($self, %options) = @_;
    
    my $data;
    foreach my $key (keys %{$self->{snmp_response}->{$oid_hrSWRunName}}) {
        if ($key =~ /\.([0-9]+)$/ && defined($self->{snmp_response}->{$oid_hrSWRunPerfMem}->{$oid_hrSWRunPerfMem . '.' . $1})) {
            $data->{$self->{snmp_response}->{$oid_hrSWRunName}->{$oid_hrSWRunName . '.' . $1}}->{memory} += $self->{snmp_response}->{$oid_hrSWRunPerfMem}->{$oid_hrSWRunPerfMem . '.' . $1} * 1024;
            push @{$data->{$self->{snmp_response}->{$oid_hrSWRunName}->{$oid_hrSWRunName . '.' . $1}}->{pids}}, $1;
        }
    }

    my $i = 1;
    foreach my $name (sort { $data->{$b}->{memory} <=> $data->{$a}->{memory} } keys %$data) {
        last if ($i > $self->{option_results}->{top_num});
        last if ($data->{$name}->{memory} < $self->{option_results}->{top_size});
        
        my ($mem_value, $mem_unit) = $self->{perfdata}->change_bytes(value => $data->{$name}->{memory});
        $self->{output}->output_add(long_msg => sprintf("Top %d '%s' [pids: %s] memory usage: %s %s", $i, $name, join(", ", @{$data->{$name}->{pids}}), $mem_value, $mem_unit));
        $self->{output}->perfdata_add(label => 'top_' . $name, unit => 'B',
                                      value => $data->{$name}->{memory}, min => 0);        
        $i++;
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $extra_oids = [];
    foreach my $filter (keys %$filters) {
        if (defined($self->{option_results}->{'process_' . $filter}) && $self->{option_results}->{'process_' . $filter} ne '') {
            $filters->{$filter}->{value} = $self->{option_results}->{'process_' . $filter};

            if ($filters->{$filter}->{default} == 0) {
                push @{$extra_oids}, $filters->{$filter}->{oid};
            }
        }
        if (defined($self->{option_results}->{'regexp_' . $filter})) {
            $filters->{$filter}->{regexp} = 1;
        }
    }
    if (defined($self->{option_results}->{memory})) {
        push @{$extra_oids}, $oid_hrSWRunPerfMem;
    }
    if (defined($self->{option_results}->{cpu})) {
        push @{$extra_oids}, $oid_hrSWRunPerfCPU;
    }

    my $oids_multiple_table = [ { oid => $oid_hrSWRunStatus } ];
    if (defined($self->{option_results}->{top})) {
        push @{$oids_multiple_table}, { oid => $oid_hrSWRunName };
        push @{$oids_multiple_table}, { oid => $oid_hrSWRunPerfMem };
    }

    # First lookup on name and status
    $self->{snmp_response} = $self->{snmp}->get_multiple_table(oids => $oids_multiple_table);
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$self->{snmp_response}->{$oid_hrSWRunStatus}})) {
        $key =~ /\.([0-9]+)$/;
        my $pid = $1;
        $self->{results}->{$pid}->{status} = $map_process_status{$self->{snmp_response}->{$oid_hrSWRunStatus}->{$oid_hrSWRunStatus . '.' . $pid}};

        foreach my $filter (keys %$filters) {
            next if !defined($self->{results}->{$pid}) || $filters->{$filter}->{value} eq '' || $filters->{$filter}->{default} == 0;
            
            if ((defined($filters->{$filter}->{regexp}) && $self->{results}->{$pid}->{$filter} !~ /$filters->{$filter}->{value}/)
                || (!defined($filters->{$filter}->{regexp}) && $self->{results}->{$pid}->{$filter} ne $filters->{$filter}->{value})) {
                    delete $self->{results}->{$pid};
            }
        }
    }
    
    # Second lookup on extra oids
    if (scalar(keys %{$self->{results}}) > 0) {
        if (scalar(@$extra_oids) > 0) {
            $self->{snmp}->load(oids => $extra_oids, instances => [ keys %{$self->{results}} ]);
            $self->{snmp_response_extra} = $self->{snmp}->get_leef();

            foreach my $pid (keys %{$self->{results}}) {
                foreach my $filter (keys %$filters) {
                    next if !defined($self->{results}->{$pid}) || $filters->{$filter}->{value} eq '' || $filters->{$filter}->{default} == 1;

                    if ((defined($filters->{$filter}->{regexp}) && $self->{snmp_response_extra}->{$filters->{$filter}->{oid} . '.' . $pid} !~ /$filters->{$filter}->{value}/)
                        || (!defined($filters->{$filter}->{regexp}) && $self->{snmp_response_extra}->{$filters->{$filter}->{oid} . '.' . $pid} ne $filters->{$filter}->{value})) {
                            delete $self->{results}->{$pid};
                    } else {
                        $self->{results}->{$pid}->{$filter} = $self->{snmp_response_extra}->{$filters->{$filter}->{oid} . '.' . $pid};
                    }
                }
            }
        }
    }

    my $num_processes_match = scalar(keys(%{$self->{results}}));
    my $exit = $self->{perfdata}->threshold_check(value => $num_processes_match, 
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, 
                                                                 { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => "Number of current processes running: $num_processes_match");
    $self->{output}->perfdata_add(label => 'nbproc',
                                  value => $num_processes_match,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    # Check memory
    if (defined($self->{option_results}->{memory}) && $num_processes_match > 0) {
        my $total_memory = 0;
        foreach my $pid (keys %{$self->{results}}) {
            $total_memory += ($self->{snmp_response_extra}->{$oid_hrSWRunPerfMem . "." . $pid} * 1024);
            my ($memory_value, $memory_unit) = $self->{perfdata}->change_bytes(value => $self->{snmp_response_extra}->{$oid_hrSWRunPerfMem . '.' . $pid} * 1024);
            $self->{results}->{$pid}->{memory} = $memory_value . " " . $memory_unit;

            $exit = $self->{perfdata}->threshold_check(value => $self->{snmp_response_extra}->{$oid_hrSWRunPerfMem . '.' . $pid} * 1024, 
                                                       threshold => [ { label => 'critical-mem-each', exit_litteral => 'critical' }, 
                                                                      { label => 'warning-mem-each', exit_litteral => 'warning' } ]);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Process '%s' memory usage: %.2f %s", $pid, $memory_value, $memory_unit));
            }
        }
        
        my $exit = $self->{perfdata}->threshold_check(value => $total_memory, 
                                                      threshold => [ { label => 'critical-mem-total', exit_litteral => 'critical' }, 
                                                                     { label => 'warning-mem-total', exit_litteral => 'warning' } ]);
        my ($total_mem_value, $total_mem_unit) = $self->{perfdata}->change_bytes(value => $total_memory);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Total memory usage: %s", $total_mem_value . " " . $total_mem_unit));
        $self->{output}->perfdata_add(label => 'mem_total', unit => 'B',
                                      value => $total_memory,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-mem-total'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-mem-total'),
                                      min => 0);
                                      
        $exit = $self->{perfdata}->threshold_check(value => $total_memory / $num_processes_match, 
                                                   threshold => [ { label => 'critical-mem-avg', exit_litteral => 'critical' }, 
                                                                  { label => 'warning-mem-avg', exit_litteral => 'warning' } ]);
        my ($avg_mem_value, $avg_mem_unit) = $self->{perfdata}->change_bytes(value => $total_memory / $num_processes_match);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Average memory usage: %.2f %s", $avg_mem_value, $avg_mem_unit));
        $self->{output}->perfdata_add(label => 'mem_avg', unit => 'B',
                                      value => sprintf("%.2f", $total_memory / $num_processes_match),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-mem-avg'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-mem-avg'),
                                      min => 0);
    }

    # Check cpu
    if (defined($self->{option_results}->{cpu}) && $num_processes_match > 0) {
        my $datas = {};
        $datas->{last_timestamp} = time();

        $self->{statefile_cache}->read(statefile => "snmpstandard_" . $self->{snmp}->get_hostname() . '_' . 
                                        $self->{snmp}->get_port() . '_' . $self->{mode} . '_' . md5_hex($self->{filter4md5}));
        my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
        
        my $total_cpu = 0;
        my $checked = 0;
        foreach my $pid (keys %{$self->{results}}) {
            $datas->{'cpu_' . $pid} = $self->{snmp_response_extra}->{$oid_hrSWRunPerfCPU . "." . $pid};
            my $old_cpu = $self->{statefile_cache}->get(name => 'cpu_' . $pid);
            # No value added
            if (!defined($old_cpu) || !defined($old_timestamp)) {
                $self->{results}->{$pid}->{cpu} = 'Buffer creation...';
                next;
            }
            # Go back to zero
            if ($old_cpu > $datas->{'cpu_' . $pid}) {
                $old_cpu = 0;
            }
            my $time_delta = ($datas->{last_timestamp} - $old_timestamp);
            # At least one seconds.
            if ($time_delta == 0) {
                $time_delta = 1;
            }
            
            $total_cpu += (($datas->{'cpu_' . $pid} - $old_cpu) / $time_delta);
            $self->{results}->{$pid}->{cpu} = sprintf("%.2f %%", ($datas->{'cpu_' . $pid} - $old_cpu) / $time_delta);
            $checked = 1;
        }
        
        if ($checked == 1) {
            $exit = $self->{perfdata}->threshold_check(value => $total_cpu, threshold => [ { label => 'critical-cpu-total', exit_litteral => 'critical' }, 
                                                                                           { label => 'warning-cpu-total', exit_litteral => 'warning' } ]);
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Total CPU usage: %.2f %%", $total_cpu));
            $self->{output}->perfdata_add(label => 'cpu_total', unit => '%',
                                          value => sprintf("%.2f", $total_cpu),
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-cpu-total'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-cpu-total'),
                                          min => 0);
        }
        
        $self->{statefile_cache}->write(data => $datas);
    }
    
    $self->check_top() if (defined($self->{option_results}->{top}));

    foreach my $pid (keys %{$self->{results}}) {
        my $long_msg = sprintf("Process '%s'", $pid);
        foreach my $key (keys %{$self->{results}->{$pid}}) {
            $long_msg .= sprintf(" [%s: %s]", $key, $self->{results}->{$pid}->{$key});
        }
        $self->{output}->output_add(long_msg => $long_msg);
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system number of processes.
Can also check memory usage and cpu usage.

=over 8

=item B<--process-status>

Filter process status. Can be a regexp. 
(Default: 'running|runnable').

=item B<--process-name>

Filter process name.

=item B<--regexp-name>

Allows to use regexp to filter process 
name (with option --process-name).

=item B<--process-path>

Filter process path.

=item B<--regexp-path>

Allows to use regexp to filter process 
path (with option --process-path).

=item B<--process-args>

Filter process arguments.

=item B<--regexp-args>

Allows to use regexp to filter process 
arguments (with option --process-args).

=item B<--warning>

Threshold warning of matching processes count.

=item B<--critical>

Threshold critical of matching processes count.

=item B<--memory>

Check memory usage.

=item B<--warning-mem-each>

Threshold warning of memory 
used by each matching processes (in Bytes).

=item B<--critical-mem-each>

Threshold critical of memory 
used by each matching processes (in Bytes).

=item B<--warning-mem-total>

Threshold warning of total 
memory used by matching processes (in Bytes).

=item B<--critical-mem-total>

Threshold critical of total 
memory used by matching processes (in Bytes).

=item B<--warning-mem-avg>

Threshold warning of average 
memory used by matching processes (in Bytes).

=item B<--critical-mem-avg>

Threshold critical of average 
memory used by matching processes (in Bytes).

=item B<--cpu>

Check cpu usage. Should be used with fix processes.
If processes pid changes too much, the plugin can't compute values.

=item B<--warning-cpu-total>

Threshold warning of cpu usage for all processes (in percent).
CPU usage is in % of one cpu, so maximum can be 100% * number of CPU 
and a process can have a value greater than 100%.

=item B<--critical-cpu-total>

Threshold critical of cpu usage for all processes (in percent).
CPU usage is in % of one cpu, so maximum can be 100% * number of CPU 
and a process can have a value greater than 100%.

=item B<--top>

Enable top memory usage display.

=item B<--top-num>

Number of processes in top memory display (Default: 5).

=item B<--top-size>

Minimum memory usage to be in top memory display 
(Default: 52428800 -> 50 MB).

=back

=cut
