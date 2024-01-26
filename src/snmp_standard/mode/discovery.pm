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

package snmp_standard::mode::discovery;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Socket;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'resource-type:s' => { name => 'resource_type' },
        'prettify'        => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{resource_type}) || $self->{option_results}->{resource_type} eq '') {
        $self->{option_results}->{resource_type} = 'rfc4293';
    }
    if ($self->{option_results}->{resource_type} !~ /^rfc4293$/) {
        $self->{output}->add_option_msg(short_msg => 'unknown resource type');
        $self->{output}->option_exit();
    }
}

sub get_ipv6 {
    my ($self, %options) = @_;

    my $ipv6 = '';
    foreach my $val (split /\./, $options{value}) {
        $ipv6 .= pack('C', $val);
    }

    return Socket::inet_ntop(Socket::AF_INET6, $ipv6);
}

sub discovery_rfc4293 {
    my ($self, %options) = @_;

    my $mapping_if = {
        ifName  => { oid => '.1.3.6.1.2.1.31.1.1.1.1' },
        ifDesc  => { oid => '.1.3.6.1.2.1.2.2.1.2' },
        ifAlias => { oid => '.1.3.6.1.2.1.31.1.1.1.18' }
    };
    my $mapping = {
        ipAddressTable => {
            ifIndex   => { oid => '.1.3.6.1.2.1.4.34.1.3' }, # ipAddressIfIndex
        },
        ipAddrTable => {
            ifIndex   => { oid => '.1.3.6.1.2.1.4.20.1.2' }, # ipAdEntIfIndex
            netmask   => { oid => '.1.3.6.1.2.1.4.20.1.3' }  # ipAdEntNetMask
        }
    };

    my $branch = 'ipAddressTable';
    my $snmp_result = $options{snmp}->get_table(
        oid => $mapping->{ipAddressTable}->{ifIndex}->{oid}
    );
    if (scalar(keys %$snmp_result) <= 0) {
        my $oid_ipAddrTable = '.1.3.6.1.2.1.4.20';
        $branch = 'ipAddrTable';
        $snmp_result = $options{snmp}->get_table(
            oid => $oid_ipAddrTable,
            start => $mapping->{ipAddrTable}->{ifIndex}->{oid},
            end => $mapping->{ipAddrTable}->{netmask}->{oid}
        );
    }    

    my $ifs = [];
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{$branch}->{ifIndex}->{oid}\.(.*)/);
        push @$ifs, $mapping_if->{ifName}->{oid} . '.' . $snmp_result->{$_},
            $mapping_if->{ifDesc}->{oid} . '.' . $snmp_result->{$_},
            $mapping_if->{ifAlias}->{oid} . '.' . $snmp_result->{$_};
    }
    my $if_snmp_result = $options{snmp}->get_leef(oids => $ifs);

    my $disco_data = [];
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{$branch}->{ifIndex}->{oid}\.(.*)$/);
        my $instance = $1;

        my ($ip, $result);
        my $type = 'ipv4';
        if ($branch eq 'ipAddrTable') {
            $ip = $instance;
            $result = $options{snmp}->map_instance(mapping => $mapping->{ipAddrTable}, results => $snmp_result, instance => $instance);
        } else {
            $instance =~ /^\d+\.(\d+)\.(.*)$/;
            my ($num, $addr) = ($1, $2);
            if ($num > 4) {
                $type = 'ipv6';
                $ip = $self->get_ipv6(value => $addr);
            } else {
                $ip = $addr;
            }
        }

        my $if_result = $options{snmp}->map_instance(mapping => $mapping_if, results => $if_snmp_result, instance => $snmp_result->{$oid});

        my $node = {};
        $node->{ip} = $ip;
        $node->{type} = $type;
        $node->{netmask} = defined($result->{netmask}) ? $result->{netmask} :  '';
        $node->{interface_name} = defined($if_result->{ifName}) ? $if_result->{ifName} : '';
        $node->{interface_alias} = defined($if_result->{ifAlias}) ? $if_result->{ifAlias} : '';
        $node->{interface_description} = defined($if_result->{ifDesc}) ? $if_result->{ifDesc} : '';

        push @$disco_data, $node;
    }

    return $disco_data;
}

sub run {
    my ($self, %options) = @_;

    my $disco_stats;
    $disco_stats->{start_time} = time();

    my $results = [];
    if ($self->{option_results}->{resource_type} eq 'rfc4293') {
        $results = $self->discovery_rfc4293(
            snmp => $options{snmp}
        );
    }

    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = scalar(@$results);
    $disco_stats->{results} = $results;

    my $encoded_data;
    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->pretty->encode($disco_stats);
        } else {
            $encoded_data = JSON::XS->new->utf8->canonical(1)->encode($disco_stats);
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Resources discovery.

=over 8

=item B<--resource-type>

Choose the type of resources to discover (can be: 'rfc4293').

=item B<--prettify>

Prettify JSON output.

=back

=cut
