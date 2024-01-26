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
# Authors : Alexandre Moreau <alexandre.moreau@cheops.fr> (@SpyL1nk)

package network::aruba::cppm::snmp::mode::tacacs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_tacacs_auth_output {
    my ($self, %options) = @_;

    return "Tacacs authentication '" . $options{instance}. "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'tacacs_auth', type => 1, cb_prefix_output => 'prefix_tacacs_auth_output', message_multiple => 'All tacas+ authentication are ok' }
    ];

    $self->{maps_counters}->{tacacs_auth} = [
        { label => 'tacacs-auth-policy-eval', nlabel => 'tacacs.authentication.policy.evaluation.milliseconds', set => {
                key_values => [ { name => 'policyEvalTime' } ],
                output_template => 'policy evaluation time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-policy-eval', nlabel => 'tacacs.authentication.service.policy.evaluation.milliseconds', set => {
                key_values => [ { name => 'servicePolicyEvalTime' } ],
                output_template => 'service policy evaluation time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-requests-auth-time', nlabel => 'tacacs.authentication.requests.authentication.time.milliseconds', set => {
                key_values => [ { name => 'authTimeReq' } ],
                output_template => 'requests authentication time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-requests-time', nlabel => 'tacacs.authentication.requests.time.milliseconds', set => {
                key_values => [ { name => 'timeReq' } ],
                output_template => 'requests time: %s ms',
                perfdatas => [
                    { template => '%s', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-requests', nlabel => 'tacacs.authentication.requests.count', set => {
                key_values => [ { name => 'totalReq' } ],
                output_template => 'total requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-requests-failed', nlabel => 'tacacs.authentication.requests.failed.count', set => {
                key_values => [ { name => 'failedReq' } ],
                output_template => 'failed requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'tacacs-auth-requests-succeeded', nlabel => 'tacacs.authentication.requests.succeeded.count', set => {
                key_values => [ { name => 'successReq' } ],
                output_template => 'succeeded requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        hostname              => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.1.1.1.4' }, # cppmSystemHostname
        successReq            => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.1' }, # tacAuthCounterSuccess
        failedReq             => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.2' }, # tacAuthCounterFailure
        totalReq              => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.3' }, # tacAuthCounterCount
        timeReq               => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.4' }, # tacAuthCounterTime
        authTimeReq           => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.5' }, # tacAuthCounterAuthTime
        servicePolicyEvalTime => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.6' }, # tacServicePolicyEvalTime
        policyEvalTime        => { oid => '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1.7' }  # tacPolicyEvalTime
    };
    my $oid_tacacsAuthEntry = '.1.3.6.1.4.1.14823.1.6.1.1.2.7.1';

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_tacacsAuthEntry },
            { oid => $mapping->{hostname}->{oid} }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{tacacs_auth} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{hostname}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);

        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{hostname} !~ /$self->{option_results}->{filter_name}/);

        $self->{tacacs_auth}->{ $result->{hostname} } = $result;
    }
}

1;

__END__

=head1 MODE

Check TACACS+ statistics.

=over 8

=item B<--filter-name>

Filter tacacs by system hostname (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'tacacs-auth-policy-eval', 'tacacs-auth-policy-eval', 'tacacs-auth-requests-auth-time','
'tacacs-auth-requests-time', 'tacacs-auth-requests', 'tacacs-auth-requests-failed',
'tacacs-auth-requests-succeeded'.

=back

=cut
