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

package network::ruckus::smartzone::snmp::mode::accesspoints;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "connection status is '%s' [config status: '%s'] [registration status: '%s']",
        $self->{result_values}->{connection_status},
        $self->{result_values}->{config_status},
        $self->{result_values}->{registration_status}
    );
}

sub ap_long_output {
    my ($self, %options) = @_;

    return "checking access point '" . $options{instance_value}->{display} . "'";
}

sub prefix_ap_output {
    my ($self, %options) = @_;

    return "access point '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'accesspoints', type => 3, cb_prefix_output => 'prefix_ap_output', cb_long_output => 'ap_long_output',
          indent_long_output => '    ', message_multiple => 'All access points are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'connection', type => 0, skipped_code => { -10 => 1 } },
                { name => 'traffic', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{status} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'connection_status' }, { name => 'config_status' },
                    { name => 'registration_status' }, { name => 'display' }
                ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];

    $self->{maps_counters}->{connection} = [
        { label => 'connection-client-devices-authorized', nlabel => 'accesspoint.connection.client.devices.authorized.count', set => {
                key_values => [ { name => 'authorized_clients' }, { name => 'display' } ],
                output_template => 'client devices authorized connections: %d',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{traffic} = [
        { label => 'traffic-in', nlabel => 'accesspoint.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'accesspoint.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s%s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'display' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status']);
}

my $mapping = {
    authorized_clients  => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.15' }, # ruckusSZAPNumSta
    connection_status   => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.16' }, # ruckusSZAPConnStatus
    registration_status => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.17' }, # ruckusSZAPRegStatus
    config_status       => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.18' }, # ruckusSZAPConfigStatus
    traffic_out         => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.57' }, # ruckusSZAPIpsecTXBytes
    traffic_in          => { oid => '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.58' }, # ruckusSZAPIpsecRXBytes
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_ruckusSZAPName = '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.5';
    my $oid_ruckusSZAPSerial = '.1.3.6.1.4.1.25053.1.4.2.1.1.2.2.1.9';
    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [
            { oid => $oid_ruckusSZAPName },
            { oid => $oid_ruckusSZAPSerial }
        ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{accesspoints} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$oid_ruckusSZAPName\.(.*)/);
        my $instance = $1;
        my $name = defined($snmp_result->{$_}) && $snmp_result->{$_} ne '' ? 
            $snmp_result->{$_} : $snmp_result->{$oid_ruckusSZAPSerial . '.' . $instance};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping access point '" . $name . "'.", debug => 1);
            next;
        }

        $self->{accesspoints}->{$instance} = {
            display => $name,
            status => { display => $name },
            connection => { display => $name },
            traffic => { display => $name }
        };
    }

    return if (scalar(keys %{$self->{accesspoints}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping)) ],
        instances => [ keys %{$self->{accesspoints}} ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    foreach (keys %{$self->{accesspoints}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);

        $self->{accesspoints}->{$_}->{status}->{connection_status} = $result->{connection_status};
        $self->{accesspoints}->{$_}->{status}->{registration_status} = $result->{registration_status};
        $self->{accesspoints}->{$_}->{status}->{config_status} = $result->{config_status};

        $self->{accesspoints}->{$_}->{connection}->{authorized_clients} = $result->{authorized_clients};

        $self->{accesspoints}->{$_}->{traffic}->{traffic_in} = $result->{traffic_in} * 8;
        $self->{accesspoints}->{$_}->{traffic}->{traffic_out} = $result->{traffic_out} * 8;
    }

    $self->{cache_name} = 'ruckus_smartzone_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' .
        (defined($self->{option_results}->{filter_counters_block}) ? md5_hex($self->{option_results}->{filter_counters_block}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'))
}

1;

__END__

=head1 MODE

Check access points.

=over 8

=item B<--filter-name>

Filter by access point name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{config_status}, %{connection_status}, %{registration_status}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like:  %{config_status}, %{connection_status}, %{registration_status}

=item B<--critical-status>

Set critical threshold for status.
Can used special variables like:  %{config_status}, %{connection_status}, %{registration_status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'traffic-in', 'traffic-out', 'connection-client-devices-authorized'.

=back

=cut
