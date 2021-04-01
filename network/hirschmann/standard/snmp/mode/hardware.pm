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

package network::hirschmann::standard::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(?:temperature)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{thresholds} = {
        fan => [
            #hios
            ['not-available', 'OK'],
            ['available-and-ok', 'OK'],
            ['available-but-failure', 'CRITICAL'],

            # classic
            ['ok', 'OK'],
            ['failed', 'CRITICAL']
        ],
        psu => [
            # classic
            ['ok', 'OK'],
            ['failed', 'CRITICAL'],
            ['notInstalled', 'OK'],
            ['unknown', 'UNKNOWN'],
            ['ignore', 'OK'],

            # hios
            ['present', 'OK'],
            ['defective', 'CRITICAL']
        ],
        led => [
            ['off', 'OK'],
            ['green', 'OK'],
            ['yellow', 'WARNING'],
            ['red', 'CRITICAL']
        ]
    };

    $self->{myrequest} = {
        classic => [],
        hios => []
    };

    $self->{components_path} = 'network::hirschmann::standard::snmp::mode::components';
    $self->{components_module} = ['fan', 'led', 'psu', 'temperature'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};

    my $hios_serial = '.1.3.6.1.4.1.248.11.10.1.1.3.0'; # hm2DevMgmtSerialNumber
    my $classic_version = '.1.3.6.1.4.1.248.14.1.1.2.0'; # hmSysVersion
    my $snmp_result = $self->{snmp}->get_leef(
        oids => [ $hios_serial, $classic_version ],
        nothing_quit => 1
    );

    $self->{os_type} = 'unknown';
    $self->{results} = {};
    if (defined($snmp_result->{$classic_version})) {
        $self->{os_type} = 'classic';
        $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{myrequest}->{classic});
    } elsif ($snmp_result->{$hios_serial}) {
        $self->{os_type} = 'hios';
        $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{myrequest}->{hios});
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'fan', 'psu', 'temperature', 'led'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan)
Can also exclude specific instance: --filter=fan,1.1

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=psu,1.1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='psu,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
