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

package apps::monitoring::mip::restapi::mode::scenarios;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $mapping_units = {
    requests => { label => 'requests' },
    bytes    => { label => 'bytes', scale => 1, extra_unit => '' },
    ms       => { label => 'milliseconds' },
    bps      => { label => 'bitspersecond', scale => 1, extra_unit => '/s', network => 1 },
    status   => { label => 'count' }
};

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub custom_metric_output {
    my ($self, %options) = @_;

    my $msg;
    if (defined($mapping_units->{ $self->{result_values}->{unit} }->{scale})) {
        $msg = sprintf(
            'value: %s %s%s',
            $self->{perfdata}->change_bytes(
                value => $self->{result_values}->{value},
                network => $mapping_units->{ $self->{result_values}->{unit} }->{network}
            ),
            $mapping_units->{ $self->{result_values}->{unit} }->{extra_unit}
        );
    } else {
        $msg = sprintf(
            'value: %s %s',
            $self->{result_values}->{value},
            $self->{result_values}->{unit}
        );
    }
    return $msg;
}

sub custom_formatted_metric_output {
    my ($self, %options) = @_;

    return sprintf(
        'value: %s',
        $self->{result_values}->{value}
    );
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        unit => $self->{result_values}->{unit},
        nlabel => 'scenario.metric.usage.' . $mapping_units->{ $self->{result_values}->{unit} }->{label},
        instances => $self->{instance},
        value => $self->{result_values}->{value}
    );
}

sub custom_formatted_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'scenario.formatted_metric.usage.count',
        instances => $self->{instance},
        value => $self->{result_values}->{value}
    );
}

sub scenario_long_output {
    my ($self, %options) = @_;

    return "checking scenario '" . $options{instance_value}->{display} . "'";
}

sub prefix_scenario_output {
    my ($self, %options) = @_;

    return "Scenario '" . $options{instance_value}->{display} . "' ";
}

sub prefix_metric_output {
    my ($self, %options) = @_;

    return "metric '" . $options{instance_value}->{display} . "' ";
}

