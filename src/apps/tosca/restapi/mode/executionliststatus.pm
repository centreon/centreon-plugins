#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::tosca::restapi::mode::executionliststatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf("Execution list '" . $options{instance_value}->{name} . "' entries ");
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'entries-passed', nlabel => 'entries.passed.count', set => {
                key_values => [ { name => 'passed' }, { name => 'name' } ],
                output_template => 'passed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'entries-failed', nlabel => 'entries.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'name' } ],
                output_template => 'failed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'entries-not-executed', nlabel => 'entries.not_executed.count', set => {
                key_values => [ { name => 'not_executed' }, { name => 'name' } ],
                output_template => 'not executed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'entries-unknown', nlabel => 'entries.unknown.count', set => {
                key_values => [ { name => 'unknown' }, { name => 'name' } ],
                output_template => 'unknown: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
        'workspace:s'           => { name => 'workspace' },
        'execution-list-id:s'   => { name => 'execution_list_id' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{execution_list_id}) || $self->{option_results}->{execution_list_id} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --execution-list-id option.');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{workspace}) || $self->{option_results}->{workspace} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --workspace option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %scenario_log = $options{custom}->get_execution_list(
        workspace => $self->{option_results}->{workspace},
        execution_list_id => $self->{option_results}->{execution_list_id}
    );

    $self->{global} = {
        name => $scenario_log{Name},
        passed => $scenario_log{NumberOfTestCasesPassed},
        failed => $scenario_log{NumberOfTestCasesFailed},
        not_executed => $scenario_log{NumberOfTestCasesNotExecuted},
        unknown => $scenario_log{NumberOfTestCasesWithUnknownState}
    };
}

1;

__END__

=head1 MODE

Check execution list status.

=over 8

=item B<--workspace>

Workspace name of the provided execution list.

=item B<--execution-list-id>

Execution list unique ID.

=item B<--warning-entries-*> B<--critical-entries-*>

Thresholds.
Can be: 'passed', 'failed', 'not-executed', 'unknown'.

=back

=cut
