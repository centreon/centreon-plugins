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

package cloud::azure::management::costs::mode::budgets;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_cost_perfdata {
    my ($self, %options) = @_;

    my %budget_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $budget_options{total} = $self->{result_values}->{budget};
        $budget_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        nlabel => 'azure.budget.consumption.currency',
        value => sprintf("%.2f", $self->{result_values}->{cost}),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %budget_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %budget_options),
        min => 0, max => $self->{result_values}->{budget}
    );
}

sub custom_cost_threshold {
    my ($self, %options) = @_;

    my $threshold_value = $self->{result_values}->{cost};
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_cost};
    }
    my $exit = $self->{perfdata}->threshold_check(
        value => $threshold_value,
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' }
        ]
    );
    return $exit;
}

sub custom_cost_output {
    my ($self, %options) = @_;

    return sprintf(
        "Spent amount is %.2f%s on %d%s of allowed budget (%.2f%% consumption) for the past %d days",
	$self->{result_values}->{cost},
	$self->{instance_mode}->{currency},
        $self->{result_values}->{budget},
	$self->{instance_mode}->{currency},
        $self->{result_values}->{prct_cost},
	$self->{instance_mode}->{lookup_days}
    );
}

sub custom_cost_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{cost} = $options{new_datas}->{$self->{instance} . '_cost'};
    $self->{result_values}->{budget} = $options{new_datas}->{$self->{instance} . '_budget'};
    $self->{result_values}->{prct_cost} = ($self->{result_values}->{budget} != 0) ? $self->{result_values}->{cost} * 100 / $self->{result_values}->{budget} : 0;
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'cost', type => 0 }
    ];

    $self->{maps_counters}->{cost} = [
        { label => 'cost', set => {
	    key_values => [ { name => 'cost' }, { name => 'budget' } ],
                closure_custom_calc => $self->can('custom_cost_calc'),
                closure_custom_output => $self->can('custom_cost_output'),
                closure_custom_threshold_check => $self->can('custom_cost_threshold'),
                closure_custom_perfdata => $self->can('custom_cost_perfdata')
	  }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
	    "budget-name:s"     => { name => 'budget_name' },
	    "resource-group:s"  => { name => 'resource_group' },
	    "lookup-days:s"     => { name => 'lookup_days', default => 30 },
	    "units:s"           => { name => 'units', default => '%' },
	    "timeout:s"         => { name => 'timeout', default => '60' },
    });   

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{budget_name}) || $self->{option_results}->{budget_name} eq '') {
	    $self->{output}->add_option_msg(short_msg => "Need to specify --budget-name option");
	    $self->{output}->option_exit();
    }

    $self->{lookup_days} = $self->{option_results}->{lookup_days};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $budget = $options{custom}->azure_get_budget(
        resource_group => $self->{option_results}->{resource_group},
	    budget_name => $self->{option_results}->{budget_name}
    );

    my $usage_start = DateTime->now()->add(days => - $self->{option_results}->{lookup_days} + 1);
    my $usage_end = DateTime->now();
    my $costs = $options{custom}->azure_get_usagedetails(
	    resource_group => $self->{option_results}->{resource_group},
	    usage_start    => $usage_start,
	    usage_end      => $usage_end
    );
    
    my $cost = 0;
    for (my $i = 0; $costs->[$i]; $i++) {
	    $cost += $costs->[$i]->{properties}->{cost};
    }

    if (!$budget) {
	    $self->{output}->add_option_msg(short_msg => "No " . $self->{option_results}->{budget_name} . " found (or missing permissions)");
	    $self->{output}->option_exit();
    }
    
    if (!$costs || $cost < 0.01) {
	    $self->{output}->add_option_msg(short_msg => "Null or < 0.01 " . $budget->{properties}->{currentSpend}->{unit} . " cost found on the specified scope.");
	    $self->{output}->option_exit();
    }

    $self->{currency} = $budget->{properties}->{currentSpend}->{unit};
    $self->{cost} = {
	    cost   => $cost,
	    budget => $budget->{properties}->{amount},
    };
}

1;

__END__

=head1 MODE

Check cost status.

Example:
perl centreon_plugins.pl --plugin=cloud::azure::management::costs::plugin --custommode=api --mode=costs
--resource-group='MYRESOURCEGROUP' --budget-name='MYBUDGET

You should NOT execute the plugin for a given subscription/resource group more than once a day otherwise,
you might reach the Azure API calls limit if you have many.

For subscription with large ressource with usagedetail consumption that might requite many API calls,
you may have to increase timeout.

=over 8

=item B<--budget-name>

Set budget name (required).

=item B<--resource-group>

Set resource group (optional).

=item B<--lookup-days>

Days backward to look up (default: '30').

=item B<--warning-cost>

Set warning threshold for cost).

=item B<--critical-cost>

Define the conditions to match for the status to be CRITICAL.

=item B<--units>
Unit of thresholds (default: '%') ('%', 'count').

=back

=cut
