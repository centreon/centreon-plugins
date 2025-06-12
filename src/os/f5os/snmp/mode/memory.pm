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

package os::f5os::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{total}),
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{used}),
        $self->{result_values}->{prct_used},
        $self->{perfdata}->change_bytes(value => $self->{result_values}->{free}),
        $self->{result_values}->{prct_free}
    );
}

sub prefix_memory_output {
    my ($self, %options) = @_;
   
    return "Memory ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'total'}, { name => 'prct_free' }],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'free', display_ok => 0, nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'total' }, { name => 'prct_free' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'memory.usage.percent', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'total' }, { name => 'prct_free' },],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'free-prct', nlabel => 'memory.free.percent', display_ok => 0, set => {
                key_values => [ { name => 'prct_free' }, { name => 'used' }, { name => 'free' }, { name => 'total' }, { name => 'prct_used' }, ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
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

my $mapping = {
    memPlatformTotal            => { oid => '.1.3.6.1.4.1.12276.1.2.1.4.1.1.5' },
    memPlatformUsed             => { oid => '.1.3.6.1.4.1.12276.1.2.1.4.1.1.6' },
};
my $oid_memoryStatsEntry = '.1.3.6.1.4.1.12276.1.2.1.4.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $results = $options{snmp}->get_table(
        oid => $oid_memoryStatsEntry,
        nothing_quit => 1
    );

    my $result;
    foreach (keys %$results) {
        if (/^$mapping->{memPlatformUsed}->{oid}\.(.*)$/) {
            $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $1);
            last
        }
    }

    my $free = $result->{memPlatformTotal} - $result->{memPlatformUsed};
    $self->{memory} = {
        total => $result->{memPlatformTotal},
        used => $result->{memPlatformUsed},
        free => $free, 
        prct_used => ($result->{memPlatformUsed} / $result->{memPlatformTotal}) * 100,
        prct_free => $free * 100 / $result->{memPlatformTotal},
    };
}

1;

__END__

=head1 MODE

Check memory usage.

    - memory.free.bytes                    Total amount of platform free memory in bytes
    - memory.free.percent                  Total amount of platform used memory in percent
    - memory.usage.bytes                   Total amount of platform used memory in bytes
    - memory.usage.percent                 Total amount of platform used memory in percent

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Can be : usage free usage-prct free-prct
Example : --filter-counters='^usage$'

=item B<--warning-free>

Threshold in bytes.

=item B<--critical-free>

Threshold in bytes.

=item B<--warning-free-prct>

Threshold in percentage.

=item B<--critical-free-prct>

Threshold in percentage.

=item B<--warning-usage>

Threshold in bytes.

=item B<--critical-usage>

Threshold in bytes.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
