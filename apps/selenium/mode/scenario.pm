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

package apps::selenium::mode::scenario;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use XML::XPath;
use XML::XPath::XMLParser;
use WWW::Selenium;

my %handlers = (ALRM => {} );

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
         {
         "selenium-hostname:s"  => { name => 'selenium_hostname', default => 'localhost' },
         "selenium-port:s"      => { name => 'selenium_port', default => '4444' },
         "browser:s"            => { name => 'browser', default => '*firefox' },
         "directory:s"          => { name => 'directory', default => '/var/lib/centreon_waa' },
         "scenario:s"           => { name => 'scenario' },
         "warning:s"            => { name => 'warning' },
         "critical:s"           => { name => 'critical' },
         "timeout:s"            => { name => 'timeout', default => 50 },
         });
    $self->set_signal_handlers;
    return $self;
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{ALRM} = \&class_handle_ALRM;
    $handlers{ALRM}->{$self} = sub { $self->handle_ALRM() };
}

sub class_handle_ALRM {
    foreach (keys %{$handlers{ALRM}}) {
        &{$handlers{ALRM}->{$_}}();
    }
}

sub handle_ALRM {
    my $self = shift;
    
    $self->{output}->output_add(severity => 'UNKNOWN',
                                short_msg => sprintf("Cannot finished scenario execution (timeout received)"));
    $self->{output}->display();
    $self->{output}->exit();
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
    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        alarm($self->{option_results}->{timeout});
    }
    if (!defined($self->{option_results}->{scenario})) { 
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario name.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    my $p = XML::Parser->new(NoLWP => 1);
    my $filename = $self->{option_results}->{directory} . '/' . $self->{option_results}->{scenario} . '.html';
    my $xp = XML::XPath->new(parser => $p, filename => $filename);

    my $baseurlNode = $xp->find('/html/head/link[@rel="selenium.base"]');
    my $baseurl = $baseurlNode->shift->getAttribute('href');

    my $listActionNode = $xp->find('/html/body/table/tbody/tr');

    my $sel = WWW::Selenium->new(
        host => $self->{option_results}->{selenium_hostname},
        port => $self->{option_results}->{selenium_port},
        browser => $self->{option_results}->{browser},
        browser_url => $baseurl
    );

    $sel->start;

    $self->{output}->output_add(long_msg => "Base URL : " . $baseurl);

    my $timing0 = [gettimeofday];
    my ($action, $filter, $value);
    my $step = $listActionNode->get_nodelist;
    my $temp_step = 0;
    my $stepOk = 0;
    my ($last_echo_msg, $last_cmd);
    my $exit1 = 'UNKNOWN';
    foreach my $actionNode ($listActionNode->get_nodelist) {
        ($action, $filter, $value) = $xp->find('./td', $actionNode)->get_nodelist;
        my $trim_action = centreon::plugins::misc::trim($action->string_value);
        my $trim_filter = centreon::plugins::misc::trim($filter->string_value);
        my $trim_value = centreon::plugins::misc::trim($value->string_value);
        $temp_step++;
        if ($trim_action eq 'pause') {
            my $sleepTime = 1000;
            if ($trim_value =~ /^\d+$/) {
                $sleepTime = $trim_value;
            }
            if ($trim_filter =~ /^\d+$/) {
                $sleepTime = $trim_filter;
            }
            sleep($sleepTime / 1000);
            $stepOk++;
            $self->{output}->output_add(long_msg => "Step " . $temp_step . " - Pause : " . $sleepTime . "ms");
        # It's an echo command => do not send it to Selenium server
        # and store the associated string so that it can be displayed
        # in case of a failure as an info message
        } elsif ($trim_action eq 'echo'){
            $last_echo_msg = $trim_filter;
            # Prevent output breakage in case of echo message contains invalid chars
            $last_echo_msg =~ s/\||\n/ - /msg;
            $stepOk += 1;
        } else {
            my $exit_command;
            
            $last_cmd = $trim_action . ' ' . $trim_filter . ' ' . $trim_value;
            eval {
                $exit_command = $sel->do_command($trim_action, $trim_filter, $trim_value);
            };
            $self->{output}->output_add(long_msg => "Step " . $temp_step
                                                    . " - Command : '" . $trim_action . "'"
                                                    . " , Filter : '" . $trim_filter . "'"
                                                    . " , Value : '" . $trim_value . "'");
            if (!$@ && $exit_command eq 'OK') {
                $exit1 = 'OK';
                $stepOk++;
            } else {
                if ($@) {
                    $self->{output}->output_add(long_msg => "display: $@");
                }
                $exit1 = 'CRITICAL';
                last;
            }
        }
    }
    my $timeelapsed = tv_interval ($timing0, [gettimeofday]);
    my $availability = sprintf("%d", $stepOk * 100 / $step);

    my $exit2 = $self->{perfdata}->threshold_check(value => $timeelapsed,
                                                   threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    if ($exit eq 'OK') {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d/%d steps (%.3fs)", $stepOk, $step, $timeelapsed));
    } else {
        my $extra_info = $last_cmd;
        if (defined($last_echo_msg)) {
            $extra_info .= " - $last_echo_msg";
        }
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("%d/%d steps (%.3fs) - %s", $stepOk, $step, $timeelapsed, $extra_info));
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

=item B<--selenium-hostname>

IP Addr/FQDN of the Selenium server

=item B<--selenium-port>

Port used by Selenium server

=item B<--browser>

Browser used by Selenium server (Default : '*firefox')

=item B<--directory>

Directory where scenarii are stored

=item B<--scenario>

Scenario used by Selenium server (without extension)

=item B<--timeout>

Set global execution timeout (Default: 50)

=item B<--warning>

Threshold warning in seconds (Scenario execution time)

=item B<--critical>

Threshold critical in seconds (Scenario execution response time)

=back

=cut
