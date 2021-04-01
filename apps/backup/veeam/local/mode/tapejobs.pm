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

package apps::backup::veeam::local::mode::tapejobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::tapejobs;
use apps::backup::veeam::local::mode::resources::types qw($job_tape_type $job_tape_result $job_tape_state);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::misc;
use JSON::XS;

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "last result: '%s' [type: '%s'][last state: '%s']",
        $self->{result_values}->{last_result},
        $self->{result_values}->{type},
        $self->{result_values}->{last_state},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'job', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'tapejobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total jobs: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{job} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'display' }, { name => 'enabled' },
                    { name => 'type' }, { name => 'last_result' },
                    { name => 'last_state' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'timeout:s'           => { name => 'timeout', default => 50 },
        'command:s'           => { name => 'command', default => 'powershell.exe' },
        'command-path:s'      => { name => 'command_path' },
        'command-options:s'   => { name => 'command_options', default => '-InputFormat none -NoLogo -EncodedCommand' },
        'no-ps'               => { name => 'no_ps' },
        'ps-exec-only'        => { name => 'ps_exec_only' },
        'ps-display'          => { name => 'ps_display' },
        'filter-name:s'       => { name => 'filter_name' },
        'filter-type:s'       => { name => 'filter_type' },
        'unknown-status:s'    => { name => 'unknown_status', default => '' },
        'warning-status:s'    => { name => 'warning_status', default => '' },
        'critical-status:s'   => { name => 'critical_status', default => '%{enabled} == 1 and not %{last_result} =~ /Success|None/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Tape job '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;

    if (!defined($self->{option_results}->{no_ps})) {
        my $ps = centreon::common::powershell::veeam::tapejobs::get_powershell();
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

    my ($stdout) = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
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

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($stdout);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response: $@");
        $self->{output}->option_exit();
    }

    #[
    #  { name: 'xxxx', type: 0, Enabled: True, lastResult: 0, lastState: 0 },
    #  { name: 'xxxx', type: 1, Enabled: True, lastResult: 1, lastState: 1 }
    #]

    $self->{global} = { total => 0 };
    $self->{job} = {};
    foreach my $job (@$decoded) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        
        $self->{job}->{ $job->{name} } = {
            display => $job->{name},
            type => $job_tape_type->{ $job->{type} },
            enabled => $job->{enabled} =~ /True|1/ ? 1 : 0,
            last_result => $job_tape_result->{ $job->{lastResult} },
            last_state => $job_tape_state->{ $job->{lastState} }
        };
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check tape jobs status.

=over 8

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

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--filter-type>

Filter job type (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status (Default: '')
Can used special variables like: %{display}, %{enabled}, %{type}, %{last_result}, %{last_state}.

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{display}, %{enabled}, %{type}, %{last_result}, %{last_state}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{enabled} == 1 and not %{last_result} =~ /Success|None/i').
Can used special variables like: %{display}, %{enabled}, %{type}, %{last_result}, %{last_state}.

=item B<--warning-total>

Set warning threshold for total jobs.

=item B<--critical-total>

Set critical threshold for total jobs.

=back

=cut
