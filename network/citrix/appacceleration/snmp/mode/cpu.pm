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

package network::citrix::appacceleration::snmp::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'cpu', set => {
                key_values => [ { name => 'cpu' } ],
                output_template => 'CPU Usage : %.2f%% (1min)',
                perfdatas => [
                    { label => 'cpu', value => 'cpu', template => '%.2f',
                      min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'load', set => {
                key_values => [ { name => 'load' } ],
                output_template => 'Load : %s',
                perfdatas => [
                    { label => 'load', value => 'load', template => '%s',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_wsCpuUsage = '.1.3.6.1.4.1.3845.30.4.1.1.1.24.0';
    my $oid_wsSystemLoad = '.1.3.6.1.4.1.3845.30.4.1.1.1.34.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [
        $oid_wsCpuUsage, $oid_wsSystemLoad], nothing_quit => 1);

    $self->{global} = { 'cpu' => $snmp_result->{$oid_wsCpuUsage}, 'load' => $snmp_result->{$oid_wsSystemLoad} };
}

1;

__END__

=head1 MODE

Check cpu usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='cpu'

=item B<--warning-*>

Threshold warning.
Can be: 'cpu', 'load'.

=item B<--critical-*>

Threshold critical.
Can be: 'cpu', 'load'.

=back

=cut
    
