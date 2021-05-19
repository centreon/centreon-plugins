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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'group:s'                   => { name => 'group' },
        'organization:s'            => { name => 'organization' },
        'filter-org-name:s'         => { name => 'filter_org_name' },
        'filter-device-name:s'      => { name => 'filter_device_name' },
        'filter-device-type:s'      => { name => 'filter_device_type' },
        'filter-local-wan-link:s'   => { name => 'filter_local_wan_link' },
        'filter-remote-site-name:s' => { name => 'filter_remote_site_name' },
        'filter-remote-wan-link:s'  => { name => 'filter_remote_wan_link' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{group}) || $self->{option_results}->{group} eq '') {
        $self->{option_results}->{group} = 'remoteSiteName';
    }
    
    my $dimensions = { localsitename => 'localSiteName', localwanlink => 'localWanLink', remotesitename => 'remoteSiteName', remotewanlink => 'remoteWanLink' };
    my ($grp, $subgrp) = split(/,/, $self->{option_results}->{group});
    if (!defined($dimensions->{ lc($grp) })) {
        $self->{output}->add_option_msg(short_msg => "Unknown --group name: $grp.");
        $self->{output}->option_exit();
    }
    $self->{grp_name} = $dimensions->{ lc($grp) };
    if (defined($subgrp)) {
        if (!defined($dimensions->{ lc($subgrp) })) {
            $self->{output}->add_option_msg(short_msg => "Unknown --group name: $subgrp.");
            $self->{output}->option_exit();
        }
        $self->{subgrp_name} = $dimensions->{ lc($subgrp) };
    }
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

    $self->{global} = { up => 0, down => 0 };
    $self->{grp1} = {};

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

        my $paths = $options{custom}->get_device_paths(
            org_name => $root_org_name,
            device_name => $device->{name}
        );
        foreach my $path (@{$paths->{entries}}) {
            $path->{localSiteName} = $device->{name};
            next if (
                defined($self->{option_results}->{filter_local_wan_link}) && $self->{option_results}->{filter_local_wan_link} ne '' &&
                $path->{localWanLink} !~ /$self->{option_results}->{filter_local_wan_link}/
            );
            next if (
                defined($self->{option_results}->{filter_remote_site_name}) && $self->{option_results}->{filter_remote_site_name} ne '' &&
                $path->{remoteSiteName} !~ /$self->{option_results}->{filter_remote_site_name}/
            );
            next if (
                defined($self->{option_results}->{filter_remote_wan_link}) && $self->{option_results}->{filter_remote_wan_link} ne '' &&
                $path->{remoteWanLink} !~ /$self->{option_results}->{filter_remote_wan_link}/
            );

            if (!defined($self->{grp1}->{ $path->{$self->{grp_name}} })) {
                $self->{grp1}->{ $path->{$self->{grp_name}} } = {
                    name => $path->{ $self->{grp_name} },
                    grp1_paths => {
                        up => 0,
                        down => 0
                    },
                    grp2 => {}
                };
            }

            $self->{global}->{ $path->{connState} }++;
            $self->{grp1}->{ $path->{$self->{grp_name}} }->{grp1_paths}->{ $path->{connState} }++;
            next if (!defined($self->{subgrp_name}));

            if (!defined($self->{grp1}->{ $path->{$self->{grp_name}} }->{grp2}->{ $path->{$self->{subgrp_name}} })) {
                $self->{grp1}->{ $path->{$self->{grp_name}} }->{grp2}->{ $path->{$self->{subgrp_name}} } = {
                    name => $path->{$self->{subgrp_name}},
                    up => 0,
                    down => 0
                };
            }
            $self->{grp1}->{ $path->{$self->{grp_name}} }->{grp2}->{ $path->{$self->{subgrp_name}} }->{ $path->{connState} }++;
        }
    }
}

1;

__END__

=head1 MODE

Check paths.

=over 8

=item B<--group>

Choose dimensions to group paths up/down.
Default: --group='remoteSiteName'

=item B<--organization>

Check device under an organization name.

=item B<--filter-org-name>

Filter organizations by name (Can be a regexp).

=item B<--filter-device-name>

Filter devices by name (Can be a regexp).

=item B<--filter-device-type>

Filter devices by type (Can be a regexp).

=item B<--filter-local-wan-link>

Filter paths by localWanLink (Can be a regexp).

=item B<--filter-remote-site-name>

Filter paths by remoteSiteName (Can be a regexp).

=item B<--filter-remote-wan-link>

Filter paths by remoteWanLink (Can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-paths-up', 'total-paths-down',
'group-paths-up', 'group-paths-down', 
'subgroup-paths-up', 'subgroup-paths-down'.

=back

=cut
