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

package storage::emc::xtremio::restapi::mode::dpg;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_service_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "health: %s",
        $self->{result_values}->{health}
    );
}

sub dpg_long_output {
    my ($self, %options) = @_;

    return "checking data protection group '" . $options{instance} . "'";
}

sub prefix_dpg_output {
    my ($self, %options) = @_;

    return "data protection group '" . $options{instance} . "' ";
}

sub prefix_indicator_output {
    my ($self, %options) = @_;

    return "indicator '" . $options{instance_value}->{indicator} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'dpg', type => 3, cb_prefix_output => 'prefix_dpg_output', cb_long_output => 'dpg_long_output',
          indent_long_output => '    ', message_multiple => 'All data protection groups are ok',
            group => [
                 { name => 'indicators', display_long => 1, cb_prefix_output => 'prefix_indicator_output',  message_multiple => 'All health indicators are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{indicators} = [
        {
            label => 'health-indicator',
            type => 2,
            critical_default => '%{health} !~ /done|normal|null/i',
            set => {
                key_values => [ { name => 'health' }, { name => 'indicator' } ],
                closure_custom_output => $self->can('custom_service_status_output'),
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

    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $urlbase = '/api/json/types/';
    my @items = $options{custom}->get_items(
        url => $urlbase,
        obj => 'data-protection-groups'
    );

    my @indicators = ('dpg-state', 'protection-state', 'rebuild-in-progress', 'ssd-preparation-in-progress', 'rebalance-progress');

    $self->{dpg} = {};
    foreach my $item (@items) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $item !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping dpg '" . $item . "'.", debug => 1);
            next;
        }

        my $details = $options{custom}->get_details(
            url  => $urlbase,
            obj  => 'data-protection-groups',
            name => $item
        );

        $self->{dpg}->{$item} = { indicators => {} };
        foreach (@indicators) {
            next if (!defined($details->{$_}));

            $self->{dpg}->{$item}->{indicators}->{$_} = { 
                indicator => $_,
                health => $details->{$_}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check data protection groups.

=over 8

=item B<--filter-name>

Filter data protection groups by name (can be a regexp).

=item B<--unknown-health-indicator>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{health}, %{indicator}

=item B<--warning-health-indicator>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{health}, %{indicator}

=item B<--critical-health-indicator>

Define the conditions to match for the status to be CRITICAL (default: '%{health} !~ /done|normal|null/i').
You can use the following variables: %{health}, %{indicator}

=back

=cut
