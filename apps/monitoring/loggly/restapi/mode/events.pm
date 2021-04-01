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

package apps::monitoring::loggly::restapi::mode::events;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'events', nlabel => 'events.count', set => {
                key_values => [ { name => 'events' } ],
                output_template => 'Matching events: %s',
                perfdatas => [
                    { template => '%s', value => 'events', min => 0 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'time-period:s'  => { name => 'time_period' },
        'query:s'        => { name => 'query' },
        'output-field:s' => { name => 'output_field' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{time_period}) || $self->{option_results}->{time_period} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --time-period option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->api_events(
        time_period => $self->{option_results}->{time_period},
        query => $self->{option_results}->{query},
        output_field => $self->{option_results}->{output_field}
    );
    $self->{global} = { events => $results->{total_events} };
    if (length($results->{message})) {
        $self->{output}->output_add(long_msg => 'Last ' . $self->{option_results}->{output_field} . ': ' . $results->{message});
    }
}

1;

__END__

=head1 MODE

Count events matching the query.

=over 8

=item B<--time-period>

Set request period, in minutes.

=item B<--query>

Set the query.

=item B<--output-field>

Set the field to verbose-output from the last matching event (ex: json.message).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'events'.

=back

=cut
