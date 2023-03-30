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

package network::aruba::clearpass::snmp::mode::radius;

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

    my $oid_radPolicyEvalTime       = '.1.3.6.1.4.1.14823.1.6.1.1.2.1.1.1.0';
    my $oid_radAuthRequestTime      = '.1.3.6.1.4.1.14823.1.6.1.1.2.1.1.2.0';
    my $oid_radServerCounterSuccess = '.1.3.6.1.4.1.14823.1.6.1.1.2.1.1.3.0';
    my $oid_radServerCounterFailure = '.1.3.6.1.4.1.14823.1.6.1.1.2.1.1.4.0';
    my $oid_radServerCounterCount   = '.1.3.6.1.4.1.14823.1.6.1.1.2.1.1.5.0';

    my $result = $self->{snmp}->get_leef(
        oids => [$oid_radPolicyEvalTime,
            $oid_radAuthRequestTime,
            $oid_radServerCounterSuccess,
            $oid_radServerCounterFailure,
            $oid_radServerCounterCount],
        nothing_quit => 1
    );

    my $radius = {
        policy_eval_time    => $result->{$oid_radPolicyEvalTime},
        auth_req_time       => $result->{$oid_radAuthRequestTime},
        auth_success        => $result->{$oid_radServerCounterSuccess},
        auth_failure        => $result->{$oid_radServerCounterFailure},
        auth_total          => $result->{$oid_radServerCounterCount},
    };

    my $exit = $self->{perfdata}->threshold_check(value => $radius->{auth_req_time}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf(
            "RADIUS policy eval time: %sms request time: %sms total request (success/failure): %s (%s/%s)",
                        $radius->{policy_eval_time},
                        $radius->{auth_req_time},
                        $radius->{auth_total},
                        $radius->{auth_success},
                        $radius->{auth_failure}
        )
    );

    if (defined($self->{option_results}->{filter_counter}) && $self->{option_results}->{filter_counter} ne '') {
        if  ("policy_eval_time" =~ /$self->{option_results}->{filter_counter}/) {
            $self->{output}->perfdata_add(
                label => "policy_eval_time", unit => 'ms',
                value => $radius->{policy_eval_time},
                min => 0,
            );
        }

        if  ("auth_req_time" =~ /$self->{option_results}->{filter_counter}/) {
            $self->{output}->perfdata_add(
                label => "auth_req_time", unit => 'ms',
                value => $radius->{auth_req_time},
                min => 0,
            );
        }
    
        if  ("auth_success" =~ /$self->{option_results}->{filter_counter}/) {
            $self->{output}->perfdata_add(
                label => "auth_success",
                value => $radius->{auth_success},
                min => 0,
            );
        }

        if  ("auth_failure" =~ /$self->{option_results}->{filter_counter}/) {
            $self->{output}->perfdata_add(
                label => "auth_failure",
                value => $radius->{auth_failure},
                min => 0,
            );
        }

        if  ("auth_total" =~ /$self->{option_results}->{filter_counter}/) {
            $self->{output}->perfdata_add(
                label => "auth_total",
                value => $radius->{auth_total},
                min => 0,
            );
        }
    } else {
        $self->{output}->perfdata_add(
            label => "policy_eval_time", unit => 'ms',
            value => $radius->{policy_eval_time},
            min => 0,
        );
        $self->{output}->perfdata_add(
            label => "auth_req_time", unit => 'ms',
            value => $radius->{auth_req_time},
            min => 0,
        );
        $self->{output}->perfdata_add(
            label => "auth_success",
            value => $radius->{auth_success},
            min => 0,
        );
        $self->{output}->perfdata_add(
            label => "auth_failure",
            value => $radius->{auth_failure},
            min => 0,
        );
        $self->{output}->perfdata_add(
            label => "auth_total",
            value => $radius->{auth_total},
            min => 0,
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check ClearPass server RADIUS statistics.

=over 8

=item B<--warning>

Threshold warning in miliseconds.

=item B<--critical>

Threshold critical in miliseconds.

=item B<--filter-counter>

Filter perfdata output, match regular expression.
Existing counters are: policy_eval_time,auth_req_time,
auth_success,auth_failure,auth_total

=back

=cut