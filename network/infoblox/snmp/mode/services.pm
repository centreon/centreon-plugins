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

package network::infoblox::snmp::mode::services;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        default => [
            ['unknown', 'OK'],
            ['working', 'OK'],
            ['inactive', 'OK'],
            ['warning', 'WARNING'],
            ['failed', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'network::infoblox::snmp::mode::components';
    $self->{components_module} = ['service'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_load_components => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

=head1 MODE

Check physical service status.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'service'.

=item B<--filter>

Filter component instances (syntax: component,regexp_filter). Component instances are excluded if matching regexp_filter.
E.g: --filter=service,fan1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='service,OK,warning'

=back

=cut

package network::infoblox::snmp::mode::components::service;

use strict;
use warnings;

my %map_service_status = (
    1 => 'working', 2 => 'warning',
    3 => 'failed', 4 => 'inactive', 5 => 'unknown',
);
my %map_service_name = (
    1 => 'dhcp', 2 => 'dns', 3 => 'ntp', 4 => 'tftp', 5 => 'http-file-dist',
    6 => 'ftp', 7 => 'bloxtools-move', 8 => 'bloxtools', 9 => 'node-status',
    10 => 'disk-usage', 11 => 'enet-lan', 12 => 'enet-lan2', 13 => 'enet-ha',
    14 => 'enet-mgmt', 15 => 'lcd', 16 => 'memory', 17 => 'replication', 18 => 'db-object',
    19 => 'raid-summary', 20 => 'raid-disk1', 21 => 'raid-disk2', 22 => 'raid-disk3',
    23 => 'raid-disk4', 24 => 'raid-disk5', 25 => 'raid-disk6', 26 => 'raid-disk7',
    27 => 'raid-disk8', 28 => 'fan1', 29 => 'fan2', 30 => 'fan3', 31 => 'fan4',
    32 => 'fan5', 33 => 'fan6', 34 => 'fan7', 35 => 'fan8', 36 => 'power-supply1',
    37 => 'power-supply2', 38 => 'ntp-sync', 39 => 'cpu1-temp', 40 => 'cpu2-temp',
    41 => 'sys-temp', 42 => 'raid-battery', 43 => 'cpu-usage', 44 => 'ospf',
    45 => 'bgp', 46 => 'mgm-service', 47 => 'subgrid-conn', 48 => 'network-capacity',
    49 => 'reporting', 50 => 'dns-cache-acceleration', 51 => 'ospf6',
    52 => 'swap-usage', 53 => 'discovery-consolidator', 54 => 'discovery-collector',
    55 => 'discovery-capacity', 56 => 'threat-protection', 57 => 'cloud-api',
    58 => 'threat-analytics', 59 => 'taxii', 60 => 'bfd', 61 => 'outbound',
);

my $mapping = {
    ibNodeServiceName   => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.10.1.1', map => \%map_service_name },
    ibNodeServiceStatus => { oid => '.1.3.6.1.4.1.7779.3.1.1.2.1.10.1.2', map => \%map_service_status },
};
my $oid_ibMemberNodeServiceStatusEntry = '.1.3.6.1.4.1.7779.3.1.1.2.1.10.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_ibMemberNodeServiceStatusEntry, end => $mapping->{ibNodeServiceStatus}->{oid} };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking services");
    $self->{components}->{service} = {name => 'services', total => 0, skip => 0};
    return if ($self->check_filter(section => 'service'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$oid_ibMemberNodeServiceStatusEntry}})) {
        next if ($oid !~ /^$mapping->{ibNodeServiceName}->{oid}\.(.*)$/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$oid_ibMemberNodeServiceStatusEntry}, instance => $instance);

        next if ($self->check_filter(section => 'service', instance => $result->{ibNodeServiceName}));

        $self->{components}->{service}->{total}++;
        $self->{output}->output_add(
            long_msg => sprintf(
                "service '%s' status is '%s' [instance = %s]",
                $result->{ibNodeServiceName}, $result->{ibNodeServiceStatus}, $result->{ibNodeServiceName}
            )
        );
        my $exit = $self->get_severity(label => 'default', section => 'service', instance => $result->{ibNodeServiceName}, value => $result->{ibNodeServiceStatus});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Service '%s' status is '%s'", $result->{ibNodeServiceName}, $result->{ibNodeServiceStatus})
            );
        }
    }
}

1;
