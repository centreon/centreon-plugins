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

package network::athonet::epc::snmp::mode::lte;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'sctp status: %s [s1ap status: %s]',
        $self->{result_values}->{sctp_status},
        $self->{result_values}->{s1ap_status}
    );
}

sub custom_attach_req_output {
    my ($self, %options) = @_;

    return sprintf(
        'attach requests total: %s success: %s (%.2f%%)',
        $self->{result_values}->{attach_req_total},
        $self->{result_values}->{attach_req_success},
        $self->{result_values}->{prct_success}
    );
}

sub custom_attach_req_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{attach_req_total} = $options{new_datas}->{$self->{instance} . '_attach_req_total'} - $options{old_datas}->{$self->{instance} . '_attach_req_total'};
    $self->{result_values}->{attach_req_success} = $options{new_datas}->{$self->{instance} . '_attach_req_success'} - $options{old_datas}->{$self->{instance} . '_attach_req_success'};
    $self->{result_values}->{prct_success} = 100;
    if ($self->{result_values}->{attach_req_total} > 0) {
        $self->{result_values}->{prct_success} = $self->{result_values}->{attach_req_success} * 100 / $self->{result_values}->{attach_req_total};
    }
    return 0;
}

sub custom_pdn_req_output {
    my ($self, %options) = @_;

    return sprintf(
        'pdn context activation requests total: %s success: %s (%.2f%%)',
        $self->{result_values}->{pdn_context_total},
        $self->{result_values}->{pdn_context_success},
        $self->{result_values}->{prct_success}
    );
}

sub custom_pdn_req_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{pdn_context_total} = $options{new_datas}->{$self->{instance} . '_pdn_context_total'} - $options{old_datas}->{$self->{instance} . '_pdn_context_total'};
    $self->{result_values}->{pdn_context_success} = $options{new_datas}->{$self->{instance} . '_pdn_context_success'} - $options{old_datas}->{$self->{instance} . '_pdn_context_success'};
    $self->{result_values}->{prct_success} = 100;
    if ($self->{result_values}->{pdn_context_total} > 0) {
        $self->{result_values}->{prct_success} = $self->{result_values}->{pdn_context_success} * 100 / $self->{result_values}->{pdn_context_total};
    }
    return 0;
}

sub prefix_lte_output {
    my ($self, %options) = @_;

    return 'Lte ';
}

sub lte_long_output {
    my ($self, %options) = @_;

    return 'checking lte';
}

