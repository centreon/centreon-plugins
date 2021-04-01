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

package storage::dell::compellent::local::mode::volumeusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::dell::compellent::volumeusage;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sc', type => 1, cb_prefix_output => 'prefix_sc_output', message_multiple => 'All storage centers are ok', cb_init => 'sc_init' },
        { name => 'volume', type => 1, cb_prefix_output => 'prefix_volume_output', message_multiple => 'All volumes are ok' }
    ];

    $self->{maps_counters}->{sc} = [
        { label => 'sc-total', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' }, { name => 'type' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];

    $self->{maps_counters}->{volume} = [
        { label => 'volume-usage', set => {
                key_values => [ { name => 'display' }, { name => 'used' }, { name => 'total' }, { name => 'type' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
        { label => 'volume-overhead', set => {
                key_values => [ { name => 'overhead' }, { name => 'display' } ],
                output_template => 'Raid Overhead : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'volume_overhead', value => 'overhead', template => '%d',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'volume-replay', set => {
                key_values => [ { name => 'replay' }, { name => 'display' } ],
                output_template => 'Replay : %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'volume_replay', value => 'replay', template => '%d',
                      unit => 'B', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_sc_output {
    my ($self, %options) = @_;

    return "Storage center '" . $options{instance_value}->{display} . "' ";
}

sub prefix_volume_output {
    my ($self, %options) = @_;

    return "Volume '" . $options{instance_value}->{display} . "' ";
}

sub sc_init {
    my ($self, %options) = @_;

    if (defined($self->{option_results}->{ps_sc_volume}) && $self->{option_results}->{ps_sc_volume} ne '')  {
        return 1;
    }
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    my $label = $self->{result_values}->{type} . '_used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($self->{instance_mode}->{option_results}->{free})) {
        $label = $self->{result_values}->{type} . '_free';
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
    my $msg = sprintf(
        "Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
        $total_size_value . " " . $total_size_unit,
        $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
        $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free}
    );
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{type} = $options{new_datas}->{$self->{instance} . '_type'};

    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    # snapshot can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }

    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'cem-host:s'        => { name => 'cem_host' },
        'cem-user:s'        => { name => 'cem_user' },
        'cem-password:s'    => { name => 'cem_password' },
        'cem-port:s'        => { name => 'cem_port', default => 3033 },
        'sdk-path-dll:s'    => { name => 'sdk_path_dll' },
        'timeout:s'         => { name => 'timeout', default => 50 },
        'command:s'         => { name => 'command', default => 'powershell.exe' },
        'command-path:s'    => { name => 'command_path' },
        'command-options:s' => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'             => { name => 'no_ps' },
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'ps-sc-filter:s'    => { name => 'ps_sc_filter' },
        'ps-sc-volume:s'    => { name => 'ps_sc_volume' },
        'units:s'           => { name => 'units', default => '%' },
        'free'              => { name => 'free' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $label (('cem_host', 'cem_user', 'cem_password', 'cem_port', 'sdk_path_dll')) {
        if (!defined($self->{option_results}->{$label}) || $self->{option_results}->{$label} eq '') {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label_opt . " option.");
            $self->{output}->option_exit();
        }
    }    
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::dell::compellent::volumeusage::get_powershell(
            cem_host => $self->{option_results}->{cem_host},
            cem_user => $self->{option_results}->{cem_user},
            cem_password => $self->{option_results}->{cem_password},
            cem_port => $self->{option_results}->{cem_port},
            sdk_path_dll => $self->{option_results}->{sdk_path_dll},
            filter_sc => $self->{option_results}->{ps_sc_filter},
            filter_vol => $self->{option_results}->{ps_sc_volume}
        );
        if (defined($self->{option_results}->{ps_display})) {
            $self->{output}->output_add(
                severity => 'OK',
                short_msg => $ps
            );
            $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
            $self->{output}->exit();
        }

        $self->{option_results}->{command_options} .= " " . centreon::plugins::misc::powershell_encoded($ps);
    }

    my ($stdout) = centreon::plugins::misc::windows_execute(
        output => $self->{output},
        timeout => $self->{option_results}->{timeout},
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $stdout
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    # [sc=PRD-SAN-01][volume=SC-S06][configuredSpace=xxxxx][freeSpace=xxxxx][activeSpace=xxxxx][raidOverhead=xxx][totalDiskSpace=xxxx][replaySpace=xxxx]
    $self->{volume} = {};
    $self->{sc} = {};
    while ($stdout =~ /^\[sc=(.*?)\]\[volume=(.*?)\]\[configuredSpace=(.*?)\]\[freeSpace=(.*?)\]\[activeSpace=(.*?)\]\[raidOverhead=(.*?)\]\[totalDiskSpace=(.*?)\]\[replaySpace=(.*?)\]/mig) {
        my ($sc, $volume, $configured_space, $free_space, $active_space, $raid_overhead, $total_disk_space, $replay_space) = 
            ($1, $2, $3, $4, $5, $6, $7, $8);
        my $name = $sc . '/' . $volume;

        $self->{volume}->{$name} = {
            display => $name, total => $configured_space, type => 'volume',
            used => $active_space + $raid_overhead + $replay_space,
            overhead => $raid_overhead, replay => $replay_space
        };
        $self->{sc}->{$sc} = { display => $sc, total => 0, used => 0, type => 'sc' } if (!defined($self->{sc}->{$sc}));
        $self->{sc}->{$sc}->{used} += $active_space + $raid_overhead + $replay_space;
    }

    # [sc=PRD-SAN-01][disk=01-01][spare=False][allocatedSpace=960195723264]
    while ($stdout =~ /^\[sc=(.*?)\]\[disk=(.*?)\]\[spare=(.*?)\]\[allocatedSpace=(.*?)\]/mig) {
        my ($sc, $disk, $spare, $allocated_space) = 
            ($1, $2, $3, $4);
        $self->{sc}->{$sc}->{total} += $allocated_space;
    }
}

1;

__END__

=head1 MODE

Check storage center and volume usages.

=over 8

=item B<--cem-host>

Compellent Entreprise Manager hostname (Required).

=item B<--cem-user>

Compellent Entreprise Manager username (Required).

=item B<--cem-password>

Compellent Entreprise Manager password (Required).

=item B<--cem-port>

Compellent Entreprise Manager port (Default: 3033).

=item B<--sdk-path-dll>

Path to 'DellStorage.ApiCommandSet.dll' (Required).

=item B<--timeout>

Set timeout time for command execution (Default: 50 sec)

=item B<--no-ps>

Don't encode powershell. To be used with --command and 'type' command.

=item B<--command>

Command to get information (Default: 'powershell.exe').
Can be changed if you have output in a file. To be used with --no-ps option!!!

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: '-InputFormat none -NoLogo -EncodedCommand').

=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--ps-sc-filter>

Filter Storage Center (only wilcard '*' can be used. In Powershell).

=item B<--ps-sc-volume>

Filter Volume Name to display.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^sc-total$'

=item B<--warning-*>

Threshold warning.
Can be: 'sc-total', 'volume-usage', 'volume-overhead', 'volume-replay'.

=item B<--critical-*>

Threshold critical.
Can be: 'sc-total', 'volume-usage', 'volume-overhead', 'volume-replay'.

=back

=cut
