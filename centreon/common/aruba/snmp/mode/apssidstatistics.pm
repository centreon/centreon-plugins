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

package centreon::common::aruba::snmp::mode::apssidstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'ap', type => 3, cb_prefix_output => 'prefix_output_ap', cb_long_output => 'long_output',
          message_multiple => 'All AP BSSID are ok', indent_long_output => '    ',
            group => [
                { name => 'global', type => 0 },
                { name => 'essid', display_long => 1, cb_prefix_output => 'prefix_output_essid',
                  message_multiple => 'All ESSID are ok', type => 1 },
                { name => 'bssid', display_long => 1, cb_prefix_output => 'prefix_output_bssid',
                  message_multiple => 'All BSSID are ok', type => 1 },
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'stations-associated', nlabel => 'stations.associated.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Stations Associated: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{essid} = [
        { label => 'essid-stations-associated', nlabel => 'essid.stations.associated.count', set => {
                key_values => [ { name => 'wlanAPEssidNumAssociatedStations' }, { name => 'wlanAPESSID' } ],
                output_template => 'Associated Stations: %d',
                perfdatas => [
                    { value => 'wlanAPEssidNumAssociatedStations', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{bssid} = [
        { label => 'bssid-stations-associated', nlabel => 'bssid.stations.associated.count', set => {
                key_values => [ { name => 'wlanAPBssidNumAssociatedStations' }, { name => 'wlanAPBSSID' },
                    { name => 'wlanAPESSID' } ],
                output_template => 'Associated Stations: %d',
                perfdatas => [
                    { value => 'wlanAPBssidNumAssociatedStations', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'channel-noise', nlabel => 'bssid.channel.noise.count', set => {
                key_values => [ { name => 'apChannelNoise' }, { name => 'wlanAPBSSID' },
                    { name => 'wlanAPESSID' } ],
                output_template => 'Channel Noise: %d',
                perfdatas => [
                    { value => 'apChannelNoise', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'signal-noise-ratio', nlabel => 'bssid.signal.noise.ratio.count', set => {
                key_values => [ { name => 'apSignalToNoiseRatio' }, { name => 'wlanAPBSSID' },
                    { name => 'wlanAPESSID' } ],
                output_template => 'Signal To Noise Ratio: %d',
                perfdatas => [
                    { value => 'apSignalToNoiseRatio', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_output_ap {
    my ($self, %options) = @_;

    return "AP '" . $options{instance_value}->{wlanAPName} . "' [Mac: " . $options{instance_value}->{wlanAPMacAddress} . "] ";
}

sub prefix_output_essid {
    my ($self, %options) = @_;

    return "ESSID '" . $options{instance_value}->{wlanAPESSID} . "' ";
}

sub prefix_output_bssid {
    my ($self, %options) = @_;

    return "BSSID '" . $options{instance_value}->{wlanAPBSSID} . "' [ESSID: " .
        $options{instance_value}->{wlanAPESSID} . "][Protocol: " . $options{instance_value}->{wlanAPBssidPhyType} . "] ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking AP '" . $options{instance_value}->{wlanAPName} . "' [Mac: " . $options{instance_value}->{wlanAPMacAddress} . "] ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "filter-ap:s"       => { name => 'filter_ap' },
        "filter-essid:s"    => { name => 'filter_essid' },
        "filter-protocol:s" => { name => 'filter_protocol' },
        "filter-bssid:s"    => { name => 'filter_bssid' },
    });

    return $self;
}

my %map_type = (
    1 => '802.11a', 2 => '802.11b', 3 => '802.11g',
    4 => '802.11ag', 5 => 'wired'    
);

my $oid_wlsxSwitchAccessPointTable = '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1';

my $mapping_switch = {
    apChannelNoise => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.13' },
    apSignalToNoiseRatio => { oid => '.1.3.6.1.4.1.14823.2.2.1.1.3.3.1.14' },
};

my $oid_wlsxWlanAPBssidTable = '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1';

my $mapping_wlan = {
    wlanAPESSID => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1.2' },
    wlanAPBssidPhyType => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1.5', map => \%map_type },
    wlanAPBssidUpTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1.9' },
    wlanAPBssidInactiveTime => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1.10' },
    wlanAPBssidNumAssociatedStations => { oid => '.1.3.6.1.4.1.14823.2.2.1.5.2.1.7.1.12' },
};

my $oid_wlanAPName = '.1.3.6.1.4.1.14823.2.2.1.5.2.1.4.1.3';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_wlsxSwitchAccessPointTable,
              start => $mapping_switch->{apChannelNoise}->{oid},
              end => $mapping_switch->{apSignalToNoiseRatio}->{oid} },
            { oid => $oid_wlsxWlanAPBssidTable,
              start => $mapping_wlan->{wlanAPESSID}->{oid},
              end => $mapping_wlan->{wlanAPBssidNumAssociatedStations}->{oid} },
            { oid => $oid_wlanAPName  },
        ],
        nothing_quit => 1
    );
    
    $self->{ap} = {};
    
    foreach my $oid (keys %{$snmp_result->{$oid_wlsxWlanAPBssidTable}}) {
        next if ($oid !~ /^$mapping_wlan->{wlanAPESSID}->{oid}\.(.*)/);
        my $instance = $1;
        
        my $result = $options{snmp}->map_instance(
            mapping => $mapping_wlan,
            results => $snmp_result->{$oid_wlsxWlanAPBssidTable},
            instance => $instance
        );

        my @digits = split /\./, $instance;
        $result->{wlanAPMacAddress} = join(':', unpack("(A2)*", unpack('H*', pack('C*', @digits[0..5]))));
        $result->{wlanAPBSSID} = join(':', unpack("(A2)*", unpack('H*', pack('C*', @digits[7..12]))));
        $result->{wlanAPName} = $snmp_result->{$oid_wlanAPName}->{$oid_wlanAPName . '.' . join('.', @digits[0..5])};
        $result->{apChannelNoise} = $snmp_result->{$oid_wlsxSwitchAccessPointTable}->{$mapping_switch->{apChannelNoise}->{oid} . '.' . join('.', @digits[7..12])};
        $result->{apSignalToNoiseRatio} = $snmp_result->{$oid_wlsxSwitchAccessPointTable}->{$mapping_switch->{apSignalToNoiseRatio}->{oid} . '.' . join('.', @digits[7..12])};
        
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $result->{wlanAPName} !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPName} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_essid}) && $self->{option_results}->{filter_essid} ne '' &&
            $result->{wlanAPESSID} !~ /$self->{option_results}->{filter_essid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPESSID} . "': no matching filter essid.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_bssid}) && $self->{option_results}->{filter_bssid} ne '' &&
            $result->{wlanAPBSSID} !~ /$self->{option_results}->{filter_bssid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPESSID} . "': no matching filter bssid.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_protocol}) && $self->{option_results}->{filter_protocol} ne '' &&
            $result->{wlanAPBssidPhyType} !~ /$self->{option_results}->{filter_protocol}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{wlanAPBssidPhyType} . "': no matching filter protocol.", debug => 1);
            next;
        }
    
        $self->{ap}->{$result->{wlanAPName}}->{global}->{total} += $result->{wlanAPBssidNumAssociatedStations};
        $self->{ap}->{$result->{wlanAPName}}->{wlanAPName} = $result->{wlanAPName};
        $self->{ap}->{$result->{wlanAPName}}->{wlanAPMacAddress} = $result->{wlanAPMacAddress};
        $self->{ap}->{$result->{wlanAPName}}->{essid}->{$result->{wlanAPESSID}}->{wlanAPEssidNumAssociatedStations} += $result->{wlanAPBssidNumAssociatedStations};
        $self->{ap}->{$result->{wlanAPName}}->{essid}->{$result->{wlanAPESSID}}->{wlanAPESSID} = $result->{wlanAPESSID};
        $self->{ap}->{$result->{wlanAPName}}->{bssid}->{$result->{wlanAPBSSID}} = { %{$result} };
    }
    
    if (scalar(keys %{$self->{ap}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No AP found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AP ESSID and BSSID statistics (WLSX-WLAN-MIB, WLSX-SWITCH-MIB).

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'stations-associated' (ESSID and BSSID),
'channel-noise', 'signal-noise-ratio' (BSSID).

=item B<--critical-*>

Threshold critical.
Can be: 'stations-associated' (ESSID and BSSID),
'channel-noise', 'signal-noise-ratio' (BSSID).

=item B<--filter-*>

Filter by 'ap', 'essid', 'protocol', 'bssid' (regexp can be used).

=back

=cut
