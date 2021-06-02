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

package network::infoblox::snmp::mode::dnsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_dns_output {
    my ($self, %options) = @_;
    
    return "zone '" . $options{instance_value}->{name} . "' ";
}

sub prefix_aa_output {
    my ($self, %options) = @_;

    return 'autoritative average latency ';
}

sub prefix_naa_output {
    my ($self, %options) = @_;

    return 'non autoritative average latency ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'aa', type => 0, cb_prefix_output => 'prefix_aa_output' },
        { name => 'naa', type => 0, cb_prefix_output => 'prefix_naa_output' },
        { name => 'dns', type => 1, cb_prefix_output => 'prefix_dns_output', message_multiple => 'All dns zones are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-query-rate', nlabel => 'dns.queries.persecond', set => {
                key_values => [ { name => 'dns_query' } ],
                output_template => 'query rate: %s/s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-hit-ratio', nlabel => 'dns.hits.percentage', set => {
                key_values => [ { name => 'dns_hit' } ],
                output_template => 'hit ratio: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];

    my $nlabels = { aa => 'authoritative', naa => 'non_authoritative' };
    foreach (('aa', 'naa')) {
        $self->{maps_counters}->{$_} = [];
        foreach my $timeframe (('1m', '5m', '15m')) {
            push @{$self->{maps_counters}->{$_}}, {
                label => $_ . '-latency-' . $timeframe, nlabel => 'dns.queries.' . $nlabels->{$_} . '.latency.' . $timeframe . '.microseconds', set => {
                    key_values => [ { name => $_ . '_latency_' . $timeframe } ],
                    output_template => '%s (' . $timeframe  . ')',
                    perfdatas => [
                        { template => '%s', min => 0, unit => 'us' }
                    ]
                }
            };
        }
    }

    $self->{maps_counters}->{dns} = [
        { label => 'success-count', nlabel => 'zone.responses.succeeded.count', set => {
                key_values => [ { name => 'success', diff => 1 }, { name => 'name' } ],
                output_template => 'success responses: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'referral-count', nlabel => 'zone.referrals.count', set => {
                key_values => [ { name => 'referral', diff => 1 }, { name => 'name' } ],
                output_template => 'referrals: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'nxrrset-count', nlabel => 'zone.queries.nxrrset.count', set => {
                key_values => [ { name => 'nxrrset', diff => 1 }, { name => 'name' } ],
                output_template => 'non-existent record: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'failure-count', nlabel => 'zone.queries.failed.count', set => {
                key_values => [ { name => 'failure', diff => 1 }, { name => 'name' } ],
                output_template => 'failed queries: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
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
    name     => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.1' }, # ibBindZoneName
    success  => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.2' }, # ibBindZoneSuccess
    referral => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.3' }, # ibBindZoneReferral
    nxrrset  => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.4' }, # ibBindZoneNxRRset
    failure  => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.7' }  # ibBindZoneFailure
};
my $mapping2 = {
    naa_latency_1m  => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.2.1.1' }, # ibNetworkMonitorDNSNonAAT1AvgLatency
    naa_latency_5m  => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.2.2.1' }, # ibNetworkMonitorDNSNonAAT5AvgLatency
    naa_latency_15m => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.2.3.1' }, # ibNetworkMonitorDNSNonAAT15AvgLatency
    aa_latency_1m   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.3.1.1' }, # ibNetworkMonitorDNSAAT1AvgLatency
    aa_latency_5m   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.3.2.1' }, # ibNetworkMonitorDNSAAT5AvgLatency
    aa_latency_15m  => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.3.1.3.3.1' }, # ibNetworkMonitorDNSAAT15AvgLatency
    dns_hit         => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.5' }, # ibDnsHitRatio
    dns_query       => { oid => '.1.3.6.1.4.1.7779.3.1.1.3.1.6' }  # ibDnsQueryRate
};
my $oid_ibZoneStatisticsEntry = '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_leef(
        oids => [ map($_->{oid} . '.0', values(%$mapping2)) ],
        nothing_quit => 1
    );
    $self->{global} = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => 0);
    $self->{aa} = $self->{global};
    $self->{naa} = $self->{global};

    $snmp_result = $options{snmp}->get_table(oid => $oid_ibZoneStatisticsEntry);
    $self->{dns} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_ibZoneStatisticsEntry}}) {
        next if ($oid !~ /^$mapping->{ibBindZoneName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_ibZoneStatisticsEntry}, instance => $instance);

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{ibBindZoneName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{ibBindZoneName} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{dns}->{$instance} = $result;
    }
    
    $self->{cache_name} = 'infoblox_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check dns usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='success'

=item B<--filter-name>

Filter dns zone name (can be a regexp).

=item B<--warning-*>

Threshold warning.
Can be: 'total-query-rate', 'total-hit-ratio', 'success-count', 'referral-count', 'nxrrset-count', 
'failure-count'.

=item B<--critical-*>

Threshold critical.
Can be: 'total-query-rate', 'total-hit-ratio',
'success-count', 'referral-count', 'nxrrset-count', 'failure-count',
'aa-latency-1m', 'aa-latency-5m', 'aa-latency-15m',
'naa-latency-1m', 'naa-latency-5m', 'naa-latency-15m'.

=back

=cut
