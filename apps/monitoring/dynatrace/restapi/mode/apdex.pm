#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::monitoring::dynatrace::restapi::mode::apdex;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Problem '" . $options{instance_value}->{displayName} . "' ";
}

sub prefix_entity_output {
    my ($self, %options) = @_;

    return sprintf(
        "Entity '%s' ", 
        $options{instance_value}->{display}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'apdex', type => 1, cb_prefix_output => 'prefix_entity_output', message_multiple => 'All Apdex are OK', skipped_code => { -10 => 1 }}
    ];

    $self->{maps_counters}->{apdex} = [
        { label => 'apdex', nlabel => 'apdex', set => {
                key_values => [ { name => 'apdex' }, { name => 'display' } ],
                output_template => 'apdex : %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'aggregation-type:s' => { name => 'aggregation_type', default => 'count' },
        'filter-entity:s'    => { name => 'filter_entity' },
        'relative-time:s'    => { name => 'relative_time', default => 'min' },
        'query-mode:s'       => { name => 'query_mode', default => 'total' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_apdex(relative_time => $options{options}->{relative_time});
    $self->{apdex} = {};

    foreach my $apdex (keys %{$results->{dataPoints}}) {
        
        if (defined($self->{option_results}->{filter_entity}) && $self->{option_results}->{filter_entity} ne '' &&
            $results->{entities}->{$apdex} !~ /$self->{option_results}->{filter_entity}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $results->{entities}->{$apdex} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{apdex}->{$results->{entities}->{$apdex}} = {
            display => $results->{entities}->{$apdex},
            apdex => $results->{dataPoints}->{$apdex}[0][1]
        };
    }

    if (scalar(keys %{$self->{apdex}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entity machine found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Apdex.

=over 8

=item B<--relative-time>

Set request relative time (Default: 'min').
Can use: min, 5mins, 10mins, 15mins, 30mins, hour, 2hours, 6hours, day, 3days, week, month.

=item B<--filter-entity>

Filter ApDex by entity (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}, %{time}

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}, %{time}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "OPEN"').
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{entityName}, %{eventType}, %{entityId}, %{startTime}, %{endTime}, %{commentCount}, %{time}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'problems-open'.

=back

=cut
