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

package centreon::common::cisco::ironport::snmp::mode::proxyusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub custom_data_calc {
    my ($self, %options) = @_;

    my $delta_value = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{hit_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{hit_ref}};
    my $delta_total = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref}} - $options{old_datas}->{$self->{instance} . '_' . $options{extra_options}->{total_ref}};

    $self->{result_values}->{hits_prct} = 100;
    if ($delta_total > 0) {
        $self->{result_values}->{hits_prct} = $delta_value * 100 / $delta_total;
    }
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'global_http', type => 0, cb_prefix_output => 'prefix_http_output', skipped_code => { -10 => 1 } },
        { name => 'global_icp', type => 0, cb_prefix_output => 'prefix_icp_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global_http} = [
         { label => 'client-http-hits-rate', nlabel => 'client.http.hits.percentage', set => {
                key_values => [ { name => 'cacheClientRequests', diff => 1 }, { name => 'cacheClientHits', diff => 1 } ],
                closure_custom_calc => $self->can('custom_data_calc'),
                closure_custom_calc_extra_options => { hit_ref => 'cacheClientHits', total_ref => 'cacheClientRequests' },
                output_template => 'client hits rate: %.2f %%', output_use => 'hits_prct', threshold_use => 'hits_prct',
                perfdatas => [
                    { value => 'hits_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
        { label => 'client-http-errors', display_ok => 0, nlabel => 'client.http.errors.count', set => {
                key_values => [ { name => 'cacheClientErrors', diff => 1 } ],
                output_template => 'client errors: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'client-http-traffic-in', display_ok => 0, nlabel => 'client.http.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'cacheClientInKb', per_second => 1 } ],
                output_template => 'client traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'client-http-traffic-out', display_ok => 0, nlabel => 'client.http.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'cacheClientOutKb', per_second => 1 } ],
                output_template => 'client traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'total-con-clients', nlabel => 'client.http.total.connections.count', set => {
                key_values => [ { name => 'cacheClientTotalConns' } ],
                output_template => 'total number of clients: %s',
                perfdatas => [
                    { template => '%s', min => 0 },
                ],
            }
        },
        { label => 'client-http-requests', display_ok => 0, nlabel => 'client.http.requests.persecond', set => {
                key_values => [ { name => 'cacheClientRequests', per_second => 1 } ],
                output_template => 'client requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{global_icp} = [
        { label => 'client-icp-hits-rate', nlabel => 'client.icp.hits.percentage', set => {
                key_values => [ { name => 'cacheClientICPRequests', diff => 1 }, { name => 'cacheClientICPHits', diff => 1 } ],
                closure_custom_calc_extra_options => { hit_ref => 'cacheClientICPHits', total_ref => 'cacheClientICPRequests' },
                closure_custom_calc => $self->can('custom_data_calc'),
                output_template => 'client hits rate: %.2f %%', output_use => 'hits_prct', threshold_use => 'hits_prct',
                perfdatas => [
                    { value => 'hits_prct', template => '%.2f', min => 0, max => 100, unit => '%' },
                ],
            }
        },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'http-mean-time', nlabel => 'http.response.mean.time.milliseconds', set => {
                key_values => [ { name => 'cacheMeanRespTime' } ],
                output_template => 'http mean response time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms' },
                ],
            }
        },
        { label => 'server-traffic-in', display_ok => 0, nlabel => 'server.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'cacheServerInKb', per_second => 1 } ],
                output_template => 'server traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
        { label => 'server-traffic-out', display_ok => 0, nlabel => 'server.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'cacheServerOutKb', per_second => 1 } ],
                output_template => 'server traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s' },
                ],
            }
        },
    ];
}

sub prefix_http_output {
    my ($self, %options) = @_;

    return 'http ';
}

sub prefix_icp_output {
    my ($self, %options) = @_;

    return 'icp ';
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

    my %oids = (
        cacheClientRequests => '.1.3.6.1.4.1.15497.1.2.3.2.2.0',
        cacheClientHits => '.1.3.6.1.4.1.15497.1.2.3.2.3.0',
        cacheClientErrors => '.1.3.6.1.4.1.15497.1.2.3.2.4.0',
        cacheClientInKb => '.1.3.6.1.4.1.15497.1.2.3.2.5.0',
        cacheClientOutKb => '.1.3.6.1.4.1.15497.1.2.3.2.6.0',
        cacheClientICPRequests => '.1.3.6.1.4.1.15497.1.2.3.2.11.0',
        cacheClientICPHits => '.1.3.6.1.4.1.15497.1.2.3.2.12.0',
        cacheServerInKb => '.1.3.6.1.4.1.15497.1.2.3.3.5.0',
        cacheServerOutKb => '.1.3.6.1.4.1.15497.1.2.3.3.6.0',
        cacheClientTotalConns => '.1.3.6.1.4.1.15497.1.2.3.2.8.0',
        cacheMeanRespTime => '.1.3.6.1.4.1.15497.1.2.3.6.2.0',
    );
    my $snmp_result = $options{snmp}->get_leef(oids => [
            values %oids
        ],
        nothing_quit => 1
    );

    $self->{global_http} = {
        cacheClientRequests => $snmp_result->{$oids{cacheClientRequests}},
        cacheClientHits => $snmp_result->{$oids{cacheClientHits}},
        cacheClientErrors => $snmp_result->{$oids{cacheClientErrors}},
        cacheClientInKb => $snmp_result->{$oids{cacheClientInKb}} * 1024 * 8,
        cacheClientOutKb => $snmp_result->{$oids{cacheClientOutKb}} * 1024 * 8,
        cacheClientTotalConns => $snmp_result->{$oids{cacheClientTotalConns}},
    };
    $self->{global_icp} = {
        cacheClientICPRequests => $snmp_result->{$oids{cacheClientICPRequests}},
        cacheClientICPHits => $snmp_result->{$oids{cacheClientICPHits}},
    };
    $self->{global} = {
        cacheMeanRespTime => $snmp_result->{$oids{cacheMeanRespTime}},
        cacheServerInKb => $snmp_result->{$oids{cacheServerInKb}} * 1024 * 8,
        cacheServerOutKb => $snmp_result->{$oids{cacheServerOutKb}} * 1024 * 8,
    };
    
    $self->{cache_name} = "cisco_ironport_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check proxy usage (websecurity appliance).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='http'

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'client-http-hits-rate', 'client-http-errors', 'client-http-traffic-in',
'client-http-traffic-out', 'client-http-requests', 'total-con-clients', 'client-icp-hits-rate', 
'server-traffic-in', 'server-traffic-out', 'http-mean-time'.

=back

=cut
