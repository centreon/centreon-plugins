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

package network::juniper::common::junos::mode::bgppeerprefixstatistics;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'peers', type => 3, cb_prefix_output => 'prefix_output_peer', cb_long_output => 'long_output',
          message_multiple => 'All peers prefix statistics are ok', indent_long_output => '    ',
            group => [
                { name => 'afisafi', display_long => 1, cb_prefix_output => 'prefix_output_afisafi',
                  message_multiple => 'All prefix statistics are ok', type => 1 },
            ]
        }
    ];
    
    $self->{maps_counters}->{afisafi} = [
        { label => 'prefixes-in', nlabel => 'peer.afisafi.prefixes.in.count', set => {
                key_values => [ { name => 'jnxBgpM2PrefixInPrefixes' }, { name => 'jnxBgpM2PrefixCountersAfiSafi' } ],
                output_template => 'Prefixes In: %d',
                perfdatas => [
                    { value => 'jnxBgpM2PrefixInPrefixes', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'prefixes-in-accepted', nlabel => 'peer.afisafi.prefixes.in.accepted.count', set => {
                key_values => [ { name => 'jnxBgpM2PrefixInPrefixesAccepted' }, { name => 'jnxBgpM2PrefixCountersAfiSafi' } ],
                output_template => 'Prefixes In Accepted: %d',
                perfdatas => [
                    { value => 'jnxBgpM2PrefixInPrefixesAccepted', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'prefixes-in-rejected', nlabel => 'peer.afisafi.prefixes.in.rejected.count', set => {
                key_values => [ { name => 'jnxBgpM2PrefixInPrefixesRejected' }, { name => 'jnxBgpM2PrefixCountersAfiSafi' } ],
                output_template => 'Prefixes In Rejected: %d',
                perfdatas => [
                    { value => 'jnxBgpM2PrefixInPrefixesRejected', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'prefixes-in-active', nlabel => 'peer.afisafi.prefixes.in.active.count', set => {
                key_values => [ { name => 'jnxBgpM2PrefixInPrefixesActive' }, { name => 'jnxBgpM2PrefixCountersAfiSafi' } ],
                output_template => 'Prefixes In Active: %d',
                perfdatas => [
                    { value => 'jnxBgpM2PrefixInPrefixesActive', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
        { label => 'prefixes-out', nlabel => 'peer.afisafi.prefixes.out.count', set => {
                key_values => [ { name => 'jnxBgpM2PrefixOutPrefixes' }, { name => 'jnxBgpM2PrefixCountersAfiSafi' } ],
                output_template => 'Prefixes Out: %d',
                perfdatas => [
                    { value => 'jnxBgpM2PrefixOutPrefixes', template => '%d',
                      label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_output_peer {
    my ($self, %options) = @_;

    return "Peer '" . $options{instance_value}->{jnxBgpM2PeerIdentifier} . "' ";
}

sub prefix_output_afisafi {
    my ($self, %options) = @_;

    return "AFI/SAFI '" . $options{instance_value}->{jnxBgpM2PrefixCountersAfiSafi} . "' ";
}

sub long_output {
    my ($self, %options) = @_;

    return "Checking peer '" . $options{instance_value}->{jnxBgpM2PeerIdentifier} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "filter-peer:s" => { name => 'filter_peer' },
    });

    return $self;
}

my $oid_jnxBgpM2PeerIdentifier = '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.1';
my $oid_jnxBgpM2PeerIndex = '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.14' ;

my $oid_jnxBgpM2PrefixCountersTable = '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1';

my $mapping = {
    jnxBgpM2PrefixInPrefixes            => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1.7' },
    jnxBgpM2PrefixInPrefixesAccepted    => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1.8' },
    jnxBgpM2PrefixInPrefixesRejected    => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1.9' },
    jnxBgpM2PrefixOutPrefixes           => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1.10' },
    jnxBgpM2PrefixInPrefixesActive      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.6.2.1.11' },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peers} = {};

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_jnxBgpM2PeerIdentifier },
            { oid => $oid_jnxBgpM2PeerIndex },
        ],
        nothing_quit => 1
    );
    
    my %peers;
    foreach my $oid (keys %{$snmp_result->{$oid_jnxBgpM2PeerIndex}}) {
        next if ($oid !~ /^$oid_jnxBgpM2PeerIndex\.(.*)$/);
        my $instance = $1;

        $peers{$snmp_result->{$oid_jnxBgpM2PeerIndex}->{$oid}} =
            join('.', map { hex($_) } unpack('(H2)*', $snmp_result->{$oid_jnxBgpM2PeerIdentifier}->{$oid_jnxBgpM2PeerIdentifier . '.' . $instance}));
    }
    
    $snmp_result = $options{snmp}->get_table(
        oid => $oid_jnxBgpM2PrefixCountersTable,
        start => $mapping->{jnxBgpM2PrefixInPrefixes}->{oid},
        end => $mapping->{jnxBgpM2PrefixInPrefixesActive}->{oid},
        nothing_quit => 1
    );

    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{jnxBgpM2PrefixInPrefixes}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );

        ($instance =~ /(\d+).(\d+).(\d+)/);
        my $jnxBgpM2PeerIdentifier = $peers{$1};
        my $jnxBgpM2PrefixCountersAfiSafi = $2 . "-" . $3;

        if (defined($self->{option_results}->{filter_peer}) && $self->{option_results}->{filter_peer} ne '' &&
            $jnxBgpM2PeerIdentifier !~ /$self->{option_results}->{filter_peer}/) {
            $self->{output}->output_add(
                long_msg => "skipping peer '" . $jnxBgpM2PeerIdentifier . "': no matching filter.",
                debug => 1
            );
            next;
        }

        $self->{peers}->{$jnxBgpM2PeerIdentifier}->{jnxBgpM2PeerIdentifier} = $jnxBgpM2PeerIdentifier;
        $self->{peers}->{$jnxBgpM2PeerIdentifier}->{afisafi}->{$jnxBgpM2PrefixCountersAfiSafi} =
            { %{$result}, jnxBgpM2PrefixCountersAfiSafi => $jnxBgpM2PrefixCountersAfiSafi };
    }

    if (scalar(keys %{$self->{peers}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No peers found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check BGP peer prefixes per AFI/SAFI (BGP4-V2-MIB-JUNIPER)

=over 8

=item B<--filter-peer>

Filter by peer identifier (Can be regexp)

=item B<--warning-*>

Specify warning threshold.
Can be: 'prefixes-in', 'prefixes-in-accepted',
'prefixes-in-rejected', 'prefixes-in-active', 'prefixes-out'

=item B<--critical-*>

Specify critical threshold.
Can be: 'prefixes-in', 'prefixes-in-accepted',
'prefixes-in-rejected', 'prefixes-in-active', 'prefixes-out'

=back

=cut
