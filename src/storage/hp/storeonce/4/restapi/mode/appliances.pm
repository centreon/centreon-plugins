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

package storage::hp::storeonce::4::restapi::mode::appliances;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_disk_usage_output {
    my ($self, %options) = @_;

    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    return sprintf(
        'disk space usage total: %s used: %s (%.2f%%) free: %s (%.2f%%)',
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
}

sub appliance_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking appliance '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_appliance_output {
    my ($self, %options) = @_;

    return sprintf(
        "appliance '%s' ",
        $options{instance_value}->{name}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of appliances ';
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return sprintf(
        "service '%s' ",
        $options{instance_value}->{service}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        {
            name => 'appliances', type => 3, cb_prefix_output => 'prefix_appliance_output', cb_long_output => 'appliance_long_output', indent_long_output => '    ', message_multiple => 'All appliances are ok',
            group => [
                { name => 'disk', type => 0 },
                { name => 'dedup', type => 0 },
                { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'services are ok', display_long => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'appliances-detected', display_ok => 0, nlabel => 'appliances.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{services} = [
        {
            label => 'service-status',
            type => 2,
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /critical/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'service' }
                ],
                output_template => "status: %s",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{disk} = [
        { label => 'disk-space-usage', nlabel => 'appliance.disk.space.usage.bytes', set => {
                key_values => [ { name => 'used' }, { name => 'free' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'disk-space-usage-free', nlabel => 'appliance.disk.space.free.bytes', display_ok => 0, set => {
                key_values => [ { name => 'free' }, { name => 'used' }, { name => 'prct_used' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%d', min => 0, max => 'total', unit => 'B', cast_int => 1, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'disk-space-usage-prct', nlabel => 'appliance.disk.space.usage.percentage', display_ok => 0, set => {
                key_values => [ { name => 'prct_used' }, { name => 'used' }, { name => 'free' }, { name => 'prct_free' }, { name => 'total' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_disk_usage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{dedup} = [
        { label => 'dedup', nlabel => 'appliance.deduplication.ratio.count', set => {
                key_values => [ { name => 'dedup' }, { name => 'name' } ],
                output_template => 'deduplication ratio: %.2f',
                perfdatas => [
                    { template => '%.2f', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
        'filter-uuid:s'     => { name => 'filter_uuid' },
        'filter-hostname:s' => { name => 'filter_hostname' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $members = $options{custom}->request_api(endpoint => '/api/v1/management-services/federation/members');

    $self->{global} = { detected => 0 };
    $self->{appliances} = {};

    foreach my $member (@{$members->{members}}) {
        next if (defined($self->{option_results}->{filter_uuid}) && $self->{option_results}->{filter_uuid} ne '' &&
            $member->{uuid} !~ /$self->{option_results}->{filter_uuid}/);
        next if (defined($self->{option_results}->{filter_hostname}) && $self->{option_results}->{filter_hostname} ne '' &&
            $member->{hostname} !~ /$self->{option_results}->{filter_hostname}/);

        $self->{global}->{detected}++;

        my $appliance = $options{custom}->request_api(endpoint => '/api/v1/data-services/dashboard/appliance/' . $member->{uuid});

        $self->{appliances}->{ $member->{uuid} } = {
            name => $member->{hostname},
            services => {
                dataServices => { service => 'dataServices', status => lc($appliance->{dataServicesStatus}) },
                license => { service => 'license', status => lc($appliance->{licenseStatus}) },
                userStorage => { service => 'userStorage', status => lc($appliance->{userStorageStatus}) },
                hardware => { service => 'hardware', status => lc($appliance->{hardwareStatus}) },
                remoteSupport => { service => 'remoteSupport', status => lc($appliance->{remoteSupportStatus}) }
            },
            disk => {
                name => $member->{hostname},
                total => $appliance->{localCapacityBytes},
                used => $appliance->{localCapacityBytes} - $appliance->{localFreeBytes},
                free => $appliance->{localFreeBytes},
                prct_used => 100 - ($appliance->{localFreeBytes} * 100 / $appliance->{localCapacityBytes}),
                prct_free => $appliance->{localFreeBytes} * 100 / $appliance->{localCapacityBytes}
            },
            dedup => {
                name => $member->{hostname},
                dedup => $appliance->{dedupeRatio}
            } 
        };
    }
}

1;

__END__

=head1 MODE

Check appliances.

=over 8

=item B<--filter-uuid>

Filter appliances by UUID.

=item B<--filter-name>

Filter appliances by hostname.

=item B<--unknown-service-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{service}, %{status}

=item B<--warning-service-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warning/i').
You can use the following variables: %{service}, %{status}

=item B<--critical-service-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /critical/i').
You can use the following variables: %{service}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'appliances-detected', 'disk-space-usage, 'disk-space-usage-free',
'disk-space-usage-prct', 'dedup'.

=back

=cut
