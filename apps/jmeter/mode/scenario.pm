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

package apps::jmeter::mode::scenario;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use XML::XPath;
use XML::XPath::XMLParser;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "remote"                  => { name => 'remote' },
         "hostname:s"              => { name => 'hostname' },
         "ssh-option:s@"           => { name => 'ssh_option' },
         "ssh-path:s"              => { name => 'ssh_path' },
         "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
         "sudo"                    => { name => 'sudo' },
         "command:s"               => { name => 'command', default => 'jmeter' },
         "command-path:s"          => { name => 'command_path' },
         "command-extra-options:s" => { name => 'command_extra_options' },
         "timeout:s"               => { name => 'timeout', default => 50 },
         "directory:s"             => { name => 'directory' },
         "scenario:s"              => { name => 'scenario' },
         "warning:s"               => { name => 'warning' },
         "critical:s"              => { name => 'critical' },
         });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{scenario})) { 
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario name.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $filename = $self->{option_results}->{directory} . '/' . $self->{option_results}->{scenario} . '.jmx';
    my $command_options .= '-t ' . $filename;

    # Temporary write result on stderr
    $command_options .= ' -l /dev/stderr';

    # Write logs to trash
    $command_options .= ' -j /dev/null';

    $command_options .= ' -n';
    $command_options .= ' -J jmeter.save.saveservice.output_format=xml';

    if (defined($self->{option_results}->{command_extra_options})) {
        $command_options .= ' ' . $self->{option_results}->{command_extra_options};
    }

    # Redirect result on stdout and default stdout to trash
    $command_options .= ' 2>&1 >/dev/null';

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $command_options);

    my $p = XML::Parser->new(NoLWP => 1);
    my $xp = XML::XPath->new(parser => $p, xml => $stdout);

    my $listHttpSampleNode = $xp->findnodes('/testResults/httpSample|/testResults/sample');

    my $timing0 = 0;
    my $timing1 = 0;
    my $step = $listHttpSampleNode->get_nodelist;
    my $stepOk = 0;
    my $first_failed_label;
    my $exit1 = 'OK';

    foreach my $httpSampleNode ($listHttpSampleNode->get_nodelist) {
        my $temp_exit = 'OK';

        my $elapsed_time = $httpSampleNode->getAttribute('t');
        my $timestamp = $httpSampleNode->getAttribute('ts');
        my $success = $httpSampleNode->getAttribute('s');
        my $label = $httpSampleNode->getAttribute('lb');
        my $response_code = $httpSampleNode->getAttribute('rc');
        my $response_message = $httpSampleNode->getAttribute('rm');

        $self->{output}->output_add(long_msg => "* Sample: " . $label);
        $self->{output}->output_add(long_msg => "  - Success: " . $success);
        $self->{output}->output_add(long_msg => "  - Elapsed Time: " . $elapsed_time / 1000 . "s");
        $self->{output}->output_add(long_msg => "  - Response Code: " . $response_code);
        $self->{output}->output_add(long_msg => "  - Response Message: " . $response_message);

        if ($success ne 'true') {
            $temp_exit = 'CRITICAL';
        }

        my $listAssertionResultNode = $xp->findnodes('./assertionResult', $httpSampleNode);

        foreach my $assertionResultNode ($listAssertionResultNode->get_nodelist) {
            my $name = $xp->findvalue('./name', $assertionResultNode);
            my $failure = $xp->findvalue('./failure', $assertionResultNode);
            my $error = $xp->findvalue('./error', $assertionResultNode);

            $self->{output}->output_add(long_msg => "  - Assertion: " . $name);

            if (($failure eq 'true') || ($error eq 'true')) {
                my $failure_message = $xp->findvalue('./failureMessage', $assertionResultNode);
                $self->{output}->output_add(long_msg => "    + Failure Message: " . $failure_message);

                $temp_exit = 'CRITICAL';
            }
        }

        if ($temp_exit eq 'OK') {
            $stepOk++;
        } else {
            if (!defined($first_failed_label)) {
                $first_failed_label = $label . " (" . $response_code . " " . $response_message . ")";
            }

            $exit1 = $self->{output}->get_most_critical(status => [ $exit1, $temp_exit ]);
        }

        if ($timestamp > 0) {
            if ($timing0 == 0) {
                $timing0 = $timestamp;
            }

            $timing1 = $timestamp + $elapsed_time;
        }
    }

    my $timeelapsed = ($timing1 - $timing0) / 1000;
    my $availability = sprintf("%d", $stepOk * 100 / $step);

    my $exit2 = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                   threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    if (!defined($first_failed_label)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d/%d steps (%.3fs)", $stepOk, $step, $timeelapsed));
    } else {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d/%d steps (%.3fs) - %s", $stepOk, $step, $timeelapsed, $first_failed_label));
    }
    $self->{output}->perfdata_add(label => "time", unit => 's',
                                  value => sprintf('%.3f', $timeelapsed),
                                  min => 0,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'));
    $self->{output}->perfdata_add(label => "steps",
                                  value => sprintf('%d', $stepOk),
                                  min => 0,
                                  max => $step);
    $self->{output}->perfdata_add(label => "availability", unit => '%',
                                  value => sprintf('%d', $availability),
                                  min => 0,
                                  max => 100);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check scenario execution

=over 8

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none).

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command>

Command to get information (default: 'jmeter').

=item B<--command-path>

Command path (default: none).

=item B<--command-extra-options>

Command extra options (default: none).

=item B<--timeout>

Timeout in seconds for the command (default: 50).

=item B<--directory>

Directory where scenarii are stored.

=item B<--scenario>

Scenario used by JMeter (without extension).

=item B<--warning>

Threshold warning in seconds (scenario execution time).

=item B<--critical>

Threshold critical in seconds (scenario execution time).

=back

=cut
