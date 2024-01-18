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

package apps::vmware::vcsa::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

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

    my $storage_type_ram = '.1.3.6.1.2.1.25.2.1.2';
    my $oid_hrstoragetype = '.1.3.6.1.2.1.25.2.3.1.2';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_hrstoragetype, nothing_quit => 1);
    my $storages = [];
    foreach (keys %$snmp_result) {
        next if ($snmp_result->{$_} ne $storage_type_ram);
        /^$oid_hrstoragetype\.(.*)$/;
        push @$storages, $1;        
    }

    $options{snmp}->load(
        oids => [map($_->{oid}, values(%$mapping))], 
        instances => $storages,
        nothing_quit => 1
    );
    $snmp_result = $options{snmp}->get_leef();

    my ($total, $used);
    #.1.3.6.1.2.1.25.2.3.1.3.45 = STRING: Real Memory
    foreach (@$storages) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        my $current = $result->{hrStorageUsed} * $result->{hrStorageAllocationUnits};
        next if ($current < 0);
        
        if ($result->{hrStorageDescr} =~ /Real\s+Memory/i) {
            $used = $current;
            $total = $result->{hrStorageSize} * $result->{hrStorageAllocationUnits};
        }
    }

    $self->{ram} = {
        total => $total,
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
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
