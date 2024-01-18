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

package hardware::devices::nvidia::gpu::smi::mode::stats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use XML::LibXML::Simple;

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

    return "checking device gpu '" . $options{instance} . "'";
}

sub prefix_device_output {
    my ($self, %options) = @_;

    return "Device gpu '" . $options{instance} . "' ";
}

sub prefix_util_output {
    my ($self, %options) = @_;

    return 'utilization ';
}

sub prefix_fb_output {
    my ($self, %options) = @_;

    return 'frame buffer ';
}

sub prefix_bar1_output {
    my ($self, %options) = @_;

    return 'bar1 ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'devices', type => 3, cb_prefix_output => 'prefix_device_output', cb_long_output => 'device_long_output', indent_long_output => '    ', message_multiple => 'All devices are ok',
            group => [
                { name => 'util', cb_prefix_output => 'prefix_util_output', type => 0, skipped_code => { -10 => 1 } },
                { name => 'fb', type => 0, cb_prefix_output => 'prefix_fb_output', skipped_code => { -10 => 1 } },
                { name => 'bar1', type => 0, cb_prefix_output => 'prefix_bar1_output', skipped_code => { -10 => 1 } },
                { name => 'fan', type => 0, skipped_code => { -10 => 1 } },
                { name => 'temp', type => 0, skipped_code => { -10 => 1 } },
                { name => 'power', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-gpu-total', nlabel => 'devices.gpu.total.count', display_ok => 0, set => {
                key_values => [ { name => 'devices'} ],
                output_template => 'total gpu devices: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ]
            }
        }
    ];

    $self->{maps_counters}->{util} = [
        { label => 'gpu-utilization', nlabel => 'device.gpu.utilization.percentage', set => {
                key_values => [ { name => 'gpu_util' } ],
                output_template => 'gpu: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gpu-memory-utilization', nlabel => 'device.gpu.memory.utilization.percentage', set => {
                key_values => [ { name => 'mem_util' } ],
                output_template => 'memory: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gpu-encoder-utilization', nlabel => 'device.gpu.encoder.utilization.percentage', set => {
                key_values => [ { name => 'encoder_util' } ],
                output_template => 'encoder: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'gpu-decoder-utilization', nlabel => 'device.gpu.decoder.utilization.percentage', set => {
                key_values => [ { name => 'decoder_util' } ],
                output_template => 'decoder: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{fb} = [
        { label => 'fb-memory-usage', nlabel => 'device.gpu.frame_buffer.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'fb-memory-usage-free', display_ok => 0, nlabel => 'device.gpu.frame_buffer.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'fb-memory-usage-prct', display_ok => 0, nlabel => 'device.gpu.frame_buffer.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{bar1} = [
        { label => 'bar1-memory-usage', nlabel => 'device.gpu.bar1.memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'bar1-memory-usage-free', display_ok => 0, nlabel => 'device.gpu.bar1.memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'bar1-memory-usage-prct', display_ok => 0, nlabel => 'device.gpu.bar1.memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{fan} = [
        { label => 'fan-speed', nlabel => 'device.gpu.fan.speed.percentage', set => {
                key_values => [ { name => 'speed' } ],
                output_template => 'fan speed: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{temp} = [
        { label => 'temperature', nlabel => 'device.gpu.temperature.celsius', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'gpu temperature: %s C',
                perfdatas => [
                    { template => '%s', unit => 'C', label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{power} = [
        { label => 'power', nlabel => 'device.gpu.power.consumption.watt', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'power consumption: %s W',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'W', label_extra_instance => 1 }
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

sub get_bytes {
    my ($self, %options) = @_;

    return undef if ($options{value} !~ /(\d+)\s*([a-zA-Z]+)/);
    my ($value, $unit) = ($1, $2);
    if ($unit =~ /KiB*/i) {
        $value = $value * 1024;
    } elsif ($unit =~ /MiB*/i) {
        $value = $value * 1024 * 1024;
    } elsif ($unit =~ /GiB*/i) {
        $value = $value * 1024 * 1024 * 1024;
    } elsif ($unit =~ /TiB*/i) {
        $value = $value * 1024 * 1024 * 1024 * 1024;
    }

    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;
     
    my ($stdout) = $options{custom}->execute_command(
        command => 'nvidia-smi',
        command_options => '-q -x'
    );

    my $decoded;
    eval {
        $SIG{__WARN__} = sub {};
        $decoded = XMLin($stdout, KeyAttr => [], ForceArray => ['gpu']);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }

    $self->{global} = { devices => 0 };
    $self->{devices} = {};
    foreach my $entry (@{$decoded->{gpu}}) {
        my $name = $entry->{product_name} . ':' . $entry->{id};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $name . "'.", debug => 1);
            next;
        }

        $self->{devices}->{$name} = { util => {} };
        if (defined($entry->{utilization}->{gpu_util}) && $entry->{utilization}->{gpu_util} =~ /([0-9\.]+)\s*%/) {
            $self->{devices}->{$name}->{util}->{gpu_util} = $1;
        }
        if (defined($entry->{utilization}->{memory_util}) && $entry->{utilization}->{memory_util} =~ /([0-9\.]+)\s*%/) {
            $self->{devices}->{$name}->{util}->{mem_util} = $1;
        }
        if (defined($entry->{utilization}->{encoder_util}) && $entry->{utilization}->{encoder_util} =~ /([0-9\.]+)\s*%/) {
            $self->{devices}->{$name}->{util}->{encoder_util} = $1;
        }
        if (defined($entry->{utilization}->{decoder_util}) && $entry->{utilization}->{decoder_util} =~ /([0-9\.]+)\s*%/) {
            $self->{devices}->{$name}->{util}->{decoder_util} = $1;
        }
        if (defined($entry->{fb_memory_usage})) {
            my $total = $self->get_bytes(value => $entry->{fb_memory_usage}->{total});
            my $used = $self->get_bytes(value => $entry->{fb_memory_usage}->{used});
            my $free = $self->get_bytes(value => $entry->{fb_memory_usage}->{free});
            $self->{devices}->{$name}->{fb} = {
                total => $total,
                used => $used,
                free => $free,
                prct_used => $used * 100 / $total,
                prct_free => 100 - ($used * 100 / $total)
            };
        }
        if (defined($entry->{bar1_memory_usage})) {
            my $total = $self->get_bytes(value => $entry->{bar1_memory_usage}->{total});
            my $used = $self->get_bytes(value => $entry->{bar1_memory_usage}->{used});
            my $free = $self->get_bytes(value => $entry->{bar1_memory_usage}->{free});
            $self->{devices}->{$name}->{bar1} = {
                total => $total,
                used => $used,
                free => $free,
                prct_used => $used * 100 / $total,
                prct_free => 100 - ($used * 100 / $total)
            };
        }
        if (defined($entry->{fan_speed}) && $entry->{fan_speed} =~ /([0-9\.]+)\s*%/) {
            $self->{devices}->{$name}->{fan} = { speed => $1 };
        }
        if (defined($entry->{temperature}) && $entry->{temperature}->{gpu_temp} =~ /([0-9\.]+)\s*C/) {
            $self->{devices}->{$name}->{temp} = { current => $1 };
        }
        if (defined($entry->{power_readings}) && $entry->{power_readings}->{power_draw} =~ /([0-9\.]+)\s*W/) {
            $self->{devices}->{$name}->{power} = { current => $1 };
        }

        $self->{global}->{devices}++;
    }
}

1;

__END__

=head1 MODE

Check GPU statistics.

Command used: nvidia-smi -q -x

=over 8

=item B<--filter-name>

Filter gpu devices by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'devices-gpu-total',
'bar1-memory-usage', 'bar1-memory-usage-free', 'bar1-memory-usage-prct', 
'fb-memory-usage', 'fb-memory-usage-free', 'fb-memory-usage-prct',
'gpu-utilization', 'gpu-memory-utilization', 'gpu-encoder-utilization', 'gpu-decoder-utilization',
'temperature', 'fan-speed', 'power'.

=back

=cut
