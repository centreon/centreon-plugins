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

package centreon::common::polycom::endpoint::snmp::mode::videoconferencing;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'conferences-active', nlabel => 'videoconferencing.conferences.active.count', set => {
                key_values => [ { name => 'NumberActiveConferences' } ],
                output_template => 'Current Conferences : %s',
                perfdatas => [
                    { label => 'conferences_active', value => 'NumberActiveConferences', template => '%d', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_conferenceNumberActiveConferences = '.1.3.6.1.4.1.13885.101.1.5.1.0';
    my $results = $options{snmp}->get_leef(oids => [$oid_conferenceNumberActiveConferences], nothing_quit => 1);

    $self->{global} = { NumberActiveConferences => $results->{$oid_conferenceNumberActiveConferences} };
}

1;

__END__

=head1 MODE

Check video conferencing usage.

=over 8

=item B<--warning-conferences-active>

Threshold warning.

=item B<--critical-conferences-active>

Threshold critical.

=back

=cut
