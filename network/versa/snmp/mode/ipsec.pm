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

package network::versa::snmp::mode::ipsec;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ipsec', type => 1, cb_prefix_output => 'prefix_ipsec_output', message_multiple => 'All IPsec tunnels are ok' }
    ];

    $self->{maps_counters}->{ipsec} = [
        { label => 'packets-in', nlabel => 'ipsec.packets.in.count', display_ok => 0, set => {
                key_values => [
                    { name => 'in_pkts', diff => 1 }, { name => 'org_name' }
                ],
                output_template => 'packets in: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        },
        { label => 'packets-invalid', nlabel => 'ipsec.packets.invalid.count', display_ok => 0, set => {
                key_values => [
                    { name => 'invalid_pkts', diff => 1 }, { name => 'org_name' }
                ],
                output_template => 'packets invalid: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'ipsec.traffic.in.bytespersecond', set => {
                key_values => [
                    { name => 'in_bytes', per_second => 1 }, { name => 'org_name' }
                ],
                output_template => 'traffic in: %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        },
        { label => 'packets-out', nlabel => 'ipsec.packets.out.count', display_ok => 0, set => {
                key_values => [
                    { name => 'out_pkts', diff => 1 }, { name => 'org_name' }
                ],
                output_template => 'packets out: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'ipsec.traffic.out.bytespersecond', set => {
                key_values => [
                    { name => 'out_bytes', per_second => 1 }, { name => 'org_name' }
                ],
                output_template => 'traffic out: %.2f %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%.2f', unit => 'B/s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        },
        { label => 'ike-disconnected', nlabel => 'ipsec.ike.disconnected.count', set => {
                key_values => [
                    { name => 'ike_disconnected', diff => 1 }, { name => 'org_name' }
                ],
                output_template => 'ike disconnected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'org_name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-org:s' => { name => 'filter_org' }
    });

    return $self;
}

sub prefix_ipsec_output {
    my ($self, %options) = @_;

    return sprintf(
        "IPsec '%s' ",
        $options{instance_value}->{org_name}
    );
}

my $mapping = {
    in_pkts          => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.5' },  # ipsecMibIpsecStatsInPkts
    in_bytes         => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.6' },  # ipsecMibIpsecStatsInBytes
    invalid_pkts     => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.5' },  # ipsecMibIpsecStatsInInvalid
    out_pkts         => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.14' }, # ipsecMibIpsecStatsOutPkts
    out_bytes        => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.15' }, # ipsecMibIpsecStatsOutBytes
    ike_disconnected => { oid => '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.42' }  # ipsecMibIpsecStatsIkeDisconnects
};
my $oid_ipsecMibIpsecStatsOrgName = '.1.3.6.1.4.1.42359.2.2.1.2.1.9.1.1.2';

sub manage_selection {
    my ($self, %options) = @_;

    if ($options{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => 'Need to use SNMP v2c or v3.');
        $self->{output}->option_exit();
    }

    my $snmp_result = $options{snmp}->get_table(oid => $oid_ipsecMibIpsecStatsOrgName, nothing_quit => 1);
    $self->{ipsec} = {};
    foreach (keys %$snmp_result) {
        /^$oid_ipsecMibIpsecStatsOrgName\.(.*)$/;
        my $instance = $1;
        my $org_name = $snmp_result->{$_};

        if (defined($self->{option_results}->{filter_org}) && $self->{option_results}->{filter_org} ne '' &&
            $org_name !~ /$self->{option_results}->{filter_org}/) {
            $self->{output}->output_add(long_msg => "skipping ipsec '" . $org_name . "'.", debug => 1);
            next;
        }

        $self->{ipsec}->{$instance} = { org_name => $org_name };
    }

    if (scalar(keys %{$self->{ipsec}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No ipsec tunnels found.");
        $self->{output}->option_exit();
    }

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{ipsec}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{ipsec}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{ipsec}->{$_} = { %{$self->{ipsec}->{$_}}, %$result };
    }
    
    $self->{cache_name} = 'versanetworks_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_org}) ? md5_hex($self->{option_results}->{filter_org}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check ipsec tunnels.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='traffic'

=item B<--filter-org>

Filter monitoring on 'org' -organization name- (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'packets-in', 'packets-invalid', 'traffic-in', 'packets-out', 
'traffic-out', 'ike-disconnected'.

=back

=cut