sub prefix_pdn_rej_output {
    my ($self, %options) = @_;

    return 'pdn context requests reject ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'lte', type => 3, cb_prefix_output => 'prefix_lte_output', cb_long_output => 'lte_long_output', indent_long_output => '    ',
            group => [
                { name => 'global_traffic', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_users', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_attach_req', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_pdn_req', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_ue', type => 0, skipped_code => { -10 => 1 } },
                { name => 'global_pdn_rej', type => 0, cb_prefix_output => 'prefix_pdn_rej_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global_traffic} = [
        { label => 'packets-in', nlabel => 'lte.packets.in.count', set => {
                key_values => [ { name => 'packets_in', diff => 1 } ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'packets-out', nlabel => 'lte.packets.out.count', set => {
                key_values => [ { name => 'packets_out', diff => 1 } ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_users} = [
        { label => 'users-connected', nlabel => 'lte.users.connected.count', set => {
                key_values => [ { name => 'users_connected' } ],
                output_template => 'connected users: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'users-idle', nlabel => 'lte.users.idle.count', set => {
                key_values => [ { name => 'users_idle' } ],
                output_template => 'idle users: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'sessions-active', nlabel => 'lte.sessions.active.count', set => {
                key_values => [ { name => 'sessions_active' } ],
                output_template => 'active sessions: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_attach_req} = [
        { label => 'requests-attach-success', nlabel => 'lte.requests.attach.success.count', set => {
                key_values => [ { name => 'attach_req_success', diff => 1 }, { name => 'attach_req_total', diff => 1 } ],
                closure_custom_calc => $self->can('custom_attach_req_calc'),
                closure_custom_output => $self->can('custom_attach_req_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'attach_req_total' }
                ]
            }
        },
        { label => 'requests-attach-success-prct', nlabel => 'lte.requests.attach.success.percentage', display_ok => 0, set => {
                key_values => [ { name => 'attach_req_success', diff => 1 }, { name => 'attach_req_total', diff => 1 } ],
                closure_custom_calc => $self->can('custom_attach_req_calc'),
                closure_custom_output => $self->can('custom_attach_req_output'),
                threshold_use => 'prct_success',
                perfdatas => [
                    { value => 'prct_success', template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_pdn_req} = [
        { label => 'requests-pdn-context-activation', nlabel => 'lte.requests.pdn_context.activations.success.count', set => {
                key_values => [ { name => 'pdn_context_success', diff => 1 }, { name => 'pdn_context_total', diff => 1 } ],
                closure_custom_calc => $self->can('custom_pdn_req_calc'),
                closure_custom_output => $self->can('custom_pdn_req_output'),
                perfdatas => [
                    { template => '%s', min => 0, max => 'pdn_context_total' }
                ]
            }
        },
        { label => 'requests-pdn-context-activation-prct', nlabel => 'lte.requests.pdn_context.activations.success.percentage', display_ok => 0, set => {
                key_values => [ { name => 'pdn_context_success', diff => 1 }, { name => 'pdn_context_total', diff => 1 } ],
                closure_custom_calc => $self->can('custom_pdn_req_calc'),
                closure_custom_output => $self->can('custom_pdn_req_output'),
                threshold_use => 'prct_success',
                perfdatas => [
                    { value => 'prct_success', template => '%s', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_ue} = [
        { label => 'requests-ue-context-release-total', nlabel => 'lte.requests.ue_context_release.total.count', set => {
                key_values => [ { name => 'ue_release_req', diff => 1 } ],
                output_template => 'ue context release requests: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-ue-context-release-radio-lost', nlabel => 'lte.requests.ue_context_release.radio_lost.count', set => {
                key_values => [ { name => 'ue_release_req_radio_lost', diff => 1 } ],
                output_template => 'ue context release with radio lost requests: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{global_pdn_rej} = [
        { label => 'requests-pdn-context-rej-insufres', nlabel => 'lte.requests.pdn_context.reject.insufficent_resources.count', set => {
                key_values => [ { name => 'pdn_rej_insuf_res', diff => 1 } ],
                output_template => 'insufficent resources: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-pdn-context-rej-noapn', nlabel => 'lte.requests.pdn_context.reject.no_apn.count', set => {
                key_values => [ { name => 'pdn_rej_no_apn', diff => 1 } ],
                output_template => 'missing or unknown apn: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'requests-pdn-context-rej-nosub', nlabel => 'lte.requests.pdn_context.reject.not_subscribed.count', set => {
                key_values => [ { name => 'pdn_rej_no_sub', diff => 1 } ],
                output_template => 'not subscribed: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
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
    });

    return $self;
}

my $mapping = {
    users_connected     => { oid => '.1.3.6.1.4.1.35805.10.2.2.1' }, # lteUsersConnected
    users_idle          => { oid => '.1.3.6.1.4.1.35805.10.2.2.2' }, # lteUsersIdle
    sessions_active     => { oid => '.1.3.6.1.4.1.35805.10.2.2.4' }, # lteActiveConnections
    packets_in          => { oid => '.1.3.6.1.4.1.35805.10.2.2.5' }, # lteLoadPktInGi
    packets_out         => { oid => '.1.3.6.1.4.1.35805.10.2.2.6' }, # lteLoadPktOutGi
    attach_req_total    => { oid => '.1.3.6.1.4.1.35805.10.2.2.7' }, # lteTotalAttachReq
    attach_req_success  => { oid => '.1.3.6.1.4.1.35805.10.2.2.8' }, # lteSuccesfullAttach
    pdn_context_total   => { oid => '.1.3.6.1.4.1.35805.10.2.2.10' }, # lteTotalPDNActReq
    pdn_context_success => { oid => '.1.3.6.1.4.1.35805.10.2.2.11' }, # lteActivatedPDNContext
    ue_release_req            => { oid => '.1.3.6.1.4.1.35805.10.2.2.19' }, # lteUERelReq
    ue_release_req_radio_lost => { oid => '.1.3.6.1.4.1.35805.10.2.2.20' }, # lteUERelReqRadioLost
    pdn_rej_insuf_res         => { oid => '.1.3.6.1.4.1.35805.10.2.2.21' }, # ltePDNRejInsufRes
    pdn_rej_no_apn            => { oid => '.1.3.6.1.4.1.35805.10.2.2.22' }, # ltePDNRejNoApn
    pdn_rej_no_sub            => { oid => '.1.3.6.1.4.1.35805.10.2.2.23' }  # ltePDNRejNoSubscribed
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'athonet_epc_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));

     my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{lte}->{global}->{global_traffic} = {
        packets_in => $result->{packets_in},
        packets_out => $result->{packets_out}
    };
    $self->{lte}->{global}->{global_users} = {
        users_connected => $result->{users_connected},
        users_idle => $result->{users_idle},
        sessions_active => $result->{sessions_active}
    };
    $self->{lte}->{global}->{global_attach_req} = {
        attach_req_total => $result->{attach_req_total},
        attach_req_success => $result->{attach_req_success}
    };
    $self->{lte}->{global}->{global_pdn_req} = {
        pdn_context_total => $result->{pdn_context_total},
        pdn_context_success => $result->{pdn_context_success}
    };
    $self->{lte}->{global}->{global_ue} = {
        ue_release_req => $result->{ue_release_req},
        ue_release_req_radio_lost => $result->{ue_release_req_radio_lost}
    };
    $self->{lte}->{global}->{global_pdn_rej} = {
        pdn_rej_insuf_res => $result->{pdn_rej_insuf_res},
        pdn_rej_no_apn => $result->{pdn_rej_no_apn},
        pdn_rej_no_sub => $result->{pdn_rej_no_sub}
    };
}

1;

__END__

=head1 MODE

Check lte.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='users'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'users-connected', 'users-idle', 'sessions-active',
'packets-in', 'packets-out', 
'requests-ue-context-release-total', 'requests-ue-context-release-radio-lost',
'requests-attach-success', 'requests-attach-success-prct',
'requests-pdn-context-activation', 'requests-pdn-context-activation-prct', 
'requests-pdn-context-rej-insufres', 'requests-pdn-context-rej-noapn', 'requests-pdn-context-rej-nosub'.

=back

=cut
