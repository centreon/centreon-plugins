#
# Copyright 2023 Centreon (http://www.centreon.com/)
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
# Authors : Alexandre Moreau <alexandre.moreau@cheops.fr> (@SpyL1nk)

package network::aruba::clearpass::snmp::mode::tacacs;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "warning:s"         => { name => 'warning' },
        "critical:s"        => { name => 'critical' },
        "filter-counter:s"  => { name => 'filter_counter' }
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
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_tacAuthCounterSuccess       = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.1.0';
    my $oid_tacAuthCounterFailure       = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.2.0';
    my $oid_tacAuthCounterCount         = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.3.0';
    my $oid_tacAuthCounterTime          = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.4.0';
    my $oid_tacAuthCounterAuthTime      = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.5.0';
    my $oid_tacServicePolicyEvalTime    = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.6.0';
    my $oid_tacPolicyEvalTime           = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.7.0';

    my $result = $self->{snmp}->get_leef(
        oids => [$oid_tacAuthCounterSuccess,
            $oid_tacAuthCounterFailure,
            $oid_tacAuthCounterCount,
            $oid_tacAuthCounterTime,
            $oid_tacAuthCounterAuthTime,
            $oid_tacServicePolicyEvalTime,
            $oid_tacPolicyEvalTime],
        nothing_quit => 1
    );

    my $tacacs = {
        auth_success        => $result->{$oid_tacAuthCounterSuccess},
        auth_failure        => $result->{$oid_tacAuthCounterFailure},
        auth_total          => $result->{$oid_tacAuthCounterCount},
        auth_e2e_time       => $result->{$oid_tacAuthCounterTime},
        auth_req_time       => $result->{$oid_tacAuthCounterAuthTime},
        service_eval_time   => $result->{$oid_tacServicePolicyEvalTime},
        policy_eval_time    => $result->{$oid_tacPolicyEvalTime},
    };

    my $exit = $self->{perfdata}->threshold_check(value => $tacacs->{auth_req_time}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "TACACS+ policy eval time: %sms service eval time: %sms request time: %sms request end-to-end: %sms total request (success/failure): %s (%s/%s)",
                        $tacacs->{policy_eval_time},
                        $tacacs->{service_eval_time},
                        $tacacs->{auth_req_time},
                        $tacacs->{auth_e2e_time},
                        $tacacs->{auth_total},
                        $tacacs->{auth_success},
                        $tacacs->{auth_failure}
        )
    );

    if (defined($self->{option_results}->{filter_counter}) && $self->{option_results}->{filter_counter} ne '') {
        if  ("auth_success" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "auth_success",
                value => $tacacs->{auth_success},
                min => 0,
            );
        }

        if ("auth_failure" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "auth_failure",
                value => $tacacs->{auth_failure},
                min => 0,
            );
        }

        if ("auth_total" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "auth_total",
                value => $tacacs->{auth_total},
                min => 0,
            );
        }

        if ("auth_e2e_time" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "auth_e2e_time", unit => 'ms',
                value => $tacacs->{auth_e2e_time},
                min => 0,
            );
        }

        if ("auth_req_time" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "auth_req_time", unit => 'ms',
                value => $tacacs->{auth_req_time},
                min => 0,
            );
        }

        if ("service_eval_time" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "service_eval_time", unit => 'ms',
                value => $tacacs->{service_eval_time},
                min => 0,
            );
        }

        if ("policy_eval_time" =~ /$self->{option_results}->{filter_counter}/) {

            $self->{output}->perfdata_add(
                label => "policy_eval_time", unit => 'ms',
                value => $tacacs->{policy_eval_time},
                min => 0,
            );
        }
    } else {
        $self->{output}->perfdata_add(
            label => "auth_success",
            value => $tacacs->{auth_success},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "auth_failure",
            value => $tacacs->{auth_failure},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "auth_total",
            value => $tacacs->{auth_total},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "auth_e2e_time", unit => 'ms',
            value => $tacacs->{auth_e2e_time},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "auth_req_time", unit => 'ms',
            value => $tacacs->{auth_req_time},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "service_eval_time", unit => 'ms',
            value => $tacacs->{service_eval_time},
            min => 0,
        );

        $self->{output}->perfdata_add(
            label => "policy_eval_time", unit => 'ms',
            value => $tacacs->{policy_eval_time},
            min => 0,
        );
    }


    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check ClearPass server TACACS+ statistics.

=over 8

=item B<--warning>

Threshold warning in miliseconds.

=item B<--critical>

Threshold critical in miliseconds.

=item B<--filter-counter>

Filter perfdata output, match regular expression.
Existing counters are: auth_success,auth_failure,auth_total,
auth_e2e_time,auth_req_time,service_eval_time,policy_eval_time


=back

=cut