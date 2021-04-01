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

package network::colubris::snmp::mode::load;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_load_output' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => '1min', set => {
                key_values => [ { name => 'load1' } ],
                output_template => '%s',
                perfdatas => [
                    { label => 'load1', value => 'load1', template => '%s', min => 0 },
                ],
            }
        },
        { label => '5min', set => {
                key_values => [ { name => 'load5' } ],
                output_template => '%s',
                perfdatas => [
                    { label => 'load5', value => 'load5', template => '%s', min => 0 },
                ],
            }
        },
        { label => '1min', set => {
                key_values => [ { name => 'load15' } ],
                output_template => '%s',
                perfdatas => [
                    { label => 'load15', value => 'load15', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub prefix_load_output {
    my ($self, %options) = @_;
    
    return "Load average: ";
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

    my $oid_coUsInfoLoadAverage1Min = '.1.3.6.1.4.1.8744.5.21.1.1.5.0';
    my $oid_coUsInfoLoadAverage5Min = '.1.3.6.1.4.1.8744.5.21.1.1.6.0';
    my $oid_coUsInfoLoadAverage15Min = '.1.3.6.1.4.1.8744.5.21.1.1.7.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $oid_coUsInfoLoadAverage1Min,
            $oid_coUsInfoLoadAverage5Min, $oid_coUsInfoLoadAverage15Min
        ],
        nothing_quit => 1
    );

    $self->{global} = { 
        load1 => $snmp_result->{$oid_coUsInfoLoadAverage1Min},
        load5 => $snmp_result->{$oid_coUsInfoLoadAverage5Min},
        load15 => $snmp_result->{$oid_coUsInfoLoadAverage15Min},
    };
}

1;

__END__

=head1 MODE

Check load-average.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='15min'

=item B<--warning-*>

Threshold warning.
Can be: '1min', '5min', '15min'.

=item B<--critical-*>

Threshold critical.
Can be: '1min', '5min', '15min'.

=back

=cut
