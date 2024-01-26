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

package cloud::nutanix::snmp::mode::vmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub prefix_vm_output {
    my ($self, %options) = @_;

    return sprintf(
        "Virtual machine '%s' ", 
        $options{instance_value}->{display}
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "state: '%s'",
        $self->{result_values}->{vmPowerState}
    );
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my ($label, $nlabel) = ('memory_used', $self->{nlabel});
    my $value_perf = $self->{result_values}->{used};
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = (total => $self->{result_values}->{total}, cast_int => 1);

    $self->{output}->perfdata_add(
        label => $label . $extra_label, unit => 'B',
        nlabel => $nlabel,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'Memory Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_vmMemory'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_vmMemoryUsagePercent'};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{used} = $self->{result_values}->{prct_used} * $self->{result_values}->{total} / 100;
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{vm} = [
        { 
            label => 'vm-power-state', 
            type => 2, 
            critical_default => '%{vmPowerState} ne "on"', 
            set => {
                key_values => [ { name => 'vmPowerState' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'cpu', nlabel => 'vm.cpu.utilization.percentage', set => {
                key_values => [ { name => 'vmCpuUsagePercent' }, { name => 'display' } ],
                output_template => 'CPU Usage : %s %%',
                perfdatas => [
                    { label => 'cpu_usage', template => '%s', unit => '%',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ]
            }
        },
        { label => 'memory', nlabel => 'vm.memory.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'vmMemory' }, { name => 'vmMemoryUsagePercent' } ],
                threshold_use => 'prct_used',
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata')
            }
        },
        { label => 'avg-latency', nlabel => 'vm.average.io.latency.microseconds', set => {
                key_values => [ { name => 'vmAverageLatency' }, { name => 'display' } ],
                output_template => 'Average Latency : %s µs',
                perfdatas => [
                    { label => 'avg_latency', template => '%s', unit => 'µs',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'read-iops', nlabel => 'vm.read.usage.iops', set => {
                key_values => [ { name => 'vmReadIOPerSecond' }, { name => 'display' } ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'vm.write.usage.iops', set => {
                key_values => [ { name => 'vmWriteIOPerSecond' }, { name => 'display' } ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'vm.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'vmRxBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ],
            }
        },
        { label => 'traffic-out', nlabel => 'vm.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'vmTxBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

my $mapping = {
    vmName                  => { oid => '.1.3.6.1.4.1.41263.10.1.3' },
    vmPowerState            => { oid => '.1.3.6.1.4.1.41263.10.1.5' },
    vmCpuUsagePercent       => { oid => '.1.3.6.1.4.1.41263.10.1.7' },
    vmMemory                => { oid => '.1.3.6.1.4.1.41263.10.1.8' },
    vmMemoryUsagePercent    => { oid => '.1.3.6.1.4.1.41263.10.1.9' },
    vmReadIOPerSecond       => { oid => '.1.3.6.1.4.1.41263.10.1.10' },
    vmWriteIOPerSecond      => { oid => '.1.3.6.1.4.1.41263.10.1.11' },
    vmAverageLatency        => { oid => '.1.3.6.1.4.1.41263.10.1.12' },
    vmRxBytes               => { oid => '.1.3.6.1.4.1.41263.10.1.14' },
    vmTxBytes               => { oid => '.1.3.6.1.4.1.41263.10.1.15' },
};

my $oid_vmEntry = '.1.3.6.1.4.1.41263.10.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{vm} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_vmEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vmName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{vmName} = centreon::plugins::misc::trim($result->{vmName});
        $result->{vmPowerState} = centreon::plugins::misc::trim($result->{vmPowerState});
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vmName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{vmName} . "': no matching filter.", debug => 1);
            next;
        }
    
        $result->{vmRxBytes} *= 8;
        $result->{vmTxBytes} *= 8;
        $self->{vm}->{$instance} = {
            display => $result->{vmName}, 
            %$result
        };
    }

    if (scalar(keys %{$self->{vm}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No virtual machine found.");
        $self->{output}->option_exit();
    }

    $self->{cache_name} = "nutanix_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual machine usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory$'

=item B<--filter-name>

Filter virtual machine name (can be a regexp).

=item B<--warning-vm-power-state>

Set warning threshold for the virtual machine power state.
You can use the following variables: %{vmPowerState}.

=item B<--critical-vm-power-state>

Set critical threshold for the virtual machine power state.
You can use the following variables: %{vmPowerState}.

=item B<--warning-*>

Warning threshold.
Can be: 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'memory' (%s), 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Critical threshold.
Can be: 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'memory' (%s), 'traffic-in', 'traffic-out'.

=back

=cut
