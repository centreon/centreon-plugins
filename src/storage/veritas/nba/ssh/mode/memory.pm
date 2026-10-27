#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::veritas::nba::ssh::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);

sub custom_memory_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used (-buffers/cache): %s %s (%.2f%%) free: %s %s (%.2f%%) available: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{available}),
        $self->{result_values}->{prct_available}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'available' }, { name => 'prct_available' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B' }
                ]
            }
        },
        { label => 'memory-usage-free', nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'available' }, { name => 'prct_available' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B' }
                ]
            }
        },
        { label => 'memory-usage-prct', nlabel => 'memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'available' }, { name => 'prct_available' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'memory-available', nlabel => 'memory.available.bytes', display_ok => 0, set => {
                key_values => [ { name => 'available' }, { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'prct_available' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B' }
                ]
            }
        },
        { label => 'memory-available-prct', nlabel => 'memory.available.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_available' }, { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'available' } ],
                closure_custom_output => $self->can('custom_memory_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'buffer' } ],
                output_template => 'buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'shared', nlabel => 'memory.shared.bytes', set => {
                key_values => [ { name => 'shared' } ],
                output_template => 'shared: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($result) = $options{custom}->execute_scenario(
        request => {
            interactive => 1,
            pty => {
                rows => 800,
                cols => 80
            },
            scenario => [
                { cmd => 'waitfor', options => { Match => 'Main_Menu>', Timeout => 30 } },
                { cmd => 'put', options => { String => "Monitor\n" } },
                { cmd => 'waitfor', options => { Match => 'Monitor>', Timeout => 5 } },
                { cmd => 'put', options => { String => "MemoryStatus\n" } },
                { cmd => 'waitfor', options => { Match => 'Total:', Timeout => 10 } },
                { cmd => 'close' }
            ]
        }
    );

    #               total        used        free      shared  buff/cache   available
    #Mem:      262873544   122588148     3147172      142120   137138224   137563492
    #Swap:      66674684    14492760    52181924
    #Total:    329548228   137080908    55329096
    if ($result !~ /^Mem:\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/m) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find memory information in the output');
        $self->{output}->option_exit();
    }

    my ($total, $used, $free, $shared, $buffer, $available) = map { $_ * 1024 } ($1, $2, $3, $4, $5, $6);

    $self->{memory} = {
        total => $total,
        used => $used,
        free => $free,
        prct_used => $used * 100 / $total,
        prct_free => $free * 100 / $total,
        available => $available,
        prct_available => $available * 100 / $total,
        buffer => $buffer,
        shared => $shared
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-memory-usage>

Threshold in bytes.

=item B<--critical-memory-usage>

Threshold in bytes.

=item B<--warning-memory-usage-free>

Threshold in bytes.

=item B<--critical-memory-usage-free>

Threshold in bytes.

=item B<--warning-memory-usage-prct>

Threshold in percentage.

=item B<--critical-memory-usage-prct>

Threshold in percentage.

=item B<--warning-memory-available>

Threshold in bytes.

=item B<--critical-memory-available>

Threshold in bytes.

=item B<--warning-memory-available-prct>

Threshold in percentage.

=item B<--critical-memory-available-prct>

Threshold in percentage.

=item B<--warning-buffer>

Threshold in bytes (the appliance reports buffers and cache as a single value).

=item B<--critical-buffer>

Threshold in bytes (the appliance reports buffers and cache as a single value).

=item B<--warning-shared>

Threshold in bytes.

=item B<--critical-shared>

Threshold in bytes.

=back

=cut