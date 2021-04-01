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

package network::checkpoint::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    return sprintf(
        'Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, 100 - $self->{result_values}->{prct_used}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output' },
        { name => 'swap', type => 0, cb_prefix_output => 'prefix_swap_output', skipped_code => { -10 => 1 } },
        { name => 'malloc', type => 0, skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'memory', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'prct_used'}, { name => 'used' }, { name => 'free' }, { name => 'total' }  ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'memory', value => 'used', template => '%s', threshold_total => 'total', cast_int => 1,
                      min => 0, max => 'total', unit => 'B' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{swap} = [
        { label => 'swap', nlabel => 'swap.usage.bytes', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'swap', value => 'used', template => '%s', threshold_total => 'total', cast_int => 1,
                      min => 0, max => 'total', unit => 'B' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{malloc} = [
        { label => 'failed-malloc', nlabel => 'memory.allocations.failed.persecond', set => {
                key_values => [ { name => 'failed_mallocs', per_second => 1 } ],
                output_template => 'Failed memory allocations %.2f/s',
                perfdatas => [
                    { label => 'failed_mallocs', template => '%.2f', min => 0 }
                ]
            }
        }
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory ";
}

sub prefix_swap_output {
    my ($self, %options) = @_;

    return "Swap ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "checkpoint_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
    (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    #  CHECKPOINT-MIB
    my $oid_memTotalVirtual64 = '.1.3.6.1.4.1.2620.1.6.7.4.1.0';
    my $oid_memActiveVirtual64 = '.1.3.6.1.4.1.2620.1.6.7.4.2.0';
    my $oid_memTotalReal64 = '.1.3.6.1.4.1.2620.1.6.7.4.3.0';
    my $oid_memActiveReal64 = '.1.3.6.1.4.1.2620.1.6.7.4.4.0';
    my $oid_memFreeReal64 = '.1.3.6.1.4.1.2620.1.6.7.4.5.0';
    my $oid_fwKmemFailedAlloc = '.1.3.6.1.4.1.2620.1.1.26.2.15.0';

    my $results = $options{snmp}->get_leef(
        oids => [
            $oid_memTotalVirtual64, $oid_memActiveVirtual64, $oid_fwKmemFailedAlloc,
            $oid_memTotalReal64, $oid_memActiveReal64, $oid_memFreeReal64
        ],
        nothing_quit => 1
    );

    $self->{memory} = {
        prct_used => $results->{$oid_memActiveReal64} * 100 / $results->{$oid_memTotalReal64},
        used => $results->{$oid_memActiveReal64},
        free => $results->{$oid_memFreeReal64},
        total => $results->{$oid_memTotalReal64},
    };

    if ($results->{$oid_memTotalVirtual64} > $results->{$oid_memTotalReal64}) {
        $self->{swap} = {
            prct_used => ($results->{$oid_memActiveVirtual64} - $results->{$oid_memActiveReal64}) * 100 / ($results->{$oid_memTotalVirtual64} - $results->{$oid_memTotalReal64}),
            used => $results->{$oid_memActiveVirtual64} - $results->{$oid_memActiveReal64},
            free => $results->{$oid_memTotalVirtual64} - $results->{$oid_memTotalReal64} - ($results->{$oid_memActiveVirtual64} - $results->{$oid_memActiveReal64}),
            total => $results->{$oid_memTotalVirtual64} - $results->{$oid_memTotalReal64}
        };
    }

    $self->{malloc} = { failed_mallocs => $results->{$oid_fwKmemFailedAlloc} };
}

1;

__END__

=head1 MODE

Check memory, swap usage and failed memory allocations per sec

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='failed-malloc'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory' (%), 'swap' (%), 'failed-malloc'

=back

=cut