sub prefix_formatted_metric_output {
    my ($self, %options) = @_;

    return "formatted metric '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'scenario', type => 3, cb_prefix_output => 'prefix_scenario_output', cb_long_output => 'scenario_long_output', indent_long_output => '    ', message_multiple => 'All scenarios are ok',
            group => [
                { name => 'global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'metric', display_long => 1, cb_prefix_output => 'prefix_metric_output',  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } },
                { name => 'formatted_metrics', display_long => 1, display_short => 0, cb_prefix_output => 'prefix_formatted_metric_output',  message_multiple => 'All formatted metrics are ok', type => 1, skipped_code => { -10 => 1 } }
            ]
        }        
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => 2,
            unknown_default => '%{status} =~ /unknown/i',
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /critical/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{metric} = [
        { label => 'metric', set => {
                key_values => [ { name => 'value' }, { name => 'unit' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => sub { return 'ok'; }
            }
        }
    ];

    $self->{maps_counters}->{formatted_metrics} = [
        { label => 'formatted-metric', set => {
                key_values => [ { name => 'value' }, { name => 'display' },  ],
                closure_custom_output => $self->can('custom_formatted_metric_output'),
                closure_custom_perfdata => $self->can('custom_formatted_metric_perfdata'),
                closure_custom_threshold_check => sub { return 'ok'; }
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-id:s'           => { name => 'filter_id' },
        'filter-display-name:s' => { name => 'filter_display_name' },
        'filter-name:s'         => { name => 'filter_name' },
        'filter-app-name:s'     => { name => 'filter_app_name' },
        'memory'                => { name => 'memory' },
        'display-instance:s'    => { name => 'display_instance', default => '%{name}' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{display_instance} = '%{name}' if (!defined($self->{option_results}->{display_instance}) || $self->{option_results}->{display_instance} eq '');
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    # default time: &from=now-1h&to=now
    my $results = $options{custom}->request_api(
        url_path => '/api/measures/details?fields=displayName,frequency,timeout,scenario.name,scenario.application.name&scenario.name__neq=null&limit=-1'
    );

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(
            statefile => 'mip_' . $self->{mode} . '_' . $options{custom}->get_hostname()  . '_' . $options{custom}->get_port() . '_' .
                (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_id}) ? md5_hex($self->{option_results}->{filter_id}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_display_name}) ? md5_hex($self->{option_results}->{filter_display_name}) : md5_hex('all')) . '_' .
                (defined($self->{option_results}->{filter_app_name}) ? md5_hex($self->{option_results}->{filter_app_name}) : md5_hex('all'))
        );
    }
    my $save_scenario_times = {};

    $self->{scenario} = {};
    foreach my $entry (@{$results->{results}}) {
        my $mapping = {
            id => $entry->{measure}->{id},
            name => $entry->{measure}->{name},
            display_name => $entry->{measure}->{displayName},
            app_name => defined($entry->{measure}->{scenario}->{application}->{name}) ? $entry->{measure}->{scenario}->{application}->{name} : '-',
        };

        my $filter = 0;
        foreach (keys %$mapping) {
            if (defined($self->{option_results}->{'filter_' . $_}) && $self->{option_results}->{'filter_' . $_} ne '' &&
                $mapping->{$_} !~ /$self->{option_results}->{'filter_' . $_}/) {
                $filter = 1;
                $self->{output}->output_add(long_msg => "skipping scenario id '" . $mapping->{id} . "': no matching filter '$_'.", debug => 1);
                last;
            }
        }
        next if ($filter == 1);

        my $scenario_name = $self->{option_results}->{display_instance};
        $scenario_name =~ s/%\{(.*?)\}/$mapping->{$1}/g;
        $self->{scenario}->{$scenario_name} = {
            display => $scenario_name,
            global => {
                display => $scenario_name,
            },
            metric => {},
            formatted_metrics => {}
        };

        my @sorted = sort(keys %{$entry->{results}});
        my $last_time = pop(@sorted);

        if (defined($self->{option_results}->{memory})) {
            my $save_time = $self->{statefile_cache}->get(name => $mapping->{id});
            $save_scenario_times->{$mapping->{id}} = $last_time;
            if (defined($save_time) && $save_time eq $last_time) {
                $self->{scenario}->{$scenario_name}->{global}->{status} = 'noNewValue';
                next;
            }
        }

        $self->{scenario}->{$scenario_name}->{global}->{status} = $entry->{results}->{$last_time}->{state}->{type};

        foreach (keys %{$entry->{metricInfo}}) {
            $self->{scenario}->{$scenario_name}->{metric}->{ $entry->{metricInfo}->{$_}->{label} } = {
                display => $entry->{metricInfo}->{$_}->{label},
                unit => $entry->{metricInfo}->{$_}->{unit},
                value => $entry->{results}->{$last_time}->{metrics}->{$_}
            };
        }

        foreach my $fmetric_label (keys %{$entry->{results}->{$last_time}->{formatedMetrics}}) {
            next if ($fmetric_label =~ /^(?:API_VERSION|SCRIPT_VERSION)$/);
            $self->{scenario}->{$scenario_name}->{formatted_metrics}->{ $fmetric_label } = {
                display => $fmetric_label,
                value => $entry->{results}->{$last_time}->{formatedMetrics}->{$fmetric_label}
            };
        }
    }

    if (scalar(keys %{$self->{scenario}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No scenario found");
        $self->{output}->option_exit();
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => $save_scenario_times);
    }
}

1;

__END__

=head1 MODE

Check scenarios.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^status$'

=item B<--filter-id>

Filter scenarios by id (can be a regexp).

=item B<--filter-display-name>

Filter scenarios by display name (can be a regexp).

=item B<--filter-name>

Filter scenarios by name (can be a regexp).

=item B<--filter-app-name>

Filter scenarios by applicationn name (can be a regexp).

=item B<--display-instance>

Set the scenario display value (Default: '%{name}').
Can used special variables like: %{name}, %{app_name}, %{display_name}, %{id}

=item B<--memory>

Only check new result entries for scenarios.

=item B<--unknown-status>

Set warning threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /warning/i').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /critical/i').
Can used special variables like: %{status}, %{display}

=back

=cut
