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

package network::stormshield::snmp::mode::properties;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    return $self;
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my $oid_system_name = '.1.3.6.1.4.1.11256.1.18.4.0';
    my $oid_system_node_name = '.1.3.6.1.4.1.11256.1.18.16.0';
    my $oid_bios_version = '.1.3.6.1.4.1.11256.1.18.17.0';
    my $oid_model = '.1.3.6.1.4.1.11256.1.18.1.0';
    my $oid_version = '.1.3.6.1.4.1.11256.1.18.2.0';
    my $oid_serial_number = '.1.3.6.1.4.1.11256.1.18.3.0';
    my $oid_date = '.1.3.6.1.4.1.11256.1.10.1.0';
    my $oid_uptime = '.1.3.6.1.4.1.11256.1.10.2.0';
    
    my $oids = [ $oid_system_name, $oid_system_node_name, $oid_bios_version, $oid_model, $oid_version, $oid_serial_number, $oid_date, $oid_uptime ];

    my $snmp_result = $options{snmp}->get_leef(
        oids => $oids,
        nothing_quit => 1
    );

    my $system_name = $snmp_result->{$oid_system_name};
    my $system_node_name = $snmp_result->{$oid_system_node_name};
    my $bios_version = $snmp_result->{$oid_bios_version};
    my $model = $snmp_result->{$oid_model};
    my $version = $snmp_result->{$oid_version};
    my $serial_number = $snmp_result->{$oid_serial_number};
    my $date = $snmp_result->{$oid_date};
    my $uptime = $snmp_result->{$oid_uptime};

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf("Click to see more infos: ...\nSystem Name: %s \nSystem node Name: %s \nModel: %s \nSerial Number: %s \nVersion: %s \nBios Version: %s \nDate: %s \nUptime: %s",
            $system_name, $system_node_name, $model, $serial_number, $version, $bios_version, $date, $uptime
        )
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

This mode retrieves and displays basic properties of the Stormshield device such as system name, model, version, serial number, and date.

=over 8

=item B<--warning-*> B<--critical-*>

These options are not applicable for this mode as it does not generate performance data or thresholds.

=back

=cut