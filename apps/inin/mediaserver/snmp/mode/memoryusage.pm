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

package apps::inin::mediaserver::snmp::mode::memoryusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'usage', set => {
                key_values => [ { name => 'used' } ],
                output_template => 'Memory Used : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'used', value => 'used', template => '%s',
                      unit => 'B', min => 0 },
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

    my $oid_i3MsGeneralInfoMemoryUsage = '.1.3.6.1.4.1.2793.8227.1.10.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [
            $oid_i3MsGeneralInfoMemoryUsage
        ], nothing_quit => 1);

    $self->{global} = { used => $snmp_result->{$oid_i3MsGeneralInfoMemoryUsage} };
}

1;

__END__

=head1 MODE

Check memory.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'usage' (B).

=item B<--critical-*>

Threshold critical.
Can be: 'usage' (B).

=back

=cut
