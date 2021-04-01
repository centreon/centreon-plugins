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

package apps::centreon::map::jmx::mode::openviews;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'open-views', set => {
                key_values => [ { name => 'OpenContextCount' } ],
                output_template => 'Open Views: %d',
                perfdatas => [
                    { label => 'open_views', value => 'OpenContextCount', template => '%d',
                      min => 0, unit => 'views' },
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mbean_context = "com.centreon.studio.map:type=context,name=statistics";

sub manage_selection {
    my ($self, %options) = @_;

    $self->{request} = [
        { mbean => $mbean_context }
    ];

    my $result = $options{custom}->get_attributes(request => $self->{request}, nothing_quit => 0);

    $self->{global} = {};

    $self->{global} = {
        OpenContextCount => $result->{$mbean_context}->{OpenContextCount},
    };
}

1;

__END__

=head1 MODE

Check open views count.

Example:

perl centreon_plugins.pl --plugin=apps::centreon::map::jmx::plugin --custommode=jolokia
--url=http://10.30.2.22:8080/jolokia-war --mode=open-views

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'open-views'.

=item B<--critical-*>

Threshold critical.
Can be: 'open-views'.

=back

=cut

