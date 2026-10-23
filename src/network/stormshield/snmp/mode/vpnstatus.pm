#
# Copyright 2024-Present Centreon (http://www.centreon.com/)
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

package network::stormshield::snmp::mode::vpnstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc qw(is_excluded);
use Digest::SHA qw(sha256_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::constants qw(:counters :values);

sub custom_traffic_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'b/s',
        instances => [$self->{result_values}->{num}, $self->{result_values}->{ipSrc}, $self->{result_values}->{ipDst}],
        value => sprintf('%d', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL, prefix_output => 'VPN ' },
        { name => 'vpn', type => COUNTER_TYPE_INSTANCE, prefix_output => "VPN '%{num}/%{ipSrc}/%{ipDst}' ", message_multiple => 'All vpn are ok', skipped_code => { NO_VALUE() => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'vpn-detected', display_ok => 0, nlabel => 'vpn.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vpn} = [
        {
            label => 'status',
            type => COUNTER_KIND_TEXT,
            warning_default => '%{state} eq "dead"',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'ipSrc' }, { name => 'ipDst' }
                ],
                output_template => 'state: %s',
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'traffic', nlabel => 'vpn.traffic.bitspersecond', set => {
                key_values => [ { name => 'traffic', per_second => 1 }, { name => 'ipSrc' }, { name => 'ipDst' }, { name => 'num' } ],
                output_template => 'traffic: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_perfdata')
            }
        },
        { label => 'traffic-in', nlabel => 'vpn.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'ipSrc' }, { name => 'ipDst' }, { name => 'num' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_perfdata')
            }
        },
        { label => 'traffic-out', nlabel => 'vpn.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'ipSrc' }, { name => 'ipDst' }, { name => 'num' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_traffic_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'include-id:s'     => { name => 'include_id', default => '' },
        'exclude-id:s'     => { name => 'exclude_id', default => '' },
        'include-src-ip:s' => { name => 'include_src_ip', default => '' },
        'exclude-src-ip:s' => { name => 'exclude_src_ip', default => '' },
        'include-dst-ip:s' => { name => 'include_dst_ip', default => '' },
        'exclude-dst-ip:s' => { name => 'exclude_dst_ip', default => '' },
        'filter-id:s'      => { redirect => 'include_id' },
        'filter-src-ip:s'  => { redirect => 'include_src_ip' },
        'filter-dst-ip:s'  => { redirect => 'include_dst_ip' }
    });

    return $self;
}

my $map_state = {
    0 => 'larval', 1 => 'mature',
    2 => 'dying', 3 => 'dead'
};
my $mapping = {
    legacy => {
        state   => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.11', map => $map_state },
        traffic => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.13' }
    },
    current => {
        state       => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.18' }, # snsVPNSAState
        traffic_in  => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.19' }, # snsVPNSABytesIn
        traffic_out => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.20' }  # snsVPNSABytesOut
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cache_name} = 'stormshield_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port()
        . '_' . sha256_hex(
            join('_',
                $self->{option_results}->{filter_counters} // '',
                map { $self->{option_results}->{$_} } qw(include_id exclude_id include_src_ip exclude_src_ip include_dst_ip exclude_dst_ip)
            )
        );

    my $os_version = '.1.3.6.1.4.1.11256.1.0.2.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [ $os_version ], nothing_quit => 1);

    my $version = 'legacy';
    my $mapping_filter = {
        ipSrc => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.2' },  
        ipDst => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.3' },
    };
    if (centreon::plugins::misc::minimal_version($snmp_result->{$os_version}, '4.2.1')) {
        $version = 'current';
        $mapping_filter = {
            ipSrc => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.5' }, # snsVPNSAIPSrc
            ipDst => { oid => '.1.3.6.1.4.1.11256.1.1.1.1.6' }  # snsVPNSAIPDst
        };
    }

    $snmp_result = $options{snmp}->get_table(
        oid => '.1.3.6.1.4.1.11256.1.1.1.1', # snsVPNSAEntry
        start => $mapping_filter->{ipSrc}->{oid},
        end => $mapping_filter->{ipDst}->{oid}
    );

    $self->{global} = { detected => 0 };
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping_filter->{ipSrc}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping_filter, results => $snmp_result, instance => $instance);

        next if (is_excluded($instance, $self->{option_results}->{include_id}, $self->{option_results}->{exclude_id}, output => $self->{output}));
        next if (is_excluded($result->{ipSrc}, $self->{option_results}->{include_src_ip}, $self->{option_results}->{exclude_src_ip}, output => $self->{output}));
        next if (is_excluded($result->{ipDst}, $self->{option_results}->{include_dst_ip}, $self->{option_results}->{exclude_dst_ip}, output => $self->{output}));

        $self->{global}->{detected}++;
        $self->{vpn}->{$instance} = $result;
        $self->{vpn}->{$instance}->{num} = $instance;
    }

    return if (scalar(keys %{$self->{vpn}}) <= 0);

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%{$mapping->{$version}})) 
        ],
        instances => [ map($_, keys %{$self->{vpn}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    
    foreach (keys %{$self->{vpn}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{$version}, results => $snmp_result, instance => $_);
        $self->{vpn}->{$_}->{state} = $result->{state};
        $self->{vpn}->{$_}->{traffic} = $result->{traffic} * 8 if (defined($result->{traffic}));
        $self->{vpn}->{$_}->{traffic_out} = $result->{traffic_out} * 8 if (defined($result->{traffic_out}));
        $self->{vpn}->{$_}->{traffic_in} = $result->{traffic_in} * 8 if (defined($result->{traffic_in}));
    }
}

1;

__END__

=head1 MODE

Check vpn.

=over 8

=item B<--include-id>

Filter by ID (regexp can be used). Option C<--filter-id> is a deprecated alias.

=item B<--exclude-id>

Exclude VPN by ID (regexp can be used).

=item B<--include-src-ip>

Filter by source IP address (regexp can be used). Option C<--filter-src-ip> is a deprecated alias.

=item B<--exclude-src-ip>

Exclude VPN by source IP address (regexp can be used).

=item B<--include-dst-ip>

Filter by destination IP address (regexp can be used). Option C<--filter-dst-ip> is a deprecated alias.

=item B<--exclude-dst-ip>

Exclude VPN by destination IP address (regexp can be used).

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{state}, %{ipSrc}, %{ipDst}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '%{state} eq "dead"').
You can use the following variables: %{state}, %{ipSrc}, %{ipDst}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{state}, %{ipSrc}, %{ipDst}

=item B<--warning-vpn-detected>

Threshold on the number of detected VPN.

=item B<--critical-vpn-detected>

Threshold on the number of detected VPN.

=item B<--warning-traffic>

Threshold in b/s (firmware older than 4.2.1).

=item B<--critical-traffic>

Threshold in b/s (firmware older than 4.2.1).

=item B<--warning-traffic-in>

Threshold in b/s.

=item B<--critical-traffic-in>

Threshold in b/s.

=item B<--warning-traffic-out>

Threshold in b/s.

=item B<--critical-traffic-out>

Threshold in b/s.

=back

=cut
