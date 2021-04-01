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

package network::zyxel::snmp::mode::listvpn;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                  "filter-name:s"         => { name => 'filter_name' },
                                });
    $self->{vpn} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

my %map_active_status = (0 => 'inactive', 1 => 'active');
my %map_connect_status = (0 => 'disconnected', 1 => 'connected');

my $mapping = {
    vpnStatusConnectionName => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.2' },
    vpnStatusActiveStatus   => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.5', map => \%map_active_status },
    vpnStatusConnectStatus  => { oid => '.1.3.6.1.4.1.890.1.6.22.2.4.1.6', map => \%map_connect_status },
};

my $oid_vpnStatusEntry = '.1.3.6.1.4.1.890.1.6.22.2.4.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(oid => $oid_vpnStatusEntry, nothing_quit => 1);
    foreach my $oid (keys %{$snmp_result}) {
        next if ($oid !~ /^$mapping->{vpnStatusConnectionName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{vpnStatusConnectionName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{vpnStatusConnectionName} . "': no matching filter.", debug => 1);
            next;
        }
        
        $self->{vpn}->{$result->{vpnStatusConnectionName}} = { 
            name => $result->{vpnStatusConnectionName},
            active_status => $result->{vpnStatusActiveStatus},
            connect_status => $result->{vpnStatusConnectStatus},
        };
    }
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{vpn}}) { 
        $self->{output}->output_add(long_msg => '[name = ' . $self->{vpn}->{$instance}->{name} . "]" .
            " [active status = '" . $self->{vpn}->{$instance}->{active_status} . "']" .
            " [connect status = '" . $self->{vpn}->{$instance}->{connect_status} . "']"
        );
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List VPNs:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'active_status', 'connect_status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $instance (sort keys %{$self->{vpn}}) {             
        $self->{output}->add_disco_entry(
            %{$self->{vpn}->{$instance}}
        );
    }
}

1;

__END__

=head1 MODE

List VPNs.

=over 8

=item B<--filter-name>

Filter by VPN name.

=back

=cut
    
