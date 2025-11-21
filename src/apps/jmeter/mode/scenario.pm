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

package apps::jmeter::mode::scenario;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'command-extra-options:s' => { name => 'command_extra_options' },
        'timeout:s'               => { name => 'timeout', default => 50 },
        'directory:s'             => { name => 'directory' },
        'scenario:s'              => { name => 'scenario' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{scenario})) {
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario name.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{directory})) {
        $self->{output}->add_option_msg(short_msg => "Please specify a directory.");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{directory} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{directory});
    $self->{option_results}->{scenario} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{scenario});
    $self->{option_results}->{command_extra_options} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{command_extra_options});
}

sub custom_steps_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Steps: %s/%s", $self->{result_values}->{steps_ok}, $self->{result_values}->{steps_total});
    return $msg;
}

sub custom_steps_threshold {
    my ($self, %options) = @_;

    return 'ok' if ($self->{result_values}->{steps_ok} == $self->{result_values}->{steps_total});
    return 'critical';
}

sub suffix_output {
    my ($self, %options) = @_;

    my $msg = '';
    if (defined($options{instance_value}->{first_failed_label})) {
        $msg .= ' - First failed: ' . $options{instance_value}->{first_failed_label};
    }
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_suffix_output => 'suffix_output' }
    ];

    $self->{maps_counters}->{global} = [
        {
            label  => 'time',
            nlabel => 'scenario.time.seconds',
            set    => {
                key_values      => [ { name => 'time' } ],
                output_template => 'Elapsed Time: %.3fs',
                perfdatas       => [
                    { template             => '%.3f',
                      min                  => 0,
                      unit                 => 's',
                      label_extra_instance => 1
                    }
                ]
            }
        },
        {
            label  => 'steps',
            nlabel => 'scenario.steps.count',
            set    => {
                key_values                     => [ { name => 'steps_ok' }, { name => 'steps_total' } ],
                closure_custom_output          => $self->can('custom_steps_output'),
                perfdatas                      => [
                    { value    => 'steps_ok',
                      template => '%d',
                      min      => 0,
                      max      => 'steps_total' }
                ],
                closure_custom_threshold_check => $self->can('custom_steps_threshold')
            }
        },
        {
            label  => 'availability',
            nlabel => 'scenario.availability.percentage',
            set    => {
                key_values      => [ { name => 'availability' } ],
                output_template => 'Availability: %d%%',
                perfdatas       => [
                    { value    => 'availability',
                      template => '%d',
                      min      => 0,
                      max      => 100,
                      unit     => '%'
                    }
                ]
            }
        }
    ];
}

sub manage_selection {
    my ($self, %options) = @_;

    # Specify test plan file path
    my $filename = $self->{option_results}->{directory} . '/' . $self->{option_results}->{scenario} . '.jmx';
    my $command_options = '-t ' . $filename;
    # Temporary write result on stderr
    $command_options .= ' -l /dev/stderr';
    # Write logs to trash
    $command_options .= ' -j /dev/null';
    # Non-GUI mode
    $command_options .= ' -n';
    # XML output format
    $command_options .= ' -J jmeter.save.saveservice.output_format=xml';
    # Extra options
    if (defined($self->{option_results}->{command_extra_options})) {
        $command_options .= ' ' . $self->{option_results}->{command_extra_options};
    }
    # Redirect result on stdout and default stdout to trash
    $command_options .= ' 2>&1 >/dev/null';

    my ($stdout) = $options{custom}->execute_command(
        command         => 'jmeter',
        command_options => $command_options
    );

    my $p = XML::Parser->new(NoLWP => 1);
    my $xp = XML::XPath->new(parser => $p, xml => $stdout);

    my $listHttpSampleNode = $xp->findnodes('/testResults/httpSample|/testResults/sample');

    my $start_time = 0;
    my $end_time = 0;
    my $steps = $listHttpSampleNode->get_nodelist;
    my $steps_ok = 0;
    my $first_failed_label;

    foreach my $httpSampleNode ($listHttpSampleNode->get_nodelist) {
        my $elapsed_time = $httpSampleNode->getAttribute('t');
        my $timestamp = $httpSampleNode->getAttribute('ts');
        my $success = $httpSampleNode->getAttribute('s');
        my $label = $httpSampleNode->getAttribute('lb');
        my $response_code = $httpSampleNode->getAttribute('rc');
        my $response_message = $httpSampleNode->getAttribute('rm');

        if ($self->{output}->is_verbose()) {
            $self->{output}->output_add(long_msg => "* Sample: " . $label);
            $self->{output}->output_add(long_msg => "  - Success: " . $success);
            $self->{output}->output_add(long_msg => "  - Elapsed Time: " . $elapsed_time / 1000 . "s");
            $self->{output}->output_add(long_msg => "  - Response Code: " . $response_code);
            $self->{output}->output_add(long_msg => "  - Response Message: " . $response_message);
        }

        my $listAssertionResultNode = $xp->findnodes('./assertionResult', $httpSampleNode);

        foreach my $assertionResultNode ($listAssertionResultNode->get_nodelist) {
            my $name = $xp->findvalue('./name', $assertionResultNode);
            $self->{output}->output_add(long_msg => "  - Assertion: " . $name);

            if ($self->{output}->is_verbose()) {
                my $failure = $xp->findvalue('./failure', $assertionResultNode);
                my $error = $xp->findvalue('./error', $assertionResultNode);
                if (($failure eq 'true') || ($error eq 'true')) {
                    my $failure_message = $xp->findvalue('./failureMessage', $assertionResultNode);
                    $self->{output}->output_add(long_msg => "    + Failure Message: " . $failure_message);
                }
            }
        }

        if ($success eq 'true') {
            $steps_ok++;
        } else {
            if (!defined($first_failed_label)) {
                $first_failed_label = $label . " (" . $response_code . " " . $response_message . ")";
            }
        }

        if ($timestamp > 0) {
            if ($timestamp < $start_time || $start_time == 0) {
                $start_time = $timestamp;
            }
            my $current_time = $timestamp + $elapsed_time;
            if ($current_time > $end_time) {
                $end_time = $current_time;
            }
        }
    }
    my $timeelapsed = ($end_time - $start_time) / 1000;
    my $availability = sprintf("%d", $steps_ok * 100 / $steps);

    $self->{global}->{time} = $timeelapsed;
    $self->{global}->{steps_ok} = $steps_ok;
    $self->{global}->{steps_total} = $steps;
    $self->{global}->{first_failed_label} = $first_failed_label;
    $self->{global}->{availability} = $availability;
}

1;

__END__

=head1 MODE

Check scenario execution.

Command used: 'jmeter -t %(directory)/%(scenario).jmx -l /dev/stderr -j /dev/null -n -J jmeter.save.saveservice.output_format=xml %(command-extra-options) 2>&1 >/dev/null'

=over 8

=item B<--command-extra-options>

JMeter command extra options.

=item B<--directory>

Directory where scenarii are stored.

=item B<--scenario>

Scenario used by JMeter (without extension).

=item B<--warning-time>

Warning threshold in seconds (scenario execution time).

=item B<--critical-time>

Critical threshold in seconds (scenario execution time).

=back

=cut
