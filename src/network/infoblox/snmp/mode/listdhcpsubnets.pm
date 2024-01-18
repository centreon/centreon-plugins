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

package network::infoblox::snmp::mode::listdhcpsubnets;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my $mapping = {
    address => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.1' }, # ibDHCPSubnetNetworkAddress
    mask    => { oid => '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1.2' }  # ibDHCPSubnetNetworkMask
};
my $oid_ibDHCPSubnetEntry = '.1.3.6.1.4.1.7779.3.1.1.4.1.1.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_ibDHCPSubnetEntry,
        end => $mapping->{mask}->{oid},
    );

    my $subnets = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{address}->{oid}\.(.*)$/);
        $subnets->{$1} = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
    }

    return $subnets;
}

sub run {
    my ($self, %options) = @_;
  
    my $subnets = $self->manage_selection(%options);
    foreach (keys %$subnets) {
        $self->{output}->output_add(
            long_msg => sprintf(
                '[address: %s][mask: %s]',
                $subnets->{$_}->{address},
                $subnets->{$_}->{mask}
            )
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List subnets:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['address', 'mask']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $subnets = $self->manage_selection(%options);
    foreach (keys %$subnets) {
        $self->{output}->add_disco_entry(%{$subnets->{$_}});
    }
}

1;

__END__

=head1 MODE

List DHCP subnets.

=over 8

=back

=cut
