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

package cloud::azure::policyinsights::policystates::mode::compliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_compliance_state_output {
    my ($self, %options) = @_;
    return "Compliance state for policy '$self->{result_values}->{policy_name}' on resource '$self->{result_values}->{resource_name}' is '$self->{result_values}->{compliance_state}'";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'non_compliant_policies', type => 0 },
        { name => 'compliance_state', type => 1, message_multiple => 'All compliances states are ok' }
    ];

    $self->{maps_counters}->{non_compliant_policies} = [
        { label => 'non-compliant-policies', nlabel => 'policies.non_compliant.count', set => {
                key_values => [ { name => 'non_compliant_policies' } ],
                output_template => 'Number of non compliant policies: %d',
                perfdatas => [
                    { label => 'total_non_compliant_policies', template => '%d', min => 0, unit => '' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{compliance_state} = [
        {   label => 'compliance-state',
            type => 2,
            critical_default => '%{compliance_state} eq "NonCompliant"',
            set => {
                key_values => [ { name => 'compliance_state' }, { name => 'policy_name' }, { name => 'resource_name' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_compliance_state_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'api-version:s'    => { name => 'api_version', default => '2019-10-01'},
        'policy-states:s'  => { name => 'policy_states', default => 'default' },
        'policy-name:s' => { name => 'policy_name' },
        'resource-group:s' => { name => 'resource_group' },
        'resource-location:s' => { name => 'resource_location' },
        'resource-type:s' => { name => 'resource_type' }
    });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{policy_states} = (defined($self->{option_results}->{policy_states}) && $self->{option_results}->{policy_states} ne "") ? $self->{option_results}->{policy_states} : "default";
    $self->{api_version} = (defined($self->{option_results}->{api_version}) && $self->{option_results}->{api_version} ne "") ? $self->{option_results}->{api_version} : "2019-10-01";
}

sub manage_selection {
    my ($self, %options) = @_;

    my $policy_states = $options{custom}->azure_list_policystates(
        providers => 'Microsoft.PolicyInsights/policyStates',
        resource => $self->{policy_states},
	    resource_group => $self->{option_results}->{resource_group},
        query_name => 'queryResults',
	    resource_location => $self->{option_results}->{resource_location},
	    resource_type => $self->{option_results}->{resource_type},
	    policy_name => $self->{option_results}->{policy_name}
    );

    my $non_compliant_policies = 0;
    $self->{compliance_state} = {};
    foreach my $policy_state (@{ $policy_states }) {
        my $resource_name = $policy_state->{resourceId};
        $resource_name =~ /(\w*)$/;
        $resource_name = $1;
        my $display = $policy_state->{policyDefinitionName} . "_" . $resource_name;
        $self->{compliance_state}->{ $display } = {
            display          => $display,
            compliance_state => $policy_state->{complianceState},
            policy_name      => $policy_state->{policyDefinitionName},
            resource_name    => $resource_name
        };
        $non_compliant_policies = $non_compliant_policies + 1 if $policy_state->{complianceState} eq 'NonCompliant';
    };
    $self->{non_compliant_policies} = { non_compliant_policies => $non_compliant_policies };
}

1;

__END__

=head1 MODE

Check Azure policies compliance.

Example:

perl centreon_plugins.pl --plugin=cloud::azure::policyinsights::policystates::plugin --mode=compliance --policy-states=default
[--resource-group='MYRESOURCEGROUP'] --api-version=2019-10-01


=over 8

=item B<--policy-states>

The virtual resource under PolicyStates resource type. In a given time range, 'latest' represents the latest policy state(s), whereas 'default' represents all policy state(s).

=item B<--resource-group>

Set resource group (optional).

=item B<--resource-location>

Set resource location (optional).

=item B<--resource-type>

Set resource type (optional).

=item B<--policy-name>

Set policy name (optional).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'non-compliant-policies' ,'compliance-state'.

=back

=cut
