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

package network::moxa::switch::snmp::mode::memory;

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

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'free' }, { name => 'used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_memory_usage_output'),
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
    iks6726a => {
        total => { oid => '.1.3.6.1.4.1.8691.7.116.1.56' },
        free  => { oid => '.1.3.6.1.4.1.8691.7.116.1.57' },
        used  => { oid => '.1.3.6.1.4.1.8691.7.116.1.58' }
    },
    eds405a => {
        total => { oid => '.1.3.6.1.4.1.8691.7.6.1.56' },
        free  => { oid => '.1.3.6.1.4.1.8691.7.6.1.57' },
        used  => { oid => '.1.3.6.1.4.1.8691.7.6.1.58' }
    },
    edsp506e => {
        total => { oid => '.1.3.6.1.4.1.8691.7.162.1.56' },
        free  => { oid => '.1.3.6.1.4.1.8691.7.162.1.57' },
        used  => { oid => '.1.3.6.1.4.1.8691.7.162.1.58' }
    },
    edsp506a => {
        total => { oid => '.1.3.6.1.4.1.8691.7.41.1.56' },
        free  => { oid => '.1.3.6.1.4.1.8691.7.41.1.57' },
        used  => { oid => '.1.3.6.1.4.1.8691.7.41.1.58' }
    }
};

sub manage_selection {
    my ($self, %options) = @_;
   
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            map(
                $_->{oid} . '.0',
                values(%{$mapping->{iks6726a}}),
                values(%{$mapping->{eds405a}}),
                values(%{$mapping->{edsp506e}}),
                values(%{$mapping->{edsp506a}})
            )
        ],
        nothing_quit => 1
    );

    foreach (keys %$mapping) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$_}, results => $snmp_result, instance => 0);
        next if (!defined($result->{total}));
        $self->{global} = $result;
        $self->{global}->{prct_used} = $result->{used} * 100 / $result->{total};
        $self->{global}->{prct_free} = $result->{free} * 100 / $result->{total};
        last;
    }
}

1;

__END__

=head1 MODE

Check memory usage 

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage-prct', 'memory-usage', 'memory-usage-free',

=back

=cut
