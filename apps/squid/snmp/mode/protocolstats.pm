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

package apps::squid::snmp::mode::protocolstats;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_data_calc {
    my ($self, %options) = @_;

    my $delta_value = $options{new_datas}->{$self->{instance} . '_cacheHttpHits'} - $options{old_datas}->{$self->{instance} . '_cacheHttpHits'};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_cacheProtoClientHttpRequests'} - $options{old_datas}->{$self->{instance} . '_cacheProtoClientHttpRequests'};

    $self->{result_values}->{hits_prct} = 100;
    if ($delta_total > 0) {
        $self->{result_values}->{hits_prct} = $delta_value * 100 / $delta_total;
    }
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global_http', type => 0, cb_prefix_output => 'prefix_http_output', skipped_code => { -10 => 1 } },
        { name => 'global_icp', type => 0, cb_prefix_output => 'prefix_icp_output', skipped_code => { -10 => 1 } },
        { name => 'global', type => 0, cb_prefix_output => 'prefix_server_output', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{global_http} = [
         { label => 'http-hits-rate', set => {
                key_values => [ { name => 'cacheProtoClientHttpRequests', diff => 1 }, { name => 'cacheHttpHits', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'),
                output_template => 'hits rate : %.2f %%', output_use => 'hits_prct', threshold_use => 'hits_prct',
                perfdatas => [
                    { label => 'http_hits_rate', value => 'hits_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'http-errors', set => {
                key_values => [ { name => 'cacheHttpErrors', diff => 1 } ],
                output_template => 'errors : %s',
                perfdatas => [
                    { label => 'http_errors', template => '%s',
                      min => 0 },
                ],
            }
        },
        { label => 'http-traffic-in', set => {
                key_values => [ { name => 'cacheHttpInKb', per_second => 1 } ],
                output_template => 'traffic in : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_in', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'http-traffic-out', set => {
                key_values => [ { name => 'cacheHttpOutKb', per_second => 1 } ],
                output_template => 'traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'http_traffic_out', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{global_icp} = [
        { label => 'icp-traffic-in', set => {
                key_values => [ { name => 'cacheIcpKbRecv', per_second => 1 } ],
                output_template => 'traffic in : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'icp_traffic_in', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'icp-traffic-out', set => {
                key_values => [ { name => 'cacheIcpKbSent', per_second => 1 } ],
                output_template => 'traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'icp_traffic_out', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
    ];
        
    $self->{maps_counters}->{global} = [
        { label => 'server-traffic-in', set => {
                key_values => [ { name => 'cacheServerInKb', per_second => 1 } ],
                output_template => 'traffic in : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'server_traffic_in', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'server-traffic-out', set => {
                key_values => [ { name => 'cacheServerOutKb', per_second => 1 } ],
                output_template => 'traffic Out : %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { label => 'server_traffic_out', template => '%s',
                      min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'clients', set => {
                key_values => [ { name => 'cacheClients' } ],
                output_template => 'current number of clients : %s',
                perfdatas => [
                    { label => 'clients', template => '%s', min => 0 },
                ]
            }
        }
    ];
}

sub prefix_http_output {
    my ($self, %options) = @_;

    return "HTTP ";
}

sub prefix_icp_output {
    my ($self, %options) = @_;

    return "ICP ";
}

sub prefix_server_output {
    my ($self, %options) = @_;

    return "Server ";
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

    my %oids = (
        cacheProtoClientHttpRequests => '.1.3.6.1.4.1.3495.1.3.2.1.1.0',
        cacheHttpHits => '.1.3.6.1.4.1.3495.1.3.2.1.2.0',
        cacheHttpErrors => '.1.3.6.1.4.1.3495.1.3.2.1.3.0',
        cacheHttpInKb => '.1.3.6.1.4.1.3495.1.3.2.1.4.0',
        cacheHttpOutKb => '.1.3.6.1.4.1.3495.1.3.2.1.5.0',
        cacheIcpKbSent => '.1.3.6.1.4.1.3495.1.3.2.1.8.0',
        cacheIcpKbRecv => '.1.3.6.1.4.1.3495.1.3.2.1.9.0',
        cacheServerInKb => '.1.3.6.1.4.1.3495.1.3.2.1.12.0',
        cacheServerOutKb => '.1.3.6.1.4.1.3495.1.3.2.1.13.0',
        cacheClients => '.1.3.6.1.4.1.3495.1.3.2.1.15.0',
    );
    my $snmp_result = $options{snmp}->get_leef(oids => [
            values %oids
        ], nothing_quit => 1);

    $self->{global_http} = {
        cacheProtoClientHttpRequests => $snmp_result->{$oids{cacheProtoClientHttpRequests}},
        cacheHttpHits => $snmp_result->{$oids{cacheHttpHits}},
        cacheHttpErrors => $snmp_result->{$oids{cacheHttpErrors}},
        cacheHttpInKb => $snmp_result->{$oids{cacheHttpInKb}} * 1024 * 8,
        cacheHttpOutKb => $snmp_result->{$oids{cacheHttpOutKb}} * 1024 * 8,
    };
    $self->{global_icp} = {
        cacheIcpKbSent => $snmp_result->{$oids{cacheIcpKbSent}} * 1024 * 8,
        cacheIcpKbRecv => $snmp_result->{$oids{cacheIcpKbRecv}} * 1024 * 8,
    };
    $self->{global} = {
        cacheServerInKb => $snmp_result->{$oids{cacheServerInKb}} * 1024 * 8,
        cacheServerOutKb => $snmp_result->{$oids{cacheServerOutKb}} * 1024 * 8,
        cacheClients => $snmp_result->{$oids{cacheClients}},
    };
    
    $self->{cache_name} = "squid_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check protocol statistics.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='http'

=item B<--warning-*>

Threshold warning.
Can be: 'http-hits-rate', 'http-errors', 'http-traffic-in', 'http-traffic-out',
'icp-traffic-in', 'icp-traffic-out', 'server-traffic-in', 'server-traffic-out',
'clients'.

=item B<--critical-*>

Threshold critical.
Can be: 'http-hits-rate', 'http-errors', 'http-traffic-in', 'http-traffic-out',
'icp-traffic-in', 'icp-traffic-out', 'server-traffic-in', 'server-traffic-out',
'clients'.

=back

=cut
