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

package cloud::nutanix::snmp::mode::hypervisorusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'memory_used';
    my $value_perf = $self->{result_values}->{used};
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = (total => $self->{result_values}->{total}, cast_int => 1);

    $self->{output}->perfdata_add(
        label => $label . $extra_label, unit => 'B',
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
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
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_hypervisorMemory'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_hypervisorMemoryUsagePercent'};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{used} = $self->{result_values}->{prct_used} * $self->{result_values}->{total} / 100;
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'hypervisor', type => 1, cb_prefix_output => 'prefix_hypervisor_output', message_multiple => 'All hypervisors are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{hypervisor} = [
        { label => 'cpu', set => {
                key_values => [ { name => 'hypervisorCpuUsagePercent' }, { name => 'display' } ],
                output_template => 'CPU Usage : %s %%',
                perfdatas => [
                    { label => 'cpu_usage', value => 'hypervisorCpuUsagePercent', template => '%s', unit => '%',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'memory', set => {
                key_values => [ { name => 'display' }, { name => 'hypervisorMemory' }, { name => 'hypervisorMemoryUsagePercent' } ],
                threshold_use => 'prct_used',
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
            }
        },
        { label => 'avg-latency', set => {
                key_values => [ { name => 'hypervisorAverageLatency' }, { name => 'display' } ],
                output_template => 'Average Latency : %s µs',
                perfdatas => [
                    { label => 'avg_latency', value => 'hypervisorAverageLatency', template => '%s', unit => 'µs',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'hypervisorReadIOPerSecond' }, { name => 'display' } ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', value => 'hypervisorReadIOPerSecond', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'hypervisorWriteIOPerSecond' }, { name => 'display' } ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', value => 'hypervisorWriteIOPerSecond', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'vm-count', set => {
                key_values => [ { name => 'hypervisorVmCount' }, { name => 'display' } ],
                output_template => 'VM Count : %s',
                perfdatas => [
                    { label => 'vm_count', value => 'hypervisorVmCount', template => '%s',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub prefix_hypervisor_output {
    my ($self, %options) = @_;

    return "Hypervisor '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    hypervisorName                  => { oid => '.1.3.6.1.4.1.41263.9.1.3' },
    hypervisorVmCount               => { oid => '.1.3.6.1.4.1.41263.9.1.4' },
    hypervisorCpuUsagePercent       => { oid => '.1.3.6.1.4.1.41263.9.1.6' },
    hypervisorMemory                => { oid => '.1.3.6.1.4.1.41263.9.1.7' },
    hypervisorMemoryUsagePercent    => { oid => '.1.3.6.1.4.1.41263.9.1.8' },
    hypervisorReadIOPerSecond       => { oid => '.1.3.6.1.4.1.41263.9.1.9' },
    hypervisorWriteIOPerSecond      => { oid => '.1.3.6.1.4.1.41263.9.1.10' },
    hypervisorAverageLatency        => { oid => '.1.3.6.1.4.1.41263.9.1.11' },
};

my $oid_hypervisorEntry = '.1.3.6.1.4.1.41263.9.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    $self->{hypervisor} = {};
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_hypervisorEntry,
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{hypervisorName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $result->{hypervisorName} = centreon::plugins::misc::trim($result->{hypervisorName});
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{hypervisorName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{hypervisorName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{hypervisor}->{$instance} = {
            display => $result->{hypervisorName}, 
            %$result,
        };
    }

    if (scalar(keys %{$self->{hypervisor}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No hypervisor found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check hypervisor usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory$'

=item B<--filter-name>

Filter hypervisor name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'memory' (%), 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'vm-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'memory' (%), 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'vm-count'.

=back

=cut
