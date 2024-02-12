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

package network::symbol::wing::snmp::mode::systems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_memory_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        "memory usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub device_long_output {
    my ($self, %options) = @_;

    return "checking device '" . $options{instance_value}->{name} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device '" . $options{instance_value}->{name} . "' ";
}

sub prefix_cpu_output {
    my ($self, %options) = @_;

    return 'cpu average usage: ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'cpu', type => 0, cb_prefix_output => 'prefix_cpu_output', skipped_code => { -10 => 1 } },
                { name => 'memory', type => 0, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-total', nlabel => 'devices.total.count', display_ok => 0, set => {
                key_values => [ { name => 'devices'} ],
                output_template => 'total devices: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ]
            }
        }
    ];

    $self->{maps_counters}->{cpu} = [
        { label => 'cpu-utilization-1m', nlabel => 'cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'cpu_load1' } ],
                output_template => '%.2f %% (1m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cpu-utilization-5m', nlabel => 'cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'cpu_load5' } ],
                output_template => '%.2f %% (5m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'cpu-utilization-15m', nlabel => 'cpu.utilization.15m.percentage', set => {
                key_values => [ { name => 'cpu_load15' } ],
                output_template => '%.2f %% (15m)',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'device.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'device.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'device.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    mem_free   => { oid => '.1.3.6.1.4.1.388.50.1.4.2.2.1.1.1' }, # wingStatsDevSysInfoFreeMem
    mem_total  => { oid => '.1.3.6.1.4.1.388.50.1.4.2.2.1.1.2' }, # wingStatsDevSysInfoTotalMem
    cpu_load1  => { oid => '.1.3.6.1.4.1.388.50.1.4.2.2.1.1.8' }, # wingStatsDevSysInfoLoadLimitS0
    cpu_load5  => { oid => '.1.3.6.1.4.1.388.50.1.4.2.2.1.1.9' }, # wingStatsDevSysInfoLoadLimitS1
    cpu_load15 => { oid => '.1.3.6.1.4.1.388.50.1.4.2.2.1.1.10' } # wingStatsDevSysInfoLoadLimitS2
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hostname = '.1.3.6.1.4.1.388.50.1.4.2.1.1.3'; # wingStatsDevHostname
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_hostname,
        nothing_quit => 1
    );

    $self->{devices} = {};
    foreach (keys %$snmp_result) {
        /^$oid_hostname\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $snmp_result->{$_} . "'.", debug => 1);
            next;
        }

        $self->{devices}->{ $snmp_result->{$_} } = {
            name => $snmp_result->{$_},
            instance => $instance
        };
    }

    $self->{global} = { devices => scalar(keys %{$self->{devices}}) };

    return if (scalar(keys %{$self->{devices}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_->{instance}, values(%{$self->{devices}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{devices}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{devices}->{$_}->{instance});

        $self->{devices}->{$_}->{cpu} = {
            cpu_load1 => $result->{cpu_load1} / 10,
            cpu_load5 => $result->{cpu_load5} / 10,
            cpu_load15 => $result->{cpu_load15} / 10
        };
        $result->{mem_free} *= 1024;
        $result->{mem_total} *= 1024;
        $self->{devices}->{$_}->{memory} = {
            free => $result->{mem_free},
            total => $result->{mem_total},
            used => $result->{mem_total} - $result->{mem_free}
        };
        $self->{devices}->{$_}->{memory}->{prct_free} = $result->{mem_free} * 100 / $result->{mem_total};
        $self->{devices}->{$_}->{memory}->{prct_used} = 100 - $self->{devices}->{$_}->{memory}->{prct_free};
    }
}

1;

__END__

=head1 MODE

Check systems.

=over 8

=item B<--filter-name>

Filter devices by device hostname (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-total',
'memory-usage-prct', 'memory-usage', 'memory-usage-free',
'cpu-utilization-1m', 'cpu-utilization-5m', 'cpu-utilization-15m'.

=back

=cut
