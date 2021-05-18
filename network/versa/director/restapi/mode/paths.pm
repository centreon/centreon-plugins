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

package network::versa::director::restapi::mode::paths;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub grp1_long_output {
    my ($self, %options) = @_;

    return "checking '" . $options{instance_value}->{name} . "'";
}

sub prefix_grp1_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{name} . "' ";
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Total paths ';
}

sub prefix_grp1_paths_output {
    my ($self, %options) = @_;

    return 'paths ';
}

sub prefix_grp2_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'grp1', type => 3, cb_prefix_output => 'prefix_grp1_output', cb_long_output => 'grp1_long_output', indent_long_output => '    ', message_multiple => 'All group paths are ok',
            group => [
                { name => 'grp1_paths', type => 0, cb_prefix_output => 'prefix_grp1_paths_output', skipped_code => { -10 => 1 } },
                { name => 'grp2', type => 1, display_long => 1, cb_prefix_output => 'prefix_grp2_output', message_multiple => 'sub-group paths are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-paths-up', nlabel => 'paths.up.count', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        { label => 'total-paths-down', nlabel => 'paths.down.count', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{grp1_paths} = [
        { label => 'group-paths-up', nlabel => 'paths.up.count', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'group-paths-down', nlabel => 'paths.down.count', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{grp2} = [
        { label => 'subgroup-paths-up', nlabel => 'paths.up.count', set => {
                key_values => [ { name => 'up' } ],
                output_template => 'up: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'subgroup-paths-down', nlabel => 'paths.down.count', set => {
                key_values => [ { name => 'down' } ],
                output_template => 'down: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'organization:s'       => { name => 'organization' },
        'filter-org-name:s'    => { name => 'filter_org_name' },
        'filter-device-name:s' => { name => 'filter_device_name' },
        'filter-device-type:s' => { name => 'filter_device_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $orgs = $options{custom}->get_organizations();
    my $root_org_name = $options{custom}->find_root_organization_name(orgs => $orgs);

    my $devices = {};
    if (defined($self->{option_results}->{organization}) && $self->{option_results}->{organization} ne '') {
        my $result = $options{custom}->get_devices(org_name => $self->{option_results}->{organization});
        $devices = $result->{entries};
    } else {
        foreach my $org (values %{$orgs->{entries}}) {
            if (defined($self->{option_results}->{filter_org_name}) && $self->{option_results}->{filter_org_name} ne '' &&
                $org->{name} !~ /$self->{option_results}->{filter_org_name}/) {
                $self->{output}->output_add(long_msg => "skipping org '" . $org->{name} . "': no matching filter name.", debug => 1);
                next;
            }

            my $result = $options{custom}->get_devices(org_name => $org->{name});
            $devices = { %$devices, %{$result->{entries}} };
        }
    }

    $self->{global} = { total => 0 };
    $self->{devices} = {};

    foreach my $device (values %$devices) {
        if (defined($self->{option_results}->{filter_device_name}) && $self->{option_results}->{filter_device_name} ne '' &&
            $device->{name} !~ /$self->{option_results}->{filter_device_name}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_device_type}) && $self->{option_results}->{filter_device_type} ne '' &&
            $device->{type} !~ /$self->{option_results}->{filter_device_type}/) {
            $self->{output}->output_add(long_msg => "skipping device '" . $device->{name} . "': no matching filter type.", debug => 1);
            next;
        }

        $self->{devices}->{ $device->{name} } = {
            display => $device->{name}
        };

        # we want all paths. So we check from root org
        my $paths = $options{custom}->get_device_paths(
            org_name => $root_org_name,
            device_name => $device->{name}
        );
        foreach (@{$paths->{entries}}) {
            $self->{devices}->{ $device->{name} }->{device_paths}->{ $_->{connState} }++;
        }

        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check paths.

=over 8

=item B<--organization>

Check device under an organization name.

=item B<--filter-org-name>

Filter organizations by name (Can be a regexp).

=item B<--filter-device-name>

Filter device by name (Can be a regexp).

=item B<--filter-device-type>

Filter device by type (Can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{ping_status}, %{services_status}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{ping_status}, %{service_sstatus}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{ping_status} ne "reachable" or %{services_status} ne "good"').
Can used special variables like: %{ping_status}, %{services_status}, %{sync_status}, %{controller_status}, %{path_status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total','memory-usage', 'memory-usage-free', 'memory-usage-prct',
'disk-usage', 'disk-usage-free', 'disk-usage-prct',
'alarms-critical', 'alarms-major', 'alarms-minor', 'alarms-warning', 'alarms-indeterminate',
'bgp-health-up' 'bgp-health-down' 'bgp-health-disabled' 
'path-health-up' 'path-health-down' 'path-health-disabled'
'service-health-up' 'service-health-down' 'service-health-disabled' 
'port-health-up' 'port-health-down' 'port-health-disabled'
'reachability-health-up' 'reachability-health-down' 'reachability-health-disabled'
'interface-health-up' 'interface-health-down' 'interface-health-disabled' 
'ike-health-up' 'ike-health-down' 'ike-health-disabled'
'config-health-up' 'config-health-down' 'config-health-disabled'
'packets-dropped-novalidlink', 'packets dropped by sla action',
'paths-up', 'paths-down'.

=back

=cut
