#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package apps::backup::rubrik::graphql::mode::compliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_excluded value_of flatten_arrays/;
use apps::backup::rubrik::graphql::common qw/check_compliance_timerange/;

sub custom_status_output {
    my ($self, %options) = @_;

    return 'compliance status: ' . $self->{result_values}->{status} . ', protection status: ' . $self->{result_values}->{protection_status};
}

sub prefix_object_output {
    my ($self, %options) = @_;

    return "object '" . $options{instance_value}->{name} . "' (" . $options{instance_value}->{id} . ") " .
        ( $self->{output}->is_verbose() ?
            "cluster '" . $options{instance_value}->{cluster_name} . "' ".
            "slaDomain '" . $options{instance_value}->{sla_domain_name} . "' ".
            "objectType '" . $options{instance_value}->{object_type}. "' " :
            '' );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL  },
        { name => 'objects', type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_object_output', message_multiple => 'All objects are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'objects-count', nlabel => 'objects.count', critical_default => '0:0', set => {
                key_values => [ { name => 'count' } ],
                output_template => 'Total number of returned objects: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{objects} = [
        { label => 'status', type => COUNTER_KIND_TEXT, set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'protection_status' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'missed-snapshots', nlabel => 'object.snapshots.missed.count', display_ok => 0, set => {
                key_values => [ { name => 'missed_snapshots' } ],
                output_template => 'missed snapshots: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
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
        'object-type:s@'               => { name => 'object_type' },
        'excluded-object-type:s@'      => { name => 'excluded_object_type' },
        'object-state:s@'              => { name => 'object_state' },
        'protection-status:s@'         => { name => 'protection_status' },
        'compliance-status:s@'         => { name => 'compliance_status' },
        'sla-domain-id:s'              => { name => 'sla_domain_id',          default => '' },
        'include-object-id:s'          => { name => 'include_object_id',      default => '' },
        'exclude-object-id:s'          => { name => 'exclude_object_id',      default => '' },
        'include-object-name:s'        => { name => 'include_object_name',    default => '' },
        'exclude-object-name:s'        => { name => 'exclude_object_name',    default => '' },
        'include-object-type:s'        => { name => 'include_object_type',    default => '' },
        'exclude-object-type:s'        => { name => 'exclude_object_type',    default => '' },
        'include-location:s'           => { name => 'include_location',       default => '' },
        'exclude-location:s'           => { name => 'exclude_location',       default => '' },
        'include-compliance-status:s'  => { name => 'include_compliance_status',   default => '' },
        'exclude-compliance-status:s'  => { name => 'exclude_compliance_status',   default => '' },
        'time-range:s'                 => { name => 'time_range',             default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{$_} = flatten_arrays($self->{option_results}->{$_}) foreach qw/object_type excluded_object_type object_state protection_status compliance_status/;
    $self->{option_results}->{compliance_status} = [ 'OUT_OF_COMPLIANCE' ]
        unless $self->{option_results}->{compliance_status} && @{$self->{option_results}->{compliance_status}};
    $self->{option_results}->{compliance_status} = [ grep { ! /^ALL$/ } @{$self->{option_results}->{compliance_status}} ];
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($valid, $label) = check_compliance_timerange(timerange => $self->{option_results}->{time_range});
    $self->{output}->option_exit(short_msg => $label) unless $valid;

    my $cluster_filters = $options{custom}->common_filters();

    # get_snappable_connection does not support native filtering by name, so we convert names to UUIDs
    my $cluster_ids = $cluster_filters->{id} // [];
    if ($cluster_filters->{name}) {
        my $other_clusters = $options{custom}->clusters_uuid_from_name(@{$cluster_filters->{name}});

        $self->{output}->option_exit(short_msg => 'No matching cluster !')
            unless ref $other_clusters eq 'ARRAY' && @$other_clusters;

        push @$cluster_ids, @$other_clusters;
    }

    my %filters;
    $filters{cluster} = { id => $cluster_ids } if $cluster_ids && @$cluster_ids;
    $filters{complianceStatus} = $self->{option_results}->{compliance_status} if @{$self->{option_results}->{compliance_status}};
    $filters{objectType} = $self->{option_results}->{object_type} if @{$self->{option_results}->{object_type}};
    $filters{excludedObjectTypes} = $self->{option_results}->{excluded_object_type} if @{$self->{option_results}->{excluded_object_type}};
    $filters{objectState} = $self->{option_results}->{object_state} if @{$self->{option_results}->{object_state}};
    $filters{protectionStatus} = $self->{option_results}->{protection_status} if @{$self->{option_results}->{protection_status}};

    $filters{slaTimeRange} = uc $self->{option_results}->{time_range} if $self->{option_results}->{time_range} ne '';
    $filters{slaDomain} = { id => $self->{option_results}->{sla_domain_id} } if $self->{option_results}->{sla_domain_id} ne '';

    my $result = $options{custom}->get_snappable_compliance(
        filters => \%filters
    );

    $self->{global} = { count => 0 };
    $self->{objects} = {};

    $self->{output}->option_exit(short_msg => 'No matching data !')
        unless ref $result eq 'ARRAY';

    foreach my $obj (@$result) {
        next if exists $self->{objects}->{$obj->{id}};
        next if is_excluded($obj->{id}, $self->{option_results}->{include_object_id}, $self->{option_results}->{exclude_object_id}) ||
                is_excluded($obj->{name}, $self->{option_results}->{include_object_name}, $self->{option_results}->{exclude_object_name}) ||
                is_excluded($obj->{objectType}, $self->{option_results}->{include_object_type}, $self->{option_results}->{exclude_object_type}) ||
                is_excluded($obj->{location}, $self->{option_results}->{include_location}, $self->{option_results}->{exclude_location}) ||
                is_excluded($obj->{complianceStatus}, $self->{option_results}->{include_compliance_status}, $self->{option_results}->{exclude_compliance_status});
        my $cluster_id = value_of($obj, "->{cluster}->{id}", '');
        my $cluster_name =value_of($obj, "->{cluster}->{name}", '');
        next if $options{custom}->is_common_excluded(id => $cluster_id, name => $cluster_name);

        $self->{objects}->{ $obj->{id} } = {
            name => $obj->{name},
            id => $obj->{id},
            status => $obj->{complianceStatus},
            protection_status => $obj->{protectionStatus},
            object_type => $obj->{objectType},
            location => $obj->{location},
            sla_domain_name => value_of($obj, "->{slaDomain}->{name}", ''),
            cluster_name => $cluster_name,
            missed_snapshots => $obj->{missedSnapshots}
        };

        $self->{global}->{count}++;
    }
}

1;

__END__

=head1 MODE

Check compliance status via GraphQL API.

=over 8

=item B<--object-type>

Filter by object type.
Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--excluded-object-type>

Exclude objects by type.
Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--object-state>

Filter by object state.
Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--protection-status>

Filter by protection status.
Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--sla-domain-id>

Filter by SLA domain ID. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--include-object-id>

Include object ID (can be a regexp).

=item B<--exclude-object-id>

Exclude object ID (can be a regexp).

=item B<--include-object-name>

Include object name (can use regex).

=item B<--exclude-object-name>

Exclude object name (can use regex).

=item B<--include-object-type>

Include object type (can use regex).

=item B<--exclude-object-type>

Exclude object type.
Multiple values can be separated by comma. This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--include-location>

Include location (can use regex).

=item B<--exclude-location>

Exclude location (can use regex).

=item B<--compliance-status>

Filter by compliance status. Multiple values can be separated by comma (default: 'OUT_OF_COMPLIANCE').
This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--include-compliance-status>

Include compliance status (can be a regexp).

=item B<--exclude-compliance-status>

Exclude compliance status (can be a regexp).

=item B<--time-range>

Time range for compliance check. Accepted values: 'LAST_24_HOURS', 'LAST_2_SNAPSHOTS', 'LAST_3_SNAPSHOTS', 'LAST_SNAPSHOT', 'PAST_7_DAYS', 'PAST_30_DAYS', 'PAST_90_DAYS', 'SINCE_PROTECTION'.
This filter is passed directly to the GraphQL API (server-side filtering).

=item B<--warning-objects-count>

Warning threshold for total number of returned objects.

=item B<--critical-objects-count>

Critical threshold for total number of returned objects (default: '0:0').

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}

=item B<--warning-missed-snapshots>

Warning threshold for missed snapshots.

=item B<--critical-missed-snapshots>

Critical threshold for missed snapshots.

=back

=cut
