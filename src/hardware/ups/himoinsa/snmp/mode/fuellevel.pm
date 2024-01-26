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

package hardware::ups::himoinsa::snmp::mode::fuellevel;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'fuel-level', nlabel => 'fuel.level.percentage', set => {
                key_values => [ { name => 'fuelLevel' } ],
                output_template => 'Fuel level: %s%%',
                perfdatas => [
                    { template => '%.2f', unit => '%', min => 0, max => 100 }
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

    my $oid_fuelLevel = '.1.3.6.1.4.1.41809.1.27.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_fuelLevel], nothing_quit => 1);

    $self->{global} = {
        fuelLevel => $snmp_result->{$oid_fuelLevel} / 10
    };
}

1;

__END__

=head1 MODE

Check fuel level.

=over 8

=item B<--warning-fuel-level>

Warning threshold for fuel level.

=item B<--critical-fuel-level>

Critical threshold for fuel level.

=back

=cut
