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

package apps::backup::veeam::wsman::mode::tapejobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::powershell::veeam::tapejobs;
use apps::backup::veeam::wsman::mode::resources::types qw($job_tape_type $job_tape_result $job_tape_state);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
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

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Tape job '" . $options{instance_value}->{display} . "' ";
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
        { label => 'status', type => 2, critical => '%{enabled} == 1 and not %{last_result} =~ /Success|None/i', set => {
                key_values => [
                    { name => 'display' }, { name => 'enabled' },
                    { name => 'type' }, { name => 'last_result' },
                    { name => 'last_state' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'ps-exec-only'      => { name => 'ps_exec_only' },
        'ps-display'        => { name => 'ps_display' },
        'filter-name:s'     => { name => 'filter_name' },
        'exclude-name:s'    => { name => 'exclude_name' },
        'filter-type:s'     => { name => 'filter_type' }
    });

    return $self;
}


sub manage_selection {
    my ($self, %options) = @_;

    my $ps = centreon::common::powershell::veeam::tapejobs::get_powershell();
    if (defined($self->{option_results}->{ps_display})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $ps
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $result = $options{wsman}->execute_powershell(
        label => 'tapejobs',
        content => centreon::plugins::misc::powershell_encoded($ps)
    );
    if (defined($self->{option_results}->{ps_exec_only})) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $result->{tapejobs}->{stdout}
        );
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
        $self->{output}->exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->decode($self->{output}->decode($result->{tapejobs}->{stdout}));
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
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $job->{name} !~ /$self->{option_results}->{filter_name}/);
        next if (defined($self->{option_results}->{exclude_name}) && $self->{option_results}->{exclude_name} ne '' &&
            $job->{name} =~ /$self->{option_results}->{exclude_name}/);

        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $job->{type} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping job '" . $job->{name} . "': no matching filter type.", debug => 1);
            next;
        }
        # Sometimes we may get such JSON: [{"lastResult":null,"name":null,"lastState":null,"type":null,"enabled":null}]
        if (!defined($job->{name})) {
            $self->{output}->output_add(long_msg => "skipping nulled job (empty json)", debug => 1);
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

        if (scalar(keys %{$self->{job}}) <= 0) {
            $self->{output}->add_option_msg(short_msg => "No tape jobs found. Review filters. More infos with --debug option");
            $self->{output}->option_exit();
        }
    }
}

1;

__END__

=head1 MODE

[EXPERIMENTAL] Monitor tape jobs status.

=over 8


=item B<--ps-display>

Display powershell script.

=item B<--ps-exec-only>

Print powershell output.

=item B<--filter-name>

Filter job name (can be a regexp).

=item B<--exclude-name>

Exclude job name (regexp can be used).

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
