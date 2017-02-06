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
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "warning-cpu-total:s"     => { name => 'warning_cpu_total', },
                                  "critical-cpu-total:s"    => { name => 'critical_cpu_total', },
                                  "warning-mem-total:s"     => { name => 'warning_mem_total', },
                                  "critical-mem-total:s"    => { name => 'critical_mem_total', },
                                  "warning-mem-avg:s"       => { name => 'warning_mem_avg', },
                                  "critical-mem-avg:s"      => { name => 'critical_mem_avg', },
                                  "process-name:s"          => { name => 'process_name', },
                                  "regexp-name"             => { name => 'regexp_name', },
                                  "process-path:s"          => { name => 'process_path', },
                                  "regexp-path"             => { name => 'regexp_path', },
                                  "process-args:s"          => { name => 'process_args', },
                                  "regexp-args"             => { name => 'regexp_args', },
                                  "process-status:s"        => { name => 'process_status', default => 'running|runnable' },
                                  "memory"                  => { name => 'memory', },
                                  "cpu"                     => { name => 'cpu', },
                                  "top"                     => { name => 'top', },
                                  "top-num:s"               => { name => 'top_num', default => 5 },
                                  "top-size:s"              => { name => 'top_size', default => 52428800 }, # 50MB
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

my $oids = {
    name => '.1.3.6.1.2.1.25.4.2.1.2', # hrSWRunName
    path => '.1.3.6.1.2.1.25.4.2.1.4', # hrSWRunPath
    args => '.1.3.6.1.2.1.25.4.2.1.5', # hrSWRunParameters (Warning: it's truncated. (128 characters))
    status => '.1.3.6.1.2.1.25.4.2.1.7', # hrSWRunStatus
};
my $oid_hrSWRunPerfMem = '.1.3.6.1.2.1.25.5.1.1.2';
my $oid_hrSWRunPerfCPU = '.1.3.6.1.2.1.25.5.1.1.1';

