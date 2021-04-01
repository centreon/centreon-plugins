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

package network::nortel::standard::snmp::mode::memory;

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

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All memory usages are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'usage', display_ok => 0, nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'display' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;
    
    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
    });

    return $self;
}

my $mapping = {
    s5ChasUtilMemoryAvailable => { oid => '.1.3.6.1.4.1.45.1.6.3.8.1.1.9' }
};
my $mapping_khi = {
    rcKhiSlotMemUsed => { oid => '.1.3.6.1.4.1.2272.1.85.10.1.1.6' }, # KB
    rcKhiSlotMemFree => { oid => '.1.3.6.1.4.1.2272.1.85.10.1.1.7' }  # KB
};
my $oid_rcKhiSlotPerfEntry = '.1.3.6.1.4.1.2272.1.85.10.1.1';

sub check_khi {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_rcKhiSlotPerfEntry,
        start => $mapping_khi->{rcKhiSlotMemUsed}->{oid},
        end => $mapping_khi->{rcKhiSlotMemFree}->{oid},
        nothing_quit => 1
    );

    foreach (keys %$snmp_result) {
        next if (! /^$mapping_khi->{rcKhiSlotMemUsed}->{oid}\.(\d+)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_khi, results => $snmp_result, instance => $instance);

        my $total = $result->{rcKhiSlotMemUsed} * 1024 + $result->{rcKhiSlotMemFree} * 1024;
        $self->{memory}->{'slot_' . $1} = {
            display => 'slot_' . $1,
            used => $result->{rcKhiSlotMemUsed} * 1024,
            free => $result->{rcKhiSlotMemFree} * 1024,
            prct_used => $result->{rcKhiSlotMemUsed} * 1024 / $total,
            prct_free => $result->{rcKhiSlotMemFree} * 1024 / $total,
            total => $total
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $mapping->{s5ChasUtilMemoryAvailable}->{oid}
    );

    $self->{memory} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{s5ChasUtilMemoryAvailable}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        $self->{memory}->{$instance} = {
            display => $instance, 
            prct_used => 100 - $result->{s5ChasUtilMemoryAvailable}
        };
    }

    if (scalar(keys %{$self->{memory}}) <= 0) {
        $self->check_khi(snmp => $options{snmp});
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
