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

package network::f5::bigip::snmp::mode::connections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_client_tps_calc {
    my ($self, %options) = @_;

    my $diff_native = $options{new_datas}->{$self->{instance} . '_client_ssl_tot_native'} - $options{old_datas}->{$self->{instance} . '_client_ssl_tot_native'};
    my $diff_compat = $options{new_datas}->{$self->{instance} . '_client_ssl_tot_compat'} - $options{old_datas}->{$self->{instance} . '_client_ssl_tot_compat'};
    $self->{result_values}->{client_ssl_tps} = ($diff_native + $diff_compat) / $options{delta_time};
    
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'client', set => {
                key_values => [ { name => 'client' } ],
                output_template => 'Current client connections : %s',
                perfdatas => [
                    { label => 'Client', template => '%s',  min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'client-ssl', set => {
                key_values => [ { name => 'client_ssl' } ],
                output_template => 'Current client SSL connections : %s',
                perfdatas => [
                    { label => 'ClientSSL', template => '%s',  min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'client-ssl-tps', set => {
                key_values => [ { name => 'client_ssl_tot_native', diff => 1 }, { name => 'client_ssl_tot_compat', diff => 1 } ],
                output_template => 'TPS client SSL connections : %.2f', threshold_use => 'client_ssl_tps', output_use => 'client_ssl_tps',
                closure_custom_calc => $self->can('custom_client_tps_calc'),
                perfdatas => [
                    { label => 'ClientSSL_Tps', value => 'client_ssl_tps', template => '%.2f',
                      unit => 'tps', min => 0 },
                ],
            }
        },
        { label => 'server', set => {
                key_values => [ { name => 'server' } ],
                output_template => 'Current server connections: %s',
                perfdatas => [
                    { label => 'Server', template => '%s', min => 0, unit => 'con' },
                ],
            }
        },
        { label => 'server-ssl', set => {
                key_values => [ { name => 'server_ssl' } ],
                output_template => 'Current server SSL connections : %s',
                perfdatas => [
                    { label => 'ServerSSL', template => '%s',  min => 0, unit => 'con' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
                                
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = "f5_bipgip_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
    
    my $oid_sysStatClientCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.8.0';
    my $oid_sysStatServerCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.1.15.0';
    my $oid_sysClientsslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.2.0';
    my $oid_sysServersslStatCurConns = '.1.3.6.1.4.1.3375.2.1.1.2.10.2.0';
    my $oid_sysClientsslStatTotNativeConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.6.0';
    my $oid_sysClientsslStatTotCompatConns = '.1.3.6.1.4.1.3375.2.1.1.2.9.9.0';
    
    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_sysStatClientCurConns, $oid_sysStatServerCurConns, 
            $oid_sysClientsslStatCurConns, $oid_sysServersslStatCurConns,
            $oid_sysClientsslStatTotNativeConns, $oid_sysClientsslStatTotCompatConns
        ],
        nothing_quit => 1
    );
    $self->{global} = { 
        client => $result->{$oid_sysStatClientCurConns},
        client_ssl => $result->{$oid_sysClientsslStatCurConns},
        client_ssl_tot_native => $result->{$oid_sysClientsslStatTotNativeConns},
        client_ssl_tot_compat => $result->{$oid_sysClientsslStatTotCompatConns},
        server => $result->{$oid_sysStatServerCurConns},
        server_ssl => $result->{$oid_sysServersslStatCurConns},
    };
}
    
1;

__END__

=head1 MODE

Check current connections on F5 BIG IP device.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to check SSL connections only : --filter-counters='^client-ssl|server-ssl$'

=item B<--warning-*>

Threshold warning.
Can be: 'client', 'server', 'client-ssl', 'server-ssl', 'client-ssl-tps'.

=item B<--critical-*>

Threshold critical.
Can be: 'client', 'server', 'client-ssl', 'server-ssl', 'client-ssl-tps'.

=back

=cut
