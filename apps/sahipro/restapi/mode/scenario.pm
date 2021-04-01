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

package apps::sahipro::restapi::mode::scenario;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use centreon::plugins::http;
use Time::HiRes;
use POSIX qw(strftime);
use XML::Simple;
use DateTime;

my %handlers = (ALRM => {});

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf('status is %s', $self->{result_values}->{status});
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    foreach (keys %{$options{new_datas}}) {
        if (/$self->{instance}_(step\d+_time)/) {
            $self->{result_values}->{$1} = $options{new_datas}->{$_};
        }
    }
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'steps', type => 1, cb_prefix_output => 'prefix_step_output', message_multiple => 'All steps are ok', sort_method => 'num' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [],
                manual_keys => 1,
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'total-time', display_ok => 0, set => {
                key_values => [ { name => 'time_taken' } ],
                output_template => 'execution time : %s ms',
                perfdatas => [
                    { label => 'total_time', value => 'time_taken', template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'total-steps', display_ok => 0, set => {
                key_values => [ { name => 'total_steps' } ],
                output_template => 'total steps : %s',
                perfdatas => [
                    { label => 'total_steps', value => 'total_steps', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'failures', display_ok => 0, set => {
                key_values => [ { name => 'failures' } ],
                output_template => 'failures : %s',
                perfdatas => [
                    { label => 'failures', value => 'failures', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'errors', display_ok => 0, set => {
                key_values => [ { name => 'errors' } ],
                output_template => 'errors : %s',
                perfdatas => [
                    { label => 'errors', value => 'errors', template => '%s', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{steps} = [
        { label => 'step-time', set => {
                key_values => [ { name => 'time_taken' }, { name => 'step' } ],
                output_template => 'execution time : %s ms',
                perfdatas => [
                    { label => 'step_time', value => 'time_taken', template => '%s',
                      min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'step' },
                ],
            }
        },

    ];
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Scenario ';
}

sub prefix_step_output {
    my ($self, %options) = @_;

    return "Step '" . $options{instance_value}->{step} . "' [" . $options{instance_value}->{display}  . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
         'sahi-hostname:s'      => { name => 'sahi_hostname' },
         'sahi-port:s'          => { name => 'sahi_port', default => 9999 },
         'sahi-proto:s'         => { name => 'sahi_proto', default => 'http' },
         'sahi-http-timeout:s'  => { name => 'sahi_http_timeout', default => 5 },
         'sahi-endpoint:s'      => { name => 'sahi_endpoint', default => '/_s_/dyn/' },
         'sahi-suite:s'         => { name => 'sahi_suite' },
         'sahi-threads:s'       => { name => 'sahi_threads', default => 1 },
         'sahi-startwith:s'     => { name => 'sahi_startwith', default => 'BROWSER' },
         'sahi-browsertype:s'   => { name => 'sahi_browsertype', default => 'chrome' },
         'sahi-baseurl:s'       => { name => 'sahi_baseurl' },
         'timeout:s'            => { name => 'timeout' },
         'retries-scenario-status:s'    => { name => 'retries_scenario_status' },
         'interval-scenario-status:s'   => { name => 'interval_scenario_status', default => 10 },
         'unknown-run-status:s'     => { name => 'unknown_run_status', default => '%{http_code} < 200 or %{http_code} >= 300' },
         'warning-run-status:s'     => { name => 'warning_run_status' },
         'critical-run-status:s'    => { name => 'critical_run_status', default => '' },
         'warning-status:s'         => { name => 'warning_status', default => '' },
         'critical-status:s'        => { name => 'critical_status', default => '%{status} ne "SUCCESS"' },
    });
    
    $self->{http} = centreon::plugins::http->new(%options);
    $self->set_signal_handlers();
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

    $self->killed_scenario();
    $self->{output}->add_option_msg(short_msg => 'Cannot finished scenario execution (timeout received)');
    $self->{output}->option_exit();
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    foreach my $option (('sahi_hostname', 'sahi_suite', 'sahi_startwith', 'sahi_browsertype')) {
        (my $label = $option) =~ s/_/-/g;
        if (!defined($self->{option_results}->{$option}) || $self->{option_results}->{$option} eq '') {
            $self->{output}->add_option_msg(short_msg => 'Please set ' . $label . ' option');
            $self->{output}->option_exit();
        }
    }
    
    if (!defined($self->{option_results}->{interval_scenario_status}) || $self->{option_results}->{interval_scenario_status} !~ /^\d+$/ ||
        $self->{option_results}->{interval_scenario_status} < 0) {
        $self->{option_results}->{interval_scenario_status} = 10;
    }
    if (!defined($self->{option_results}->{retries_scenario_status}) || $self->{option_results}->{retries_scenario_status} !~ /^\d+$/ ||
        $self->{option_results}->{retries_scenario_status} < 0) {
        $self->{option_results}->{retries_scenario_status} = 0;
    }
    
    if (defined($self->{option_results}->{timeout}) && $self->{option_results}->{timeout} =~ /^\d+$/ &&
        $self->{option_results}->{timeout} > 0) {
        alarm($self->{option_results}->{timeout});
    }
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
    $self->{http}->set_options(port => $self->{option_results}->{sahi_port}, proto => $self->{option_results}->{sahi_proto});
}

sub decode_xml_response {
    my ($self, %options) = @_;

    my $content;
    eval {
        $content = XMLin($options{response}, ForceArray => $options{ForceArray}, KeyAttr => []);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode xml response: $@");
        $self->{output}->option_exit();
    }
    
    return $content;
}

sub generate_user_defined_id {
    my ($self, %options) = @_;
    
    my ($seconds, $microseconds) = Time::HiRes::gettimeofday();
    my $user_defined_id = strftime('%d%B%Y__%H_%M_%S_', localtime($seconds));
    $user_defined_id .= $microseconds;

    return $user_defined_id;
}

sub time2ms {
    my ($self, %options) = @_;

    #2019-02-26 10:38:47.407
    return -1 if ($options{time} !~ /^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2}).(\d+)/);
    my $dt = DateTime->new(year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, nanosecond => $7 * 1000000);
    return $dt->hires_epoch;
}

sub killed_scenario {
    my ($self, %options) = @_;
    
    return if (!defined($self->{user_defined_id}));
    $self->{http}->request(
        proto => $self->{option_results}->{sahi_proto},
        port => $self->{option_results}->{sahi_port},
        hostname => $self->{option_results}->{sahi_hostname},
        url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_killAll',
        timeout => $self->{option_results}->{sahi_http_timeout},
        unknown_status => '', warning_status => '', critical_status => '',
        get_param => ['userDefinedId=' . $self->{user_defined_id}]
    );
}

sub cleanup_scenario {
    my ($self, %options) = @_;
    
    return if (!defined($self->{user_defined_id}));
    $self->{http}->request(
        proto => $self->{option_results}->{sahi_proto},
        port => $self->{option_results}->{sahi_port},
        hostname => $self->{option_results}->{sahi_hostname},
        url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_cleanup',
        timeout => $self->{option_results}->{sahi_http_timeout},
        unknown_status => '', warning_status => '', critical_status => '',
        get_param => ['userDefinedId=' . $self->{user_defined_id}]
    );
}

sub run_scenario {
    my ($self, %options) = @_;
    
    my $user_defined_id = $self->generate_user_defined_id();
    my ($content) = $self->{http}->request(
        proto => $self->{option_results}->{sahi_proto},
        port => $self->{option_results}->{sahi_port},
        hostname => $self->{option_results}->{sahi_hostname},
        url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_run',
        timeout => $self->{option_results}->{sahi_http_timeout},
        unknown_status => $self->{option_results}->{unknown_run_status},
        warning_status => $self->{option_results}->{warning_run_status},
        critical_status => $self->{option_results}->{critical_run_status},
        get_param => [
            'threads=' . $self->{option_results}->{sahi_threads},
            'startWith=' . $self->{option_results}->{sahi_startwith},
            'browserType=' . $self->{option_results}->{sahi_browsertype},
            'suite=' . $self->{option_results}->{sahi_suite},
            'baseURL=' . (defined($self->{option_results}->{sahi_baseurl}) ? $self->{option_results}->{sahi_baseurl} : ''),
            'userDefinedId=' . $user_defined_id,
        ]
    );
    
    if ($self->{http}->get_code() != 200) {
        $self->{output}->add_option_msg(short_msg => 'run scenario issue:' . $content);
        $self->{output}->option_exit();
    }
    
    $self->{user_defined_id} = $user_defined_id;
}

sub check_scenario_status {
    my ($self, %options) = @_;
    
    my $content;
    my $retries = 0;
    while (1) {
        ($content) = $self->{http}->request(
            proto => $self->{option_results}->{sahi_proto},
            port => $self->{option_results}->{sahi_port},
            hostname => $self->{option_results}->{sahi_hostname},
            url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_status',
            timeout => $self->{option_results}->{sahi_http_timeout},
            unknown_status => '', warning_status => '', critical_status => '',
            get_param => ['userDefinedId=' . $self->{user_defined_id}]
        );
        if ($self->{http}->get_code() != 200) {
            if ($retries == $self->{option_results}->{retries_scenario_status}) {
                $self->{output}->add_option_msg(short_msg => 'check scenario status issue:' . $content);
                $self->{output}->option_exit();
            }
            $retries++;
        } else {
            $retries = 0;
        }
    
        # other state: INITIAL, RUNNING
        last if ($content =~ /SUCCESS|FAILURE|ABORTED|SKIPPED|USER_ABORTED/);
        
        sleep($self->{option_results}->{interval_scenario_status});
    }
    
    my $status = 'UNKNOWN';
    $status = $1 if ($content =~ /(SUCCESS|FAILURE|ABORTED|SKIPPED|USER_ABORTED)/);
    
    $self->{global}->{status} = $status;
}

sub get_suite_report {
    my ($self, %options) = @_;
    
    my ($content) = $self->{http}->request(
        proto => $self->{option_results}->{sahi_proto},
        port => $self->{option_results}->{sahi_port},
        hostname => $self->{option_results}->{sahi_hostname},
        url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_suiteReport',
        timeout => $self->{option_results}->{sahi_http_timeout},
        unknown_status => '', warning_status => '', critical_status => '',
        get_param => [
            'userDefinedId=' . $self->{user_defined_id}, 
            'type=xml'
        ]
    );
    
    if ($self->{http}->get_code() != 200) {
        $self->cleanup_option_exit(short_msg => 'get suite report issue:' . $content);
    }
    
    my $response = $self->decode_xml_response(response => $content, ForceArray => ['summary']);
    if (!defined($response->{suite}->{scriptSummaries}->{summary})) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->cleanup_option_exit(short_msg => 'get suite report issue: unknown response format');
    }
    
    # in milliseconds
    $self->{global}->{time_taken} = $response->{suite}->{scriptSummaries}->{summary}->[0]->{TIMETAKEN};
    $self->{global}->{total_steps} = $response->{suite}->{scriptSummaries}->{summary}->[0]->{TOTALSTEPS};
    $self->{global}->{failures} = $response->{suite}->{scriptSummaries}->{summary}->[0]->{FAILURES};
    $self->{global}->{errors} = $response->{suite}->{scriptSummaries}->{summary}->[0]->{ERRORS};
    $self->{script_reportid} = $response->{suite}->{scriptSummaries}->{summary}->[0]->{SCRIPTREPORTID};
}

sub get_script_report {
    my ($self, %options) = @_;

    my ($content) = $self->{http}->request(
        proto => $self->{option_results}->{sahi_proto},
        port => $self->{option_results}->{sahi_port},
        hostname => $self->{option_results}->{sahi_hostname},
        url_path => $self->{option_results}->{sahi_endpoint} . 'SahiEndPoint_scriptReport',
        timeout => $self->{option_results}->{sahi_http_timeout},
        unknown_status => '', warning_status => '', critical_status => '',
        get_param => [
            'id=' . $options{id}, 
            'type=xml'
        ]
    );
    
    if ($self->{http}->get_code() != 200) {
        $self->cleanup_option_exit(short_msg => 'get suite report issue:' . $content);
    }
    
    my $response = $self->decode_xml_response(response => $content, ForceArray => ['step']);
    if (!defined($response->{steps}->{step})) {
        $self->{output}->output_add(long_msg => $response, debug => 1);
        $self->cleanup_option_exit(short_msg => 'get script report issue: unknown response format');
    }
    
    $self->{steps} = {};
    for (my $i = 0; $i < (scalar(@{$response->{steps}->{step}}) - 1); $i++) {
        my $display = $response->{steps}->{step}->[$i]->{MESSAGETYPE};
        $display .= '.' . $response->{steps}->{step}->[$i]->{STEPMESSAGE}
            if (defined($response->{steps}->{step}->[$i]->{STEPMESSAGE}) && $response->{steps}->{step}->[$i]->{STEPMESSAGE} ne '');
        $display =~ s/\|//g;
        
        my $current_time = $self->time2ms(time => $response->{steps}->{step}->[$i]->{MESSAGETIMESTAMP});
        my $next_time = $self->time2ms(time => $response->{steps}->{step}->[$i + 1]->{MESSAGETIMESTAMP});
        my $time_taken = int(($next_time * 1000) - ($current_time * 1000));

        $self->{steps}->{$i} = {
            step => $i,
            display => $display,
            time_taken => $time_taken,
        };
        $self->{global}->{'step' . $i . '_time'} = $time_taken;
    }
}

sub cleanup_option_exit {
    my ($self, %options) = @_;
    
    $self->cleanup_scenario();
    $self->{output}->add_option_msg(short_msg => $options{short_msg});
    $self->{output}->option_exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {};
    $self->run_scenario();
    $self->check_scenario_status();
    
    if ($self->{global}->{status} =~ /FAILURE|SUCCESS/) {
        $self->get_suite_report();
        $self->get_script_report(id => $self->{script_reportid});
    }
    
    $self->cleanup_scenario();
}

1;

__END__

=head1 MODE

Check scenario execution.

=over 8

=item B<--sahi-hostname>

IP Addr/FQDN of the host

=item B<--sahi-port>

Port used (Default: 9999)

=item B<--sahi-proto>

Specify https if needed (Default: 'http')

=item B<--sahi-endpoint>

Specify endpoint (Default: '/_s_/dyn/')

=item B<--sahi-suite>

Full path to scenario and scenario name (Required)

=item B<--sahi-http-timeout>

Timeout for each HTTP requests (Default: 5)

=item B<--sahi-threads>

Number of simultaneous browser instances that can be executed (Default: 1)

=item B<--sahi-startwith>

Specify the start mode (Default: BROWSER)

=item B<--sahi-browsertype>

Browser on which scripts will be executed (Default: chrome)

=item B<--sahi-baseurl>

Url where the script should start

=item B<--timeout>

Specify the global script timeout. If timeout is reached, scenario is killed.

=item B<--retries-scenario-status>

Specify the number of retries to get scenario status (if we fail to get the status).

=item B<--interval-scenario-status>

Specify time interval to get scenario status in seconds (Default: 10).

=item B<--unknown-run-status>

Threshold unknown for running scenario rest api response.
(Default: '%{http_code} < 200 or %{http_code} >= 300')

=item B<--warning-run-status>

Threshold warning for running scenario rest api response.

=item B<--critical-run-status>

Threshold critical for running scenario rest api response.

=item B<--warning-status>

Set warning threshold for scenario status.
Can used special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for scenario status (Default: '%{status} ne "SUCCESS"').
Can used special variables like: %{status}.

=item B<--warning-*> B<--critical-*>

Set thresholds.
Can be: 'total-time', 'total-steps', 'failures', 'errors', 'step-time'.

=back

=cut
