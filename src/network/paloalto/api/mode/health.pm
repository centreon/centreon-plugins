#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::health;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::Local qw(timelocal);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);
use centreon::plugins::misc qw(is_empty is_excluded);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-device-serial:s'   => { name => 'include_device_serial',    default => '' },
        'exclude-device-serial:s'   => { name => 'exclude_device_serial',    default => '' },
        'include-device-hostname:s' => { name => 'include_device_hostname',  default => '' },
        'exclude-device-hostname:s' => { name => 'exclude_device_hostname',  default => '' },
        'include-plugin:s'       => { name => 'include_plugin',       default => '' },
        'exclude-plugin:s'       => { name => 'exclude_plugin',       default => '' },
        'include-template:s'     => { name => 'include_template',     default => '' },
        'exclude-template:s'     => { name => 'exclude_template',     default => '' },
        'connected-only'         => { name => 'connected_only' }
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global',         type => COUNTER_TYPE_GLOBAL,   prefix_output => 'Panorama ' },
        { name => 'devices',        type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_device_output',
          message_multiple => 'All devices are ok' },
        { name => 'plugins',        type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_plugin_output',
          message_multiple => 'All plugins are ok' },
        { name => 'device_groups',  type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_device_group_output',
          message_multiple => 'All device groups are ok' },
        { name => 'templates',      type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_template_output',
          message_multiple => 'All templates are ok' },
        { name => 'template_sync',  type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_template_sync_output',
          message_multiple => 'All template assignments are synchronized' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'devices-total', nlabel => 'panorama.devices.total.count', set => {
                key_values => [ { name => 'devices_total' } ],
                output_template => 'total devices: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'devices-connected', nlabel => 'panorama.devices.connected.count', set => {
                key_values => [ { name => 'devices_connected' } ],
                output_template => 'connected devices: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'devices-out-of-sync', nlabel => 'panorama.devices.out_of_sync.count', set => {
                key_values => [ { name => 'devices_out_of_sync' } ],
                output_template => 'out of sync devices: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'device-groups-total', nlabel => 'panorama.device_groups.total.count', set => {
                key_values => [ { name => 'device_groups_total' } ],
                output_template => 'total device-groups: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'templates-total', nlabel => 'panorama.templates.total.count', set => {
                key_values => [ { name => 'templates_total' } ],
                output_template => 'total templates: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'template-assignments-total', nlabel => 'panorama.template_assignments.total.count', set => {
                key_values => [ { name => 'template_assignments_total' } ],
                output_template => 'template assignments: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'template-assignments-out-of-sync', nlabel => 'panorama.template_assignments.out_of_sync.count', set => {
                key_values => [ { name => 'template_assignments_out_of_sync' } ],
                output_template => 'template assignments out of sync: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'push-status', type => COUNTER_KIND_TEXT,
          critical_default => '%{push_status} !~ /^(?:OK|success)$/i',
          set => {
                key_values => [ { name => 'push_status' } ],
                output_template => 'last push status: %{push_status}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'push-age', nlabel => 'panorama.push.age.seconds',
          set => {
                key_values => [ { name => 'push_age_seconds' } ],
                output_template => 'last push age: %{push_age_seconds} seconds',
                perfdatas => [ { template => '%s', unit => 's', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{devices} = [
        { label => 'device-connection-status', type => COUNTER_KIND_TEXT,
          critical_default => '%{connected} ne "yes"',
          set => {
                key_values => [ { name => 'connected' }, { name => 'hostname' }, { name => 'serial' } ],
                output_template => 'connected: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'device-software-version', type => COUNTER_KIND_TEXT, display_ok => 0,
          set => {
                key_values => [ { name => 'sw_version' }, { name => 'hostname' }, { name => 'serial' } ],
                output_template => 'software version: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'device-ha-state', type => COUNTER_KIND_TEXT, display_ok => 0,
          set => {
                key_values => [ { name => 'ha_state' }, { name => 'hostname' }, { name => 'serial' } ],
                output_template => 'HA state: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{plugins} = [
        { label => 'plugin-status', type => COUNTER_KIND_TEXT,
          critical_default => '%{status} !~ /success/i',
          set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'version' } ],
                output_template => 'status: %{status} (version: %{version})',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{device_groups} = [
    ];

    $self->{maps_counters}->{templates} = [
        { label => 'template-devices-count', nlabel => 'template.devices.count',
          set => {
                key_values => [ { name => 'devices_count' }, { name => 'hostname' } ],
                output_template => 'assigned devices: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        }
    ];

    $self->{maps_counters}->{template_sync} = [
        { label => 'template-sync-status', type => COUNTER_KIND_TEXT,
          critical_default => '%{sync_status} ne "in-sync"',
          set => {
                key_values => [ { name => 'sync_status' }, { name => 'template_name' }, { name => 'device_serial' }, { name => 'vsys' } ],
                output_template => 'template: %{template_name}, vsys: %{vsys}, status: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_device_output {
    my ($self, %options) = @_;
    return sprintf("device '%s' (%s) ", $options{instance_value}->{hostname}, $options{instance_value}->{serial});
}

sub prefix_plugin_output {
    my ($self, %options) = @_;
    return sprintf("plugin '%s' ", $options{instance_value}->{name});
}

sub prefix_device_group_output {
    my ($self, %options) = @_;
    return sprintf("device-group '%s' ", $options{instance_value}->{name});
}

sub prefix_template_output {
    my ($self, %options) = @_;
    return sprintf("template '%s' ", $options{instance_value}->{name});
}

sub prefix_template_sync_output {
    my ($self, %options) = @_;
    return sprintf("template-assignment '%s' ", $options{instance_value}->{device_serial});
}

sub _parse_panorama_timestamp {
    my ($self, $timestamp) = @_;

    # Format: "2024/01/15 10:30:10" or similar
    if ($timestamp && $timestamp =~ /(\d{4})\/(\d{2})\/(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/) {
        my ($year, $mon, $mday, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
        return timelocal($sec, $min, $hour, $mday, $mon - 1, $year - 1900);
    }

    return undef;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $custom = $options{custom};

    $self->{global} = {
        devices_total => 0,
        devices_connected => 0,
        devices_out_of_sync => 0,
        device_groups_total => 0,
        templates_total => 0,
        template_assignments_total => 0,
        template_assignments_out_of_sync => 0,
        push_status => 'unknown',
        push_age_seconds => -1
    };

    $self->{devices}       = {};
    $self->{plugins}       = {};
    $self->{device_groups} = {};
    $self->{templates}     = {};
    $self->{template_sync} = {};

    # Get devices info
    my $filter = $self->{option_results}->{connected_only} ? 'connected' : 'all';
    my $devices_result = $custom->request_api(
        type => 'op',
        cmd => "<show><devices><$filter></$filter></devices></show>",
        ForceArray => [ 'entry' ]
    );

    my %devices_by_serial = ();

    if ($devices_result && $devices_result->{devices} && ref $devices_result->{devices}->{entry} eq 'ARRAY') {
        foreach my $device (@{$devices_result->{devices}->{entry}}) {
            my $serial = $device->{name};
            my $hostname = $device->{hostname} // '';

            next if is_excluded($serial, $self->{option_results}->{include_device_serial}, $self->{option_results}->{exclude_device_serial}, output => $self->{output}) ||
                    is_excluded($hostname, $self->{option_results}->{include_device_hostname}, $self->{option_results}->{exclude_device_hostname}, output => $self->{output});

            my $connected = lc($device->{connected} // 'no');

            # Determine sync status from vsys entries
            my $sync_state = 'unknown';
            my %vsys_sync_states = ();

            if ($device->{vsys} && ref $device->{vsys}->{entry} eq 'ARRAY') {
                foreach my $vsys_entry (@{$device->{vsys}->{entry}}) {
                    my $vsys_name = $vsys_entry->{name} // 'vsys1';
                    my $vsys_status = $vsys_entry->{'shared-policy-status'} // 'unknown';
                    $vsys_sync_states{$vsys_name} = $vsys_status;

                    if ($vsys_status eq 'Out of Sync') {
                        $sync_state = 'Out of Sync';
                    } elsif ($vsys_status eq 'In Sync' && $sync_state eq 'unknown') {
                        $sync_state = 'In Sync';
                    }
                }
            }

            $self->{devices}->{$serial} = {
                serial      => $serial,
                hostname    => $hostname,
                connected   => $connected,
                sync_state  => $sync_state,
                sw_version  => $device->{'sw-version'} // 'unknown',
                ha_state    => $device->{ha}->{state} // 'unknown',
                vsys_sync   => \%vsys_sync_states
            };

            $devices_by_serial{$serial} = $self->{devices}->{$serial};

            $self->{global}->{devices_total}++;
            $self->{global}->{devices_connected}++ if $connected eq 'yes';
            $self->{global}->{devices_out_of_sync}++ if $sync_state eq 'Out of Sync';
        }
    }

    # Get plugins info
    my $plugins_result = $custom->request_api(
        type => 'op',
        cmd  => '<show><plugins></plugins></show>',
        ForceArray => ['entry']
    );

    if ($plugins_result && $plugins_result->{plugins} && ref $plugins_result->{plugins}->{entry} eq 'ARRAY') {
        foreach my $plugin (@{$plugins_result->{plugins}->{entry}}) {
            my $plugin_name = $plugin->{name} // '';
            next if is_excluded($plugin_name, $self->{option_results}->{include_plugin}, $self->{option_results}->{exclude_plugin}, output => $self->{output});

            $self->{plugins}->{$plugin_name} = {
                name    => $plugin_name,
                version => $plugin->{version} // 'unknown',
                status  => $plugin->{status} // 'unknown'
            };
        }
    }

    # Get templates info with assigned devices
    my $templates_result = $custom->request_api(
        type => 'config',
        action => 'get',
        xpath => "/config/devices/entry//template",
        ForceArray => [ 'entry' ]
    );

    if ($templates_result && $templates_result->{template} && ref $templates_result->{template}->{entry} eq 'ARRAY') {
        foreach my $template (@{$templates_result->{template}->{entry}}) {
            my $template_name = $template->{name} // '';
            next if is_excluded($template_name, $self->{option_results}->{include_template}, $self->{option_results}->{exclude_template}, output => $self->{output});

            my @assigned_devices = @{$template->{devices}->{entry} // []};
            my $devices_count = scalar(@assigned_devices);

            my $template_instance = $template_name;
            $self->{templates}->{$template_instance} = {
                name          => $template_name,
                devices_count => $devices_count,
                description   => $template->{description} // ''
            };

            $self->{global}->{templates_total}++;

            # Build template sync status entries
            foreach my $assigned_device (@assigned_devices) {
                my $device_serial = $assigned_device->{name} // '';
                next unless $device_serial;

                $self->{global}->{template_assignments_total}++;

                # Get device details if available
                if (exists $devices_by_serial{$device_serial}) {
                    my $device_info = $devices_by_serial{$device_serial};
                    my $vsys_sync_states = $device_info->{vsys_sync};

                    # Create entry for each vsys with sync status
                    foreach my $vsys_name (keys %{$vsys_sync_states}) {
                        my $sync_status = $vsys_sync_states->{$vsys_name} // 'unknown';
                        my $entry_key = "$template_name-$device_serial-$vsys_name";

                        $self->{template_sync}->{$entry_key} = {
                            template_name => $template_name,
                            device_serial => $device_serial,
                            device_name   => $device_info->{name},
                            vsys          => $vsys_name,
                            sync_status   => lc($sync_status),
                            connected     => $device_info->{connected}
                        };

                        if ($sync_status ne 'In Sync' && $sync_status ne 'unknown') {
                            $self->{global}->{template_assignments_out_of_sync}++;
                        }
                    }
                } else {
                    # Device not found in devices list
                    my $entry_key = "$template_name-$device_serial-unknown";
                    $self->{template_sync}->{$entry_key} = {
                        template_name => $template_name,
                        device_serial => $device_serial,
                        device_name   => $device_serial,
                        vsys          => 'unknown',
                        sync_status   => 'disconnected',
                        connected     => 'no'
                    };
                    $self->{global}->{template_assignments_out_of_sync}++;
                }
            }
        }
    }

    # Get jobs info (push history)
    my $jobs_result = $custom->request_api(
        type => 'op',
        cmd  => '<show><jobs><all></all></jobs></show>',
        ForceArray => ['job']
    );

    my $last_push = undef;
    my $now = time();

    if ($jobs_result && ref $jobs_result->{job} eq 'ARRAY') {
        foreach my $job (@{$jobs_result->{job}}) {
            next unless $job->{type} && $job->{type} =~ /^(?:CommitAll|Push)/i;

            my $result = $job->{result} // 'unknown';
            my $tfin = $job->{tfin} // $job->{tdeq};

            # Keep only the most recent push job
            if ($last_push) {
                my $epoch = $self->_parse_panorama_timestamp($tfin);
                if ($epoch && $last_push->{timestamp_epoch} && $epoch > $last_push->{timestamp_epoch}) {
                    my $age_seconds = ($now - $epoch);
                    $last_push = {
                        status          => $result,
                        timestamp       => $tfin,
                        timestamp_epoch => $epoch,
                        age_seconds     => $age_seconds
                    };
                }
            } else {
                my $epoch = $self->_parse_panorama_timestamp($tfin);
                my $age_seconds = $epoch ? ($now - $epoch) : -1;
                $last_push = {
                    status          => $result,
                    timestamp       => $tfin,
                    timestamp_epoch => $epoch,
                    age_seconds     => $age_seconds
                };
            }
        }
    }

    # Add last push info if available
    if ($last_push) {
        $self->{global}->{push_status} = $last_push->{status};
        $self->{global}->{push_age_seconds} = $last_push->{age_seconds} || 0;
    }
}

1;

__END__

=head1 MODE

Check Palo Alto Panorama health status including managed devices, templates, template synchronization, and push operations.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^devices-total$'

=item B<--include-device-serial>

Include specific device by serial number (can be a regexp).

=item B<--exclude-device-serial>

Exclude specific device by serial number (can be a regexp).

=item B<--include-device-hostname>

Include specific device by hostname (can be a regexp).

=item B<--exclude-device-hostname>

Exclude specific device by hostname (can be a regexp).

=item B<--include-plugin>

Include specific plugin (can be a regexp).

=item B<--exclude-plugin>

Exclude specific plugin (can be a regexp).

=item B<--include-template>

Include specific template (can be a regexp).

=item B<--exclude-template>

Exclude specific template (can be a regexp).

=item B<--unknown-device-connection-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{connected}, %{hostname}, %{serial}

=item B<--warning-device-connection-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{connected}, %{hostname}, %{serial}

=item B<--critical-device-connection-status>

Define the conditions to match for the status to be CRITICAL (default: '%{connected} ne "yes"').
You can use the following variables: %{connected}, %{hostname}, %{serial}

=item B<--unknown-device-software-version>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sw_version}, %{hostname}, %{serial}

=item B<--warning-device-software-version>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sw_version}, %{hostname}, %{serial}

=item B<--critical-device-software-version>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{sw_version}, %{hostname}, %{serial}

=item B<--unknown-device-ha-state>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{ha_state}, %{hostname}, %{serial}

=item B<--warning-device-ha-state>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{ha_state}, %{hostname}, %{serial}

=item B<--critical-device-ha-state>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{ha_state}, %{hostname}, %{serial}

=item B<--unknown-plugin-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{hostname}, %{version}

=item B<--warning-plugin-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{hostname}, %{version}

=item B<--critical-plugin-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /success/i').
You can use the following variables: %{status}, %{hostname}, %{version}

=item B<--unknown-push-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{push_status}

=item B<--warning-push-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{push_status}

=item B<--critical-push-status>

Define the conditions to match for the status to be CRITICAL (default: '%{push_status} !~ /^(?:OK|success)$/i').
You can use the following variables: %{push_status}

=item B<--warning-push-age>

Warning threshold for last push age (in seconds).

=item B<--critical-push-age>

Critical threshold for last push age (in seconds).

=item B<--unknown-template-sync-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{sync_status}, %{template_name}, %{device_serial}, %{vsys}

=item B<--warning-template-sync-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{sync_status}, %{template_name}, %{device_serial}, %{vsys}

=item B<--critical-template-sync-status>

Define the conditions to match for the status to be CRITICAL (default: '%{sync_status} ne "in-sync"').
You can use the following variables: %{sync_status}, %{template_name}, %{device_serial}, %{vsys}

=item B<--warning-devices-total>

Warning threshold for total number of managed devices.

=item B<--critical-devices-total>

Critical threshold for total number of managed devices.

=item B<--warning-devices-connected>

Warning threshold for number of connected devices.

=item B<--critical-devices-connected>

Critical threshold for number of connected devices.

=item B<--warning-devices-out-of-sync>

Warning threshold for number of out-of-sync devices.

=item B<--critical-devices-out-of-sync>

Critical threshold for number of out-of-sync devices.

=item B<--warning-templates-total>

Warning threshold for total number of templates.

=item B<--critical-templates-total>

Critical threshold for total number of templates.

=item B<--warning-template-assignments-total>

Warning threshold for total number of template assignments.

=item B<--critical-template-assignments-total>

Critical threshold for total number of template assignments.

=item B<--warning-template-assignments-out-of-sync>

Warning threshold for number of out-of-sync template assignments.

=item B<--critical-template-assignments-out-of-sync>

Critical threshold for number of out-of-sync template assignments.

=back

=cut
