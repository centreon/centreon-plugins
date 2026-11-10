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

package apps::incus::restapi::mode::instanceusage;

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:counters :values);

# GET /1.0/instances?recursion=2 state of a running instance, shortened:
# {"cpu":{"usage":3637691016,"allocated_time":4000000000},
#  "memory":{"usage":73248768,"total":12297557},
#  "disk":{"root":{"usage":502239232,"total":502239232}},
#  "network":{"lo":{"counters":{"bytes_received":192021,"bytes_sent":10888579}},
#             "vethbbcd39c7":{"counters":{"bytes_received":192021,"bytes_sent":10888579}}}}
# InstanceStateCPU.usage is a nanosecond counter.
# InstanceStateCPU.allocated_time is the CPU time available per second, in nanoseconds.
# percentage = rate(usage) / allocated_time * 100
# allocated_time of 0 is not a percentage of zero: the API uses it when the
# limit is unset, so the counter is skipped (NO_VALUE) instead of dividing.
# The interface lo is the instance loopback, not a host-facing interface.
# Source: https://github.com/lxc/incus/blob/main/doc/rest-api.yaml (InstanceStateCPU)

sub instance_id {
    my ($instance) = @_;

    return join('/', map { defined($_) ? $_ : '' } ($instance->{project}, $instance->{name}, $instance->{location}));
}

sub cpu_percent {
    my (%args) = @_;

    my $allocated_time = $args{allocated_time};
    if (!defined($allocated_time) || $allocated_time == 0) {
        return undef;
    }
    return undef if (!defined($args{usage_prev}) || !defined($args{usage_now}) || !defined($args{delta_time}) || $args{delta_time} <= 0);
    my $rate = ($args{usage_now} - $args{usage_prev}) / $args{delta_time};
    return $rate / $allocated_time * 100;
}

sub usage_percent {
    my ($usage, $total) = @_;

    return undef if (!defined($total) || $total <= 0 || !defined($usage));
    return ($usage / $total) * 100;
}

sub network_rate {
    my (%args) = @_;

    return undef if (!defined($args{usage_prev}) || !defined($args{usage_now}) || !defined($args{delta_time}) || $args{delta_time} <= 0);
    return ($args{usage_now} - $args{usage_prev}) / $args{delta_time};
}

sub interface_ignored {
    my ($name) = @_;

    return defined($name) && $name eq 'lo';
}

