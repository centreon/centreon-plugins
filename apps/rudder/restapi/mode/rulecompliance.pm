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

package apps::rudder::restapi::mode::rulecompliance;

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

    $self->{result_values}->{directive} = $options{new_datas}->{$self->{instance} . '_directive'};
    $self->{result_values}->{compliance} = $options{new_datas}->{$self->{instance} . '_compliance'};
    $self->{result_values}->{display} = $self->{instance};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rules', type => 3, cb_prefix_output => 'prefix_rule_output', cb_long_output => 'long_output',
          message_multiple => 'All rules compliance are ok', indent_long_output => '    ',
            group => [
                { name => 'global',  type => 0, skipped_code => { -10 => 1 } },
                { name => 'directives', display_long => 1, cb_prefix_output => 'prefix_directive_output',
                  message_multiple => 'All directives compliance are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'rule-compliance', set => {
                key_values => [ { name => 'compliance' } ],
                output_template => 'Compliance: %.2f%%',
                perfdatas => [
                    { label => 'rule_compliance', value => 'compliance', template => '%.2f',
                      min => 0, max => 100, unit => '%', label_extra_instance => 1 },
                ],
            }
        },
    ];
    $self->{maps_counters}->{directives} = [
        { label => 'status', set => {
                key_values => [ { name => 'compliance' }, { name => 'directive' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_rule_output {
    my ($self, %options) = @_;

    return "Rule '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
}

sub prefix_directive_output {
    my ($self, %options) = @_;
    
    return "Directive '" . $options{instance_value}->{directive} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking rule '" . $options{instance_value}->{display} . "' [Id: " . $options{instance_value}->{id} . "] ";
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

    my %rules_mapping;
    $self->{rules} = {};

    my $results = $options{custom}->request_api(url_path => '/rules');
    
    foreach my $rule (@{$results->{rules}}) {
        $rules_mapping{$rule->{id}} = $rule->{displayName};
    }

    $results = $options{custom}->request_api(url_path => '/compliance/rules?level=2');
    
    foreach my $rule (@{$results->{rules}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $rules_mapping{$rule->{id}} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $rules_mapping{$rule->{id}} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{rules}->{$rule->{id}}->{id} = $rule->{id};
        $self->{rules}->{$rule->{id}}->{display} = $rules_mapping{$rule->{id}};
        $self->{rules}->{$rule->{id}}->{global}->{compliance} = $rule->{compliance};

        foreach my $directive (@{$rule->{directives}}) {
            $self->{rules}->{$rule->{id}}->{directives}->{$directive->{id}} = {
                directive => $directive->{name},
                compliance => $directive->{compliance},
            };
        }
    }
    
    if (scalar(keys %{$self->{rules}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No rules found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check rules compliance.

=over 8

=item B<--filter-name>

Filter rule name (regexp can be used)

=item B<--warning-rule-compliance>

Set warning threshold on rule compliance.

=item B<--critical-rule-compliance>

Set critical threshold on rule compliance.

=item B<--warning-status>

Set warning threshold for status of directive compliance (Default: '').
Can used special variables like: %{directive}, %{compliance}

=item B<--critical-status>

Set critical threshold for status of directive compliance (Default: '').
Can used special variables like: %{directive}, %{compliance}

Example :
  --critical-status='%{directive} eq "Users" && %{compliance} < 85'

=back

=cut
