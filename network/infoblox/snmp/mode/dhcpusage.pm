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

package network::infoblox::snmp::mode::dhcpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'dhcp', type => 1, cb_prefix_output => 'prefix_dhcp_output', message_multiple => 'All dhcp subnets are ok' },
    ];
    
    my @map = (
        ['ibDhcpTotalNoOfDiscovers', 'discovers : %s', 'total-discovers'],
        ['ibDhcpTotalNoOfRequests', 'requests : %s', 'total-requests'],
        ['ibDhcpTotalNoOfReleases', 'releases : %s', 'total-releases'],
        ['ibDhcpTotalNoOfOffers', 'offers : %s', 'total-offers'],
        ['ibDhcpTotalNoOfAcks', 'acks : %s', 'total-acks'],
        ['ibDhcpTotalNoOfNacks', 'nacks : %s', 'total-nacks'],
        ['ibDhcpTotalNoOfDeclines', 'declines : %s', 'total-declines'],
        ['ibDhcpTotalNoOfInforms', 'informs : %s', 'total-informs'],
        ['ibDhcpTotalNoOfOthers', 'others : %s', 'total-others'],
    );
    
    $self->{maps_counters}->{global} = [];
    for (my $i = 0; $i < scalar(@map); $i++) {
        my $perf_label = $map[$i]->[2];
        $perf_label =~ s/-/_/g;
        push @{$self->{maps_counters}->{global}}, { label => $map[$i]->[2], set => {
                key_values => [ { name => $map[$i]->[0], diff => 1 } ],
                output_template => $map[$i]->[1],
                perfdatas => [
                    { label => $perf_label, value => $map[$i]->[0] , template => '%s', min => 0 },
                ],
            }
        };
    }
    
    $self->{maps_counters}->{dhcp} = [
        { label => 'subnet-used', set => {
                key_values => [ { name => 'ibDHCPSubnetPercentUsed' }, { name => 'display' } ],
                output_template => 'Used : %.2f %%',
                perfdatas => [
                    { label => 'subnet_used', value => 'iibDHCPSubnetPercentUsed', template => '%.2f', 
                      min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'display' },
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
        'filter-name:s' => { name => 'filter_name' },
    });

    return $self;
}

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "Total ";
}

sub prefix_dhcp_output {
    my ($self, %options) = @_;
    
    return "Subnet '" . $options{instance_value}->{display} . "' ";
}

my $mapping = {
    ibDhcpTotalNoOfDiscovers    => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.1' },
    ibDhcpTotalNoOfRequests     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.2' },
    ibDhcpTotalNoOfReleases     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.3' },
    ibDhcpTotalNoOfOffers       => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.4' },
    ibDhcpTotalNoOfAcks         => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.5' },
    ibDhcpTotalNoOfNacks        => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.6' },
    ibDhcpTotalNoOfDeclines     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.7' },
    ibDhcpTotalNoOfInforms      => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.8' },
    ibDhcpTotalNoOfOthers       => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.9' },
};
my $mapping2 = {
    ibDHCPSubnetNetworkAddress  => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.1' },
    ibDHCPSubnetNetworkMask     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.2' },
    ibDHCPSubnetPercentUsed     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.3' },
};

my $oid_ibDHCPStatistics = '.1.3.6.1.4.1.7779.3.1.1.4.1.3';
my $oid_ibDHCPSubnetEntry = '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ibDHCPStatistics },
            { oid => $oid_ibDHCPSubnetEntry },
        ],
        nothing_quit => 1
    );

    $self->{dhcp} = {};
    foreach my $oid (keys %{$snmp_result->{$oid_ibDHCPSubnetEntry}}) {
        next if ($oid !~ /^$mapping2->{ibDHCPSubnetNetworkAddress}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result->{$oid_ibDHCPSubnetEntry}, instance => $instance);

        my $name = $result->{ibDHCPSubnetNetworkAddress} . '/' . $result->{ibDHCPSubnetNetworkMask};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{dhcp}->{$instance} = { display => $name, 
            %$result
        };
    }

    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result->{$oid_ibDHCPStatistics}, instance => '0');
    $self->{global} = { %$result };
    
    $self->{cache_name} = "infoblox_" . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check dhcp usage.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='total-requests'

=item B<--filter-name>

Filter dhcp subnet name (can be a regexp).

=item B<--warning-*>

ibDhcpTotalNoOfDiscovers

Threshold warning.
Can be: 'total-discovers', 'total-requests', 'total-releases', 
'total-offers', 'total-acks', 'total-nacks', 'total-declines',
'total-informs', 'total-others', 'subnet-used' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'total-discovers', 'total-requests', 'total-releases', 
'total-offers', 'total-acks', 'total-nacks', 'total-declines',
'total-informs', 'total-others', 'subnet-used' (%).

=back

=cut
