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

package cloud::nutanix::snmp::mode::vmusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{vm} = [
        { label => 'cpu', set => {
                key_values => [ { name => 'vmCpuUsagePercent' }, { name => 'display' } ],
                output_template => 'CPU Usage : %s %%',
                perfdatas => [
                    { label => 'cpu_usage', template => '%s', unit => '%',
                      min => 0, max => 100, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'avg-latency', set => {
                key_values => [ { name => 'vmAverageLatency' }, { name => 'display' } ],
                output_template => 'Average Latency : %s µs',
                perfdatas => [
                    { label => 'avg_latency', template => '%s', unit => 'µs',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-iops', set => {
                key_values => [ { name => 'vmReadIOPerSecond' }, { name => 'display' } ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'vmWriteIOPerSecond' }, { name => 'display' } ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', template => '%s', unit => 'iops',
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-in', set => {
                key_values => [ { name => 'vmRxBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic In : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_in', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'traffic-out', set => {
                key_values => [ { name => 'vmTxBytes', per_second => 1 }, { name => 'display' } ],
                output_template => 'Traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'traffic_out', template => '%.2f', 
                      min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
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

sub prefix_vm_output {
    my ($self, %options) = @_;

    return "Virtual machine '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    vmName                  => { oid => '.1.3.6.1.4.1.41263.10.1.3' },
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

=item B<--warning-*>

Threshold warning.
Can be: 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'traffic-in', 'traffic-out'.

=item B<--critical-*>

Threshold critical.
Can be: 'avg-latency', 'read-iops', 'write-iops',
'cpu' (%), 'traffic-in', 'traffic-out'.

=back

=cut
