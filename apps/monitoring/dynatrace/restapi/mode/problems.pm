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

package apps::monitoring::dynatrace::restapi::mode::problems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        "problem '%s' [type: %s] [severity: %s] [impact: %s] [entity: %s]",
        $self->{result_values}->{displayName},
        $self->{result_values}->{eventType},
        $self->{result_values}->{severityLevel},
        $self->{result_values}->{impactLevel},
        $self->{result_values}->{entityName}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'problems', type => 2, message_multiple => '0 problems detected', display_counter_problem => { label => 'problems', min => 0 },
          group => [ { name => 'problem' } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'problems-open', nlabel => 'problems.open.count', display_ok => 0, set => {
                key_values => [ { name => 'problems_open' } ],
                output_template => 'number of open problems : %s',
                perfdatas => [
                    { value => 'problems_open', template => '%s', value => 'problems_open', min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{problem} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'impactLevel' }, { name => 'severityLevel' }, 
                    { name => 'entityName' }, { name => 'eventType' }, { name => 'entityId' }, { name => 'displayName' }, 
                    { name => 'startTime' }, { name => 'endTime' }, { name => 'commentCount' } 
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Problem '" . $options{instance_value}->{displayName} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'relative-time:s'   => { name => 'relative_time', default => 'min' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} eq "OPEN"' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $problem = $options{custom}->api_problem(relative_time => $options{options}->{relative_time});

    $self->{global} = { problems_open => 0 };
    $self->{problem} = {};

    $self->{problems}->{global} = { problem => {} };
    my $i = 1;
    foreach my $item (@{$problem}) {
        $self->{problems}->{global}->{problem}->{$i} = {
            displayName => $item->{displayName},
            status => $item->{status},
            impactLevel => $item->{impactLevel},
            severityLevel => $item->{severityLevel},
            entityName => join(",", centreon::plugins::misc::uniq(map { "$_->{entityName}" } @{$item->{rankedImpacts}})),
            eventType => join(",", centreon::plugins::misc::uniq(map { "$_->{eventType}" } @{$item->{rankedImpacts}})),
            entityId => join(",", centreon::plugins::misc::uniq(map { "$_->{entityId}" } @{$item->{rankedImpacts}})),
            startTime => $item->{startTime} / 1000,
            endTime => $item->{endTime} > -1 ? $item->{endTime} / 1000 : -1,
            commentCount => $item->{commentCount},
        };
        if ($item->{status} eq 'OPEN') {
            $self->{global}->{problems_open}++;
        }

        $i++;
    }
}

1;

__END__

=head1 MODE

Check problems.

=over 8

=item B<--relative-time>

Set request relative time (Default: 'min').
Can use: min, 5mins, 10mins, 15mins, 30mins, hour, 2hours, 6hours, day, 3days, week, month.

=item B<--unknown-status>

Set unknown threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "OPEN"').
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'problems-open'.

=back

=cut
