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

package network::acmepacket::snmp::mode::policyservers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_ps_output {
    my ($self, %options) = @_;

    return sprintf(
        "Policy server '%s' ",
        $options{instance_value}->{name}
    );
}

sub ps_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking policy server '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_ct_output {
    my ($self, %options) = @_;

    return 'client transactions ';
}

sub prefix_st_output {
    my ($self, %options) = @_;

    return 'server transactions ';
}

sub prefix_msg_aa_output {
    my ($self, %options) = @_;

    return 'authorization authentication messages ';
}

sub prefix_msg_st_output {
    my ($self, %options) = @_;

    return 'session termination messages ';
}

sub prefix_msg_as_output {
    my ($self, %options) = @_;

    return 'abort session messages ';
}

sub prefix_msg_ra_output {
    my ($self, %options) = @_;

    return 're-auth messages ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ps', type => 3, cb_prefix_output => 'prefix_ps_output', cb_long_output => 'ps_long_output', indent_long_output => '    ', message_multiple => 'All policy servers are ok',
            group => [
                { name => 'ct', type => 0, cb_prefix_output => 'prefix_ct_output', skipped_code => { -10 => 1 } },
                { name => 'st', type => 0, cb_prefix_output => 'prefix_st_output', skipped_code => { -10 => 1 } },
                { name => 'msg_aa', type => 0, cb_prefix_output => 'prefix_msg_aa_output', skipped_code => { -10 => 1 } },
                { name => 'msg_st', type => 0, cb_prefix_output => 'prefix_msg_st_output', skipped_code => { -10 => 1 } },
                { name => 'msg_as', type => 0, cb_prefix_output => 'prefix_msg_as_output', skipped_code => { -10 => 1 } },
                { name => 'msg_ra', type => 0, cb_prefix_output => 'prefix_msg_ra_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'policy_servers.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'number of policy servers: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{ct} = [
        { label => 'client-transactions-total', nlabel => 'policy_server.client_transactions.total.count', set => {
                key_values => [ { name => 'ct_total', diff => 1 } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'client-transactions', nlabel => 'policy_server.client_transactions.errors.count', set => {
                key_values => [ { name => 'ct_errors_recvd', diff => 1 } ],
                output_template => 'errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{st} = [
        { label => 'server-transactions-total', nlabel => 'policy_server.server_transactions.total.count', set => {
                key_values => [ { name => 'st_total', diff => 1 } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'server-transactions-requests', nlabel => 'policy_server.server_transactions.requests.count', set => {
                key_values => [ { name => 'st_req_recvd', diff => 1 } ],
                output_template => 'requests: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'server-transactions-requests-dropped', nlabel => 'policy_server.server_transactions.requests.dropped.count', set => {
                key_values => [ { name => 'st_req_dropped', diff => 1 } ],
                output_template => 'requests dropped: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'server-transactions-responses-succeded', nlabel => 'policy_server.server_transactions.responses.succeeded.count', set => {
                key_values => [ { name => 'st_success_resp_sent', diff => 1 } ],
                output_template => 'responses succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'server-transactions-responses-errors', nlabel => 'policy_server.server_transactions.responses.errors.count', set => {
                key_values => [ { name => 'st_errors_resp_sent', diff => 1 } ],
                output_template => 'responses errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{msg_aa} = [
        { label => 'messages-aar', nlabel => 'policy_server.messages.authorization_authentication_request.count', set => {
                key_values => [ { name => 'aar_sent', diff => 1 } ],
                output_template => 'request: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-aaa-succeeded', nlabel => 'policy_server.messages.authorization_authentication_answer.succeeded.count', set => {
                key_values => [ { name => 'aaa_success', diff => 1 } ],
                output_template => 'answer succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-aaa-errors', nlabel => 'policy_server.messages.authorization_authentication_answer.errors.count', set => {
                key_values => [ { name => 'aaa_errors', diff => 1 } ],
                output_template => 'answer errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{msg_st} = [
        { label => 'messages-str', nlabel => 'policy_server.messages.session_termination_request.count', set => {
                key_values => [ { name => 'str_sent', diff => 1 } ],
                output_template => 'request: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-sta-succeeded', nlabel => 'policy_server.messages.session_termination_answer.succeeded.count', set => {
                key_values => [ { name => 'sta_success', diff => 1 } ],
                output_template => 'answer succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-sta-errors', nlabel => 'policy_server.messages.session_termination_answer.errors.count', set => {
                key_values => [ { name => 'sta_errors', diff => 1 } ],
                output_template => 'answer errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{msg_as} = [
        { label => 'messages-asr', nlabel => 'policy_server.messages.abort_session_request.count', set => {
                key_values => [ { name => 'asr_sent', diff => 1 } ],
                output_template => 'request: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-asa-succeeded', nlabel => 'policy_server.messages.abort_session_answer.succeeded.count', set => {
                key_values => [ { name => 'asa_success', diff => 1 } ],
                output_template => 'answer succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-asa-errors', nlabel => 'policy_server.messages.abort_session_answer.errors.count', set => {
                key_values => [ { name => 'asa_errors', diff => 1 } ],
                output_template => 'answer errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{msg_ra} = [
        { label => 'messages-rar', nlabel => 'policy_server.messages.re_auth_request.count', set => {
                key_values => [ { name => 'rar_recvd', diff => 1 } ],
                output_template => 'request: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-raa-succeeded', nlabel => 'policy_server.messages.re_auth_answer.succeeded.count', set => {
                key_values => [ { name => 'raa_success', diff => 1 } ],
                output_template => 'answer succeeded: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'messages-raa-errors', nlabel => 'policy_server.messages.re_auth_answer.errors.count', set => {
                key_values => [ { name => 'raa_errors', diff => 1 } ],
                output_template => 'answer errors: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $mapping = {
    ct_total             => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.5' },  # apDiamRxExtPolSvrClientTrans
    ct_errors_recvd      => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.13' }, # apDiamRxExtPolSvrCTErrorsRecvd
    st_total             => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.16' }, # apDiamRxExtPolSvrServerTransactions
    st_req_recvd         => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.17' }, # apDiamRxExtPolSvrSTReqRecvd
    st_success_resp_sent => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.19' }, # apDiamRxExtPolSvrSTSuccessRespSent
    st_errors_resp_sent  => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.20' }, # apDiamRxExtPolSvrSTErrorRespSent
    st_req_dropped       => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.21' }, # apDiamRxExtPolSvrSTReqDropped
    aar_sent             => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.25' }, # apDiamRxExtPolSvrAARSent
    aaa_success          => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.26' }, # apDiamRxExtPolSvrAAASuccess
    aaa_errors           => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.27' }, # apDiamRxExtPolSvrAAAErrors
    str_sent             => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.28' }, # apDiamRxExtPolSvrSTRSent
    sta_success          => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.29' }, # apDiamRxExtPolSvrSTASuccess
    sta_errors           => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.30' }, # apDiamRxExtPolSvrSTAErrors
    rar_recvd            => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.31' }, # apDiamRxExtPolSvrRARRecvd
    raa_success          => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.32' }, # apDiamRxExtPolSvrRAARecvdSuccess
    raa_errors           => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.33' }, # apDiamRxExtPolSvrRAARecvdErrors
    asr_sent             => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.40' }, # apDiamRxExtPolSvrASRRecvd
    asa_success          => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.41' }, # apDiamRxExtPolSvrASARecvdSuccess
    asa_errors           => { oid => '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.42' }  # apDiamRxExtPolSvrASARecvdErrors
};
my $oid_name = '.1.3.6.1.4.1.9148.3.13.1.1.2.3.1.2'; # apDiamRxExtPolSvrName

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'acmepacket_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_name,
        nothing_quit => 1
    );

    $self->{ps} = {};
    foreach (keys %$snmp_result) {
        /^$oid_name\.(.*)$/;
        my $instance = $1;

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $snmp_result->{$_} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $snmp_result->{$_} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{ps}->{ $snmp_result->{$_} } = {
            name => $snmp_result->{$_},
            instance => $instance
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{ps}}) };

    return if (scalar(keys %{$self->{ps}}) <= 0);

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [map($_->{instance}, values(%{$self->{ps}}))],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{ps}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $self->{ps}->{$_}->{instance});

        $self->{ps}->{$_}->{ct} = {
            ct_total => $result->{ct_total},
            ct_errors_recvd => $result->{ct_errors_recvd}
        };
        $self->{ps}->{$_}->{st} = {
            st_total => $result->{st_total},
            st_req_recvd => $result->{st_req_recvd},
            st_req_dropped => $result->{st_req_dropped},
            st_success_resp_sent => $result->{st_success_resp_sent},
            st_errors_resp_sent => $result->{st_errors_resp_sent}
        };
        $self->{ps}->{$_}->{msg_aa} = {
            aar_sent => $result->{aar_sent},
            aaa_success => $result->{aaa_success},
            aaa_errors => $result->{aaa_errors}
        };
        $self->{ps}->{$_}->{msg_st} = {
            str_sent => $result->{str_sent},
            sta_success => $result->{sta_success},
            sta_errors => $result->{sta_errors}
        };
        $self->{ps}->{$_}->{msg_ra} = {
            rar_recvd => $result->{rar_recvd},
            raa_success => $result->{raa_success},
            raa_errors => $result->{raa_errors}
        };
        $self->{ps}->{$_}->{msg_as} = {
            asr_sent => $result->{asr_sent},
            asa_success => $result->{asa_success},
            asa_errors => $result->{asa_errors}
        };
    }
}

1;

__END__

=head1 MODE

Check external policy servers statitics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total'

=item B<--filter-name>

Filter policy servers by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be:
'total',
'client-transactions-total', 'client-transactions',
'server-transactions-total', 'server-transactions-requests', 'server-transactions-requests-dropped', 'server-transactions-responses-succeded', 'server-transactions-responses-errors',
'messages-aar', 'messages-aaa-succeeded', 'messages-aaa-errors',
'messages-rar', 'messages-raa-succeeded', 'messages-raa-errors',
'messages-str', 'messages-sta-succeeded', 'messages-sta-errors',
'messages-asr', 'messages-asa-succeeded', 'messages-asa-errors'.

=back

=cut
