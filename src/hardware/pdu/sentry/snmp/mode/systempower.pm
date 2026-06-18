#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package hardware::pdu::sentry::snmp::mode::systempower;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-power', nlabel => 'pdu.power.total.watt', display_ok => 1, set => {
            key_values      => [ { name => 'total_power' } ],
            output_template => 'total power: %s W',
            perfdatas       => [
                {
                    template             => '%d',
                    unit                 => 'W',
                    min                  => 0
                }
            ]
        }
        },
        { label => 'power-factor', nlabel => 'pdu.power.factor.percent', display_ok => 1, set => {
            key_values      => [ { name => 'power_factor' } ],
            output_template => 'power factor : %.2f %%',
            perfdatas       => [
                {
                    template             => '%s',
                    unit                 => '%',
                    min                  => 0,
                    max                  => 100
                }
            ],
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

my $oid_system_total_power = '.1.3.6.1.4.1.1718.3.1.6.0';
my $oid_system_power_factor = '.1.3.6.1.4.1.1718.3.1.10.0';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [
            $oid_system_total_power,
            $oid_system_power_factor
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        total_power  => $snmp_result->{$oid_system_total_power},
        power_factor  => $snmp_result->{$oid_system_power_factor}
    };
}

1;

__END__

=head1 MODE

Check Sentry PDU performance.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: C<--filter-counters='total-power'>

=item B<--warning-total-power>

Warning threshold. (W)

=item B<--critical-total-power>

Critical threshold. (W)

=item B<--warning-power-factor>

Warning threshold. (%)

=item B<--critical-power-factor>

Critical threshold. (%)

=back

=cut