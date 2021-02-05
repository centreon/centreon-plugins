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

package network::checkpoint::snmp::mode::gateway;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'Interface %s (%s) is the default gateway',
        $self->{result_values}->{interface_name},
        $self->{result_values}->{ipaddress}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { 
            label => 'ipaddress', 
            type => 2,
            set => {
                key_values => [ { name => 'ipaddress' }, { name => 'interface_name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
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

sub manage_selection {
    my ($self, %options) = @_;
    
    my $i = 0;
    my $default_gateway = '0.0.0.0';
    my $oid_routingDest = '.1.3.6.1.4.1.2620.1.6.6.1.2';
    my $oid_routingGateway = '.1.3.6.1.4.1.2620.1.6.6.1.4';
    my $oid_routingIntrfName = '.1.3.6.1.4.1.2620.1.6.6.1.5';

    my $snmp_result_routingDest = $options{snmp}->get_table(oid => $oid_routingDest, nothing_quit => 1);
    
    foreach my $oid ($options{snmp}->oid_lex_sort(keys %{$snmp_result_routingDest})) {
        if ($snmp_result_routingDest->{$oid} eq $default_gateway) {
            $i++;
            last;
        }
        $i++;
    }

    my $oid_routingGatewayDefault = $oid_routingGateway . '.' . $i . '.0';
    my $oid_routingIntrfNameDefault = $oid_routingIntrfName . '.' . $i . '.0';

    my $snmp_result_routingGatewayDefault = $options{snmp}->get_leef(
        oids => [$oid_routingGatewayDefault], 
        nothing_quit => 1
    );
    my $snmp_result_routingIntrfNameDefault = $options{snmp}->get_leef(
        oids => [$oid_routingIntrfNameDefault], 
        nothing_quit => 1
    );

    $self->{global} = {
        interface_name => $snmp_result_routingIntrfNameDefault->{$oid_routingIntrfNameDefault},
        ipaddress => $snmp_result_routingGatewayDefault->{$oid_routingGatewayDefault},
    };
}

1;

__END__

=head1 MODE

Check the default gateway.

=over 8

=item B<--warning-ipaddress>

Set warning threshold for ipaddress.
Can used special variables like: %{ipaddress}, %{interface_name}

=item B<--critical-ipaddress>

Set critical threshold for ipaddress.
Can used special variables like: %{ipaddress}, %{interface_name}

=back

=cut
