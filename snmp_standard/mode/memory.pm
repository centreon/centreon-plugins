#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Ram Total: %s %s Used (-buffers/cache): %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_absolute}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_absolute}),
        $self->{result_values}->{prct_used_absolute},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_absolute}),
        $self->{result_values}->{prct_free_absolute});
    return $msg;
}

sub custom_swap_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("Swap Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)",
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_absolute}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_absolute}),
        $self->{result_values}->{prct_used_absolute},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_absolute}),
        $self->{result_values}->{prct_free_absolute});
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ram', type => 0, skipped_code => { -10 => 1 } },
        { name => 'swap', type => 0, message_separator => ' - ', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{ram} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', value => 'used_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'free', value => 'free_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'used_prct', value => 'prct_used_absolute', template => '%.2f', min => 0, max => 100,
                      unit => '%' },
                ],
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'memBuffer' } ],
                output_template => 'Buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'buffer', value => 'memBuffer_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'cached', nlabel => 'memory.cached.bytes', set => {
                key_values => [ { name => 'memCached' } ],
                output_template => 'Cached: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'cached', value => 'memCached_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
        { label => 'shared', nlabel => 'memory.shared.bytes', set => {
                key_values => [ { name => 'memShared' } ],
                output_template => 'Shared: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'shared', value => 'memShared_absolute', template => '%d',
                      min => 0, unit => 'B' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{swap} = [
        { label => 'swap', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap', value => 'used_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'swap-free', display_ok => 0, nlabel => 'swap.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_swap_output'),
                perfdatas => [
                    { label => 'swap_free', value => 'free_absolute', template => '%d', min => 0, max => 'total_absolute',
                      unit => 'B', cast_int => 1 },
                ],
            }
        },
        { label => 'swap-prct', display_ok => 0, nlabel => 'swap.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'swap_prct', value => 'prct_used_absolute', template => '%.2f', min => 0, max => 100,
                      unit => '%' },
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
        'units:s'   => { name => 'units', default => '%' },
        'free'      => { name => 'free' },
        'swap'      => { name => 'check_swap' },
    });
    
    return $self;
}

sub compat_threshold_counter {
    my ($self, %options) = @_;

    foreach ('warning', 'critical') {
        next if (!defined($options{option_results}->{$_ . '-' . $options{compat}->{th}}) || $options{option_results}->{$_ . '-' . $options{compat}->{th}} eq '');
        if (defined($options{compat}->{free})) {
            $options{option_results}->{$_ . '-' . $options{compat}->{th} . '-free'} = $options{option_results}->{$_ . '-' . $options{compat}->{th}};
            $options{option_results}->{$_ . '-' . $options{compat}->{th}} = undef;
        } elsif (defined($options{compat}->{units}) && $options{compat}->{units} eq '%') {
            $options{option_results}->{$_ . '-' . $options{compat}->{th} . '-prct'} = $options{option_results}->{$_ . '-' . $options{compat}->{th}};
            $options{option_results}->{$_ . '-' . $options{compat}->{th}} = undef;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    # Compatibility
    $self->compat_threshold_counter(%options, compat => { th => 'usage', units => $options{option_results}->{units}, free => $options{option_results}->{free}});
    $self->compat_threshold_counter(%options, compat => { th => 'swap', units => $options{option_results}->{units}, free => $options{option_results}->{free}});
    $self->SUPER::check_options(%options);
}

my $mapping = {
    memTotalSwap => { oid => '.1.3.6.1.4.1.2021.4.3' },
    memAvailSwap => { oid => '.1.3.6.1.4.1.2021.4.4' },
    memTotalReal => { oid => '.1.3.6.1.4.1.2021.4.5' },
    memAvailReal => { oid => '.1.3.6.1.4.1.2021.4.6' },
    memTotalFree => { oid => '.1.3.6.1.4.1.2021.4.11' },
    memShared => { oid => '.1.3.6.1.4.1.2021.4.13' },
    memBuffer => { oid => '.1.3.6.1.4.1.2021.4.14' },
    memCached => { oid => '.1.3.6.1.4.1.2021.4.15' },
};

my $oid_memory = '.1.3.6.1.4.1.2021.4';

sub memory_calc {
    my ($self, %options) = @_;

    my $available = ($options{result}->{memAvailReal}) ? $options{result}->{memAvailReal} * 1024 : 0;
    my $total = ($options{result}->{memTotalReal}) ? $options{result}->{memTotalReal} * 1024 : 0;
    my $buffer = ($options{result}->{memBuffer}) ? $options{result}->{memBuffer} * 1024 : 0;
    my $cached = ($options{result}->{memCached}) ? $options{result}->{memCached} * 1024 : 0;
    my ($used, $free, $prct_used, $prct_free) = (0, 0, 0, 0);

    if ($total != 0) {
        $used = $total - $available - $buffer - $cached;
        $free = $total - $used;
        $prct_used = $used * 100 / $total;
        $prct_free = 100 - $prct_used;
    }
    
    $self->{ram} = {
        total => $total,
        used => $used,
        free => $free,
        prct_used => $prct_used,
        prct_free => $prct_free,
        memShared => ($options{result}->{memShared}) ? $options{result}->{memShared} * 1024 : 0,
        memBuffer => $buffer,
        memCached => $cached,
    };
}

sub swap_calc {
    my ($self, %options) = @_;

    my $free = ($options{result}->{memAvailSwap}) ? $options{result}->{memAvailSwap} * 1024 : 0;
    my $total = ($options{result}->{memTotalSwap}) ? $options{result}->{memTotalSwap} * 1024 : 0;
    my ($used, $prct_used, $prct_free) = (0, 0, 0, 0);

    if ($total != 0) {
        $used = $total - $free;
        $prct_used = $used * 100 / $total;
        $prct_free = 100 - $prct_used;
    }

    $self->{swap} = {
        total => $total,
        used => $used,
        free => $free,
        prct_used => $prct_used,
        prct_free => $prct_free,
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{snmp}->get_table(oid => $oid_memory, end => $mapping->{memCached}->{oid});
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => 0);

    $self->memory_calc(result => $result);
    if (defined($self->{option_results}->{check_swap})) {
        $self->swap_calc(result => $result);
    }
}

1;

__END__

=head1 MODE

Check memory usage (UCD-SNMP-MIB).

=over 8

=item B<--units>

Units of thresholds (Default: '%') ('%', 'absolute') (Deprecated. Please use new counters directly)

=item B<--free>

Thresholds are on free space left (Deprecated. Please use new counters directly)

=item B<--swap>

Check swap also.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%), 
'swap' (B), 'swap-free' (B), 'swap-prct' (%),
'buffer' (B), 'cached' (B), 'shared' (B).

=back

=cut
