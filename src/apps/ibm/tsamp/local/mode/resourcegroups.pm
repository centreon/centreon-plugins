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

package apps::ibm::tsamp::local::mode::resourcegroups;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'operational state: %s [nominal: %s]',
        $self->{result_values}->{opState},
        $self->{result_values}->{nominalState}
    );
}

sub prefix_rg_output {
    my ($self, %options) = @_;

    return "Resource group '" . $options{instance} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of resource groups ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'rg', type => 1, cb_prefix_output => 'prefix_rg_output', message_multiple => 'All resource groups are ok',  skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [];
    foreach ('unknown', 'offline', 'online', 'failed_offline',
        'stuck_online', 'pending_online', 'pending_offline', 'ineligible') {
        my ($label, $output) = ($_, $_);
        $label =~ s/_/-/g;
        $output =~ s/_/ /g;
        push @{$self->{maps_counters}->{global}}, {
            label => 'total-' . $label, display_ok => 0, nlabel => 'resource_groups.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $output . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{rg} = [
         {
            label => 'status',
            type => 2,
            unknown_default => '%{opState} =~ /unknown/i',
            warning_default => '%{opState} =~ /pending/i',
            critical_default => '%{opState} =~ /failed offline|stuck online/i || %{opState} ne %{nominalState}',
            set => {
                key_values => [
                    { name => 'opState' }, { name => 'nominalState' }, { name => 'name' }
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

    $options{options}->add_options(arguments => {
        'filter-rg-name:s'  => { name => 'filter_rg_name' },
        'exclude-rg-name:s' => { name => 'exclude_rg_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my ($stdout) = $options{custom}->execute_command(
        command => 'lssam',
        command_options => '-nocolor'
    );

    $self->{global} = {
        unknown => 0, offline => 0, online => 0, failed_offline => 0,
        stuck_online => 0, pending_online => 0, pending_offline => 0,
        ineligible => 0
    };

    $self->{rg} = {};
    while ($stdout =~ /^(\S.*)\s+IBM.ResourceGroup:(.*?)\s+.*?Nominal=(.*)\s*$/mig) {
        my ($name, $opState, $nominalState) = ($2, lc($1), lc($3));
        if (defined($self->{option_results}->{filter_rg_name}) && $self->{option_results}->{filter_rg_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_rg_name}/) {
            $self->{output}->output_add(long_msg => "skipping resource group '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{exclude_rg_name}) && $self->{option_results}->{exclude_rg_name} ne '' &&
            $name =~ /$self->{option_results}->{exclude_rg_name}/) {
            $self->{output}->output_add(long_msg => "skipping resource group '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{rg}->{$name} = {
            name => $name,
            opState => $opState,
            nominalState => $nominalState
        };
        $opState =~ s/\s+/_/g;
        $self->{global}->{$opState}++;
    }
}

1;

__END__

=head1 MODE

Check resource groups.

Command used: lssam -nocolor

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total'

=item B<--filter-rg-name>

Filter resource groups by name (can be a regexp).

=item B<--exclude-rg-name>

Exclude resource groups by name (can be a regexp).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN (default: '%{opState} =~ /unknown/i').
You can use the following variables: %{opState}, %{nominalState}, %{name}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{opState} =~ /pending/i').
You can use the following variables: %{opState}, %{nominalState}, %{name}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{opState} =~ /failed offline|stuck online/i || %{opState} ne %{nominalState}').
You can use the following variables: %{opState}, %{nominalState}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-unknown', 'total-offline',
'total-online', 'total-failed-offline', 'total-stuck-online', 'total-pending-online',
'total-pending-offline', 'total-ineligible'.

=back

=cut
