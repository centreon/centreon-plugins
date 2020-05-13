#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::airespace::snmp::mode::apusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'ssid', type => 1, cb_prefix_output => 'prefix_ssid_output', message_multiple => 'All users by SSID are ok' },
        { name => 'ap', type => 1, cb_prefix_output => 'prefix_ap_output', message_multiple => 'All users by AP are ok' },
    ];
    $self->{maps_counters}->{global} = [
        { label => 'total', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'Total Users : %s',
                perfdatas => [
                    { label => 'total', value => 'total', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-idle', set => {
                key_values => [ { name => 'total_idle' } ],
                output_template => 'Total Idle Users : %s',
                perfdatas => [
                    { label => 'total_idle', value => 'total_idle', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-aaapending', set => {
                key_values => [ { name => 'total_aaapending' } ],
                output_template => 'Total AaaPending Users : %s',
                perfdatas => [
                    { label => 'total_aaapending', value => 'total_aaapending', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-authenticated', set => {
                key_values => [ { name => 'total_authenticated' } ],
                output_template => 'Total Authenticated Users : %s',
                perfdatas => [
                    { label => 'total_authenticated', value => 'total_authenticated', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-associated', set => {
                key_values => [ { name => 'total_associated' } ],
                output_template => 'Total Associated Users : %s',
                perfdatas => [
                    { label => 'total_associated', value => 'total_associated', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-powersave', set => {
                key_values => [ { name => 'total_powersave' } ],
                output_template => 'Total Powersave Users : %s',
                perfdatas => [
                    { label => 'total_powersave', value => 'total_powersave', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-disassociated', set => {
                key_values => [ { name => 'total_disassociated' } ],
                output_template => 'Total Disassociated Users : %s',
                perfdatas => [
                    { label => 'total_disassociated', value => 'total_disassociated', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-tobedeleted', set => {
                key_values => [ { name => 'total_tobedeleted' } ],
                output_template => 'Total ToBeDeleted Users : %s',
                perfdatas => [
                    { label => 'total_tobedeleted', value => 'total_tobedeleted', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-probing', set => {
                key_values => [ { name => 'total_probing' } ],
                output_template => 'Total Probing Users : %s',
                perfdatas => [
                    { label => 'total_probing', value => 'total_probing', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
        { label => 'total-blacklisted', set => {
                key_values => [ { name => 'total_blacklisted' } ],
                output_template => 'Total Blacklisted Users : %s',
                perfdatas => [
                    { label => 'total_blacklisted', value => 'total_blacklisted', template => '%s', 
                      unit => 'users', min => 0 },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ssid} = [
        { label => 'ssid', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ssid', value => 'total', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
    
    $self->{maps_counters}->{ap} = [
        { label => 'ap', set => {
                key_values => [ { name => 'total' }, { name => 'display' } ],
                output_template => 'users : %s',
                perfdatas => [
                    { label => 'ap', value => 'total', template => '%s', 
                      unit => 'users', min => 0, label_extra_instance => 1, instance_use => 'display' },
                ],
            }
        },
    ];
}

sub prefix_ssid_output {
    my ($self, %options) = @_;
    
    return "SSID '" . $options{instance_value}->{display} . "' ";
}

sub prefix_ap_output {
    my ($self, %options) = @_;
    
    return "AP '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-ssid:s'   => { name => 'filter_ssid' },
        'filter-ap:s'     => { name => 'filter_ap' },
    });
    
    return $self;
}

my %map_station_status = (
    0 => 'idle',
    1 => 'aaapending',
    2 => 'authenticated',
    3 => 'associated',
    4 => 'powersave',
    5 => 'disassociated',
    6 => 'tobedeleted',
    7 => 'probing',
    8 => 'blacklisted',
);
my $mapping = {
    bsnMobileStationStatus  => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.9', map => \%map_station_status },
};
my $mapping2 = {
    bsnMobileStationSsid    => { oid => '.1.3.6.1.4.1.14179.2.1.4.1.7' },
};
my $mapping3 = {
    bsnDot11EssNumberOfMobileStations => { oid => '.1.3.6.1.4.1.14179.2.1.1.1.38' },
};

my $oid_agentInventoryMachineModel = '.1.3.6.1.4.1.14179.1.1.1.3';
my $oid_bsnDot11EssSsid = '.1.3.6.1.4.1.14179.2.1.1.1.2';
my $oid_bsnAPName = '.1.3.6.1.4.1.14179.2.2.1.1.3';
my $oid_bsnAPIfLoadNumOfClients = '.1.3.6.1.4.1.14179.2.2.13.1.4';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0, total_idle => 0, total_aaapending => 0, total_authenticated => 0,
                        total_associated => 0, total_powersave => 0, total_disassociated => 0,
                        total_tobedeleted => 0, total_probing => 0, total_blacklisted => 0};
    $self->{results} = $options{snmp}->get_multiple_table(oids => [ { oid => $oid_agentInventoryMachineModel },
                                                                   { oid => $mapping->{bsnMobileStationStatus}->{oid} },
                                                                   { oid => $mapping2->{bsnMobileStationSsid}->{oid} },
                                                                   { oid => $oid_bsnDot11EssSsid },
                                                                   { oid => $mapping3->{bsnDot11EssNumberOfMobileStations}->{oid} },
                                                                   { oid => $oid_bsnAPName },
                                                                   { oid => $oid_bsnAPIfLoadNumOfClients },
                                                                 ],
                                                         nothing_quit => 1);
    $self->{output}->output_add(long_msg => "Model: " . 
        (defined($self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'}) ? $self->{results}->{$oid_agentInventoryMachineModel}->{$oid_agentInventoryMachineModel . '.0'} : 'unknown'));
    foreach my $oid (keys %{$self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }}) {
        $oid =~ /^$mapping->{bsnMobileStationStatus}->{oid}\.(.*)$/;
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{ $mapping->{bsnMobileStationStatus}->{oid} }, instance => $instance);
        my $result2 = $options{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{ $mapping2->{bsnMobileStationSsid}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result2->{bsnMobileStationSsid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "Skipping '" . $result2->{bsnMobileStationSsid} . "': no matching filter.", debug => 1);
            next;
        }
        $self->{global}->{total}++;
        $self->{global}->{'total_' . $result->{bsnMobileStationStatus}}++;
    }
    
    # check by ssid
    $self->{ssid} = {};
    foreach my $oid (keys %{$self->{results}->{ $oid_bsnDot11EssSsid }}) {
        $oid =~ /^$oid_bsnDot11EssSsid\.(.*)$/;
        my $instance = $1;
        my $ssid_name = $self->{results}->{ $oid_bsnDot11EssSsid }->{$oid};
        my $result = $options{snmp}->map_instance(mapping => $mapping3, results => $self->{results}->{ $mapping3->{bsnDot11EssNumberOfMobileStations}->{oid} }, instance => $instance);
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $ssid_name !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "skipping ssid '" . $ssid_name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{ssid}->{$ssid_name} = { display => $ssid_name, total => 0 } if (!defined($self->{ssid}->{$ssid_name}));
        $self->{ssid}->{$ssid_name}->{total} += $result->{bsnDot11EssNumberOfMobileStations};
    }
    
    # check by ap
    $self->{ap} = {};
    foreach my $oid (keys %{$self->{results}->{ $oid_bsnAPName }}) {
        $oid =~ /^$oid_bsnAPName\.(.*)/;
        my $instance = $1;
        my $ap_name = $self->{results}->{$oid_bsnAPName}->{$oid};
        if (defined($self->{option_results}->{filter_ap}) && $self->{option_results}->{filter_ap} ne '' &&
            $ap_name !~ /$self->{option_results}->{filter_ap}/) {
            $self->{output}->output_add(long_msg => "skipping ap '" . $ap_name . "': no matching filter.", debug => 1);
            next;
        }

        foreach my $oid2 (keys %{$self->{results}->{ $oid_bsnAPIfLoadNumOfClients }}) {
            next if ($oid2 !~ /^$oid_bsnAPIfLoadNumOfClients\.$instance\./);
            $self->{ap}->{$instance} = { display => $ap_name, total => 0 } if (!defined($self->{ap}->{$instance}));
            $self->{ap}->{$instance}->{total} += $self->{results}->{$oid_bsnAPIfLoadNumOfClients}->{$oid2};
        }
    }
}

1;

__END__

=head1 MODE

Check users connected (total, by SSID, by AP).

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total|total-idle$'

=item B<--warning-*>

Threshold warning.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted', 'ssid', 'ap'.

=item B<--critical-*>

Threshold critical.
Can be: 'total', 'total-idle', 'total-aaapending', 'total-authenticated',
'total-associated', 'total-powersave', 'total-disassociated', 'total-tobedeleted',
'total-probing', 'total-blacklisted', 'ssid', 'ap'.

=item B<--filter-ssid>

Filter by SSID (can be a regexp).

=item B<--filter-ap>

Filter by AP (can be a regexp).

=back

=cut