sub check_top {
    my ($self, %options) = @_;
    
    my %data = ();
    foreach (keys %{$self->{results}->{$oids->{name}}}) {
        if (/^$oids->{name}\.(.*)/ && 
            defined($self->{results}->{$oid_hrSWRunPerfMem}->{$oid_hrSWRunPerfMem . '.' . $1})) {
            $data{$self->{results}->{$oids->{name}}->{$_}} = 0 if (!defined($data{$self->{results}->{$oids->{name}}->{$_}}));
            $data{$self->{results}->{$oids->{name}}->{$_}} += $self->{results}->{$oid_hrSWRunPerfMem}->{$oid_hrSWRunPerfMem . '.' . $1} * 1024;
        }
    }
    
    my $i = 1;
    foreach my $name (sort { $data{$b} <=> $data{$a} } keys %data) {
        last if ($i > $self->{option_results}->{top_num});
        last if ($data{$name} < $self->{option_results}->{top_size});
        
        my ($mem_value, $amem_unit) = $self->{perfdata}->change_bytes(value => $data{$name});
        $self->{output}->output_add(long_msg => sprintf("Top %d '%s' memory usage: %s %s", $i, $name, $mem_value, $amem_unit));
        $self->{output}->perfdata_add(label => 'top_' . $name, unit => 'B',
                                      value => $data{$name},
                                      min => 0);        
        $i++;
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid2check_filter = 'status';
    # To have a better order
    foreach (('name', 'path', 'args', 'status')) {
        if (defined($self->{option_results}->{'process_' . $_}) && $self->{option_results}->{'process_' . $_} ne '') {
            $oid2check_filter = $_;
            last;
        }
    }
    # Build other
    my $mores_filters = {};
    my $more_oids = [];
    if (defined($self->{option_results}->{memory})) {
        push @{$more_oids}, $oid_hrSWRunPerfMem;
    }
    if (defined($self->{option_results}->{cpu})) {
        push @{$more_oids}, $oid_hrSWRunPerfCPU;
    }
    foreach (keys %$oids) {
        if ($_ ne $oid2check_filter && defined($self->{option_results}->{'process_' . $_}) && $self->{option_results}->{'process_' . $_} ne '') {
            push @{$more_oids}, $oids->{$_};
            $mores_filters->{$_} = 1;
        }
    }

    my $oids_multiple_table = [ { oid => $oids->{$oid2check_filter} } ];
    if (defined($self->{option_results}->{top})) {
        push @{$oids_multiple_table}, { oid => $oids->{name} };
        push @{$oids_multiple_table}, { oid => $oid_hrSWRunPerfMem };
    }
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $oids_multiple_table);
    my $result = $self->{results}->{$oids->{$oid2check_filter}};
    my $instances_keep = {};
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %{$result})) {
        my $option_val = $self->{option_results}->{'process_' . $oid2check_filter};
        
        if ($oid2check_filter eq 'status') {
            if ($map_process_status{$result->{$key}} =~ /$option_val/) {
                $key =~ /\.([0-9]+)$/;
                $instances_keep->{$1} = 1;
            }
        } elsif ((defined($self->{option_results}->{'regexp_' . $oid2check_filter}) && $result->{$key} =~ /$option_val/)
                 || (!defined($self->{option_results}->{'regexp_' . $oid2check_filter}) && $result->{$key} eq $option_val)) {
            $key =~ /\.([0-9]+)$/;
            $instances_keep->{$1} = 1;
        }
    }

    my $result2;
    my $datas = {};
    $datas->{last_timestamp} = time();
    if (scalar(keys %$instances_keep) > 0) {
        if (scalar(@$more_oids) > 0) {
            $self->{snmp}->load(oids => $more_oids, instances => [ keys %$instances_keep ]);
            $result2 = $self->{snmp}->get_leef();
        }
    
        foreach my $key (keys %$instances_keep) {
            my $value = ($oid2check_filter eq 'status') ? $map_process_status{$result->{$oids->{$oid2check_filter} . '.' . $key}} : $result->{$oids->{$oid2check_filter} . '.' . $key};       
            my $long_value = '[ ' . $oid2check_filter . ' => ' . $value . ' ]';
            my $deleted = 0;
            foreach (keys %$mores_filters) {
                my $opt_val = $self->{option_results}->{'process_' . $_};
                $value = ($_ eq 'status') ? $map_process_status{$result2->{$oids->{$_} . '.' . $key}} : $result2->{$oids->{$_} . '.' . $key};
                
                if ($_ eq 'status') {
                    if ($value !~ /$opt_val/) {
                        delete $instances_keep->{$key};
                        $deleted = 1;
                        last;
                    }
                } elsif ((defined($self->{option_results}->{'regexp_' . $_}) && $value !~ /$opt_val/)
                    || (!defined($self->{option_results}->{'regexp_' . $_}) && $value ne $opt_val)) {
                    delete $instances_keep->{$key};
                    $deleted = 1;
                    last;
                }
                
                $long_value .= ' [ ' . $_ . ' => ' . $value . ' ]';
            }
            
            if ($deleted == 0) {
                $self->{output}->output_add(long_msg => 'Process: ' . $long_value);
            }
        }
    }
    
    my $num_processes_match = scalar(keys(%$instances_keep));
    my $exit = $self->{perfdata}->threshold_check(value => $num_processes_match, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
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
        foreach my $key (keys %$instances_keep) {
            $total_memory += ($result2->{$oid_hrSWRunPerfMem . "." . $key} * 1024);
        }
        
        $exit = $self->{perfdata}->threshold_check(value => $total_memory, threshold => [ { label => 'critical-mem-total', 'exit_litteral' => 'critical' }, { label => 'warning-mem-total', exit_litteral => 'warning' } ]);
        my ($total_mem_value, $total_mem_unit) = $self->{perfdata}->change_bytes(value => $total_memory);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Total memory usage: %s", $total_mem_value . " " . $total_mem_unit));
        $self->{output}->perfdata_add(label => 'mem_total', unit => 'B',
                                      value => $total_memory,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_mem_total'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_mem_total'),
                                      min => 0);
                                      
        $exit = $self->{perfdata}->threshold_check(value => $total_memory / $num_processes_match, threshold => [ { label => 'critical-mem-avg', 'exit_litteral' => 'critical' }, { label => 'warning-mem-avg', exit_litteral => 'warning' } ]);
        my ($avg_mem_value, $avg_mem_unit) = $self->{perfdata}->change_bytes(value => $total_memory / $num_processes_match);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Average memory usage: %.2f %s", $avg_mem_value, $avg_mem_unit));
        $self->{output}->perfdata_add(label => 'mem_avg', unit => 'B',
                                      value => sprintf("%.2f", $total_memory / $num_processes_match),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_avg_total'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_avg_total'),
                                      min => 0);
    }
    
    # Check cpu
    if (defined($self->{option_results}->{cpu}) && $num_processes_match > 0) {
        $self->{hostname} = $self->{snmp}->get_hostname();
        $self->{snmp_port} = $self->{snmp}->get_port();

        $self->{statefile_cache}->read(statefile => "snmpstandard_" . $self->{hostname}  . '_' . $self->{snmp_port} . '_' . $self->{mode} . '_' . md5_hex($self->{filter4md5}));
        my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
        
        my $total_cpu = 0;
        my $checked = 0;
        foreach my $key (keys %$instances_keep) {
            $datas->{'cpu_' . $key} = $result2->{$oid_hrSWRunPerfCPU . "." . $key};
            my $old_cpu = $self->{statefile_cache}->get(name => 'cpu_' . $key);
            # No value added
            if (!defined($old_cpu) || !defined($old_timestamp)) {
                $self->{output}->output_add(long_msg => 'Buffer creation for process pid ' . $key . '...');
                next;
            }
            # Go back to zero
            if ($old_cpu > $datas->{'cpu_' . $key}) {
                $old_cpu = 0;
            }
            my $time_delta = ($datas->{last_timestamp} - $old_timestamp);
            # At least one seconds.
            if ($time_delta == 0) {
                $time_delta = 1;
            }
            
            $total_cpu += (($datas->{'cpu_' . $key} - $old_cpu) / $time_delta);
            $checked = 1;
        }
        
        if ($checked == 1) {
            $exit = $self->{perfdata}->threshold_check(value => $total_cpu, threshold => [ { label => 'critical-cpu-total', 'exit_litteral' => 'critical' }, { label => 'warning-cpu-total', exit_litteral => 'warning' } ]);
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("CPU Total Usage: %.2f %%", $total_cpu));
            $self->{output}->perfdata_add(label => 'cpu_total', unit => '%',
                                          value => sprintf("%.2f", $total_cpu),
                                          warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_cpu_total'),
                                          critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_cpu_total'),
                                          min => 0);
        }
        
        $self->{statefile_cache}->write(data => $datas);
    }
    
    $self->check_top() if (defined($self->{option_results}->{top}));
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system number of processes.
Can also check memory usage and cpu usage.

