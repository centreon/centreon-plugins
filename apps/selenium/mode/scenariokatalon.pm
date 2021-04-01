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

package apps::selenium::mode::scenariokatalon;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Time::HiRes qw(gettimeofday);
use XML::XPath;
use WWW::Selenium;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

my %handlers = (ALRM => {} );

sub custom_count_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => $self->{result_values}->{label},
                                  value => $self->{result_values}->{value},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});

    $self->{output}->perfdata_add(label => $self->{result_values}->{label} . '_prct',
                                  value => sprintf('%.2f', $self->{result_values}->{value_prct}),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{result_values}->{label} . '-prct'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{result_values}->{label} . '-prct'),
                                  min => 0, max => 100, unit => '%');
}

sub custom_count_threshold {
    my ($self, %options) = @_;
    
    my $exit1 = $self->{perfdata}->threshold_check(value => $self->{result_values}->{value},
                                                  threshold => [ { label => 'critical-' . $self->{result_values}->{label}, exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{result_values}->{label}, exit_litteral => 'warning' } ]);

    my $exit2 = $self->{perfdata}->threshold_check(value => $self->{result_values}->{value} . '_prct',
                                                  threshold => [ { label => 'critical-' . $self->{result_values}->{label} . '-prct', exit_litteral => 'critical' },
                                                                 { label => 'warning-' . $self->{result_values}->{label} . '-prct', exit_litteral => 'warning' } ]);
    
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    
    return $exit;
}

sub custom_count_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("%s steps : %s/%s (%.2f%%)", ucfirst($self->{result_values}->{label}),
        $self->{result_values}->{value}, $self->{result_values}->{total}, $self->{result_values}->{value_prct});

    return $msg;
}

sub custom_count_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{label} = $options{extra_options}->{label};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $self->{result_values}->{label}};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{value_prct} = $self->{result_values}->{value} / $self->{result_values}->{total} * 100;

    return 0;
}

sub custom_state_output {
    my ($self, %options) = @_;

    my $msg = "state is '" . $self->{result_values}->{state} . "'";
    $msg .= " : " . $self->{result_values}->{comment} if (defined($self->{result_values}->{comment}) && $self->{result_values}->{comment} ne '');

    return $msg;
}

