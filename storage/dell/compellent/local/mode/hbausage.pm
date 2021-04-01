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

package storage::dell::compellent::local::mode::hbausage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::dell::compellent::hbausage;
use DateTime;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'hba', type => 1, cb_prefix_output => 'prefix_hba_output', message_multiple => 'All HBA are ok' }
    ];
    
    $self->{maps_counters}->{hba} = [
        { label => 'read-iops', set => {
                key_values => [ { name => 'read_iops' }, { name => 'display' } ],
                output_template => 'Read IOPs : %s',
                perfdatas => [
                    { label => 'read_iops', value => 'read_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-usage', set => {
                key_values => [ { name => 'read_bps' }, { name => 'display' } ],
                output_template => 'Read usage : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'read_usage', value => 'read_bps', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'read-latency', set => {
                key_values => [ { name => 'read_latency' }, { name => 'display' } ],
                output_template => 'Read latency : %s ms',
                perfdatas => [
                    { label => 'read_latency', value => 'read_latency', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-iops', set => {
                key_values => [ { name => 'write_iops' }, { name => 'display' } ],
                output_template => 'Write IOPs : %s',
                perfdatas => [
                    { label => 'write_iops', value => 'write_iops', template => '%d',
                      unit => 'iops', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-usage', set => {
                key_values => [ { name => 'write_bps' }, { name => 'display' } ],
                output_template => 'Write Usage : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'write_usage', value => 'write_bps', template => '%d',
                      unit => 'b/s', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
        { label => 'write-latency', set => {
                key_values => [ { name => 'write_latency' }, { name => 'display' } ],
                output_template => 'Write Latency : %s ms',
                perfdatas => [
                    { label => 'write_latency', value => 'write_latency', template => '%d',
                      unit => 'ms', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_hba_output {
    my ($self, %options) = @_;
    
    return "HBA '" . $options{instance_value}->{display} . "' ";
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
        'start-time:s'      => { name => 'start_time' },
        'end-time:s'        => { name => 'end_time' },
        'timezone:s'        => { name => 'timezone' },
    });

    return $self;
}

sub get_iso8601 {
    my ($self, %options) = @_;
    my $value = $options{date}->datetime . '.' . sprintf("%03d", $options{date}->millisecond());
    my $offset = $options{date}->offset();

    $value .= "-" if ($offset < 0);
    $value .= "+" if ($offset >= 0);
    $offset = abs($offset);
    $value .= sprintf("%02d:%02d", $offset / 3600, $offset % 3600);

    return $value;
}

sub parse_date {
    my ($self, %options) = @_;

    if ($options{date} !~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/) {
        $self->{output}->add_option_msg(short_msg => "Wrong time option '" . $options{date} . "'.");
        $self->{output}->option_exit();
    }

    my $dt = DateTime->new(
        year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6,
        %{$self->{tz}}
    );
    return $dt;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

 	$self->{option_results}->{timezone} = 'GMT' if (!defined($self->{option_results}->{timezone}) || $self->{option_results}->{timezone} eq '');
    foreach my $label (('cem_host', 'cem_user', 'cem_password', 'cem_port', 'sdk_path_dll')) {
        if (!defined($self->{option_results}->{$label}) || $self->{option_results}->{$label} eq '') {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Need to specify --" . $label_opt . " option.");
            $self->{output}->option_exit();
        }
    }

    my ($dt_start, $dt_end);
    $self->{tz} = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    if (defined($self->{option_results}->{end_time}) && $self->{option_results}->{end_time} ne '') {
        $dt_end = $self->parse_date(date => $self->{option_results}->{end_time});
    } else {
        $dt_end = DateTime->now(%{$self->{tz}});
    }
    $self->{end_time} = $self->get_iso8601(date => $dt_end);

    if (defined($self->{option_results}->{start_time}) && $self->{option_results}->{start_time} ne '') {
        $dt_start = $self->parse_date(date => $self->{option_results}->{start_time});
    } else {
        $dt_start = $dt_end->subtract(minutes => 30);
    }
    $self->{start_time} = $self->get_iso8601(date => $dt_start);
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::dell::compellent::hbausage::get_powershell(
            cem_host => $self->{option_results}->{cem_host},
            cem_user => $self->{option_results}->{cem_user},
            cem_password => $self->{option_results}->{cem_password},
            cem_port => $self->{option_results}->{cem_port},
            sdk_path_dll => $self->{option_results}->{sdk_path_dll},
            filter_sc => $self->{option_results}->{ps_sc_filter},
            end_time => $self->{end_time}, start_time => $self->{start_time}
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

    # microseconds for latencies
    #[sc=PRD-SAN-01][name=xxxx][ReadIops=39,5][ReadKbPerSecond=1220,75][ReadLatency=3997][WriteIops=95,75][WriteKbPerSecond=1217][WriteLatency=3903,25]
    $self->{hba} = {};
    $stdout =~ s/,/\./msg;
    while ($stdout =~ /^\[sc=(.*?)\]\[name=(.*?)\]\[ReadIops=(.*?)\]\[ReadKbPerSecond=(.*?)\]\[ReadLatency=(.*?)\]\[WriteIops=(.*?)\]\[WriteKbPerSecond=(.*?)\]\[WriteLatency=(.*?)\]/mig) {
        my ($sc, $name, $read_iops, $read_kbps, $read_latency, $write_iops, $write_kbps, $write_latency) = 
            ($1, $2, $3, $4, $5, $6, $7, $8);
        my $display = $sc . '/' . $name;
    
        $self->{hba}->{$name} = {
            display => $display, read_iops => $read_iops, read_bps => $read_kbps * 1000, read_latency => $read_latency / 1000,
            write_iops => $write_iops, write_bps => $write_kbps * 1000, write_latency => $write_latency / 1000
        };
    }
}

1;

__END__

=head1 MODE

Check hba usages.

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

=item B<--start-time>

Begin time for counters sampling. If not set, 30 minutes before the end-time option or current time
Format: 2016-05-25T10:30:00

=item B<--end-time>

End time for counters sampling. If not set, the current execution time.
Format: 2016-05-25T15:30:00

=item B<--timezone>

Timezone of time options. Default is 'GMT'.

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^read-iops$'

=item B<--warning-*>

Threshold warning.
Can be: 'read-iops', 'read-usage', 'read-latency', 
'write-iops', 'write-usage', 'write-latency'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-iops', 'read-usage', 'read-latency', 
'write-iops', 'write-usage', 'write-latency'.

=back

=cut