sub usage_selection {
    my ($instances) = @_;

    my $selected = { instances => {}, disks => {}, networks => {} };
    foreach my $instance (@{$instances // []}) {
        next if (!defined($instance->{status}) || $instance->{status} ne 'Running');

        my $id = instance_id($instance);
        my $display = defined($instance->{name}) ? $instance->{name} : $id;
        my $state = (ref($instance->{state}) eq 'HASH') ? $instance->{state} : {};
        my $cpu = (ref($state->{cpu}) eq 'HASH') ? $state->{cpu} : {};
        my $memory = (ref($state->{memory}) eq 'HASH') ? $state->{memory} : {};
        my $entry = { display => $display };
        $entry->{usage} = $cpu->{usage} if (defined($cpu->{usage}));
        $entry->{allocated_time} = $cpu->{allocated_time} if (defined($cpu->{allocated_time}));
        $entry->{memory_usage} = $memory->{usage} if (defined($memory->{usage}));
        my $memory_prct = usage_percent($memory->{usage}, $memory->{total});
        $entry->{memory_prct} = $memory_prct if (defined($memory_prct));
        $selected->{instances}->{$id} = $entry;

        my $disks = (ref($state->{disk}) eq 'HASH') ? $state->{disk} : {};
        foreach my $disk (sort keys %$disks) {
            my $info = (ref($disks->{$disk}) eq 'HASH') ? $disks->{$disk} : {};
            my $disk_entry = { display => $display . '/' . $disk };
            $disk_entry->{disk_usage} = $info->{usage} if (defined($info->{usage}));
            my $disk_prct = usage_percent($info->{usage}, $info->{total});
            $disk_entry->{disk_prct} = $disk_prct if (defined($disk_prct));
            $selected->{disks}->{$id . '/' . $disk} = $disk_entry;
        }

        my $networks = (ref($state->{network}) eq 'HASH') ? $state->{network} : {};
        foreach my $iface (sort keys %$networks) {
            next if (interface_ignored($iface));
            my $info = (ref($networks->{$iface}) eq 'HASH') ? $networks->{$iface} : {};
            my $counters = (ref($info->{counters}) eq 'HASH') ? $info->{counters} : {};
            my $net_entry = { display => $display . '/' . $iface };
            $net_entry->{bytes_received} = $counters->{bytes_received} if (defined($counters->{bytes_received}));
            $net_entry->{bytes_sent} = $counters->{bytes_sent} if (defined($counters->{bytes_sent}));
            $selected->{networks}->{$id . '/' . $iface} = $net_entry;
        }
    }
    return $selected;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;
    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'summary', type => COUNTER_TYPE_GLOBAL, prefix_output => 'instances ' },
        { name => 'instance', type => COUNTER_TYPE_INSTANCE, prefix_output => "instance '%{display}' ", message_multiple => 'all instance usage are ok', skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } },
        { name => 'disk', type => COUNTER_TYPE_INSTANCE, prefix_output => "disk '%{display}' ", message_multiple => 'all instance disks are ok', skipped_code => { NO_VALUE() => 1 } },
        { name => 'network', type => COUNTER_TYPE_INSTANCE, prefix_output => "network '%{display}' ", message_multiple => 'all instance networks are ok', skipped_code => { NO_VALUE() => 1, BUFFER_CREATION() => 1 } }
    ];

    $self->{maps_counters}->{summary} = [
        { label => 'running', nlabel => 'incus.instances.running.count', set => {
                key_values => [ { name => 'running' } ],
                output_template => 'running: %s',
                perfdatas => [ { template => '%d', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{instance} = [
        { label => 'cpu', nlabel => 'incus.instance.cpu.utilization.percentage', set => {
                key_values => [ { name => 'usage', diff => 1 }, { name => 'allocated_time' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_cpu_calc'),
                output_template => 'cpu: %.2f %%',
                output_use => 'prct',
                threshold_use => 'prct',
                perfdatas => [ { value => 'prct', template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'memory', nlabel => 'incus.instance.memory.usage.bytes', set => {
                key_values => [ { name => 'memory_usage' }, { name => 'display' } ],
                output_template => 'memory used: %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'memory-prct', nlabel => 'incus.instance.memory.usage.percentage', set => {
                key_values => [ { name => 'memory_prct' }, { name => 'display' } ],
                output_template => 'memory: %.2f %%',
                output_use => 'memory_prct',
                perfdatas => [ { value => 'memory_prct', template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'disk', nlabel => 'incus.instance.disk.usage.bytes', set => {
                key_values => [ { name => 'disk_usage' }, { name => 'display' } ],
                output_template => 'disk used: %s %s',
                output_change_bytes => 1,
                perfdatas => [ { template => '%s', min => 0, unit => 'B', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'disk-prct', nlabel => 'incus.instance.disk.usage.percentage', set => {
                key_values => [ { name => 'disk_prct' }, { name => 'display' } ],
                output_template => 'disk: %.2f %%',
                output_use => 'disk_prct',
                perfdatas => [ { value => 'disk_prct', template => '%.2f', min => 0, unit => '%', label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];

    $self->{maps_counters}->{network} = [
        { label => 'traffic-in', nlabel => 'incus.instance.network.in.bytespersecond', set => {
                key_values => [ { name => 'bytes_received', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_network_calc'),
                closure_custom_calc_extra_options => { field => 'bytes_received' },
                output_template => 'traffic in: %s %s/s',
                output_use => 'rate',
                threshold_use => 'rate',
                output_change_bytes => 2,
                perfdatas => [ { value => 'rate', template => '%.2f', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' } ]
            }
        },
        { label => 'traffic-out', nlabel => 'incus.instance.network.out.bytespersecond', set => {
                key_values => [ { name => 'bytes_sent', diff => 1 }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_network_calc'),
                closure_custom_calc_extra_options => { field => 'bytes_sent' },
                output_template => 'traffic out: %s %s/s',
                output_use => 'rate',
                threshold_use => 'rate',
                output_change_bytes => 2,
                perfdatas => [ { value => 'rate', template => '%.2f', min => 0, unit => 'B/s', label_extra_instance => 1, instance_use => 'display' } ]
            }
        }
    ];
}

sub custom_cpu_calc {
    my ($self, %options) = @_;

    my $id = $self->{instance};
    my $percent = cpu_percent(
        usage_now => $options{new_datas}->{$id . '_usage'},
        usage_prev => $options{old_datas}->{$id . '_usage'},
        delta_time => $options{delta_time},
        allocated_time => $options{new_datas}->{$id . '_allocated_time'}
    );
    $self->{result_values}->{display} = $options{new_datas}->{$id . '_display'};
    return NO_VALUE() if (!defined($percent));
    $self->{result_values}->{prct} = $percent;
    return 0;
}

sub custom_network_calc {
    my ($self, %options) = @_;

    my $id = $self->{instance};
    my $field = $options{extra_options}->{field};
    my $rate = network_rate(
        usage_now => $options{new_datas}->{$id . '_' . $field},
        usage_prev => $options{old_datas}->{$id . '_' . $field},
        delta_time => $options{delta_time}
    );
    $self->{result_values}->{display} = $options{new_datas}->{$id . '_display'};
    return NO_VALUE() if (!defined($rate));
    $self->{result_values}->{rate} = $rate;
    return 0;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metadata = $options{custom}->instances(recursion => 2);
    my $instances = $options{custom}->filter_records(records => $metadata, name_key => 'name');
    my $selected = usage_selection($instances);
    my $running = 0;
    $running++ foreach (keys %{$selected->{instances}});

    $self->{summary} = { running => $running };
    $self->{instance} = $selected->{instances};
    $self->{disk} = $selected->{disks};
    $self->{network} = $selected->{networks};
    $self->{cache_name} = 'incus_instance_usage_' . $options{custom}->cache_id() . '_' . md5_hex(
        ($self->{option_results}->{filter_name} // '') . "\0" . ($self->{option_results}->{exclude_name} // '')
    );
}

1;

__END__

=head1 MODE

Check CPU, memory, disk and network of running instances from
GET /1.0/instances?recursion=2. Stopped instances are not included.
The interface lo is ignored.

CPU usage is a nanosecond counter. allocated_time is the CPU time available
per second, in nanoseconds. The percentage is rate(usage) / allocated_time * 100,
using the Centreon differential counter. No percentage is published when
allocated_time is absent or 0. The first check has no previous sample, so the
CPU percentage and the network rate are skipped (buffer creation) instead of
being published.

Memory and disk are bytes. A percentage is published only when total is greater
than 0. Thresholds are empty by default: nothing is alerted, perfdata are still
published.

=over 8

=item B<--warning-running>

Warning threshold for the number of running instances.

=item B<--critical-running>

Critical threshold for the number of running instances.

=item B<--warning-cpu>

Warning threshold for the CPU usage of an instance, in percent.

=item B<--critical-cpu>

Critical threshold for the CPU usage of an instance, in percent.

=item B<--warning-memory>

Warning threshold for the memory used by an instance, in bytes.

=item B<--critical-memory>

Critical threshold for the memory used by an instance, in bytes.

=item B<--warning-memory-prct>

Warning threshold for the memory used by an instance, in percent.

=item B<--critical-memory-prct>

Critical threshold for the memory used by an instance, in percent.

=item B<--warning-disk>

Warning threshold for the disk used by an instance disk, in bytes.

=item B<--critical-disk>

Critical threshold for the disk used by an instance disk, in bytes.

=item B<--warning-disk-prct>

Warning threshold for the disk used by an instance disk, in percent.

=item B<--critical-disk-prct>

Critical threshold for the disk used by an instance disk, in percent.

=item B<--warning-traffic-in>

Warning threshold for the incoming traffic of an interface, in bytes per second.

=item B<--critical-traffic-in>

Critical threshold for the incoming traffic of an interface, in bytes per second.

=item B<--warning-traffic-out>

Warning threshold for the outgoing traffic of an interface, in bytes per second.

=item B<--critical-traffic-out>

Critical threshold for the outgoing traffic of an interface, in bytes per second.

=back

=cut
