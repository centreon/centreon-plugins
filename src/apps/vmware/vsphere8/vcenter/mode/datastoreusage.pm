#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::vmware::vsphere8::vcenter::mode::datastoreusage;

use base qw(apps::vmware::vsphere8::vcenter::mode);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return "'" . $self->{result_values}->{display} . "' accessible" if ($self->{result_values}->{accessible} eq 'true');
    return "'" . $self->{result_values}->{display} . "' NOT accessible" if ($self->{result_values}->{accessible} ne 'true');
}

sub custom_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total_space});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used_space});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free_space});
    my $msg = sprintf(
        'Used: %s (%.2f%%) - Free: %s (%.2f%%) - Total: %s',
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used_space},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free_space},
        $total_size_value . " " . $total_size_unit
    );
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datastore', type => 1, cb_prefix_output => 'prefix_datastore_output', message_multiple => 'All datastores are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{datastore} = [
        {
            label           => 'status',
            type            => 2,
            critical_default => '%{accessible} ne "true"',
            set => {
                key_values => [ { name => 'accessible' }, { name => 'display' },
                                { name => 'thin_provisioning_supported' }, { name => 'multiple_host_access' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label  => 'usage',
            nlabel => 'datastore.space.usage.bytes',
            type   => 1,
            set    => {
                key_values => [
                    { name => 'used_space' }, { name => 'free_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label  => 'used', template => '%d', min => 0, max => 'total_space',
                        unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        {
            label      => 'usage-free',
            nlabel     => 'datastore.space.free.bytes',
            display_ok => 0,
            type       => 1,
            set        => {
                key_values => [
                    { name => 'free_space' }, { name => 'used_space' }, { name => 'prct_used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label  => 'free', template => '%d', min => 0, max => 'total_space',
                        unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        {
            label      => 'usage-prct',
            nlabel     => 'datastore.space.usage.percentage',
            display_ok => 0,
            type       => 1,
            set        => {
                key_values => [
                    { name => 'prct_used_space' }, { name => 'free_space' }, { name => 'used_space' },
                    { name => 'prct_free_space' }, { name => 'total_space' }, { name => 'display' }
                ],
                closure_custom_output => $self->can('custom_usage_output'),
                perfdatas => [
                    { label  => 'used_prct', template => '%.2f', min => 0, max => 100,
                        unit => '%', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);

    $options{options}->add_options(
        arguments => {
            'include-name:s'  => { name => 'include_name', default => '' },
            'exclude-name:s'  => { name => 'exclude_name', default => '' }
        }
    );
    $options{options}->add_help(package => __PACKAGE__, sections => 'MODE', once => 1);

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    # get the list of datastores response from /api/vcenter/datastore endpoint
    my $response = $self->get_datastore(%options);

    for my $ds (@{$response}) {

        # exclude datastores not whitelisted
        if ( centreon::plugins::misc::is_excluded($ds->{name}, $self->{option_results}->{include_name}, $self->{option_results}->{exclude_name}) ) {
            $self->{output}->output_add(long_msg => "skipping excluded datastore '" . $ds->{name} . "'", debug => 1);
            next;
        }

        # at this point the current datastore must be monitored
        # let's get the missing data for the current datastore with a new API request
        my $detail = $self->get_datastore(%options, datastore_id => $ds->{datastore});
        # and now we store the information
        $self->{datastore}->{$ds->{datastore}} = {
            display                     => $ds->{name},
            type                        => $ds->{type},
            free_space                  => $ds->{free_space},
            total_space                 => $ds->{capacity},
            used_space                  => $ds->{capacity} - $ds->{free_space},
            prct_used_space             => 100 * ($ds->{capacity} - $ds->{free_space}) / $ds->{capacity},
            prct_free_space             => 100 * $ds->{free_space} / $ds->{capacity},
            thin_provisioning_supported => $detail->{thin_provisioning_supported},
            accessible                  => $detail->{accessible},
            multiple_host_access        => $detail->{multiple_host_access}
        };
    }
}

1;

__END__

=head1 MODE

Monitor the usage of a vCenter's datastores through vSphere 8 REST API.

=over 8

=item B<--include-name>

Filter by including only the VMs whose name matches the regular expression provided after this parameter.

Example : C<--include-name='^prod.*'>

=item B<--exclude-name>

Filter by excluding the VMs whose name matches the regular expression provided after this parameter.

Example : C<--exclude-name='^sandbox.*'>

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. You can use the following variables: C<%{accessible}>,
C<%{display}>, C<%{thin_provisioning_supported}>, C<%{multiple_host_access}>.

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. You can use the following variables: C<%{accessible}>,
C<%{display}>, C<%{thin_provisioning_supported}>, C<%{multiple_host_access}>.
Default: C<%{accessible} ne "true">

=item B<--warning-usage>

Threshold in bytes.

=item B<--critical-usage>

Threshold in bytes.

=item B<--warning-usage-free>

Threshold in bytes.

=item B<--critical-usage-free>

Threshold in bytes.

=item B<--warning-usage-prct>

Threshold in percentage.

=item B<--critical-usage-prct>

Threshold in percentage.

=back

=cut
