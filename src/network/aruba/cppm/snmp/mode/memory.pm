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

package network::aruba::cppm::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance}. "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memories', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memories are ok' }
    ];

    $self->{maps_counters}->{memories} = [
        { label => 'usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'memory.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'memory.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
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

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        hostname => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.4' },  # cppmSystemHostname
        total    => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.12' }, # cppmSystemMemoryTotal
        free     => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.13' }  # cppmSystemMemoryFree
    };
    my $oid_memEntry = '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1';

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_memEntry, start => $mapping->{total}->{oid}, end => $mapping->{free}->{oid} },
            { oid => $mapping->{hostname}->{oid} }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{memories} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{hostname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{hostname} !~ /$self->{option_results}->{filter_name}/);

        $self->{memories}->{ $result->{hostname} } = {
            free => $result->{free},
            total => $result->{total},
            used => $result->{total} - $result->{free},
            prct_used => ($result->{total} - $result->{free}) * 100 / $result->{total},
            prct_free => $result->{free} * 100 / $result->{total},
        };
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--filter-name>

Filter memory by system hostname (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage', 'usage-free', 'usage-prct'.

=back

=cut
