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

package centreon::common::airespace::snmp::mode::radiusaccservers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);

sub prefix_servers_output {
    my ($self, %options) = @_;
    
    return "Radius accounting server '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'servers', type => 1, cb_prefix_output => 'prefix_servers_output', message_multiple => 'All radius accounting servers are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'accservers-total', nlabel => 'radius.accservers.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total accounting servers: %s',
                perfdatas => [
                    { ltemplate => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{servers} = [
        { label => 'accservers-roundtrip-time', nlabel => 'radius.accservers.roundtrip.time.milliseconds', set => {
                key_values => [ { name => 'round_trip_time' }, { name => 'name' } ],
                output_template => 'round trip time: %s ms',
                perfdatas => [
                    { template => '%s', min => 0, unit => 'ms', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'accservers-packets-sent', nlabel => 'radius.accservers.packets.sent.persecond', set => {
                key_values => [ { name => 'requests', per_second => 1 }, { name => 'name' } ],
                output_template => 'packets sent: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'accservers-packets-received', nlabel => 'radius.accservers.packets.received.persecond', set => {
                key_values => [ { name => 'responses', per_second => 1 }, { name => 'name' } ],
                output_template => 'packets received: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        },
        { label => 'accservers-clients-timeout', nlabel => 'radius.accservers.clients.timeout.count', set => {
                key_values => [ { name => 'timeouts', diff => '1' }, { name => 'name' } ],
                output_template => 'clients timeout: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1, instance_use => 'name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, statefile => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

my $map_server_status = {
    0 => 'disable', 1 => 'enable'
};
my $mapping = {
    address => { oid => '.1.3.6.1.4.1.14179.2.5.2.1.2' }, # bsnRadiusAccServerAddress
    port    => { oid => '.1.3.6.1.4.1.14179.2.5.2.1.3' }, # bsnRadiusAccClientServerPortNumber
    status  => { oid => '.1.3.6.1.4.1.14179.2.5.2.1.5', map => $map_server_status } # bsnRadiusAccServerStatus
};
my $mapping2 = {
    round_trip_time => { oid => '.1.3.6.1.4.1.14179.2.5.4.1.6' }, # bsnRadiusAccClientRoundTripTime
    requests        => { oid => '.1.3.6.1.4.1.14179.2.5.4.1.7' }, # bsnRadiusAccClientRequests
    responses       => { oid => '.1.3.6.1.4.1.14179.2.5.4.1.9' }, # bsnRadiusAccClientResponses
    timeouts        => { oid => '.1.3.6.1.4.1.14179.2.5.4.1.13' } # bsnRadiusAccClientTimeouts
};
my $oid_bsnRadiusAccServerEntry = '.1.3.6.1.4.1.14179.2.5.2.1';

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_table(
        oid => $oid_bsnRadiusAccServerEntry,
        start => $mapping->{address}->{oid},
        end => $mapping->{status}->{oid},
        nothing_quit => 1
    );

    $self->{global} = { total => 0 };
    $self->{servers} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{status}->{oid}\.(.*)$/);
        my $instance = $1;

        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $instance);
        my $name = $result->{address} . ':' . $result->{port};
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': no matching filter.", debug => 1);
            next;
        }
        if ($result->{status} eq 'disable') {
            $self->{output}->output_add(long_msg => "skipping '" . $name . "': disabled.", debug => 1);
            next;
        }

        $self->{servers}->{$instance} = { name => $name };
        $self->{global}->{total}++;
    }

    return if (scalar(keys %{$self->{servers}}) <= 0);

    $options{snmp}->load(
        oids => [ map($_->{oid}, values(%$mapping2)) ],
        instances => [keys %{$self->{servers}}],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach (keys %{$self->{servers}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping2, results => $snmp_result, instance => $_);

        $self->{servers}->{$_} = { %{$self->{servers}->{$_}}, %$result };
    }

    $self->{cache_name} = 'cisco_wlc_' . $self->{mode} . '_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));

}

1;

__END__

=head1 MODE

Check radius accounting servers.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^total$'

=item B<--filter-name>

Filter radius servers by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'accservers-total', 'accservers-roundtrip-time',
'accservers-packets-sent', 'accservers-packets-received',
'accservers-clients-timeout'.

=back

=cut
