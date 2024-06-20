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

package apps::eclipse::mosquitto::mqtt::mode::clients;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [];
    for my $label (('connected', 'maximum', 'active', 'inactive')) {
        push @{$self->{maps_counters}->{global}},
             { label  => 'clients-' . $label,
               nlabel => 'clients.' . $label . '.count',
               set    => {
                   key_values      => [{ name => $label }],
                   output_template => ucfirst($label) . ' clients: %d',
                   perfdatas       => [
                       { label => $label . '_clients', template => '%d',
                         min   => 0 }
                   ]
               }
             };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my %results = $options{mqtt}->queries(
        base_topic => '$SYS/broker/clients/',
        topics     => ['connected', 'maximum', 'active', 'inactive']
    );

    for my $topic (keys %results) {
        $self->{global}->{$topic} = $results{$topic};
    }
}

1;

__END__

=head1 MODE

Check clients statistics.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'clients-connected', 'clients-maximum', 'clients-active', 'clients-inactive'.

=back

=cut