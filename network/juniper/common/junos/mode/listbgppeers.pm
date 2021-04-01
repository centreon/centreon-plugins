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

package network::juniper::common::junos::mode::listbgppeers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_peer_state = (
    1 => 'idle',
    2 => 'connect',
    3 => 'active',
    4 => 'opensent',
    5 => 'openconfirm',
    6 => 'established',
);

my %map_peer_status = (
    1 => 'halted',
    2 => 'running',
);

my $oid_jnxBgpM2PeerTable = '.1.3.6.1.4.1.2636.5.1.1.2.1.1';

my $mapping = {
    jnxBgpM2PeerIdentifier  => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.1' },
    jnxBgpM2PeerState       => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.2', map => \%map_peer_state },
    jnxBgpM2PeerStatus      => { oid => '.1.3.6.1.4.1.2636.5.1.1.2.1.1.1.3', map => \%map_peer_status },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{peers} = {};

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_jnxBgpM2PeerTable,
        start => $mapping->{jnxBgpM2PeerIdentifier}->{oid},
        end => $mapping->{jnxBgpM2PeerStatus}->{oid},
        nothing_quit => 1
    );
    
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{jnxBgpM2PeerIdentifier}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(
            mapping => $mapping,
            results => $snmp_result,
            instance => $instance
        );
        $result->{jnxBgpM2PeerIdentifier} = join('.', map { hex($_) } unpack('(H2)*', $result->{jnxBgpM2PeerIdentifier}));

        $self->{peers}->{$instance} = { %{$result} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{peers}}) { 
        $self->{output}->output_add(
            long_msg => '[name = ' . $self->{peers}->{$instance}->{jnxBgpM2PeerIdentifier} . 
                "] [status = '" . $self->{peers}->{$instance}->{jnxBgpM2PeerStatus} . "'] [state = '" .
                $self->{peers}->{$instance}->{jnxBgpM2PeerState} . "']"
            );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List peers:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status', 'state']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{peers}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{peers}->{$instance}->{jnxBgpM2PeerIdentifier}, 
            status => $self->{peers}->{$instance}->{jnxBgpM2PeerStatus},
            state => $self->{peers}->{$instance}->{jnxBgpM2PeerState}
        );
    }
}

1;

__END__

=head1 MODE

List peers.

=over 8

=back

=cut
    
