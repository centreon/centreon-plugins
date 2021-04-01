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

package network::infoblox::snmp::mode::memory;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'memory', type => 0 },
    ];
    
    $self->{maps_counters}->{memory} = [
        { label => 'mem-usage', set => {
                key_values => [ { name => 'ram_used' } ],
                output_template => 'Memory Used: %.2f%%',
                perfdatas => [
                    { label => 'memory_used', value => 'ram_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'swap-usage', set => {
                key_values => [ { name => 'swap_used' } ],
                output_template => 'Swap Used: %.2f%%',
                perfdatas => [
                    { label => 'swap_used', value => 'swap_used', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];
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

    my $oid_ibSystemMonitorMemUsage = '.1.3.6.1.4.1.7779.3.1.1.2.1.8.2.1.0';
    my $oid_ibSystemMonitorSwapUsage = '.1.3.6.1.4.1.7779.3.1.1.2.1.8.3.1.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_ibSystemMonitorMemUsage, $oid_ibSystemMonitorSwapUsage,
        ],
        nothing_quit => 1
    );

    $self->{memory} = {
        ram_used => $snmp_result->{$oid_ibSystemMonitorMemUsage},
        swap_used => $snmp_result->{$oid_ibSystemMonitorSwapUsage},
    };
}

1;

__END__

=head1 MODE

Check memory usage.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'mem-usage' (%), 'swap-usage' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'mem-usage' (%), 'swap-usage' (%).


=back

=cut
