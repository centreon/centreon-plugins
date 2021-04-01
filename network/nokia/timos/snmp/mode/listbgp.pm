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

package network::nokia::timos::snmp::mode::listbgp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_status = (1 => 'unknown', 2 => 'inService', 3 => 'outOfService',
    4 => 'transition', 5 => 'disabled',
);
my %map_type = (1 => 'noType', 2 => 'internal', 3 => 'external');
my $oid_vRtrName = '.1.3.6.1.4.1.6527.3.1.2.3.1.1.4';
my $mapping = {
    tBgpPeerNgDescription           => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.7' },
    tBgpPeerNgPeerType              => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.27', map => \%map_type },
    tBgpPeerNgOperStatus            => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.42', map => \%map_status },
    tBgpPeerNgPeerAS4Byte           => { oid => '.1.3.6.1.4.1.6527.3.1.2.14.4.7.1.66' },
};

sub manage_selection {
    my ($self, %options) = @_;

     my $snmp_result = $options{snmp}->get_multiple_table(oids => [
                                                            { oid => $oid_vRtrName },
                                                            { oid => $mapping->{tBgpPeerNgOperStatus}->{oid} },
                                                            { oid => $mapping->{tBgpPeerNgPeerType}->{oid} },
                                                            { oid => $mapping->{tBgpPeerNgDescription}->{oid} },
                                                            { oid => $mapping->{tBgpPeerNgPeerAS4Byte}->{oid} },
                                                         ], return_type => 1, nothing_quit => 1);
    $self->{bgp} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{tBgpPeerNgPeerAS4Byte}->{oid}\.(\d+)\.(\d+)\.(.*)$/);
        my ($vrtr_id, $peer_type, $peer_addr) = ($1, $2, $3);
        
        my $vrtr_name = $snmp_result->{$oid_vRtrName . '.' . $vrtr_id};
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $vrtr_id . '.' . $peer_type . '.' . $peer_addr);
        
        $self->{bgp}->{$vrtr_id . '.' . $peer_type . '.' . $peer_addr} = { 
            vrtr_name => $vrtr_name, peer_type => $result->{tBgpPeerNgPeerType},
            peer_addr => $peer_addr, peer_as => $result->{tBgpPeerNgPeerAS4Byte},
            status => $result->{tBgpPeerNgOperStatus}, description => $result->{tBgpPeerNgDescription} };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{bgp}}) { 
        $self->{output}->output_add(long_msg => '[vrtr_name = ' . $self->{bgp}->{$instance}->{vrtr_name} . 
            "] [peer_addr = '" . $self->{bgp}->{$instance}->{peer_addr} . 
            "'] [peer_as = '" . $self->{bgp}->{$instance}->{peer_as} .
            "'] [peer_type = '" . $self->{bgp}->{$instance}->{peer_type} .
            "'] [description = '" . $self->{bgp}->{$instance}->{description} .
            "'] [status = '" . $self->{bgp}->{$instance}->{status} .
            '"]');
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List BGP:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['vrtr_name', 'peer_addr', 'peer_as', 'peer_type', 'status', 'description']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{bgp}}) {             
        $self->{output}->add_disco_entry(vrtr_name => $self->{bgp}->{$instance}->{vrtr_name},
            peer_addr => $self->{bgp}->{$instance}->{peer_addr},
            peer_as => $self->{bgp}->{$instance}->{peer_as},
            peer_type => $self->{bgp}->{$instance}->{peer_type},
            status => $self->{bgp}->{$instance}->{status},
            description => $self->{bgp}->{$instance}->{description},
        );
    }
}

1;

__END__

=head1 MODE

List BGP.

=over 8

=back

=cut
    
