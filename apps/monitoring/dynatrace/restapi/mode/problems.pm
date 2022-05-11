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

package apps::monitoring::dynatrace::restapi::mode::problems;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    return sprintf(
        "problem '%s' [severity: %s] [impact: %s] [management zone: %s] [entity: %s]",
        $self->{result_values}->{displayName},
        $self->{result_values}->{severityLevel},
        $self->{result_values}->{impactLevel},
        $self->{result_values}->{managementZone},
        $self->{result_values}->{entityName}
    );
}

sub prefix_management_zones_output {
    my ($self, %options) = @_;

    return "Management Zone '" . $options{instance_value}->{displayName} . "' ";
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Problem '" . $self->{result_values}->{managementZone} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'management_zone', type => 1, cb_prefix_output => 'prefix_management_zones_output', message_multiple => 'All management zones are OK', skipped_code => { -10 => 1 } },
        { name => 'problem', type => 2,
          group => [ { name => 'problem' } ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'problems-open', nlabel => 'total.problems.open.count', display_ok => 0, set => {
                key_values => [ { name => 'problems_open' } ],
                output_template => 'number of open problems : %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{management_zone} = [
        { label => 'managementzone-problems-open', nlabel => 'problems.open.count', display_ok => 0, set => {
                key_values => [ { name => 'problems_open' }, { name => 'displayName' } ],
                output_template => 'number of open problems : %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'displayName' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{problem} = [
        { label => 'status', type => 2, critical_default => '%{status} eq "OPEN"', set => {
                key_values => [
                    { name => 'status' }, { name => 'impactLevel' }, { name => 'severityLevel' }, 
                    { name => 'entityName' }, { name => 'entityId' }, { name => 'displayName' }, 
                    { name => 'startTime' }, { name => 'endTime' }, { name => 'time' }, { name => 'managementZone' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
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
        'entity:s'          => { name => 'filter_entity' },
        'management-zone:s' => { name => 'filter_management_zone' },
        'relative-time:s'   => { name => 'relative_time', default => '2h' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $problem = $options{custom}->get_problems();
    my ($i, $time) = (1, time());
    my $management_zones;
    my $management_zone_name;
    my $entities;

    foreach my $item (@{$problem->{problems}}) {
        if (!defined(@{$item->{managementZones}}[0]->{name})) {
            $management_zones = 'undefined_management_zone';
        } else {
            $management_zones = join(",", centreon::plugins::misc::uniq(map { "$_->{name}" } @{$item->{managementZones}}));
        }
        $entities = join(",", centreon::plugins::misc::uniq(map { "$_->{name}" } @{$item->{impactedEntities}}));
        
        if ($item->{status} eq 'OPEN') {
            $self->{global}->{problems_open}++;
            foreach my $management_zones (@{$item->{managementZones}}) {
                $management_zone_name = defined($management_zones->{name}) ? $management_zones->{name} : 'undefined_management_zone';
                # if (defined($self->{option_results}->{filter_management_zone}) && $self->{option_results}->{filter_management_zone} ne '' &&
                #     $management_zone_name !~ /$self->{option_results}->{filter_management_zone}/) {
                #     next;
                # }
                $self->{management_zone}->{$management_zone_name}->{problems_open}++;
            }
        }

        $self->{problem}->{global}->{problem}->{$i} = {
            displayName    => $item->{title},
            status         => $item->{status},
            impactLevel    => $item->{impactLevel},
            severityLevel  => $item->{severityLevel},
            managementZone => $management_zones,
            entityName     => $entities,
            entityId       => join(",", centreon::plugins::misc::uniq(map { "$_->{entityId}->{id}" } @{$item->{impactedEntities}})),
            startTime      => $item->{startTime} / 1000,
            endTime        => $item->{endTime} > -1 ? $item->{endTime} / 1000 : -1,
            time           => $time
        };
        $i++;
    }

    if (scalar(keys %{$self->{problem}->{global}->{problem}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No problem found.");
        $self->{output}->option_exit();
    }

    foreach my $management_zone (keys %{$self->{management_zone}}) {
        $self->{management_zone}->{$management_zone}->{displayName} = $management_zone;
    }

}

1;

__END__

=head1 MODE

Check open problems.

=over 8

=item B<--relative-time>

Set request relative time (Default: '2h').
Can use: Xm (minutes), Xh (hours), Xd (days), Xm (months), Xy (year) where 'X' is the amount of time.

=item B<--management-zone>

Filter problems by management zone. Mutliple management zones need to be separated by comma.
Example: --management-zone='MZ1,MZ2'

=item B<--entity>

Filter problems by entity. Mutliple entities need to be separated by comma.
Example: --entity='entity1,entity2'

=item B<--unknown-status>

Set unknown threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{managementZone}, %{entityName}, %{entityId}, %{startTime}, %{endTime}, %{time}

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{managementZone}, %{entityName}, %{entityId}, %{startTime}, %{endTime}, %{time}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "OPEN"').
Can use special variables like: %{status}, %{impactLevel}, %{severityLevel}, %{managementZone}, %{entityName}, %{entityId}, %{startTime}, %{endTime}, %{time}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'problems-open', 'managementzone-problems-open'.

=back

=cut
