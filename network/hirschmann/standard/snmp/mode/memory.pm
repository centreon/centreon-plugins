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

package network::hirschmann::standard::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_ram_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Memory total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
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
        { label => 'memory-usage', nlabel => 'memory.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_ram_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-free', display_ok => 0, nlabel => 'memory.free.bytes', set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_ram_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1 }
                ]
            }
        },
        { label => 'memory-usage-prct', display_ok => 0, nlabel => 'memory.usage.percentage', set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' } ],
                closure_custom_output => $self->can('custom_ram_usage_output'),
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

my $map_enable = {
    1 => 'enable', 2 => 'disable'
};

my $mapping = {
    hios => {
        measure_enable => { oid => '.1.3.6.1.4.1.248.11.22.1.8.1', map => $map_enable }, # hm2DiagEnableMeasurement
        ram_total      => { oid => '.1.3.6.1.4.1.248.11.22.1.8.11.1' }, # hm2DiagMemoryRamAllocated
        ram_free       => { oid => '.1.3.6.1.4.1.248.11.22.1.8.11.2' }  # hm2DiagMemoryRamFree
    },
    classic => {
        measure_enable => { oid => '.1.3.6.1.4.1.248.14.2.15.1', map => $map_enable }, # hmEnableMeasurement
        ram_total      => { oid => '.1.3.6.1.4.1.248.14.2.15.3.1' }, # hmMemoryAllocated
        ram_free       => { oid => '.1.3.6.1.4.1.248.14.2.15.3.2' }  # hmMemoryFree
    }
};

sub check_memory {
    my ($self, %options) = @_;

    my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => 0);
    return 0 if (!defined($result->{ram_free}));

    if ($result->{measure_enable} eq 'disable') {
        $self->{output}->add_option_msg(short_msg => 'resource measurement is disabled');
        $self->{output}->option_exit();
    }

    $result->{ram_total} *= 1024;
    $result->{ram_free} *= 1024;
    $self->{ram} = {
        total => $result->{ram_total},
        used => $result->{ram_total} - $result->{ram_free},
        free => $result->{ram_free},
        prct_used => 100 - ($result->{ram_free} * 100 / $result->{ram_total}),
        prct_free => $result->{ram_free} * 100 / $result->{ram_total}
    };
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{hios}}), values(%{$mapping->{classic}})) ],
        nothing_quit => 1
    );
    if ($self->check_memory(snmp => $options{snmp}, type => 'hios', snmp_result => $snmp_result) == 0) {
        $self->check_memory(snmp => $options{snmp}, type => 'classic', snmp_result => $snmp_result);
    }
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct' (%).

=back

=cut
