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

package storage::synology::snmp::mode::ups;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'load', nlabel => 'ups.load.percent', set => {
                key_values => [ { name => 'ups_load' } ],
                output_template => 'ups load: %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'charge-remaining', nlabel => 'battery.charge.remaining.percent', set => {
                key_values => [ { name => 'charge_remain' } ],
                output_template => 'battery charge remaining: %s%%',
                perfdatas => [
                    { template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        },
        { label => 'lifetime-remaining', nlabel => 'battery.lifetime.remaining.seconds', set => {
                key_values => [ { name => 'lifetime_remain' } ],
                output_template => 'battery estimated lifetime: %s seconds',
                perfdatas => [
                    { template => '%s', min => 0, unit => 's' }
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

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_upsBatteryRuntimeValue = '.1.3.6.1.4.1.6574.4.3.6.1.0'; # in seconds
    my $oid_upsBatteryChargeValue = '.1.3.6.1.4.1.6574.4.3.1.1.0'; # in %
    my $oid_upsInfoLoadValue = '.1.3.6.1.4.1.6574.4.2.12.1.0'; # in %

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_upsBatteryRuntimeValue, $oid_upsBatteryChargeValue, $oid_upsInfoLoadValue
        ],
        nothing_quit => 1
    );

    $self->{global} = {
        ups_load => $snmp_result->{$oid_upsInfoLoadValue},
        charge_remain => $snmp_result->{$oid_upsBatteryChargeValue},
        lifetime_remain => $snmp_result->{$oid_upsBatteryRuntimeValue},
    };
}

1;

__END__

=head1 MODE

Check ups (SYNOLOGY-UPS-MIB).

=over 8

=item B<--warning-*> B<--critical-*> 

Thresholds
Can be: 'charge-remaining' (%), 'lifetime-remaining' (s)

=back

=cut
