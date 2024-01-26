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

package apps::tosca::restapi::mode::scenariostatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output {
    my ($self, %options) = @_;

    return sprintf("Scenario '" . $options{instance_value}->{name} . "' ");
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "result is '%s' [start time:'%s', end time:'%s']",
        $self->{result_values}->{result},
        $self->{result_values}->{start_time},
        $self->{result_values}->{end_time}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', type => 2, critical_default => '%{result} !~ /Passed/', set => {
                key_values => [ { name => 'result' }, { name => 'start_time' }, { name => 'end_time' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'duration', nlabel => 'scenario.duration.seconds', set => {
                key_values => [ { name => 'duration' }, { name => 'name' } ],
                output_template => 'duration: %.2f seconds',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 's' }
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
        'workspace:s'     => { name => 'workspace' },
        'scenario-id:s'   => { name => 'scenario_id' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{scenario_id}) || $self->{option_results}->{scenario_id} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --scenario-id option.');
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{workspace}) || $self->{option_results}->{workspace} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --workspace option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %scenario_log = $options{custom}->get_scenario_last_log(
        workspace => $self->{option_results}->{workspace},
        scenario_id => $self->{option_results}->{scenario_id}
    );

    $self->{global} = {
        name => $scenario_log{Name},
        result => $scenario_log{Result},
        start_time => $scenario_log{StartTime},
        end_time => $scenario_log{EndTime},
        duration => $scenario_log{Duration} / 1000
    };
}

1;

__END__

=head1 MODE

Check scenario status.

=over 8

=item B<--workspace>

Workspace name of the provided scenario.

=item B<--scenario-id>

Scenario unique ID.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{result}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{result} !~ /Passed/').
You can use the following variables: %{result}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'duration'.

=back

=cut
