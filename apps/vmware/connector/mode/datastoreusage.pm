#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::datastoreusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'accessible ' . $self->{result_values}->{accessible};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{accessible} = $options{new_datas}->{$self->{instance} . '_accessible'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{display} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($self->{instance_mode}->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
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
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
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
    
    if ($self->{result_values}->{total} <= 0) {
        $self->{error_msg} = 'size is 0';
        return -20;
    }
    
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_free'};
    $self->{result_values}->{used} = $self->{result_values}->{total} - $self->{result_values}->{free};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};

    return 0;
}

sub custom_provisioned_output {
    my ($self, %options) = @_;

    my ($total_uncomitted_value, $total_uncommitted_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_uncommitted});
    my $msg = sprintf("Provisioned: %s (%.2f%%)",
                   $total_uncomitted_value . " " . $total_uncommitted_unit,
                   $self->{result_values}->{prct_uncommitted});
    return $msg;
}

sub custom_provisioned_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};

    if ($self->{result_values}->{total} <= 0) {
        return -10;
    }
    
    $self->{result_values}->{total_uncommitted} = 
        ($self->{result_values}->{total} - $options{new_datas}->{$self->{instance} . '_free'}) + $options{new_datas}->{$self->{instance} . '_uncommitted'};
    $self->{result_values}->{prct_uncommitted} = $self->{result_values}->{total_uncommitted} * 100 / $self->{result_values}->{total};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datastore', type => 1, cb_prefix_output => 'prefix_datastore_output', message_multiple => 'All datastores are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{datastore} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'accessible' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'usage', set => {
                key_values => [ { name => 'display' }, { name => 'free' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'provisioned', set => {
                key_values => [ { name => 'display' }, { name => 'uncommitted' }, { name => 'total' }, { name => 'free' } ],
                closure_custom_calc => $self->can('custom_provisioned_calc'),
                closure_custom_output => $self->can('custom_provisioned_output'),
                threshold_use => 'prct_uncommitted',
                perfdatas => [
                    { label => 'provisioned', value => 'total_uncommitted', template => '%s', unit => 'B', 
                      min => 0, max => 'total', label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_datastore_output {
    my ($self, %options) = @_;

    return "Datastore '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => { 
        "datastore-name:s"      => { name => 'datastore_name' },
        "filter"                => { name => 'filter' },
        "scope-datacenter:s"    => { name => 'scope_datacenter' },
        "units:s"               => { name => 'units', default => '%' },
        "free"                  => { name => 'free' },
        "unknown-status:s"      => { name => 'unknown_status', default => '%{accessible} !~ /^true|1$/i' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
    if (!defined($self->{option_results}->{units}) || $self->{option_results}->{units} !~ /^(%|B)$/) {
        $self->{output}->add_option_msg(short_msg => "Wrong units option '" . $self->{option_results}->{units} . "'.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{datastore} = {};
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'datastoreusage');
    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};
        $self->{datastore}->{$ds_name} = { 
            display => $ds_name, 
            accessible => $response->{data}->{$ds_id}->{accessible},
            free => $response->{data}->{$ds_id}->{free},
            total => $response->{data}->{$ds_id}->{size},
            uncommitted => $response->{data}->{$ds_id}->{uncommitted},
        };        
    }    
}

1;

__END__

=head1 MODE

Check datastore usage.

=over 8

=item B<--datastore-name>

datastore name to list.

=item B<--filter>

Datastore name is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{accessible} !~ /^true|1$/i').
Can used special variables like: %{accessible}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'snapshot'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'snapshot'.

=back

=cut
