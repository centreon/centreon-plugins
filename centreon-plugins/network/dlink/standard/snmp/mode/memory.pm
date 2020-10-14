#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::dlink::standard::snmp::mode::memory;

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
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
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

my $map_memory_type = {
    1 => 'dram', 2 => 'flash', 3 => 'nvram'
};

my $mapping_industrial = {
    total => { oid => '.1.3.6.1.4.1.171.14.5.1.4.1.3' }, # dEntityExtMemUtilTotal (KB)
    used  => { oid => '.1.3.6.1.4.1.171.14.5.1.4.1.4' }, # dEntityExtMemUtilUsed (KB)
    free  => { oid => '.1.3.6.1.4.1.171.14.5.1.4.1.5' }  # dEntityExtMemUtilUsed (KB)
};
my $oid_dEntityExtMemoryUtilEntry = '.1.3.6.1.4.1.171.14.5.1.4.1';

my $mapping_common = {
    total => { oid => '.1.3.6.1.4.1.171.17.5.1.4.1.3' }, # esEntityExtMemUtilTotal (KB)
    used  => { oid => '.1.3.6.1.4.1.171.17.5.1.4.1.4' }, # esEntityExtMemUtilUsed (KB)
    free  => { oid => '.1.3.6.1.4.1.171.17.5.1.4.1.5' }  # esEntityExtMemUtilFree (KB)
};
my $oid_esEntityExtMemoryUtilEntry = '.1.3.6.1.4.1.171.17.5.1.4.1';

sub check_memory {
    my ($self, %options) = @_;

    return if ($self->{checked_memory} == 1);

    foreach (keys %{$options{snmp_result}}) {
        next if (! /^$options{mapping}->{total}->{oid}\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2;
        my $display = 'unit' . $1 . $self->{output}->get_instance_perfdata_separator() . $map_memory_type->{$2};
        my $result = $options{snmp}->map_instance(mapping => $options{mapping}, results => $options{snmp_result}, instance => $instance);

        $self->{checked_memory} = 1;
        $self->{memory}->{$display} = {
            display => $display,
            used => $result->{used} * 1024,
            free => $result->{free} * 1024,
            prct_used => ($result->{used} * 1024 * 100) / ($result->{total} * 1024),
            prct_free => ($result->{free} * 1024 * 100) / ($result->{total} * 1024),
            total => $result->{total} * 1024
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_dEntityExtMemoryUtilEntry, start => $mapping_industrial->{total}->{oid} },
            { oid => $oid_esEntityExtMemoryUtilEntry, start => $mapping_common->{total}->{oid} }
        ],
        nothing_quit => 1
    );

    $self->{checked_memory} = 0;
    $self->check_memory(snmp => $options{snmp}, snmp_result => $snmp_result->{$oid_dEntityExtMemoryUtilEntry}, mapping => $mapping_industrial);
    $self->check_memory(snmp => $options{snmp}, snmp_result => $snmp_result->{$oid_esEntityExtMemoryUtilEntry}, mapping => $mapping_common);
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
