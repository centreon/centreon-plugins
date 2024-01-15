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

package network::infoblox::snmp::mode::dnsusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
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
        'filter-name:s' => { name => 'filter_name' },
        'cache'         => { name => 'cache' },
        'cache-time:s'  => { name => 'cache_time', default => 180 }
    });

    $self->{lcache} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{cache})) {
        $self->{lcache}->check_options(option_results => $self->{option_results});
    }
}

my $mapping = {
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
my $oid_name = '.1.3.6.1.4.1.7779.3.1.1.3.1.1.1.1'; # ibBindZoneName

sub get_snmp_zones {
    my ($self, %options) = @_;

    return $options{snmp}->get_table(
        oid => $oid_name,
        nothing_quit => 1
    );
}

sub get_zones {
    my ($self, %options) = @_;

    my $zones;
    if (defined($self->{option_results}->{cache})) {
        my $has_cache_file = $self->{lcache}->read(statefile => 'infoblox_cache_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port());
        my $infos = $self->{lcache}->get(name => 'infos');
        if ($has_cache_file == 0 ||
            !defined($infos->{updated}) ||
            ((time() - $infos->{updated}) > (($self->{option_results}->{cache_time}) * 60))) {
            $zones = $self->get_snmp_zones(snmp => $options{snmp});
            $self->{lcache}->write(data => { infos => { updated => time(), snmp_result => $zones } });
        } else {
            $zones = $infos->{snmp_result};
        }
    } else {
        $zones = $self->get_snmp_zones(snmp => $options{snmp});
    }

    return $zones;
}

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

    my $zones = $self->get_zones(snmp => $options{snmp});
    $self->{dns} = {};
    foreach my $oid (keys %$zones) {
        $oid =~ /^$oid_name\.(.*)$/;
        my $instance = $1;
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $zones->{$oid} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $zones->{$oid} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{dns}->{$instance} = {
            name => $zones->{$oid}
        };
    }

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ map($_, keys(%{$self->{dns}})) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach my $instance (keys %{$self->{dns}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        foreach (keys %$result) {
            $self->{dns}->{$instance}->{$_} = $result->{$_};
        }
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

=item B<--cache>

Use cache file to store dns zone.

=item B<--cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--warning-*>

Warning threshold.
Can be: 'total-query-rate', 'total-hit-ratio', 'success-count', 'referral-count', 'nxrrset-count', 
'failure-count'.

=item B<--critical-*>

Critical threshold.
Can be: 'total-query-rate', 'total-hit-ratio',
'success-count', 'referral-count', 'nxrrset-count', 'failure-count',
'aa-latency-1m', 'aa-latency-5m', 'aa-latency-15m',
'naa-latency-1m', 'naa-latency-5m', 'naa-latency-15m'.

=back

=cut
