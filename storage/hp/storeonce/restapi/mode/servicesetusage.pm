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

package storage::hp::storeonce::restapi::mode::servicesetusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf('status : %s [replication health: %s] [housekeeping health: %s]', 
        $self->{result_values}->{health}, $self->{result_values}->{replication_health}, $self->{result_values}->{housekeeping_health});
    return $msg;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }

    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(
        label => $label, unit => 'B',
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $value_perf,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, %total_options),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, %total_options),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($self->{instance_mode}->{option_results}->{free}));
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($self->{instance_mode}->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    my $msg = sprintf("Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                   $total_size_value . " " . $total_size_unit,
                   $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                   $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'scs', type => 1, cb_prefix_output => 'prefix_scs_output', message_multiple => 'All service sets are ok' }
    ];
    
    $self->{maps_counters}->{scs} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'health' }, { name => 'replication_health' }, { name => 'housekeeping_health' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
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

    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-name:s"       => { name => 'filter_name' },
        "warning-status:s"    => { name => 'warning_status', default => '%{health} =~ /warning/' },
        "critical-status:s"   => { name => 'critical_status', default => '%{health} =~ /critical/' },
        "units:s"             => { name => 'units', default => '%' },
        "free"                => { name => 'free' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub prefix_scs_output {
    my ($self, %options) = @_;
    
    return "Service set '" . $options{instance_value}->{display} . "' ";
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
    
    $self->{scs} = {};
    my $result = $options{custom}->get(path => '/cluster/servicesets', ForceArray => ['serviceset']);
    if (defined($result->{servicesets}->{serviceset})) {
        foreach my $entry (@{$result->{servicesets}->{serviceset}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $entry->{properties}->{alias} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $entry->{properties}->{alias} . "': no matching filter.", debug => 1);
                next;
            }
            
            $self->{scs}->{$entry->{properties}->{ssid}} = { 
                display => $entry->{properties}->{alias}, 
                health => $mapping_health_level{$entry->{properties}->{healthLevel}},
                housekeeping_health => $mapping_health_level{$entry->{properties}->{housekeepingHealthLevel}},
                replication_health => $mapping_health_level{$entry->{properties}->{repHealthLevel}},
                total => $entry->{properties}->{capacityBytes}, 
                used => $entry->{properties}->{capacityBytes} - $entry->{properties}->{freeBytes},
                dedup => $entry->{properties}->{dedupeRatio}
            };
        }
    }
    
    if (scalar(keys %{$self->{scs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service set found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check service set usages.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-name>

Filter service set name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{health} =~ /warning/).
Can used special variables like: %{health}, %{replication_health}, %{housekeeping_health}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health} =~ /critical/').
Can used special variables like: %{health}, %{replication_health}, %{housekeeping_health}, %{display}

=item B<--warning-*>

Threshold warning.
Can be: 'usage', 'dedup'.

=item B<--critical-*>

Threshold critical.
Can be: 'usage', 'dedup'.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=back

=cut