=over 8

=item B<--warning>

Threshold warning (process count).

=item B<--critical>

Threshold critical (process count).

=item B<--warning-mem-total>

Threshold warning in Bytes of total memory usage processes.

=item B<--critical-mem-total>

Threshold warning in Bytes of total memory usage processes.

=item B<--warning-mem-avg>

Threshold warning in Bytes of average memory usage processes.

=item B<--critical-mem-avg>

Threshold warning in Bytes of average memory usage processes.

=item B<--warning-cpu-total>

Threshold warning in percent of cpu usage for all processes (sum).
CPU usage is in % of one cpu, so maximum can be 100% * number of CPU 
and a process can have a value greater than 100%.

=item B<--critical-cpu-total>

Threshold critical in percent of cpu usage for all processes (sum).
CPU usage is in % of one cpu, so maximum can be 100% * number of CPU 
and a process can have a value greater than 100%.

=item B<--process-name>

Check process name.

=item B<--regexp-name>

Allows to use regexp to filter process name (with option --process-name).

=item B<--process-path>

Check process path.

=item B<--regexp-path>

Allows to use regexp to filter process path (with option --process-path).

=item B<--process-args>

Check process args.

=item B<--regexp-args>

Allows to use regexp to filter process args (with option --process-args).

=item B<--process-status>

Check process status (Default: 'running|runnable'). Can be a regexp.

=item B<--memory>

Check memory.

=item B<--cpu>

Check cpu usage. Should be used with fix processes.
if processes pid changes too much, the plugin can compute values.

=item B<--top>

Enable top memory usage display.

=item B<--top-num>

Number of processes in the top (Default: 5).

=item B<--top-size>

Minimum memory usage to be in the top (Default: 52428800 -> 50 MB).

=back

=cut
