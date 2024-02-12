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

package network::infoblox::snmp::mode::dhcpusage;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Total ';
}

sub prefix_dhcp_output {
    my ($self, %options) = @_;
    
    return "Subnet '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'dhcp', type => 1, cb_prefix_output => 'prefix_dhcp_output', message_multiple => 'All dhcp subnets are ok' }
    ];
    
    my @map = (
        ['ibDhcpTotalNoOfDiscovers', 'discovers: %s', 'total-discovers', 'dhcp.discovers.count'],
        ['ibDhcpTotalNoOfRequests', 'requests: %s', 'total-requests', 'dhcp.requests.count'],
        ['ibDhcpTotalNoOfReleases', 'releases: %s', 'total-releases', 'dhcp.releases.count'],
        ['ibDhcpTotalNoOfOffers', 'offers: %s', 'total-offers', 'dhcp.offers.count'],
        ['ibDhcpTotalNoOfAcks', 'acks: %s', 'total-acks', 'dhcp.acks.count'],
        ['ibDhcpTotalNoOfNacks', 'nacks: %s', 'total-nacks', 'dhcp.nacks.count'],
        ['ibDhcpTotalNoOfDeclines', 'declines: %s', 'total-declines', 'dhcp.declines.count'],
        ['ibDhcpTotalNoOfInforms', 'informs: %s', 'total-informs', 'dhcp.informs.count'],
        ['ibDhcpTotalNoOfOthers', 'others: %s', 'total-others', 'dhcp.others.count']
    );

    $self->{maps_counters}->{global} = [];
    for (my $i = 0; $i < scalar(@map); $i++) {
        push @{$self->{maps_counters}->{global}}, {
            label => $map[$i]->[2], nlabel => $map[$i]->[3], set => {
                key_values => [ { name => $map[$i]->[0], diff => 1 } ],
                output_template => $map[$i]->[1],
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }

    $self->{maps_counters}->{dhcp} = [
        { label => 'subnet-used', nlabel => 'subnet.addresses.usage.percentage', set => {
                key_values => [ { name => 'subnet_used' }, { name => 'name' } ],
                output_template => 'used: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1, instance_use => 'name' }
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
    ibDhcpTotalNoOfDiscovers    => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.1' },
    ibDhcpTotalNoOfRequests     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.2' },
    ibDhcpTotalNoOfReleases     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.3' },
    ibDhcpTotalNoOfOffers       => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.4' },
    ibDhcpTotalNoOfAcks         => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.5' },
    ibDhcpTotalNoOfNacks        => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.6' },
    ibDhcpTotalNoOfDeclines     => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.7' },
    ibDhcpTotalNoOfInforms      => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.8' },
    ibDhcpTotalNoOfOthers       => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.3.9' }
};
my $mapping2 = {
    address => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.1' }, # ibDHCPSubnetNetworkAddress
    mask    => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.2' } # ibDHCPSubnetNetworkMask
};

my $oid_ibDHCPSubnetEntry = '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1';
my $oid_subnet_prct_used = '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.3'; # ibDHCPSubnetPercentUsed

sub get_snmp_subnets {
    my ($self, %options) = @_;

    return $options{snmp}->get_table(
        oid => $oid_ibDHCPSubnetEntry,
        end => $mapping2->{mask}->{oid},
        nothing_quit => 1
    );
}

sub get_subnets {
    my ($self, %options) = @_;

    my $subnets;
    if (defined($self->{option_results}->{cache})) {
        my $has_cache_file = $self->{lcache}->read(statefile => 'infoblox_cache_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port());
        my $infos = $self->{lcache}->get(name => 'infos');
        if ($has_cache_file == 0 ||
            !defined($infos->{updated}) ||
            ((time() - $infos->{updated}) > (($self->{option_results}->{cache_time}) * 60))) {
            $subnets = $self->get_snmp_subnets(snmp => $options{snmp});
            $self->{lcache}->write(data => { infos => { updated => time(), snmp_result => $subnets } });
        } else {
            $subnets = $infos->{snmp_result};
        }
    } else {
        $subnets = $self->get_snmp_subnets(snmp => $options{snmp});
    }

    return $subnets;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $subnets = $self->get_subnets(snmp => $options{snmp});

    $self->{dhcp} = {};
    foreach my $oid (keys %$subnets) {
        next if ($oid !~ /^$mapping2->{address}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $subnets, instance => $instance);

        my $name = $result->{address} . '/' . $result->{mask};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{dhcp}->{$instance} = {
            name => $name, 
            %$result
        };
    }

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [0],
        instance_regexp => '^(.*)$'
    );
    $options{snmp}->load(
        oids => [$oid_subnet_prct_used],
        instances => [ map($_, keys(%{$self->{dhcp}})) ],
        instance_regexp => '^(.*)$'
    );
    my $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{dhcp}}) {
        $self->{dhcp}->{$_}->{subnet_used} = $snmp_result->{ $oid_subnet_prct_used . '.' . $_ }
            if (defined($snmp_result->{ $oid_subnet_prct_used . '.' . $_ }));
    }

    $self->{global} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);
    
    $self->{cache_name} = 'infoblox_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
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

=item B<--cache>

Use cache file to store subnets.

=item B<--cache-time>

Time in minutes before reloading cache file (default: 180).

=item B<--warning-*>

ibDhcpTotalNoOfDiscovers

Warning threshold.
Can be: 'total-discovers', 'total-requests', 'total-releases', 
'total-offers', 'total-acks', 'total-nacks', 'total-declines',
'total-informs', 'total-others', 'subnet-used' (%).

=item B<--critical-*>

Critical threshold.
Can be: 'total-discovers', 'total-requests', 'total-releases', 
'total-offers', 'total-acks', 'total-nacks', 'total-declines',
'total-informs', 'total-others', 'subnet-used' (%).

=back

=cut
