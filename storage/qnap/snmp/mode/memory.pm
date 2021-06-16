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

package storage::qnap::snmp::mode::memory;

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

    $options{options}->add_options(arguments => {
        'force-counters-legacy' => { name => 'force_counters_legacy' }
    });

    return $self;
}

sub convert_bytes {
    my ($self, %options) = @_;
    my $multiple = defined($options{network}) ? 1000 : 1024;
    my %units = (K => 1, M => 2, G => 3, T => 4);
    
    if ($options{value} !~ /^\s*([0-9\.\,]+)\s*(.)/) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            output => "Cannot convert value '" . $options{value} . "'"
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    my ($bytes, $unit) = ($1, uc($2));
    
    for (my $i = 0; $i < $units{$unit}; $i++) {
        $bytes *= $multiple;
    }

    return $bytes;
}

my $mapping = {
    legacy => {
        ram_total => { oid => '.1.3.6.1.4.1.24681.1.2.2' }, # systemTotalMem
        ram_free  => { oid => '.1.3.6.1.4.1.24681.1.2.3' }  # systemFreeMem
    },
    ex => {
        ram_total => { oid => '.1.3.6.1.4.1.24681.1.3.2' }, # systemTotalMemEX
        ram_free  => { oid => '.1.3.6.1.4.1.24681.1.3.3' }  # systemFreeMemEX
    },
    es => {
        ram_total => { oid => '.1.3.6.1.4.1.24681.2.2.2' }, # es-SystemTotalMem
        ram_free  => { oid => '.1.3.6.1.4.1.24681.2.2.3' }  # es-SystemFreeMem
    }
};

sub check_memory {
    my ($self, %options) = @_;

    return 0 if (defined($self->{ram}->{total}));

    my $result = $options{snmp}->map_instance(mapping => $mapping->{ $options{type} }, results => $options{snmp_result}, instance => 0);
    return 0 if (!defined($result->{ram_free}));

    if (defined($options{convert})) {
        $result->{ram_total} = $self->convert_bytes(value => $result->{ram_total});
        $result->{ram_free} = $self->convert_bytes(value => $result->{ram_free});
    }

    if (defined($result->{ram_total}) && $result->{ram_total} > 0) {
        $self->{ram} = {
            total => $result->{ram_total},
            used => $result->{ram_total} - $result->{ram_free},
            free => $result->{ram_free},
            prct_used => 100 - ($result->{ram_free} * 100 / $result->{ram_total}),
            prct_free => $result->{ram_free} * 100 / $result->{ram_total}
        };
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%{$mapping->{legacy}}), values(%{$mapping->{ex}}), values(%{$mapping->{es}})) ],
        nothing_quit => 1
    );
    if (!defined($self->{option_results}->{force_counters_legacy})) {
        $self->check_memory(snmp => $options{snmp}, type => 'ex', snmp_result => $snmp_result);
        $self->check_memory(snmp => $options{snmp}, type => 'es', snmp_result => $snmp_result, convert => 1);
    }
    $self->check_memory(snmp => $options{snmp}, type => 'legacy', snmp_result => $snmp_result, convert => 1);
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--force-counters-legacy>

Force to use legacy counters. Should be used when EX/ES counters are buggy.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'memory-usage' (B), 'memory-usage-free' (B), 'memory-usage-prct' (%).

=back

=cut
    