sub custom_state_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{command} = $options{new_datas}->{$self->{instance} . '_command'};
    $self->{result_values}->{target} = $options{new_datas}->{$self->{instance} . '_target'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_value'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{comment} = $options{new_datas}->{$self->{instance} . '_comment'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    my $msg = "Step '" . $options{instance_value}->{display} . "' [command: " . $options{instance_value}->{command};
    $msg .= ", target: " . $options{instance_value}->{target} if (defined($options{instance_value}->{target}) && $options{instance_value}->{target} ne '');
    $msg .= ", value: " . $options{instance_value}->{value} if (defined($options{instance_value}->{value}) && $options{instance_value}->{value} ne '');
    $msg .= "] ";

    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'steps', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All steps state are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'successful', set => {
                key_values => [ { name => 'successful' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_count_calc'),
                closure_custom_calc_extra_options => { label => 'successful' },
                closure_custom_output => $self->can('custom_count_output'),
                closure_custom_perfdata => $self->can('custom_count_perfdata'),
                closure_custom_threshold_check => $self->can('custom_count_threshold'),
            }
        },
        { label => 'failed', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                closure_custom_calc => $self->can('custom_count_calc'),
                closure_custom_calc_extra_options => { label => 'failed' },
                closure_custom_output => $self->can('custom_count_output'),
                closure_custom_perfdata => $self->can('custom_count_perfdata'),
                closure_custom_threshold_check => $self->can('custom_count_threshold'),
            }
        },
        { label => 'time-scenario', set => {
                key_values => [ { name => 'time_scenario' } ],
                output_template => 'Total execution time : %.2f ms',
                perfdatas => [
                    { label => 'time_scenario', value => 'time_scenario', template => '%.2f',
                      min => 0, unit => 'ms' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{steps} = [
        { label => 'state', set => {
                key_values => [ { name => 'state' }, { name => 'command' }, { name => 'target' },
                                { name => 'value' }, { name => 'comment' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_state_calc'),
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'time-step', set => {
                key_values => [ { name => 'time_step' }, { name => 'display' } ],
                output_template => 'Execution time : %.2f ms',
                perfdatas => [
                    { label => 'time_step', value => 'time_step', template => '%.2f',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                {
                                    "selenium-hostname:s"   => { name => 'selenium_hostname', default => 'localhost' },
                                    "selenium-port:s"       => { name => 'selenium_port', default => '4444' },
                                    "browser:s"             => { name => 'browser', default => '*firefox' },
                                    "directory:s"           => { name => 'directory', default => '/var/lib/centreon_waa' },
                                    "scenario:s"            => { name => 'scenario' },
                                    "force-continue"        => { name => 'force_continue' },
                                    "timeout:s"             => { name => 'timeout', default => 50 },
                                    "action-timeout:s"      => { name => 'action_timeout', default => 10 },
                                    "warning-state:s"       => { name => 'warning_state', default => '' },
                                    "critical-state:s"      => { name => 'critical_state', default => '%{state} !~ /OK/i' },
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
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        alarm($self->{option_results}->{timeout});
    }
    if (!defined($self->{option_results}->{scenario})) { 
        $self->{output}->add_option_msg(short_msg => "Please specify a scenario name.");
        $self->{output}->option_exit();
    }
    
    $self->change_macros(macros => ['warning_state', 'critical_state']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global}->{failed} = 0;
    $self->{global}->{successful} = 0;
    $self->{global}->{time_scenario} = 0;

    $self->{selenium} = WWW::Selenium->new(
        host => $self->{option_results}->{selenium_hostname},
        port => $self->{option_results}->{selenium_port},
        browser => $self->{option_results}->{browser},
        browser_url => "file://localhost"
    );

    my $filename = $self->{option_results}->{directory} . '/' . $self->{option_results}->{scenario} . '.xml';
    my $xp = XML::XPath->new(filename => $filename);

    my $step = 1;

    $self->{selenium}->start;
    $self->{selenium}->set_timeout($self->{option_results}->{action_timeout} * 1000);

    my $actions = $xp->find('/TestCase/selenese');
    $self->{global}->{total} = $actions->size;
    
    my $start = gettimeofday() * 1000;

    foreach my $action ($actions->get_nodelist) {
        my $command = centreon::plugins::misc::trim($xp->find('command', $action)->string_value);
        my $target = centreon::plugins::misc::trim($xp->find('target', $action)->string_value);
        my $value = centreon::plugins::misc::trim($xp->find('value', $action)->string_value);
        
        $self->{steps}->{$step}->{display} = $step;
        $self->{steps}->{$step}->{command} = $command;
        $self->{steps}->{$step}->{target} = $target;
        $self->{steps}->{$step}->{value} = $value;
        $self->{steps}->{$step}->{state} = 'OK';
        $self->{steps}->{$step}->{comment} = '';
        $self->{steps}->{$step}->{time_step} = 0;
        
        my $result;
        my $step_start = gettimeofday() * 1000;
        
        eval {
            if ($command =~ /pause/) {
                $result = $self->{selenium}->pause($value);
            } else {
                $result = $self->{selenium}->do_command($command, $target, $value);
            }
        };

        $self->{steps}->{$step}->{time_step} = gettimeofday() * 1000 - $step_start;

        if (!$@) {
            $self->{global}->{successful}++;
        } else {
            $self->{steps}->{$step}->{comment} = $@;
            $self->{steps}->{$step}->{comment} =~ s/^(.*\n)//;;;
            $self->{steps}->{$step}->{comment} =~ s/\n//;;;
            $self->{steps}->{$step}->{state} = 'ERROR';
            $self->{global}->{failed}++;
            last unless $self->{option_results}->{force_continue};
        }

        $step++;
    }

    $self->{global}->{time_scenario} = gettimeofday() * 1000 - $start;
    $self->{selenium}->stop;
}

1;

__END__

=head1 MODE

Play scenario based on Katalon Automation Recorder XML export

=over 8

=item B<--selenium-hostname>

IP Addr/FQDN of the Selenium server.

=item B<--selenium-port>

Port used by Selenium server.

=item B<--browser>

Browser used by Selenium server (Default : '*firefox').

=item B<--directory>

Directory where scenarii are stored.

=item B<--scenario>

Scenario to play (without extension).

=item B<--force-continue>

Don't stop if error.

=item B<--timeout>

Set scenario execution timeout in second (Default: 50).

=item B<--action-timeout>

Set action execution timeout in second (Default: 10).

=item B<--warning-*>

Threshold warning for steps state count
(Can be: 'failed', 'successful').

=item B<--critical-*>

Threshold critical for steps state count
(Can be: 'failed', 'successful').

=item B<--warning-time-scenario>

Threshold warning in milliseconds
for scenario execution time.

=item B<--critical-time-scenario>

Threshold critical in milliseconds
for scenario execution time.

=item B<--warning-time-step>

Threshold warning in milliseconds
for step execution time.

=item B<--critical-time-step>

Threshold critical in milliseconds
for step execution time.

=item B<--warning-state>

Threshold warning for step state.

=item B<--critical-state>

Threshold critical for step state
(Default: '%{state} !~ /OK/i').

=back

=cut
