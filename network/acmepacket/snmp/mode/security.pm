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

package network::acmepacket::snmp::mode::security;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub ipsec_long_output {
    my ($self, %options) = @_;

    return 'checking ipsec';
}

sub ims_long_output {
    my ($self, %options) = @_;

    return 'checking ims-aka';
}

sub prefix_ims_output {
    my ($self, %options) = @_;

    return 'ims-aka ';
}

sub prefix_ims_sa_add_output {
    my ($self, %options) = @_;

    return 'security association add ';
}

sub set_counters {
    my ($self, %options) = @_;
    
     $self->{maps_counters_type} = [
        { name => 'ipsec', type => 3, cb_long_output => 'ipsec_long_output', indent_long_output => '    ',
            group => [
                { name => 'ipsec_global', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        },
        { name => 'ims', type => 3, cb_prefix_output => 'prefix_ims_output', cb_long_output => 'ims_long_output', indent_long_output => '    ',
            group => [
                { name => 'aka_sa_reg', type => 0, display_short => 0, skipped_code => { -10 => 1 } },
                { name => 'aka_sa_add', type => 0, display_short => 0, cb_prefix_output => 'prefix_ims_sa_add_output', skipped_code => { -10 => 1 } },
                { name => 'aka_sa_del', type => 0, display_short => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];
    
    $self->{maps_counters}->{ipsec_global} = [
        { label => 'ipsec-tunnels', nlabel => 'security.ipsec.tunnels.count', set => {
                key_values => [ { name => 'ipsec_tun_count' } ],
                output_template => 'number of tunnels: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{aka_sa_add} = [
        { label => 'imsaka-sa-add-requests', nlabel => 'security.ims_aka.security_association_add.requests.count', set => {
                key_values => [ { name => 'imsaka_sa_add_req_rcvd', diff => 1 } ],
                output_template => 'requests: %s',
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

sub manage_selection {
    my ($self, %options) = @_;

    my $mapping = {
        ipsec_tun_count            => { oid => '.1.3.6.1.4.1.9148.3.9.1.1' }, # apSecurityIPsecTunCount
        ipsec_tun_used             => { oid => '.1.3.6.1.4.1.9148.3.9.1.2' }, # apSecurityIPsecTunCapPct
        imsaka_sa_add_req_rcvd     => { oid => '.1.3.6.1.4.1.9148.3.9.5.2.2' }, # apSecSAIMSAKAAddReqRcvd
        imsaka_sa_add_success_resp => { oid => '.1.3.6.1.4.1.9148.3.9.5.2.3' }, # apSecSAIMSAKAAddSuccessRespSent
        imsaka_sa_add_fail_resp    => { oid => '.1.3.6.1.4.1.9148.3.9.5.2.5' }, # apSecSAIMSAKAAddFailRespSent
        imsaka_sa_add_created      => { oid => '.1.3.6.1.4.1.9148.3.9.5.2.29' }, # apSecSAIMSAKASaCreated
    };

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{output}->output_add(short_msg => 'Security is ok');

    $self->{ipsec} = {
        global => {
            ipsec_global => {
                ipsec_tun_count => $result->{ipsec_tun_count},
                ipsec_tun_used => $result->{ipsec_tun_used},
            }
        }
    };

    $self->{ims} = {
        global => {
            aka_sa_add => {
                imsaka_sa_add_created => $result->{imsaka_sa_add_created},
                imsaka_sa_add_req_rcvd => $result->{imsaka_sa_add_req_rcvd},
                imsaka_sa_add_success_resp => $result->{imsaka_sa_add_success_resp},
                imsaka_sa_add_fail_resp => $result->{imsaka_sa_add_fail_resp}
            },
        }
    };

    $self->{cache_name} = 'acmepacket_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check security statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^memory-usage$'

=item B<--warning-replication-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{replication_state}

=item B<--critical-replication-status>

Set critical threshold for status (Default: '%{replication_state} =~ /outOfService/i').
Can used special variables like: %{replication_state}

=item B<--warning-*>

Threshold warning.
Can be: 'license-usage' (%), 'memory-usage' (%), 'cpu-load' (%),
'health-score' (%), 'current-sessions', 'current-calls'.

=item B<--critical-*>

Threshold critical.
Can be: 'license-usage' (%), 'memory-usage' (%), 'cpu-load' (%),
'health-score' (%), 'current-sessions', 'current-calls'.

=back

=cut
