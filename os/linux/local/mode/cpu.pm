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

package os::linux::local::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_cpu_avg_calc {
    my ($self, %options) = @_;

    my ($skipped, $buffer) = (1, 1);
    my ($count, $total_cpu) = (0, 0);
    foreach (keys %{$options{new_datas}}) {
        if (/^(.*?cpu\d+)_idle/) {
            my $prefix = $1;
            $skipped = 0;
            next if (!defined($options{old_datas}->{$_}));
            $buffer = 0;

            my ($old_total, $old_cpu_idle) = (0, 0);
            if ($options{new_datas}->{$_} > $options{old_datas}->{$_}) {
                $old_total = $options{old_datas}->{$_} + $options{old_datas}->{$prefix . '_system'} + 
                    $options{old_datas}->{$prefix . '_user'} + $options{old_datas}->{$prefix . '_iowait'};
                $old_cpu_idle = $options{old_datas}->{$_};
            }
            my $total_elapsed = ($options{new_datas}->{$_} + $options{new_datas}->{$prefix . '_system'} + 
                $options{new_datas}->{$prefix . '_user'} + $options{new_datas}->{$prefix . '_iowait'}) -
                $old_total;
            if ($total_elapsed == 0) {
                $self->{error_msg} = 'no new values for cpu counters';
                return -12;
            }

            my $idle_elapsed = $options{new_datas}->{$_} - $old_cpu_idle;
            $total_cpu += 100 - (100 * $idle_elapsed / $total_elapsed);
            $count++;
        }
    }

    return -10 if ($skipped == 1);
    if ($buffer == 1) {
        $self->{error_msg} = "Buffer creation";
        return -1;
    }

    $self->{result_values}->{prct_used} = $total_cpu / $count;
    return 0;
}

sub custom_cpu_core_calc {
    my ($self, %options) = @_;

    my ($old_total, $old_cpu_idle) = (0, 0);
    if ($options{new_datas}->{$self->{instance} . '_idle'} > $options{old_datas}->{$self->{instance} . '_idle'}) {
        $old_total = $options{old_datas}->{$self->{instance} . '_idle'} + $options{old_datas}->{$self->{instance} . '_system'} + 
            $options{old_datas}->{$self->{instance} . '_user'} + $options{old_datas}->{$self->{instance} . '_iowait'};
        $old_cpu_idle = $options{old_datas}->{$self->{instance} . '_idle'};
    }
    my $total_elapsed = ($options{new_datas}->{$self->{instance} . '_idle'} + $options{new_datas}->{$self->{instance} . '_system'} + 
        $options{new_datas}->{$self->{instance} . '_user'} + $options{new_datas}->{$self->{instance} . '_iowait'}) -
        $old_total;
    if ($total_elapsed == 0) {
        $self->{error_msg} = 'no new values for cpu counters';
        return -12;
    }

    my $idle_elapsed = $options{new_datas}->{$self->{instance} . '_idle'} - $old_cpu_idle;
    $self->{result_values}->{prct_used} = 100 - (100 * $idle_elapsed / $total_elapsed);

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cpu_avg', type => 0 },
        { name => 'cpu_core', type => 1, cb_prefix_output => 'prefix_cpu_core_output' }
    ];

    $self->{maps_counters}->{cpu_avg} = [
        { label => 'average', nlabel => 'cpu.utilization.percentage', set => {
                key_values => [],
                closure_custom_calc => $self->can('custom_cpu_avg_calc'),
                manual_keys => 1, 
                output_template => 'CPU(s) average usage is %.2f %%',
                output_use => 'prct_used', threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'total_cpu_avg', value => 'prct_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [
                    { name => 'idle', diff => 1 }, { name => 'user', diff => 1 }, 
                    { name => 'system', diff => 1 }, { name => 'iowait', diff => 1 }, { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_cpu_core_calc'),
                output_template => 'usage : %.2f %%',
                output_use => 'prct_used', threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'cpu', value => 'prct_used', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'cat',
        command_options => '/proc/stat 2>&1'
    );

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};
    foreach (split(/\n/, $stdout)) {
        next if (!/cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
        my $cpu_number = $1;
        
        $self->{cpu_core}->{$cpu_number} = {
            display => $cpu_number,
            idle => $5,
            system => $4,
            user => $2,
            iowait => $6
        };
        $self->{cpu_avg}->{'cpu' . $cpu_number . '_idle'} = $5;
        $self->{cpu_avg}->{'cpu' . $cpu_number . '_system'} = $4;
        $self->{cpu_avg}->{'cpu' . $cpu_number . '_user'} = $2;
        $self->{cpu_avg}->{'cpu' . $cpu_number . '_iowait'} = $6;
    }
 
    $self->{cache_name} = 'cache_linux_local_' . $options{custom}->get_identifier()  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check system CPUs (need '/proc/stat' file).
Command used: cat /proc/stat 2>&1

=over 8

=item B<--warning-average>

Warning threshold average CPU utilization. 

=item B<--critical-average>

Critical  threshold average CPU utilization. 

=item B<--warning-core>

Warning thresholds for each CPU core

=item B<--critical-core>

Critical thresholds for each CPU core

=back

=cut
