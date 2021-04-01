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

package network::zyxel::snmp::mode::sessions;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'sessions' } ],
                output_template => 'Current active sessions : %s',
                perfdatas => [
                    { label => 'sessions', value => 'sessions', template => '%s', min => 0 },
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

    my $oid_sysSessionNum = '.1.3.6.1.4.1.890.1.6.22.1.6.0';
    my $oid_sysActiveSessionNum = '.1.3.6.1.4.1.890.1.6.22.1.6.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [$oid_sysSessionNum, $oid_sysActiveSessionNum], nothing_quit => 1);

    $self->{global} = { 
        sessions => defined($snmp_result->{$oid_sysSessionNum}) ? $snmp_result->{$oid_sysSessionNum} : $snmp_result->{$oid_sysActiveSessionNum},
    };
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=back

=cut
