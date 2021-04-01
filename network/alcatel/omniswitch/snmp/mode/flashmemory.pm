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

package network::alcatel::omniswitch::snmp::mode::flashmemory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});

    my $msg = sprintf("Memory Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'memory', type => 1, cb_prefix_output => 'prefix_memory_output', message_multiple => 'All flash memories are ok' },
    ];

    $self->{maps_counters}->{memory} = [
        { label => 'usage', nlabel => 'flash.usage.bytes', set => {
                key_values => [ { name => 'total' }, { name => 'free' }, { name => 'display' },  ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                threshold_use => 'prct_used',
                perfdatas => [
                    { label => 'used', value => 'used', template => '%.2f', min => 0, max => 'total',
                      unit => 'B', label_extra_instance => 1, instance_use => 'display', cast_int => 1 },
                ],
            }
        },
    ];
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Memory '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        aos6 => {
            entry => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.9.1',
            flash => {
                chasSupervisionFlashSize  => { oid => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.9.1.2' }, # in B
                chasSupervisionFlashFree  => { oid => '.1.3.6.1.4.1.6486.800.1.1.1.3.1.1.9.1.3' }, # in B
            },
        },
        aos7 => {
            entry => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.9.1',
            flash => {
                chasSupervisionFlashSize  => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.9.1.2' }, # in B
                chasSupervisionFlashFree  => { oid => '.1.3.6.1.4.1.6486.801.1.1.1.3.1.1.9.1.3' }, # in B
            },
        },
    };
    
    my $snmp_result = $options{snmp}->get_multiple_table(oids => [
        { oid => $mapping->{aos6}->{entry} },
        { oid => $mapping->{aos7}->{entry} },
    ], nothing_quit => 1);

    my $type = 'aos6';
    if (scalar(keys %{$snmp_result->{ $mapping->{aos7}->{entry} }}) > 0) {
        $type = 'aos7';
    }

    $self->{memory} = {};
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %{$snmp_result->{ $mapping->{$type}->{entry} }})) {
        next if ($oid !~ /^$mapping->{$type}->{flash}->{chasSupervisionFlashSize}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$type}->{flash}, results => $snmp_result->{ $mapping->{$type}->{entry} }, instance => $instance);
                
        # Skip if total = 0
        next if ($result->{chasSupervisionFlashSize} == 0);
        
        $self->{memory}->{$instance} = {
            display => $instance,
            free => $result->{chasSupervisionFlashFree},
            total => $result->{chasSupervisionFlashSize},
        };
    }
}

1;

__END__

=head1 MODE

Check flash memory (AlcatelIND1Chassis.mib).

=over 8

=item B<--warning-usage>

Threshold warning in percent.

=item B<--critical-usage>

Threshold critical in percent.

=back

=cut
