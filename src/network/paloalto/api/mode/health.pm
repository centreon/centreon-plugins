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
use centreon::plugins::misc qw(is_empty is_excluded flatten_to_hash exprintf);


sub custom_plugins_output {
    my ($self, %options) = @_;

    my $tmpl = $self->{instance_mode}->{warning_missing_plugin}->{$self->{result_values}->{name}} || $self->{instance_mode}->{critical_missing_plugin}->{$self->{result_values}->{name}}
               ? 'was missing !'
               : 'status: %{status} (version: %{version})';

    return exprintf($tmpl, $self->{result_values});
}

sub custom_plugins_check {
    my ($self, %options) = @_;

    return 'critical' if $self->{instance_mode}->{critical_missing_plugin}->{$self->{result_values}->{name}};
    return 'warning' if $self->{instance_mode}->{warning_missing_plugin}->{$self->{result_values}->{name}};

    return 'ok';
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'check:s'                    => { name => 'check',                    default => 'all', not_empty => 1,
                                          regexp_match => '^(?:all|devices|templates|plugins|jobs)$',
                                          error_message => "Invalid check value '%{check}'. Valid options are: all, devices, plugins, templates, jobs." },
        'include-device-serial:s'    => { name => 'include_device_serial',    default => '' },
        'exclude-device-serial:s'    => { name => 'exclude_device_serial',    default => '' },
        'include-device-hostname:s'  => { name => 'include_device_hostname',  default => '' },
        'exclude-device-hostname:s'  => { name => 'exclude_device_hostname',  default => '' },
        'include-plugin:s'           => { name => 'include_plugin',           default => '' },
        'exclude-plugin:s'           => { name => 'exclude_plugin',           default => '' },
        'critical-missing-plugin:s@' => { name => 'critical_missing_plugin' },
        'warning-missing-plugin:s@'  => { name => 'warning_missing_plugin' },
        'include-template:s'         => { name => 'include_template',         default => '' },
        'exclude-template:s'         => { name => 'exclude_template',         default => '' },
        'include-job-type:s'         => { name => 'include_job_type',         default => '^(?:Commit|CommitAll|Validate|Preview-Chg|AutoCom|Downld|UploadInstall|DwnldUpldInstl|WildFire)$' },
        'exclude-job-type:s'         => { name => 'exclude_job_type',         default => '' },
        'truncate-jobs-warnings'     => { name => 'truncate_jobs_warnings' },
        'connected-only'             => { name => 'connected_only' }
    });

    return $self;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global',         type => COUNTER_TYPE_GLOBAL,   prefix_output => 'Panorama ' },
        { name => 'devices',        type => COUNTER_TYPE_INSTANCE, prefix_output => "device '%{hostname}' (%{serial}) ",
          message_multiple => 'All devices are ok' },
        { name => 'plugins',        type => COUNTER_TYPE_INSTANCE, prefix_output => "plugin '%{name}' ",
          message_multiple => 'All required plugins are installed' },
        { name => 'templates',      type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_template_output',
          message_multiple => 'All templates are ok' },
        { name => 'jobs',           type => COUNTER_TYPE_INSTANCE, cb_prefix_output => 'prefix_job_output',
          message_multiple => 'All jobs are ok' }
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
        { label => 'templates-total', nlabel => 'panorama.templates.total.count', set => {
                key_values => [ { name => 'templates_total' } ],
                output_template => 'total templates: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'templates-assigned', nlabel => 'panorama.templates.assigned.count', set => {
                key_values => [ { name => 'templates_assigned' } ],
                output_template => 'template assignments: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'plugins-total', nlabel => 'panorama.plugins.total.count', set => {
                key_values => [ { name => 'plugins_total' } ],
                output_template => 'plugins checked: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
            }
        },
        { label => 'jobs-total', nlabel => 'panorama.jobs.total.count', set => {
                key_values => [ { name => 'jobs_total' } ],
                output_template => 'jobs checked: %s',
                perfdatas => [ { template => '%s', min => 0 } ]
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
        { label => 'device-ha-state', type => COUNTER_KIND_TEXT, display_ok => 1,
          set => {
                key_values => [ { name => 'ha_state' }, { name => 'hostname' }, { name => 'serial' } ],
                output_template => 'HA state: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{plugins} = [
        { label => 'plugin-status', type => COUNTER_KIND_TEXT,
          set => {
                key_values => [ { name => 'status' }, { name => 'name' }, { name => 'version' } ],
                output_template => 'status: %{status} (version: %{version})',
                closure_custom_threshold_check    => $self->can('custom_plugins_check'),
                closure_custom_output             => $self->can('custom_plugins_output')
            }
        }
    ];

    $self->{maps_counters}->{templates} = [
        { label => 'template-devices-count', nlabel => 'template.devices.count',
          set => {
                key_values => [ { name => 'devices_count' }, { name => 'name' } ],
                output_template => 'assigned devices: %s',
                perfdatas => [ { template => '%s', min => 0, label_extra_instance => 1 } ]
            }
        }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'job-status', type => COUNTER_KIND_TEXT, critical_default => "%{status} eq 'FIN' && %{result} ne 'OK'",
          set => {
                key_values => [ { name => 'status' }, { name => 'result' }, { name => 'type' }, { name => 'age' }, { name => 'id' }, { name => 'running_time'} ],
                output_template => 'status: %{status}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'job-result', type => COUNTER_KIND_TEXT, critical_default =>'%{result} !~ /OK/i',
          set => {
                key_values => [ { name => 'result' }, { name => 'status' }, { name => 'type' }, { name => 'id' }, { name => 'running_time'}],
                output_template => 'result: %{result}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'job-has-warnings', type => COUNTER_KIND_TEXT, display_ok => 0, warning_default => "%{has_warnings} eq 'yes'",
          set => {
                key_values => [ { name => 'has_warnings' }, { name => 'type' }, { name => 'id' }, { name => 'short_warnings_text' }, { name => 'warnings_text' }],
                output_template => 'has warnings: %{short_warnings_text}',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'job-running-time', nlabel => 'job.running.time.seconds', type => COUNTER_KIND_METRIC, display_ok => 0, warning_default => 1800,
          set => {
                key_values => [ { name => 'running_time' } ],
                output_template => 'running time: %s seconds',
                perfdatas => [ { template => '%s', unit => 's', min => 0, label_extra_instance => 1 } ]
            }
        }
    ];

}

sub prefix_template_output {
    my ($self, %options) = @_;
    my $output = exprintf("template '%{name}' ", $options{instance_value});

    my @devices = @{$options{instance_value}->{devices} // []};
    $output .= sprintf("(devices: %s) ", join(', ', @devices))
        if @devices;

    return $output;
}

sub prefix_job_output {
    my ($self, %options) = @_;

    $self->{output}->output_add(long_msg => exprintf("    job has warnings: %{warnings_text}", $options{instance_value}))
        if $options{instance_value}->{has_warnings} eq 'yes' && $options{instance_value}->{warnings_text}
           && !is_excluded($options{instance_value}->{type}, $self->{option_results}->{include_job_type}, $self->{option_results}->{exclude_job_type});

    return exprintf("job (type: %{type}, id: %{id}, started: %{start_time}) ", $options{instance_value});
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = flatten_to_hash($self->{option_results}->{$_})
        foreach qw/warning_missing_plugin critical_missing_plugin/;

    $self->{output}->option_exit(short_msg => "Cannot use --filter-counters/--filter-counters-block together with --check.")
        if $self->{option_results}->{check} && ($self->{option_results}->{filter_counters} || $self->{option_results}->{filter_counters_block});

    $self->{check_devices} = $self->{option_results}->{check} =~ /(?:all|devices)/;
    $self->{check_templates} = $self->{option_results}->{check} =~ /(?:all|templates)/;
    $self->{check_plugins} = $self->{option_results}->{check} =~ /(?:all|plugins)/;
    $self->{check_jobs} = $self->{option_results}->{check} =~ /(?:all|jobs)/;

    my @counter_skip;
    push @counter_skip, 'devices' unless $self->{check_devices};
    push @counter_skip, 'templates' unless $self->{check_templates};
    push @counter_skip, 'plugins' unless $self->{check_plugins};
    push @counter_skip, 'jobs' unless $self->{check_jobs};

    # Apply counter filters
    if (@counter_skip) {
        $self->{option_results}->{filter_counters_block} = '^(?:'.(join '|', @counter_skip).')$';
        $self->{option_results}->{filter_counters} = '^(?!'.(join '|', @counter_skip).')';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $custom = $options{custom};

    $self->{global} = {
        devices_total => 0,
        devices_connected => 0,
        templates_total => 0,
        templates_assigned => 0,
        plugins_total => 0,
        jobs_total => 0
    };

    $self->{devices}       = {};
    $self->{plugins}       = {};
    $self->{templates}     = {};
    $self->{jobs}          = {};

    # Get devices info
    if ($self->{check_devices}) {
        my $filter = $self->{option_results}->{connected_only} ? 'connected' : 'all';
        my $devices_result = $custom->request_api(
            type => 'op',
            cmd => "<show><devices><$filter></$filter></devices></show>",
            ForceArray => [ 'entry' ]
        );

        if ($devices_result && $devices_result->{devices} && ref $devices_result->{devices}->{entry} eq 'ARRAY') {
            foreach my $device (@{$devices_result->{devices}->{entry}}) {
                my $serial = $device->{name};
                my $hostname = $device->{hostname} // '';

                next if is_excluded($serial, $self->{option_results}->{include_device_serial}, $self->{option_results}->{exclude_device_serial}, output => $self->{output}) ||
                        is_excluded($hostname, $self->{option_results}->{include_device_hostname}, $self->{option_results}->{exclude_device_hostname}, output => $self->{output});

                my $connected = lc($device->{connected} // 'no');

                $self->{devices}->{$serial} = {
                    serial      => $serial,
                    hostname    => $hostname,
                    connected   => $connected,
                    sw_version  => $device->{'sw-version'} // 'unknown',
                    ha_state    => $device->{ha}->{state} // 'unknown'
                };

                $self->{global}->{devices_total}++;
                $self->{global}->{devices_connected}++ if $connected eq 'yes';
            }
        }
    }

    # Get plugins info
    if ($self->{check_plugins}) {
        my $plugins_result = $custom->request_api(
            type => 'op',
            cmd  => '<show><plugins><installed/></plugins></show>',
            ForceArray => ['entry']
        );

        my %installed_plugins = ();
        if ($plugins_result && $plugins_result->{list} && ref $plugins_result->{list}->{entry} eq 'ARRAY') {
            foreach my $plugin (@{$plugins_result->{list}->{entry}}) {
                my $plugin_name = $plugin->{name} // '';
                next if is_excluded($plugin_name, $self->{option_results}->{include_plugin}, $self->{option_results}->{exclude_plugin}, output => $self->{output});
                $self->{global}->{plugins_total} ++;
                $installed_plugins{$plugin_name} = 1;
                $self->{plugins}->{$plugin_name} = {
                    name    => $plugin_name,
                    version => $plugin->{version} // 'unknown',
                    status  => 'installed'
                };
            }
        }
        foreach my $plugin_name (keys %{$self->{warning_missing_plugin}}, keys %{$self->{critical_missing_plugin}}) {
            next if $self->{plugins}->{$plugin_name};
            $self->{plugins}->{$plugin_name} = { name => $plugin_name, version => '-', status => 'missing' }
        }
    }

    # Get templates and template-stacks info with assigned devices
    if ($self->{check_templates}) {
        my %template_devices = ();  # Track devices per template
        $self->{instance_mode}->{template_devices} = \%template_devices;  # Store for custom_template_output

        # Get templates
        my $templates_result = $custom->request_api(
            type => 'config',
            action => 'get',
            xpath => '/config/devices/entry[@name=\'localhost.localdomain\']/template',
            ForceArray => [ 'entry' ]
        );

        # Get template-stacks
        my $stacks_result = $custom->request_api(
            type => 'config',
            action => 'get',
            xpath => '/config/devices/entry[@name=\'localhost.localdomain\']/template-stack',
            ForceArray => [ 'entry' ]
        );

        # Process templates
        if ($templates_result && $templates_result->{template} && ref $templates_result->{template}->{entry} eq 'ARRAY') {
            foreach my $template (@{$templates_result->{template}->{entry}}) {
                my $template_name = $template->{name} // '';
                next if is_excluded($template_name, $self->{option_results}->{include_template}, $self->{option_results}->{exclude_template}, output => $self->{output});

                $self->{global}->{templates_total}++;
                $template_devices{$template_name} = [] unless exists $template_devices{$template_name};
            }
        }

        # Process template-stacks and track their devices
        if ($stacks_result && $stacks_result->{'template-stack'} && ref $stacks_result->{'template-stack'}->{entry} eq 'ARRAY') {
            foreach my $stack (@{$stacks_result->{'template-stack'}->{entry}}) {
                my $stack_name = $stack->{name} // '';

                # Get templates in this stack
                my @stack_templates = ();
                if ($stack->{templates} && $stack->{templates}->{member}) {
                    @stack_templates = ref $stack->{templates}->{member} eq 'ARRAY'
                                           ? @{$stack->{templates}->{member}}
                                           : ($stack->{templates}->{member});
                }

                # Get devices assigned to this stack
                my @assigned_devices = ();
                if ($stack->{devices} && $stack->{devices}->{entry}) {
                    if (ref $stack->{devices}->{entry} eq 'ARRAY') {
                        @assigned_devices = @{$stack->{devices}->{entry}};
                    } else {
                        @assigned_devices = ($stack->{devices}->{entry});
                    }
                }

                # Map devices to templates in this stack
                foreach my $tmpl_name (@stack_templates) {
                    next if is_excluded($tmpl_name, $self->{option_results}->{include_template}, $self->{option_results}->{exclude_template}, output => $self->{output});

                    $template_devices{$tmpl_name} = [] unless exists $template_devices{$tmpl_name};

                    foreach my $device_entry (@assigned_devices) {
                        my $device_serial = $device_entry->{name} // '';
                        next unless $device_serial;

                        # Add device to template's device list (avoid duplicates)
                        push @{$template_devices{$tmpl_name}}, $device_serial unless grep { $_ eq $device_serial } @{$template_devices{$tmpl_name}};
                    }
                }
            }
        }

        # Build template entries with device counts
        foreach my $template_name (sort keys %template_devices) {
            my @devices = @{$template_devices{$template_name}};
            my $devices_count = scalar(@devices);

            my $template_instance = $template_name;
            $self->{templates}->{$template_instance} = {
                name          => $template_name,
                devices_count => $devices_count,
                devices       => \@devices
            };

            $self->{global}->{templates_assigned} += $devices_count;
        }
    }

    if ($self->{check_jobs}) {
        # Get jobs info (push history)
        my $jobs_result = $custom->request_api(
            type => 'op',
            cmd  => '<show><jobs><all></all></jobs></show>',
            ForceArray => ['job']
        );

        my $now = time();

        # Process all jobs (not just push history)
        if ($jobs_result && ref $jobs_result->{job} eq 'ARRAY') {
            foreach my $job (@{$jobs_result->{job}}) {
                my $job_type = $job->{type} // 'unknown';
                next if is_excluded($job_type, $self->{option_results}->{include_job_type}, $self->{option_results}->{exclude_job_type}, output => $self->{output});

                $self->{global}->{jobs_total} ++;

                my $job_id = $job->{id} // 'unknown';
                my $tenq = $job->{tenq} || '-';
                my $tfin = $job->{tfin} // $job->{tdeq} // '';
                my $epoch = $self->_parse_panorama_timestamp($tfin);
                my $epoch_start = $self->_parse_panorama_timestamp($tenq);
                my $age_seconds = $epoch ? ($now - $epoch) : -1;
                my $running_time = -1;
                $running_time = $epoch - $epoch_start
                    if $epoch_start && $epoch;
                my $job_status = $job->{status} // 'unknown';
                my $job_result = $job->{result} // 'unknown';

                # Check if job has warnings and extract warning text
                my $warnings = '';
                if ($job->{warnings}) {
                    if (ref $job->{warnings}->{line} eq 'ARRAY') {
                        $warnings = join ' | ', @{$job->{warnings}->{line}};
                    } elsif ($job->{warnings}->{line}) {
                        $warnings = $job->{warnings}->{line};
                    }
                }
                my $has_warnings = $warnings eq '' ? 'no' : 'yes';
                $warnings =~ s/[\r\n]/ /gm;

                my $short_warnings = $warnings;
                $short_warnings = substr($short_warnings, 0, 30).'...' if $self->{option_results}->{truncate_jobs_warnings} && length($short_warnings) > 30;

                my $job_instance = $job_id . '-' . $job_type;
                $self->{jobs}->{$job_instance} = {
                    id            => $job_id,
                    type          => $job_type,
                    status        => $job_status,
                    result        => $job_result,
                    age           => $age_seconds,
                    has_warnings  => $has_warnings,
                    warnings_text => $warnings,
                    short_warnings_text => $short_warnings,
                    start_time    => $tenq,
                    running_time  => $running_time,
                };
            }
        }
    }
}

1;

__END__

=head1 MODE

Check Palo Alto Panorama health status including managed devices, plugins, templates, and jobs.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^devices-total$'

=item B<--check>

Check which components to monitor: all, devices, templates, plugins, or jobs (default: 'all').

=item B<--include-device-serial>

Include only specific device by serial number (regexp can be used).

=item B<--exclude-device-serial>

Exclude specific device by serial number (regexp can be used).

=item B<--include-device-hostname>

Include only specific device by hostname (regexp can be used).

=item B<--exclude-device-hostname>

Exclude specific device by hostname (regexp can be used).

=item B<--include-plugin>

Include only specific plugin (regexp can be used).

=item B<--exclude-plugin>

Exclude specific plugin (regexp can be used).

=item B<--critical-missing-plugin>

List of plugins that must be installed (comma-separated).
Returns CRITICAL status if any plugin is missing.
Example: --critical-missing-plugin='nutanix,cisco,vmware'

=item B<--warning-missing-plugin>

List of plugins that should be installed (comma-separated).
Returns WARNING status if any plugin is missing.
Example: --warning-missing-plugin='nutanix,cisco'

=item B<--include-template>

Include only specific template (regexp can be used).

=item B<--exclude-template>

Exclude specific template (regexp can be used).

=item B<--include-job-type>

Include only specific job type (regexp can be used).
Default: C<^(?:Commit|CommitAll|Validate|Preview-Chg|AutoCom|Downld|UploadInstall|DwnldUpldInstl|WildFire)$>

=item B<--exclude-job-type>

Exclude specific job type (regexp can be used).

=item B<--truncate-jobs-warnings>

Truncate job warnings text to 30 characters.

=item B<--connected-only>

Only check connected devices.

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
You can use the following variables: %{status}, %{name}, %{version}

=item B<--warning-plugin-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{name}, %{version}

=item B<--critical-plugin-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{name}, %{version}

=item B<--warning-template-devices-count>

Warning threshold for number of devices assigned to a template.

=item B<--critical-template-devices-count>

Critical threshold for number of devices assigned to a template.

=item B<--unknown-job-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{result}, %{type}, %{id}, %{age}, %{running_time}

=item B<--warning-job-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{result}, %{type}, %{id}, %{age}, %{running_time}

=item B<--critical-job-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "FIN" && %{result} ne "OK"').
You can use the following variables: %{status}, %{result}, %{type}, %{id}, %{age}, %{running_time}

=item B<--unknown-job-result>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{result}, %{status}, %{type}, %{id}, %{running_time}

=item B<--warning-job-result>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{result}, %{status}, %{type}, %{id}, %{running_time}

=item B<--critical-job-result>

Define the conditions to match for the status to be CRITICAL (default: '%{result} !~ /OK/i').
You can use the following variables: %{result}, %{status}, %{type}, %{id}, %{running_time}

=item B<--unknown-job-has-warnings>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{has_warnings}, %{type}, %{id}, %{short_warnings_text}, %{warnings_text}

=item B<--warning-job-has-warnings>

Define the conditions to match for the status to be WARNING (default: '%{has_warnings} eq "yes"').
You can use the following variables: %{has_warnings}, %{type}, %{id}, %{short_warnings_text}, %{warnings_text}

=item B<--critical-job-has-warnings>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{has_warnings}, %{type}, %{id}, %{short_warnings_text}, %{warnings_text}

=item B<--warning-job-running-time>

Warning threshold for job running time in seconds (default: 1800).

=item B<--critical-job-running-time>

Critical threshold for job running time in seconds.

=item B<--warning-devices-total>

Warning threshold for total number of managed devices.

=item B<--critical-devices-total>

Critical threshold for total number of managed devices.

=item B<--warning-devices-connected>

Warning threshold for number of connected devices.

=item B<--critical-devices-connected>

Critical threshold for number of connected devices.

=item B<--warning-templates-total>

Warning threshold for total number of templates.

=item B<--critical-templates-total>

Critical threshold for total number of templates.

=item B<--warning-templates-assigned>

Warning threshold for total number of template assignments.

=item B<--critical-templates-assigned>

Critical threshold for total number of template assignments.

=item B<--warning-plugins-total>

Warning threshold for total number of plugins.

=item B<--critical-plugins-total>

Critical threshold for total number of plugins.

=item B<--warning-jobs-total>

Warning threshold for total number of jobs.

=item B<--critical-jobs-total>

Critical threshold for total number of jobs.

=back

=cut
