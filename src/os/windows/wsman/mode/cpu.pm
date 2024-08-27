#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package os::windows::wsman::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_cpu_avg_calc {
    my ($self, %options) = @_;

    my ($skipped, $buffer) = (1, 1);
    my ($count, $total_cpu) = (0, 0);

    foreach (keys %{$options{new_datas}}) {
        if (/^(.*?cpu\d+)_PercentProcessorTime/) {
            my $prefix = $1;
            $skipped = 0;
            next if (!defined($options{old_datas}->{$_}));
            $buffer = 0;
	    if($options{old_datas}->{$prefix . '_PercentProcessorTime'} > $options{new_datas}->{$prefix . '_PercentProcessorTime'}) {
                $options{old_datas}->{$prefix . '_PercentProcessorTime'} = 0;
	    }
	    if($options{old_datas}->{$prefix . '_Timestamp_Sys100NS'} > $options{new_datas}->{$prefix . '_Timestamp_Sys100NS'}) {
		$options{old_datas}->{$prefix . '_Timestamp_Sys100NS'} = 0;
	    }

            #
            #Cal Method ref: http://technet.microsoft.com/en-us/library/cc757283%28WS.10%29.aspx
            #
            my $cpu_core = (1 - ( $options{new_datas}->{$prefix . '_PercentProcessorTime'} - $options{old_datas}->{$prefix . '_PercentProcessorTime'} ) /
                 ( $options{new_datas}->{$prefix . '_Timestamp_Sys100NS'} - $options{old_datas}->{$prefix . '_Timestamp_Sys100NS'} ) ) * 100;
            if ($cpu_core > 0) {
                $total_cpu += $cpu_core;
            }
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

    #
    #Core Calc: (1 - (270377812500 - 247044062500) /
    #                           (132846755243261461 - 132846731625406368)  ) * 100 =  1.20292504074261
    #
    my $core_usage = (1 - ( $options{new_datas}->{$self->{instance} . '_PercentProcessorTime'} - $options{old_datas}->{$self->{instance} . '_PercentProcessorTime'} ) /
        ( $options{new_datas}->{$self->{instance} . '_Timestamp_Sys100NS'} - $options{old_datas}->{$self->{instance} . '_Timestamp_Sys100NS'} ) ) * 100;
    $self->{result_values}->{prct_used} = $core_usage;
    
    if ($core_usage < 0) {
        $self->{result_values}->{prct_used} = 0;
    } else {
        $self->{result_values}->{prct_used} = $core_usage;
    }

    return 0;
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{display} . "' ";
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
                    { value => 'prct_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu_core} = [
        { label => 'core', nlabel => 'core.cpu.utilization.percentage', set => {
                key_values => [
                    { name => 'PercentProcessorTime', diff => 1 }, { name => 'Timestamp_Sys100NS', diff => 1 }, { name => 'display' }
                ],
                closure_custom_calc => $self->can('custom_cpu_core_calc'),
                output_template => 'usage: %.2f %%',
                output_use => 'prct_used', threshold_use => 'prct_used',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
 
    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => "select Name,PercentProcessorTime,Timestamp_Sys100NS from Win32_PerfRawData_PerfOS_Processor where Name != '_Total'",
        result_type => 'array'
    );

    $self->{cpu_avg} = {};
    $self->{cpu_core} = {};
    foreach (@$results) {
       my $cpu_number = $_->{Name};

       $self->{cpu_core}->{$cpu_number} = {
           display => $cpu_number,
           PercentProcessorTime => $_->{PercentProcessorTime},
           Timestamp_Sys100NS => $_->{Timestamp_Sys100NS}
       };
       $self->{cpu_avg}->{'cpu' . $cpu_number . '_PercentProcessorTime'} = $_->{PercentProcessorTime};
       $self->{cpu_avg}->{'cpu' . $cpu_number . '_Timestamp_Sys100NS'} = $_->{Timestamp_Sys100NS};
    }

    $self->{cache_name} = 'windows_wsman_' . $options{wsman}->get_hostname() . '_' . $options{wsman}->get_port  . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Monitor the processor usage.

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
