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

package centreon::common::foundry::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_usage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Ram total: %s %s used: %s %s (%.2f%%) free: %s %s (%.2f%%)',
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
        { name => 'memory', type => 0 }
    ];

    $self->{maps_counters}->{memory} = [
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
                output_template => 'Ram used: %.2f %%',
                perfdatas => [
                    { value => 'prct_used', template => '%.2f', min => 0, max => 100, unit => '%' }
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
    });

    return $self;
}

my $mapping = {
    total => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.3' }, # totalMemoryStatsRev
    free  => { oid => '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1.4' } # memoryFreeStatsRev
};

my $oid_memoryStatsEntry = '.1.3.6.1.4.1.20301.2.5.1.2.12.9.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_snAgGblDynMemUtil = '.1.3.6.1.4.1.1991.1.1.2.1.53.0'; # %
    my $oid_snAgGblDynMemTotal = '.1.3.6.1.4.1.1991.1.1.2.1.54.0'; # Bytes
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_snAgGblDynMemUtil, $oid_snAgGblDynMemTotal],
        nothing_quit => 1
    );

    my $used = $snmp_result->{$oid_snAgGblDynMemUtil} * $snmp_result->{$oid_snAgGblDynMemTotal} / 100;
    $self->{memory} = {
        prct_used => $snmp_result->{$oid_snAgGblDynMemUtil},
        prct_free => 100 - $snmp_result->{$oid_snAgGblDynMemUtil},
        total => $snmp_result->{$oid_snAgGblDynMemTotal},
        used => $used,
        free => $snmp_result->{$oid_snAgGblDynMemTotal} - $used
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%).

=back

=cut
