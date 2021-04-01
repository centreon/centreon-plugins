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

package centreon::common::aruba::snmp::mode::apconnections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, skipped_code => { -10 => 1 } },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All access points are ok' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'accesspoints.connected.current.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total access points connected : %d',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'total-time', nlabel => 'accesspoint.time.connection.current.seconds', set => {
                key_values => [ { name => 'apTotalTime' }, { name => 'bssid' }, ],
                output_template => 'Current total connection time : %.3f s',
                perfdatas => [
                    { label => 'total_time', value => 'apTotalTime', template => '%.3f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'bssid' },
                ],
            }
        },
        { label => 'inactive-time', nlabel => 'accesspoint.time.inactive.current.seconds', set => {
                key_values => [ { name => 'apInactiveTime' }, { name => 'bssid' }, ],
                output_template => 'Current inactive time : %.3f s',
                perfdatas => [
                    { label => 'inactive_time', value => 'apInactiveTime', template => '%.3f',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'bssid' },
                ],
            }
        },
        { label => 'channel-noise', nlabel => 'accesspoint.channel.noise.count', sset => {
                key_values => [ { name => 'apChannelNoise' }, { name => 'bssid' }, ],
                output_template => 'Channel noise : %d',
                perfdatas => [
                    { label => 'channel_noise', value => 'apChannelNoise', template => '%d',
                      label_extra_instance => 1, instance_use => 'bssid' },
                ],
            }
        },
        { label => 'snr', nlabel => 'accesspoint.signal.noise.ratio.dbm', set => {
                key_values => [ { name => 'apSignalToNoiseRatio' }, { name => 'bssid' }, ],
                output_template => 'Signal to noise ratio : %d',
                perfdatas => [
                    { label => 'snr', value => 'apSignalToNoiseRatio', template => '%d',
                      label_extra_instance => 1, instance_use => 'bssid' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-ip-address:s"  => { name => 'filter_ip_address' },
        "filter-bssid:s"  => { name => 'filter_bssid' },
        "filter-essid:s"  => { name => 'filter_essid' },
        "filter-type:s"   => { name => 'filter_type', default => 'ap' },
        "skip-total"      => { name => 'skip_total' },
    });

    return $self;
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "AP [bssid: '$options{instance_value}->{bssid}', essid: $options{instance_value}->{apESSID}, ip: $options{instance_value}->{apIpAddress}] Usage ";
}

my %map_role = (
    1 => 'master',
    2 => 'local',
    3 => 'standbymaster',
);
my %map_type = (
    1 => 'ap',
    2 => 'am',
);

my $mapping = {
    apESSID => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.2' },  
};
my $mapping2 = {
    apIpAddress => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.5' },
};
my $mapping3 = {
    apType => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.7', map => \%map_type },
};
my $mapping4 = {
    apTotalTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.10' },
    apInactiveTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.11' },
};
my $mapping5 = {
    apChannelNoise => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.13' },
    apSignalToNoiseRatio => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.14' },
};
    
my $oid_wlsxSwitchRole = '.1.3.6.1.4.1.14823.2.2.1.1.1.4';
my $oid_wlsxSwitchAccessPointTable = '.1.3.6.1.4.1.14823.2.2.1.1.3.3';
my $oid_wlsxSwitchAccessPointEntry = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1';
my $oid_wlsxSwitchTotalNumAccessPoints = '.1.3.6.1.4.1.14823.2.2.1.1.3.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_wlsxSwitchTotalNumAccessPoints },
            { oid => $oid_wlsxSwitchRole },
            { oid => $mapping->{apESSID}->{oid} },
            { oid => $mapping2->{apIpAddress}->{oid} },
            { oid => $mapping3->{apType}->{oid} },
            { oid => $oid_wlsxSwitchAccessPointEntry, start => $mapping4->{apTotalTime}->{oid}, end => $mapping4->{apInactiveTime}->{oid} },
            { oid => $oid_wlsxSwitchAccessPointTable, start => $mapping5->{apChannelNoise}->{oid}, end => $mapping5->{apSignalToNoiseRatio}->{oid} },
        ],
        nothing_quit => 1
    );
    my $role = $map_role{$snmp_result->{$oid_wlsxSwitchRole}->{$oid_wlsxSwitchRole . '.0'}};
    if ($role =~ /standbymaster/) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Cannot get information. Switch role is '" . $role . "'.");
        $self->{output}->display();
        $self->{output}->exit();
    }    
    
    $self->{ap} = {};
    foreach my $oid (keys %{$snmp_result->{$mapping->{apESSID}->{oid}}}) {
        next if ($oid !~ /^$mapping->{apESSID}->{oid}\.(.*)$/);
        my $bssid = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$mapping->{apESSID}->{oid}}, instance => $bssid);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$mapping2->{apIpAddress}->{oid}}, instance => $bssid);
        my $result3 = $options{snmp}->map_instance(mapping => $mapping3, results => $snmp_result->{$mapping3->{apType}->{oid}}, instance => $bssid);
        my $result4 = $options{snmp}->map_instance(mapping => $mapping4, results => $snmp_result->{$oid_wlsxSwitchAccessPointEntry}, instance => $bssid);
        my $result5 = $options{snmp}->map_instance(mapping => $mapping5, results => $snmp_result->{$oid_wlsxSwitchAccessPointTable}, instance => $bssid);
        
        if (defined($self->{option_results}->{filter_bssid}) && $self->{option_results}->{filter_bssid} ne '' &&
            $bssid !~ /$self->{option_results}->{filter_bssid}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $bssid . "': no matching filter bssid.");
            next;
        }
        if (defined($self->{option_results}->{filter_ip_address}) && $self->{option_results}->{filter_ip_address} ne '' &&
            $result2->{apIpAddress} !~ /$self->{option_results}->{filter_ip_address}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result2->{apIpAddress} . "': no matching filter ip-address.");
            next;
        }
        if (defined($self->{option_results}->{filter_essid}) && $self->{option_results}->{filter_essid} ne '' &&
            $result->{apESSID} !~ /$self->{option_results}->{filter_essid}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{apESSID} . "': no matching filter essid.");
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result3->{apType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $result->{apType} . "': no matching filter type.");
            next;
        }
        
        $self->{ap}->{$bssid} = { bssid => $bssid, %$result2, %$result, %$result4, %$result5};
        $self->{ap}->{$bssid}->{apInactiveTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apInactiveTime}));
        $self->{ap}->{$bssid}->{apTotalTime} *= 0.01 if (defined($self->{ap}->{$bssid}->{apTotalTime}));
    }
    
    if (!defined($self->{option_results}->{skip_total}) && defined($snmp_result->{$oid_wlsxSwitchTotalNumAccessPoints}->{$oid_wlsxSwitchTotalNumAccessPoints . '.0'})) {
        $self->{global} = { total => $snmp_result->{$oid_wlsxSwitchTotalNumAccessPoints}->{$oid_wlsxSwitchTotalNumAccessPoints . '.0'} };
    }
}

1;

__END__

=head1 MODE

Check AP connections (Deprecated).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-time', 'inactive-time', 'channel-noise', 'snr'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-time', 'inactive-time', 'channel-noise', 'snr'.

=item B<--filter-bssid>

Filter by physical address (regexp can be used).

=item B<--filter-ip-address>

Filter by ip address (regexp can be used).

=item B<--filter-essid>

Filter by ESSID (regexp can be used).

=item B<--filter-type>

Filter by type (regexp can be used. Can be: 'ap' or 'am'. Default: 'ap').

=item B<--skip-total>

Don't display total AP connected (useful when you check each AP).

=back

=cut
