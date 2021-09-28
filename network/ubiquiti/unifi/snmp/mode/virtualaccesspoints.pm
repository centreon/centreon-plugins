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

package network::ubiquiti::unifi::snmp::mode::virtualaccesspoints;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_vap_output {
    my ($self, %options) = @_;

    return sprintf(
        "Virtual access point '%s' [ssid: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{ssid}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'vaps', type => 1, cb_prefix_output => 'prefix_vap_output', message_multiple => 'All virtual access points are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'virtual_access_points.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'total-clients-connected', nlabel => 'virtual_access_points.clients.connected.count', display_ok => 0, set => {
                key_values => [ { name => 'clients_connected' } ],
                output_template => 'clients connected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{vaps} = [
        {
            label => 'status', type => 2, critical_default => '%{status} eq "down"',
            set => {
                key_values => [
                    { name => 'name' }, { name => 'ssid' },
                    { name => 'status' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'clients-connected', nlabel => 'virtual_access_point.clients.connected.count', set => {
                key_values => [ { name => 'clients' }, { name => 'name' } ],
                output_template => 'clients connected: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'virtual_access_point.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'name' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'virtual_access_point.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'name' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1, instance_use => 'name' }
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
        'filter-name:s' => { name => 'filter_name' },
        'filter-ssid:s' => { name => 'filter_ssid' }
    });

    return $self;
}

my $map_status = { 1 => 'up', 2 => 'down' };

my $mapping = {
    filters => {
        ssid        => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.6' }, # unifiVapEssId
        name        => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.7' }  # unifiVapName
    },
    metrics => {
        clients     => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.8' },  # unifiVapNumStations
        traffic_in  => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.10' }, # unifiVapRxBytes
        traffic_out => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.16' }, # unifiVapTxBytes
        status      => { oid => '.1.3.6.1.4.1.41112.1.6.1.2.1.22', map => $map_status } # unifiVapUp
    }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_vap_table = '.1.3.6.1.4.1.41112.1.6.1.2'; # unifiVapTable
    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_vap_table,
        start => $mapping->{filters}->{ssid}->{oid},
        end => $mapping->{filters}->{name}->{oid},
        nothing_quit => 1
    );

    $self->{vaps} = {};
    foreach (keys %$snmp_result) {
        next if (! /^$mapping->{filters}->{name}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping->{filters}, results => $snmp_result, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $result->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_ssid}) && $self->{option_results}->{filter_ssid} ne '' &&
            $result->{ssid} !~ /$self->{option_results}->{filter_ssid}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $result->{name} . "': no matching filter.", debug => 1);
            next;
        }

        $self->{vaps}->{$instance} = $result;
    }

    $self->{global} = { total => scalar(keys %{$self->{vaps}}), clients_connected => 0 };

    return if (scalar(keys %{$self->{vaps}}) <= 0);

    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%{$mapping->{metrics}}))
        ],
        instances => [keys %{$self->{vaps}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{vaps}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping->{metrics}, results => $snmp_result, instance => $_);

        $result->{traffic_in} *= 8;
        $result->{traffic_out} *= 8;
        $self->{vaps}->{$_} = { %{$self->{vaps}->{$_}}, %$result };
        $self->{global}->{clients_connected} += $result->{clients};
    }

    $self->{cache_name} = 'ubiquiti_unifi_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_ssid}) ? md5_hex($self->{option_results}->{filter_ssid}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check virtual access points.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter virtual access points by name (can be a regexp).

=item B<--filter-ssid>

Filter virtual access points by SSID (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{name}, %{ssid}, %{status}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{name}, %{ssid}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "down"').
Can used special variables like: %{name}, %{ssid}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'total-clients-connected', 'clients-connected', 'traffic-in', 'traffic-out'.

=back

=cut
