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

package hardware::ups::socomec::netvision::snmp::mode::alarms;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'alarms-current', nlabel => 'alarms.current.count', set => {
                key_values => [ { name => 'current_alarms' } ],
                output_template => 'current alarms: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ]
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

    my $oid_upsAlarmsPresent = '.1.3.6.1.4.1.4555.1.1.7.1.6.1.0';    
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_upsAlarmsPresent ], nothing_quit => 1);

    $self->{global} = { current_alarms => $snmp_result->{$oid_upsAlarmsPresent} };
}

1;

__END__

=head1 MODE

Check current alarms.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'alarms-current'.

=back

=cut
