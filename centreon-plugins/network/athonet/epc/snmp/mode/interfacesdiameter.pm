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

package network::athonet::epc::snmp::mode::interfacesdiameter;

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

sub custom_transport_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'transport status: %s [type: %s]',
        $self->{result_values}->{transport_status},
        $self->{result_values}->{transport_type}
    );
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return sprintf(
        "Diameter interface '%s' [local: %s] [peer: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{local_hostname},
        $options{instance_value}->{peer_hostname}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'interfaces', type => 1, cb_prefix_output => 'prefix_interface_output', message_multiple => 'All diameter interfaces are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'diameter.interfaces.total.count', display_ok => 0, set => {
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
                key_values => [ { name => 'status' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        {
            label => 'transport-status', type => 2, critical_default => '%{transport_status} =~ /down/i',
            set => {
                key_values => [ { name => 'transport_status' }, { name => 'transport_type' }, { name => 'name' } ],
                closure_custom_output => $self->can('custom_transport_status_output'),
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
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_status = { 0 => 'down', 1 => 'up' };
my $map_transport_type = { 0 => 'sctp', 1 => 'tcp', 2 => 'udp' };

my $mapping = {
    peer_hostname    => { oid => '.1.3.6.1.4.1.35805.10.2.12.2.1.4' }, # iDiameterPeerHostName
    transport_type   => { oid => '.1.3.6.1.4.1.35805.10.2.12.2.1.8', map => $map_transport_type }, # iDiameterTransportType
    transport_status => { oid => '.1.3.6.1.4.1.35805.10.2.12.2.1.9', map => $map_status }, # iDiameterTransportState
    status           => { oid => '.1.3.6.1.4.1.35805.10.2.12.2.1.10', map => $map_status }  # iDiameterState
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_local_hostname = '.1.3.6.1.4.1.35805.10.2.12.2.1.2'; # iDiameterLocalHostName
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_local_hostname,
        nothing_quit => 1
    );

    $self->{interfaces} = {};
    foreach (keys %$snmp_result) {
        /^$oid_local_hostname\.(\d+\.(.*))$/;
        my $instance = $1;
        my $name = $self->{output}->decode(join('', map(chr($_), split(/\./, $2))));

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }

        $self->{interfaces}->{$instance} = {
            name => $name,
            local_hostname => $snmp_result->{$_}
        };
    }

    $self->{global} = { total => scalar(keys %{$self->{interfaces}}) };

    return if (scalar(keys %{$self->{interfaces}}) <= 0);

    $options{snmp}->load(oids => [
            map($_->{oid}, values(%$mapping))
        ],
        instances => [keys %{$self->{interfaces}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{interfaces}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{interfaces}->{$_} = { %{$self->{interfaces}->{$_}}, %$result };
    }
}

1;

__END__

=head1 MODE

Check diameter interfaces.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='transport'

=item B<--filter-name>

Filter interfaces by name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{name}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /down/i').
Can used special variables like: %{status}, %{name}

=item B<--unknown-transport-status>

Set unknown threshold for status.
Can used special variables like: %{transport_status}, %{transport_type}, %{name}

=item B<--warning-transport-status>

Set warning threshold for status.
Can used special variables like: %{transport_status}, %{transport_type}, %{name}

=item B<--critical-transport-status>

Set critical threshold for status (Default: '%{transport_status} =~ /down/i').
Can used special variables like: %{transport_status}, %{transport_type}, %{name}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
