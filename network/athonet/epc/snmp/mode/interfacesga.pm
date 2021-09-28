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

package network::athonet::epc::snmp::mode::interfacesga;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Ga interface '%s' [local: %s] [peer: %s] [type: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{local_address},
        $options{instance_value}->{peer_address},
        $options{instance_value}->{type}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All ga interfaces are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'ga.interfaces.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total interfaces: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        {
            label => 'status', type => 2, critical_default => '%{status} =~ /down/i',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'peer_address' }, 
                    { name => 'local_address' }, { name => 'name' } ],
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
        'filter-name:s'          => { name => 'filter_name' },
        'filter-local-address:s' => { name => 'filter_local_address' },
        'filter-peer-address:s'  => { name => 'filter_peer_address' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'up' };
my $map_transport_type = { 0 => 'sctp', 1 => 'tcp', 2 => 'udp' };

my $mapping = {
    local_address => { oid => '.1.3.6.1.4.1.35805.10.2.12.10.1.2' }, # iGaLinkLocalAddress
    peer_address  => { oid => '.1.3.6.1.4.1.35805.10.2.12.10.1.3' }, # iGaLinkPeerAddress
    type          => { oid => '.1.3.6.1.4.1.35805.10.2.12.10.1.4', map => $map_transport_type }, # iGaLinkTransportType
    status        => { oid => '.1.3.6.1.4.1.35805.10.2.12.10.1.5', map => $map_status },  # iGaLinkState
    name          => { oid => '.1.3.6.1.4.1.35805.10.2.12.10.1.7' }, # iGaLinkName
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_gaLinksEntry = '.1.3.6.1.4.1.35805.10.2.12.10.1';
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_gaLinksEntry,
        nothing_quit => 1
    );

    $self->{interfaces} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{local_address}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_local_address}) && $self->{option_results}->{filter_local_address} ne '' &&
            $result->{local_address} !~ /$self->{option_results}->{filter_local_address}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{local_address} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_peer_address}) && $self->{option_results}->{filter_peer_address} ne '' &&
            $result->{peer_address} !~ /$self->{option_results}->{filter_peer_address}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{peer_address} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{interfaces}->{$instance} = $result;
    }

    $self->{global} = { total => scalar(keys %{$self->{interfaces}}) };
}

1;

__END__

=head1 MODE

Check GA interfaces.

=over 8

=item B<--filter-name>

Filter interfaces by name (can be a regexp).

=item B<--filter-local-address>

Filter interfaces by local address (can be a regexp).

=item B<--filter-peer-address>

Filter interfaces by peer address (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{local_address}, %{peer_address}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{local_address}, %{peer_address}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{local_address}, %{peer_address}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
