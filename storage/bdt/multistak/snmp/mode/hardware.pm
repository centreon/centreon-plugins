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

package storage::bdt::multistak::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook1} = 'get_system_information';
    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        health => [
            ['ok', 'OK'],
            ['unknown', 'UNKNOWN'],
            ['warning', 'WARNING'],
            ['critical', 'CRITICAL']
        ],
        status => [
            ['OK', 'OK'],
            ['N/A', 'OK'],
            ['.*', 'CRITICAL']
        ]
    };

    $self->{components_path} = 'storage::bdt::multistak::snmp::mode::components';
    $self->{components_module} = ['device', 'module'];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

sub get_system_information {
    my ($self, %options) = @_;

    my $oid_vendor = '.1.3.6.1.4.1.20884.1.1.0'; # bdtDeviceDatVendor
    my $oid_product_id = '.1.3.6.1.4.1.20884.1.2.0'; # bdtDeviceDatVendor
    my $oid_serial = '.1.3.6.1.4.1.20884.1.3.0'; # bdtDeviceDatSerialNum
    my $oid_revision = '.1.3.6.1.4.1.20884.1.4.0'; # bdtDeviceDatSWRevision
    my $result = $options{snmp}->get_leef(
        oids => [
            $oid_vendor, $oid_product_id,
            $oid_serial, $oid_revision
        ]
    );

    my $vendor = defined($result->{$oid_vendor}) ? centreon::plugins::misc::trim($result->{$oid_vendor}) : 'unknown';
    my $product_id = defined($result->{$oid_product_id}) ? centreon::plugins::misc::trim($result->{$oid_product_id}) : 'unknown';
    my $serial = defined($result->{$oid_serial}) ? centreon::plugins::misc::trim($result->{$oid_serial}) : 'unknown';
    my $revision = defined($result->{$oid_revision}) ? centreon::plugins::misc::trim($result->{$oid_revision}) : 'unknown';
    $self->{output}->output_add(
        long_msg => sprintf(
            'vendor: %s, product: %s, serial: %s, revision: %s',
            $vendor, $product_id, $serial, $revision
        )
    );
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'module', 'device'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=disk --filter=psu)
Can also exclude specific instance: --filter=module,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='module,WARNING,N/A'

=back

=cut
