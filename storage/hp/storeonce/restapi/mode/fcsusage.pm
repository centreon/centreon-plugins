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

package storage::hp::storeonce::restapi::mode::fcsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'status : ' . $self->{result_values}->{health};
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'fcs', type => 1, cb_prefix_output => 'prefix_fcs_output', message_multiple => 'All federated catalyst stores are ok' }
    ];
    
    $self->{maps_counters}->{fcs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'is_online' }, { name => 'health' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'used' }, { name => 'display' } ],
                output_template => 'Used : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'used', value => 'used', template => '%s',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'dedup', set => {
                key_values => [ { name => 'dedup' }, { name => 'display' } ],
                output_template => 'Dedup Ratio : %.2f',
                perfdatas => [
                    { label => 'dedup_ratio', value => 'dedup', template => '%.2f', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'items', set => {
                key_values => [ { name => 'num_items' }, { name => 'display' } ],
                output_template => 'Num Items : %s',
                perfdatas => [
                    { label => 'items', value => 'num_items', template => '%s', 
                      min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
        "warning-status:s"    => { name => 'warning_status', default => '%{is_online} == 1 and %{health} =~ /warning/i' },
        "critical-status:s"   => { name => 'critical_status', default => '%{is_online} == 1 and %{health} =~ /critical/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_fcs_output {
    my ($self, %options) = @_;
    
    return "Federated catalyst store '" . $options{instance_value}->{display} . "' ";
}

sub change_macros {
    my ($self, %options) = @_;
    
    foreach (()) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

my %mapping_health_level = (
    0 => 'unknown',
    1 => 'ok',
    2 => 'information',
    3 => 'warning',
    4 => 'critical',
);

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{fcs} = {};
    my $result = $options{custom}->get(path => '/cluster/servicesets/*all*/teaming/services/cat/stores', ForceArray => ['store']);
    if (defined($result->{stores}->{store})) {
        foreach my $entry (@{$result->{stores}->{store}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $entry->{properties}->{name} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $entry->{properties}->{name} . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{fcs}->{$entry->{properties}->{id}} = { 
                display => $entry->{properties}->{name}, 
                health => $mapping_health_level{$entry->{properties}->{healthLevel}},
                is_online => $entry->{properties}->{isOnline} eq 'true' ? 1 : 0,
                used => $entry->{properties}->{diskBytes},
                dedup => $entry->{properties}->{dedupeRatio},
                num_items => $entry->{properties}->{numItems}
            };
        }
    }
    
    if (scalar(keys %{$self->{fcs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No federated catalyst store found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check federated catalyst store usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{is_online} == 1 and %{health} =~ /warning/i').
Can used special variables like: %{health}, %{is_online}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{is_online} == 1 and %{health} =~ /critical/i').
Can used special variables like: %{health}, %{is_online}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'dedup', 'items'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'dedup', 'items'.

=back

=cut
