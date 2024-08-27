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

package network::viptela::snmp::mode::controlconnections;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);
use Socket;

sub connection_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking control connection [public: %s] [private: %s] [type: %s]",
        $options{instance_value}->{publicIp}, 
        $options{instance_value}->{privateIp},
        $options{instance_value}->{type}
    );
}

sub prefix_connection_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking control connection [public: %s] [private: %s] [type: %s] ",
        $options{instance_value}->{publicIp}, 
        $options{instance_value}->{privateIp},
        $options{instance_value}->{type}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Number of control connections ';
}

my $map_status = {
    0 => 'down', 1 => 'connect', 2 => 'handshake', 3 => 'trying',
    4 => 'challenge', 5 => 'challengeResp', 6 => 'challengeAck', 
    7 => 'up', 8 => 'tearDown'
};
my $map_type = {
    0 => 'unknown', 1 => 'vedge', 2 => 'vhub', 
    3 => 'vsmart', 4 => 'vbond', 5 => 'vmanage',
    6 => 'ztp', 7 => 'vcontainer'
};

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output' },
        { name => 'connections', type => 3, cb_prefix_output => 'prefix_connection_output', cb_long_output => 'connection_long_output',
          indent_long_output => '    ', message_multiple => 'All control connections are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'connnections-detected', display_ok => 0, nlabel => 'control.connections.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];
    
    foreach (values %$map_status) {
        push @{$self->{maps_counters}->{global}},
            { label => 'connections-' . lc($_), display_ok => 0, nlabel => 'control.connections.' . $_ . '.count', set => {
                key_values => [ { name => $_ } ],
                output_template => $_ . ': %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        };
    }
    
    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} !~ /up|connect/',
            set => {
                key_values => [
                    { name => 'status' }, { name => 'type' },
                    { name => 'publicIp' }, { name => 'privateIp' }
                ],
                output_template => "status: %s",
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
        'filter-public-ip:s'  => { name => 'filter_public_ip' },
        'filter-private-ip:s' => { name => 'filter_private_ip' },
        'filter-type:s'       => { name => 'filter_type' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { detected => 0 };
    foreach (values %$map_status) {
        $self->{global}->{$_} = 0;
    }

    my $oid_status = '.1.3.6.1.4.1.41916.4.2.2.1.15'; # controlConnectionsState  
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_status,
        nothing_quit => 1
    );

    $self->{connections} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_status\.(\d+\.(\d+)\.\d+\.\d+\.(.*))$/;
        my $instance = $1;
        my $type = $map_type->{$2};
        my @addr = split(/\./, $3);
        my ($publicIp, $privateIp);

        if ($addr[0] == 4) {
            $privateIp = $addr[1] . '.' . $addr[2] . '.' . $addr[3] . '.' . $addr[4] . ':' . $addr[5];
        }
        if ($addr[6] == 4) {
            $publicIp = $addr[7] . '.' . $addr[8] . '.' . $addr[9] . '.' . $addr[10] . ':' . $addr[11];
        }

        next if (defined($self->{option_results}->{filter_public_ip}) && $self->{option_results}->{filter_public_ip} ne '' &&
            $publicIp !~ /$self->{option_results}->{filter_public_ip}/);
        next if (defined($self->{option_results}->{filter_private_ip}) && $self->{option_results}->{filter_private_ip} ne '' &&
            $privateIp !~ /$self->{option_results}->{filter_private_ip}/);
        next if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $type !~ /$self->{option_results}->{filter_type}/);        

        $self->{connections}->{$instance} = {
            publicIp => $publicIp,
            privateIp => $privateIp,
            type => $type,
            status => {
                publicIp => $publicIp,
                privateIp => $privateIp,
                type => $type,
                status => $map_status->{ $snmp_result->{$oid} }
            }
        };
        $self->{global}->{detected}++;
        $self->{global}->{ $map_status->{ $snmp_result->{$oid} } }++;
    }
}

1;

__END__

=head1 MODE

Check control connections.

=over 8

=item B<--filter-public-ip>

Filter connections by public ip address.

=item B<--filter-private-ip>

Filter connections by private ip address.

=item B<--filter-type>

Filter connections by type.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{type}, %{privateIp}, %{publicIp}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{type}, %{privateIp}, %{publicIp}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /up|connect/').
You can use the following variables: %{status}, %{type}, %{privateIp}, %{publicIp}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'connnections-detected', 'connections-challengeack',
'connections-handshake', 'connections-challenge', 'connections-teardown',
'connections-challengeresp', 'connections-up', 'connections-connect', 
'connections-trying', 'connections-down'.

=back

=cut
