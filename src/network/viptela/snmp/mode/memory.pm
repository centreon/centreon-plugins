#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and alarm monitoring for
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

package network::viptela::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used (-buffers/cache): %s %s (%.2f%%) free: %s %s (%.2f%%)',
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
        { name => 'ram', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{ram} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'buffers' } ],
                output_template => 'buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { template => '%d', min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'cached', nlabel => 'memory.cached.bytes', set => {
                key_values => [ { name => 'cached' } ],
                output_template => 'cached: %s %s',
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

    my $mapping = {
        total   => { oid => '.1.3.6.1.4.1.41916.11.1.17' }, # systemStatusMemTotal
        used    => { oid => '.1.3.6.1.4.1.41916.11.1.18' }, # systemStatusMemUsed
        free    => { oid => '.1.3.6.1.4.1.41916.11.1.19' }, # systemStatusMemFree
        buffers => { oid => '.1.3.6.1.4.1.41916.11.1.20' }, # systemStatusMemBuffers
        cached  => { oid => '.1.3.6.1.4.1.41916.11.1.21' }  # systemStatusMemCached
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    my $used = $result->{used};
    $used -= (defined($result->{cached}) ? $result->{cached} : 0) - (defined($result->{buffers}) ? $result->{buffers} : 0);
    $used *= 1024;

    $result->{total} *= 1024;

    $self->{ram} = {
        total => $result->{total},
        used => $used,
        free  => $result->{total} - $used,
        prct_used => $used * 100 / $result->{total},
        prct_free => 100 - ($used * 100 / $result->{total}),
        cached => $result->{cached} * 1024,
        buffers => $result->{buffers} * 1024
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-usage>

Warning threshold on used memory (in B).

=item B<--critical-usage>

Critical threshold on used memory (in B)

=item B<--warning-usage-prct>

Warning threshold on used memory (in %).

=item B<--critical-usage-prct>

Critical threshold on percentage used memory (in %)

=item B<--warning-usage-free>

Warning threshold on free memory (in B).

=item B<--critical-usage-free>

Critical threshold on free memory (in B)

=item B<--warning-*> B<--critical-*>

Thresholds (in B) on other metrics where '*' can be:
buffer, cached

=back

=cut
