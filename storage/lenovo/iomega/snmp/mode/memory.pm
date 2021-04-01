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

package storage::lenovo::iomega::snmp::mode::memory;

use base qw(snmp_standard::mode::storage);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram Total: %s %s Used (-buffers/cache): %s %s (%.2f%%) Free: %s %s (%.2f%%)',
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
                    { value => 'used', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { value => 'free', template => '%d', min => 0, max => 'total',
                      unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' } ],
                output_template => 'Ram Used : %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100,
                      unit => '%' }
                ]
            }
        },
        { label => 'buffer', nlabel => 'memory.buffer.bytes', set => {
                key_values => [ { name => 'buffer' } ],
                output_template => 'Buffer: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'buffer', template => '%d',
                      min => 0, unit => 'B' }
                ]
            }
        },
        { label => 'cached', nlabel => 'memory.cached.bytes', set => {
                key_values => [ { name => 'cached' } ],
                output_template => 'Cached: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { value => 'cached', template => '%d',
                      min => 0, unit => 'B' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    return $self;
}

my $mapping = {
    hrStorageDescr           => { oid => '.1.3.6.1.2.1.25.2.3.1.3' },
    hrStorageAllocationUnits => { oid => '.1.3.6.1.2.1.25.2.3.1.4' },
    hrStorageSize            => { oid => '.1.3.6.1.2.1.25.2.3.1.5' },
    hrStorageUsed            => { oid => '.1.3.6.1.2.1.25.2.3.1.6' }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_hrstoragetype = '.1.3.6.1.2.1.25.2.3.1.2';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_hrstoragetype, nothing_quit => 1);
    my $storages = [];
    foreach (keys %$snmp_result) {
        next if ($snmp_result->{$_} !~ /(?:\.1|\.2)$/);
        /^$oid_hrstoragetype\.(.*)$/;
        push @$storages, $1;        
    }

    $options{snmp}->load(
        oids => [map($_->{oid}, values(%$mapping))], 
        instances => $storages,
        nothing_quit => 1
    );
    $snmp_result = $options{snmp}->get_leef();

    my ($total, $used, $cached, $buffer);
    #.1.3.6.1.2.1.25.2.3.1.3.1 = STRING: Physical memory
    #.1.3.6.1.2.1.25.2.3.1.3.2 = STRING: Memory buffers
    #.1.3.6.1.2.1.25.2.3.1.3.3 = STRING: Cached memory
    foreach (@$storages) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        next if (!defined($result->{hrStorageUsed}));
        my $current = $result->{hrStorageUsed} * $result->{hrStorageAllocationUnits};
        next if ($current < 0);
    
        if ($result->{hrStorageDescr} =~ /Cached\s+memory/i) {
            $cached = $current;
        } elsif ($result->{hrStorageDescr} =~ /Memory\s+buffers/i) {
            $buffer = $current;
        } elsif ($result->{hrStorageDescr} =~ /Physical\s+memory/i) {
            $used = $current;
            $total = $result->{hrStorageSize} * $result->{hrStorageAllocationUnits};
        }
    }

    $used -= (defined($cached) ? $cached : 0) - (defined($buffer) ? $buffer : 0);
    $self->{ram} = {
        total => $total,
        cached => $cached,
        buffer => $buffer,
        used => $used,
        free => $total - $used,
        prct_used => $used * 100 / $total,
        prct_free => 100 - ($used * 100 / $total)
    };
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'buffer' (B), 'cached' (B).

=back

=cut
