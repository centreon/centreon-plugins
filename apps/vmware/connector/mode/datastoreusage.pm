#
# Copyright 2020 Centreon (http://www.centreon.com/)
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
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'accessible ' . $self->{result_values}->{accessible};
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf(
        'Usage Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space}
    );
    return $msg;
}

sub custom_provisioned_output {
    my ($self, %options) = @_;

    my ($total_uncomitted_value, $total_uncommitted_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_uncommitted});
    my $msg = sprintf(
        'Provisioned: %s (%.2f%%)',
        $total_uncomitted_value . " " . $total_uncommitted_unit,
        $self->{result_values}->{prct_uncommitted}
    );
    return $msg;
}

sub custom_provisioned_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total_space} = $options{new_datas}->{$self->{instance} . '_total_space'};

    if ($self->{result_values}->{total_space} <= 0) {
        return -10;
    }
    
    $self->{result_values}->{total_uncommitted} = 
        ($self->{result_values}->{total_space} - $options{new_datas}->{$self->{instance} . '_free_space'}) + $options{new_datas}->{$self->{instance} . '_uncommitted'};
    $self->{result_values}->{prct_uncommitted} = $self->{result_values}->{total_uncommitted} * 100 / $self->{result_values}->{total_space};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datastore', type => 1, cb_prefix_output => 'prefix_datastore_output', message_multiple => 'All datastores are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{datastore} = [
        {
            label => 'status', type => 2, unknown_default => '%{accessible} !~ /^true|1$/i',
            set => {
                key_values => [ { name => 'accessible' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'usage', nlabel => 'datastore.space.usage.bytes', set => {
                key_values => [ { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-free', nlabel => 'datastore.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'free', template => '%d', min => 0, max => 'total_space',
                      unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'usage-prct', nlabel => 'datastore.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used_space' }, { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label => 'used_prct', template => '%.2f', min => 0, max => 100,
                      unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'provisioned', nlabel => 'datastore.space.provisioned.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'uncommitted' }, { name => 'total_space' }, { name => 'free_space' } ],
                closure_custom_calc => $self->can('custom_provisioned_calc'),
                closure_custom_output => $self->can('custom_provisioned_output'),
                threshold_use => 'prct_uncommitted',
                perfdatas => [
                    { label => 'provisioned', value => 'total_uncommitted', template => '%s', unit => 'B', 
                      min => 0, max => 'total_space', label_extra_instance => 1 }
                ]
            }
        }
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
    
    $options{options}->add_options(arguments => { 
        'datastore-name:s'   => { name => 'datastore_name' },
        'filter'             => { name => 'filter' },
        'scope-datacenter:s' => { name => 'scope_datacenter' },
        'filter-host:s'      => { name => 'filter_host' },
        'units:s'            => { name => 'units', default => '' },
        'free'               => { name => 'free' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;

    # Compatibility
    $self->compat_threshold_counter(%options,
        compat => {
            th => [
                [ 'usage', { free => 'usage-free', prct => 'usage-prct'} ],
                [ 'instance-datastore-space-usage-bytes', { free => 'instance-datastore-space-free-bytes', prct => 'instance-datastore-space-usage-percentage' } ]
            ],
            units => $options{option_results}->{units},
            free => $options{option_results}->{free}
        }
    );

    $self->SUPER::check_options(%options);
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

sub manage_selection {
    my ($self, %options) = @_;

    my $response = $options{custom}->execute(
        params => $self->{option_results},
        command => 'datastoreusage'
    );

    $self->{datastore} = {};
    foreach my $ds_id (keys %{$response->{data}}) {
        my $ds_name = $response->{data}->{$ds_id}->{name};

        if (defined($response->{data}->{$ds_id}->{hosts}) && defined($self->{option_results}->{filter_host}) && $self->{option_results}->{filter_host} ne '') {
            my $filtered = 0;
            foreach (@{$response->{data}->{$ds_id}->{hosts}}) {
                $filtered = 1 if (/$self->{option_results}->{filter_host}/);
            }
            next if ($filtered == 0);
        }

        if ($response->{data}->{$ds_id}->{size} <= 0) {
            $self->{output}->output_add(long_msg => "skipping datastore '" . $ds_name . "': no total size");
            next;
        }

        $self->{datastore}->{$ds_name} = { 
            display => $ds_name, 
            accessible => $response->{data}->{$ds_id}->{accessible},
            used_space => $response->{data}->{$ds_id}->{size} - $response->{data}->{$ds_id}->{free}, 
            free_space => $response->{data}->{$ds_id}->{free},
            total_space => $response->{data}->{$ds_id}->{size},
            prct_used_space => ($response->{data}->{$ds_id}->{size} - $response->{data}->{$ds_id}->{free}) * 100 / $response->{data}->{$ds_id}->{size},
            prct_free_space => $response->{data}->{$ds_id}->{free} * 100 / $response->{data}->{$ds_id}->{size},
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

=item B<--filter-host>

Filter datastores attached to hosts (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{accessible} !~ /^true|1$/i').
Can used special variables like: %{accessible}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{accessible}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: Can be: 'usage' (B), 'usage-free' (B), 'usage-prct' (%),
'provisioned'.

=back

=cut
