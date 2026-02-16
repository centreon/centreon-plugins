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

package network::waystream::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram Total: %s %s Used: %s %s (%.2f%%) Free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ram', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{ram} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
            key_values            =>
                [
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_usage_output'),
            perfdatas             =>
                [
                    { label => 'used', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
        }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
            key_values            =>
                [
                    { name => 'free' },
                    { name => 'used' },
                    { name => 'prct_used' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_usage_output'),
            perfdatas             =>
                [
                    { label => 'free', template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
        }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
            key_values            =>
                [
                    { name => 'prct_used' },
                    { name => 'used' },
                    { name => 'free' },
                    { name => 'prct_free' },
                    { name => 'total' }
                ],
            closure_custom_output => $self->can('custom_usage_output'),
            perfdatas             =>
                [
                    { label => 'used_prct', template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
        }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(
        arguments => { 'units:s' => { name => 'units', default => '%' }, 'free' => { name => 'free' } }
    );

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Compatibility
    $self->compat_threshold_counter(
        %options,
        compat => {
            th    =>
                [
                    [ 'usage', { free => 'usage-free', prct => 'usage-prct' } ],
                    [ 'memory-usage-bytes', { free => 'memory-free-bytes', prct => 'memory-usage-percentage' } ]
                ],
            units => $options{option_results}->{units},
            free  => $options{option_results}->{free}
        }
    );
    $self->SUPER::check_options(%options);
}

# legacy counters
my $mapping = {
    wsMemoryTotal     => { oid => '.1.3.6.1.4.1.9303.4.1.1.10' },
    wsMemoryUsed      => { oid => '.1.3.6.1.4.1.9303.4.1.1.12' },
    wsMemoryFree      => { oid => '.1.3.6.1.4.1.9303.4.1.1.13' },
    wsMemoryAvailable => { oid => '.1.3.6.1.4.1.9303.4.1.1.14' },
    wsMemoryPctFree   => { oid => '.1.3.6.1.4.1.9303.4.1.1.15' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_systemStats = '.1.3.6.1.4.1.9303.4.1.1';
    my $snmp_result = $options{snmp}->get_table(
        oid          => $oid_systemStats,
        start        => $mapping->{wsMemoryTotal}->{oid},
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{ram} = {
        total     => $result->{wsMemoryTotal} * 1024,
        used      => $result->{wsMemoryUsed} * 1024,
        free      => $result->{wsMemoryFree} * 1024,
        prct_free => $result->{wsMemoryPctFree} / 10,
        prct_used => 100 - ($result->{wsMemoryPctFree} / 10),
        available => $result->{wsMemoryAvailable}
    };
}

1;

__END__

=head1 MODE

Check memory usage (UCD-SNMP-MIB).

=over 8

=item B<--units>

Units of thresholds (default: '%') ('%', 'absolute') (deprecated. Please use new counters directly)

=item B<--free>

Thresholds are on free space left (deprecated. Please use new counters directly)

=item B<--swap>

Check swap also.

=item B<--warning-buffer>

Threshold in bytes.

=item B<--critical-buffer>

Threshold in bytes.

=item B<--warning-cached>

Threshold in bytes.

=item B<--critical-cached>

Threshold in bytes.

=item B<--warning-shared>

Threshold in bytes.

=item B<--critical-shared>

Threshold in bytes.

=item B<--warning-swap>

Threshold in bytes.

=item B<--critical-swap>

Threshold in bytes.

=item B<--warning-swap-free>

Threshold in bytes.

=item B<--critical-swap-free>

Threshold in bytes.

=item B<--warning-swap-prct>

Threshold in percentage.

=item B<--critical-swap-prct>

Threshold in percentage.

=item B<--warning-usage>

Threshold in bytes.

=item B<--critical-usage>

Threshold in bytes.

=item B<--warning-usage-free>

Threshold in bytes.

=item B<--critical-usage-free>

Threshold in bytes.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=item B<--patch-redhat>

If using Red Hat distribution with net-snmp >= 5.7.2-43 and net-snmp < 5.7.2-47. But you should update net-snmp!!!!

This version: used = C<wsMemoryTotal - memAvailReal // free = memAvailReal>

Others versions: used = C<wsMemoryTotal - memAvailReal - memBuffer - memCached // free = total - used>

=item B<--force-64bits-counters>

Use this option to monitor a server/device that has more than 2 TB of RAM, the maximum size of a signed 32 bits integer.
If you omit it you'll get the remainder of the Euclidean division of the actual value by 2 TB.
NB: it cannot work with version 1 of SNMP protocol. 64 bits counters are supported starting version 2c.

=back

=cut
