#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package network::juniper::common::ive::mode::users;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'web', set => {
                key_values => [ { name => 'web' } ],
                output_template => 'Current concurrent signed-in web users connections: %s', output_error_template => 'Current concurrent signed-in web users connections: %s',
                perfdatas => [
                    { label => 'web', value => 'web_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'meeting', set => {
                key_values => [ { name => 'meeting' } ],
                output_template => 'Current concurrent meeting users connections: %s', output_error_template => 'Current concurrent meeting users connections: %s',
                perfdatas => [
                    { label => 'meeting', value => 'meeting_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'node', set => {
                key_values => [ { name => 'node' } ],
                output_template => 'Current concurrent node logged users connections: %s', output_error_template => 'Current concurrent node logged users connections: %s',
                perfdatas => [
                    { label => 'node', value => 'node_absolute', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'cluster', set => {
                key_values => [ { name => 'cluster' } ],
                output_template => 'Current concurrent cluster logged users connections: %s', output_error_template => 'Current concurrent cluster logged users connections: %s',
                perfdatas => [
                    { label => 'cluster', value => 'cluster_absolute', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_signedInWebUsers = '.1.3.6.1.4.1.12532.2.0';
    my $oid_meetingUserCount = '.1.3.6.1.4.1.12532.9.0';
    my $oid_iveConcurrentUsers = '.1.3.6.1.4.1.12532.12.0';
    my $oid_clusterConcurrentUsers = '.1.3.6.1.4.1.12532.13.0';
    my $result = $options{snmp}->get_leef(oids => [$oid_signedInWebUsers, $oid_meetingUserCount, 
                                                   $oid_iveConcurrentUsers, $oid_clusterConcurrentUsers], nothing_quit => 1);
    $self->{global} = { web => $result->{$oid_signedInWebUsers},
                        meeting => $result->{$oid_meetingUserCount},
                        node => $result->{$oid_iveConcurrentUsers},
                        cluster => $result->{$oid_clusterConcurrentUsers} };    
}

1;

__END__

=head1 MODE

Check users connections (web users, cluster users, node users, meeting users) (JUNIPER-IVE-MIB).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^web|meeting$'

=item B<--warning-*>

Threshold warning.
Can be: 'web', 'meeting', 'node', 'cluster'.

=item B<--critical-*>

Threshold critical.
Can be: 'web', 'meeting', 'node', 'cluster'.

=back

=cut
    