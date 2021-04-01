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

package snmp_standard::mode::arp;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total-entries', nlabel => 'arp.total.entries.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total entries %s',
                perfdatas => [
                    { value => 'total', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'duplicate-macaddr', nlabel => 'arp.duplicate.macaddr.count', set => {
                key_values => [ { name => 'duplicate_macaddress' } ],
                output_template => 'duplicate mac address %s',
                perfdatas => [
                    { value => 'duplicate_macaddress', template => '%s', min => 0 },
                ],
            }
        },
        { label => 'duplicate-ipaddr', nlabel => 'arp.duplicate.ipaddr.count', set => {
                key_values => [ { name => 'duplicate_ipaddress' } ],
                output_template => 'duplicate ip address %s',
                perfdatas => [
                    { value => 'duplicate_ipaddress', template => '%s', min => 0 },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_ipNetToMediaTable {
    my ($self, %options) = @_;

    my $oid_ipNetToMediaPhysAddress = '.1.3.6.1.2.1.4.22.1.2';
    my $result = $options{snmp}->get_table(oid => $oid_ipNetToMediaPhysAddress);
    return if (scalar(keys %$result) <= 0);
    
    $self->check_arp(result => $result, oid => $oid_ipNetToMediaPhysAddress);
}

sub check_atTable {
    my ($self, %options) = @_;

    return if (defined($self->{global}));

    my $oid_atPhysAddress = '.1.3.6.1.2.1.4.22.1.2';
    my $result = $options{snmp}->get_table(oid => $oid_atPhysAddress, nothing_quit => 1);
    $self->check_arp(result => $result, oid => $oid_atPhysAddress);
}

sub check_arp {
    my ($self, %options) = @_;

    $self->{global} = { total => 0, duplicate_macaddress => 0, duplicate_ipaddress => 0 };
    my $duplicate = { mac => { }, ip => {} };
    foreach (keys %{$options{result}}) {
        $self->{global}->{total}++;
        my $mac = join(':', unpack('(H2)*', $options{result}->{$_}));
        /^$options{oid}\.(\d+)\.(.*)$/;
        $duplicate->{ip}->{$2} = [] if (!defined($duplicate->{ip}->{$2}));
        push @{$duplicate->{ip}->{$2}}, $mac;
        $duplicate->{mac}->{$mac} = [] if (!defined($duplicate->{mac}->{$mac}));
        push @{$duplicate->{mac}->{$mac}}, $2;
    }

    $self->test_duplicate(duplicate => $duplicate);
}

sub test_duplicate {
    my ($self, %options) = @_;

    foreach (keys %{$options{duplicate}->{ip}}) {
        next if (scalar(@{$options{duplicate}->{ip}->{$_}}) == 1);
        $self->{global}->{duplicate_ipaddress}++;
        $self->{output}->output_add(long_msg => 
            sprintf("ip address '%s' ==> mac address: %s", $_, join(' ',  @{$options{duplicate}->{ip}->{$_}}))
        );
    }

    foreach (keys %{$options{duplicate}->{mac}}) {
        next if (scalar(@{$options{duplicate}->{mac}->{$_}}) == 1);
        $self->{global}->{duplicate_macaddress}++;
        $self->{output}->output_add(long_msg => 
            sprintf("mac address '%s' ==> ip address: %s", $_, join(' ',  @{$options{duplicate}->{mac}->{$_}}))
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->check_ipNetToMediaTable(%options);
    $self->check_atTable(%options);
}

1;

__END__

=head1 MODE

Check arp table.

=over 8

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total-entries', 'duplicate-macaddr', 'duplicate-ipaddr'. 

=back

=cut
