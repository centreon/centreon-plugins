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

package cloud::aws::securityhub::mode::findings;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw/is_excluded/;
use JSON::XS;

my $DEFAULT_FILTERS = {
    VulnerabilitiesFixAvailable => [ { Value => 'YES', Comparison => 'EQUALS' } ],
    RecordState => [ { Value => 'ACTIVE', Comparison => 'EQUALS' } ],
    WorkflowStatus => [
        { Value => 'NEW', Comparison => 'EQUALS' },
        { Value => 'NOTIFIED', Comparison => 'EQUALS' }
    ]
};

my @SEVERITIES = ('critical', 'high', 'medium', 'low', 'informational');

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'Findings ' },
        {
            name => 'resources', type => COUNTER_TYPE_INSTANCE, prefix_output => "resource '%{id}' type '%{type}' ",
            message_multiple => 'All resources are ok'
        }
    ];

    foreach my $severity (@SEVERITIES) {
        push @{$self->{maps_counters}->{global}}, {
            label => 'findings-' . $severity, nlabel => 'findings.' . $severity . '.total.count',
            set => {
                key_values => [ { name => $severity } ],
                output_template => $severity . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
        push @{$self->{maps_counters}->{resources}}, {
            label => 'resource-findings-' . $severity, nlabel => 'findings.' . $severity . '.total.count',
            set => {
                key_values => [ { name => $severity }, { name => 'id' }, { name => 'type' } ],
                output_template => $severity . ': %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'id' }
                ]
            }
        };
    }

    push @{$self->{maps_counters}->{resources}}, {
        label => 'resource-findings-total', nlabel => 'findings.total.count',
        set => {
            key_values => [ { name => 'total' }, { name => 'id' }, { name => 'type' } ],
            output_template => 'total: %s',
            perfdatas => [
                { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'id' }
            ]
        }
    };
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filters:s'               => { name => 'filters' },
        'include-resource-id:s'   => { name => 'include_resource_id' },
        'exclude-resource-id:s'   => { name => 'exclude_resource_id' },
        'include-resource-type:s' => { name => 'include_resource_type' },
        'exclude-resource-type:s' => { name => 'exclude_resource_type' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{filters} = $DEFAULT_FILTERS;
    if (defined($self->{option_results}->{filters}) && $self->{option_results}->{filters} ne '') {
        my $filters;
        eval {
            $filters = JSON::XS->new->utf8->decode($self->{option_results}->{filters});
        };
        if ($@ || ref($filters) ne 'HASH') {
            $self->{output}->add_option_msg(short_msg => "Cannot decode --filters option: it must be a JSON object.");
            $self->{output}->option_exit();
        }
        $self->{filters} = $filters;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $findings = $options{custom}->securityhub_get_findings(filters => $self->{filters});

    $self->{global} = { map { $_ => 0 } @SEVERITIES };
    $self->{resources} = {};
    foreach my $finding (@$findings) {
        next if (!defined($finding->{Severity}) || !defined($finding->{Severity}->{Label}));
        my $severity = lc($finding->{Severity}->{Label});
        next if (!defined($self->{global}->{$severity}));

        my $selected = 0;
        foreach my $resource (@{$finding->{Resources} // []}) {
            my $type = $resource->{Type} // '';
            next if (is_excluded($resource->{Id}, $self->{option_results}->{include_resource_id}, $self->{option_results}->{exclude_resource_id}, output => $self->{output}));
            next if (is_excluded($type, $self->{option_results}->{include_resource_type}, $self->{option_results}->{exclude_resource_type}, output => $self->{output}));

            $self->{resources}->{ $resource->{Id} } //= { id => $resource->{Id}, type => $type, total => 0, map { $_ => 0 } @SEVERITIES };
            $self->{resources}->{ $resource->{Id} }->{$severity}++;
            $self->{resources}->{ $resource->{Id} }->{total}++;
            $selected = 1;
        }

        $self->{global}->{$severity}++ if ($selected);
    }
}

1;

__END__

=head1 MODE

Check AWS Security Hub CSPM findings by severity, globally and per resource.

Example:

perl centreon_plugins.pl --plugin=cloud::aws::securityhub::plugin --custommode=awscli --mode=findings
--region='eu-west-1' --aws-access-key='****' --aws-secret-key='****'
--include-resource-type='^AwsEc2Instance$' --critical-findings-critical=0 --verbose

Required IAM permission: C<securityhub:GetFindings>.

=over 8

=item B<--filters>

Set the Security Hub findings filters (JSON). Default filters: 
'{"VulnerabilitiesFixAvailable":[{"Value":"YES","Comparison":"EQUALS"}],"RecordState":[{"Value":"ACTIVE","Comparison":"EQUALS"}],"WorkflowStatus":[{"Value":"NEW","Comparison":"EQUALS"},{"Value":"NOTIFIED","Comparison":"EQUALS"}]}'

=item B<--include-resource-id>

Filter resources by ID (can be a regexp).

=item B<--exclude-resource-id>

Exclude resources by ID (can be a regexp).

=item B<--include-resource-type>

Filter resources by type (can be a regexp). Example: '^AwsEc2Instance$'.

=item B<--exclude-resource-type>

Exclude resources by type (can be a regexp).

=item B<--warning-findings-critical>

Threshold for the total number of critical findings.

=item B<--critical-findings-critical>

Threshold for the total number of critical findings.

=item B<--warning-findings-high>

Threshold for the total number of high findings.

=item B<--critical-findings-high>

Threshold for the total number of high findings.

=item B<--warning-findings-medium>

Threshold for the total number of medium findings.

=item B<--critical-findings-medium>

Threshold for the total number of medium findings.

=item B<--warning-findings-low>

Threshold for the total number of low findings.

=item B<--critical-findings-low>

Threshold for the total number of low findings.

=item B<--warning-findings-informational>

Threshold for the total number of informational findings.

=item B<--critical-findings-informational>

Threshold for the total number of informational findings.

=item B<--warning-resource-findings-critical>

Threshold for the number of critical findings per resource.

=item B<--critical-resource-findings-critical>

Threshold for the number of critical findings per resource.

=item B<--warning-resource-findings-high>

Threshold for the number of high findings per resource.

=item B<--critical-resource-findings-high>

Threshold for the number of high findings per resource.

=item B<--warning-resource-findings-medium>

Threshold for the number of medium findings per resource.

=item B<--critical-resource-findings-medium>

Threshold for the number of medium findings per resource.

=item B<--warning-resource-findings-low>

Threshold for the number of low findings per resource.

=item B<--critical-resource-findings-low>

Threshold for the number of low findings per resource.

=item B<--warning-resource-findings-informational>

Threshold for the number of informational findings per resource.

=item B<--critical-resource-findings-informational>

Threshold for the number of informational findings per resource.

=item B<--warning-resource-findings-total>

Threshold for the total number of findings per resource (all severity types).

=item B<--critical-resource-findings-total>

Threshold for the total number of findings per resource (all severity types).

=back

=cut
