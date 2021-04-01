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

package apps::rudder::restapi::mode::nodecompliance;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Compliance: %.2f%%", $self->{result_values}->{compliance});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{rule} = $options{new_datas}->{$self->{instance} . '_rule'};
    $self->{result_values}->{compliance} = $options{new_datas}->{$self->{instance} . '_compliance'};
    $self->{result_values}->{display} = $self->{instance};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'nodes', type => 3, cb_prefix_output => 'prefix_node_output', cb_long_output => 'long_output',
          message_multiple => 'All nodes compliance are ok', indent_long_output => '    ',
            group => [
                { name => 'global',  type => 0, skipped_code => { -10 => 1 } },
                { name => 'rules', display_long => 1, cb_prefix_output => 'prefix_rule_output',
                  message_multiple => 'All rules compliance are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'node-compliance', set => {
                key_values => [ { name => 'compliance' }, { name => 'display' } ],
                output_template => 'Compliance: %.2f%%',
                perfdatas => [
                    { label => 'node_compliance', value => 'compliance', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    $self->{maps_counters}->{rules} = [
        { label => 'status', set => {
                key_values => [ { name => 'compliance' }, { name => 'rule' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_node_output {
    my ($self, %options) = @_;

    return "Node '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub prefix_rule_output {
    my ($self, %options) = @_;
    
    return "Rule '" . $options{instance_value}->{rule} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking node '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"         => { name => 'filter_name' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{nodes} = {};

    my $results = $options{custom}->request_api(url_path => '/compliance/nodes?level=2');
    
    foreach my $node (@{$results->{nodes}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $node->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $node->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{nodes}->{$node->{id}}->{id} = $node->{id};
        $self->{nodes}->{$node->{id}}->{display} = $node->{name};
        $self->{nodes}->{$node->{id}}->{global}->{compliance} = $node->{compliance};
        $self->{nodes}->{$node->{id}}->{global}->{display} = $node->{name};

        foreach my $rule (@{$node->{rules}}) {
            $self->{nodes}->{$node->{id}}->{rules}->{$rule->{id}} = {
                rule => $rule->{name},
                compliance => $rule->{compliance},
            };
        }
    }
    
    if (scalar(keys %{$self->{nodes}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No nodes found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check nodes compliance.

=over 8

=item B<--filter-name>

Filter node name (regexp can be used)

=item B<--warning-node-compliance>

Set warning threshold on node compliance.

=item B<--critical-node-compliance>

Set critical threshold on node compliance.

=item B<--warning-status>

Set warning threshold for status of rule compliance (Default: '').
Can used special variables like: %{rule}, %{compliance}

=item B<--critical-status>

Set critical threshold for status of rule compliance (Default: '').
Can used special variables like: %{rule}, %{compliance}

Example :
  --critical-status='%{rule} eq "Global configuration for all nodes" && %{compliance} < 95'

=back

=cut
