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

package apps::centreon::map::jmx::mode::enginestats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'drilldown-candidates-queue', set => {
                key_values => [ { name => 'DrilldownCandidatesQueue' } ],
                output_template => 'Drilldown Canditates Queue: %d',
                perfdatas => [
                    { label => 'drilldown_candidates_queue', template => '%d',
                      min => 0 },
                ],
            }
        },
        { label => 'cutback-computation-rate', set => {
                key_values => [ { name => 'Cutbackcomputation', per_second => 1 } ],
                output_template => 'Cutback Computation: %.2f/s',
                perfdatas => [
                    { label => 'cutback_computation_rate', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'minimal-computation-rate', set => {
                key_values => [ { name => 'Minimalcomputation', per_second => 1 } ],
                output_template => 'Minimal Computation: %.2f/s',
                perfdatas => [
                    { label => 'minimal_computation_rate', template => '%.2f',
                      min => 0 },
                ],
            }
        },
        { label => 'recursive-computation-rate', set => {
                key_values => [ { name => 'Recursivecomputation', per_second => 1 } ],
                output_template => 'Recursive Computation: %.2f/s',
                perfdatas => [
                    { label => 'recursive_computation_rate', template => '%.2f',
                      min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

my $mbean_engine = "com.centreon.studio.map:type=engine,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "centreon_map_" . md5_hex($options{custom}->{url}) . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

    $self->{request} = [
        { mbean => $mbean_engine }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);

    $self->{global} = {};

    $self->{global} = {
        DrilldownCandidatesQueue => $result->{$mbean_engine}->{DrilldownCandidatesQueue},
        Cutbackcomputation => $result->{$mbean_engine}->{Cutbackcomputation},
        Recursivecomputation => $result->{$mbean_engine}->{Recursivecomputation},
        Minimalcomputation => $result->{$mbean_engine}->{Minimalcomputation},
    };
}

1;

__END__

=head1 MODE

Check computation engine statistics.

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=engine-stats

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
(Example: --filter-counters='computation')

=item B<--warning-*>

Threshold warning.
Can be: ''drilldown-candidates-queue', 'cutback-computation-rate',
'minimal-computation-rate', 'recursive-computation-rate'.

=item B<--critical-*>

Threshold critical.
Can be: ''drilldown-candidates-queue', 'cutback-computation-rate',
'minimal-computation-rate', 'recursive-computation-rate'.

=back

=cut

