#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package hardware::pdu::schleifenbauer::gateway::snmp::mode::sensors;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use hardware::pdu::schleifenbauer::gateway::snmp::mode::components::resources qw($oid_pdumeasuresEntry $oid_deviceName);

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_overload_check_section_option} = '^(temperature|humidity|contact)$';
    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|humidity|contact)$';

    $self->{cb_hook2} = 'snmp_execute';

    $self->{components_path} = 'hardware::pdu::schleifenbauer::gateway::snmp::mode::components';
    $self->{components_module} = ['humidity', 'temperature', 'contact'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [
        { oid => $oid_deviceName },
        { oid => $oid_pdumeasuresEntry },
    ]);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

1;

__END__

=head1 MODE

Check sensors.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'temperature', 'humidity', 'contact'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=temperature --filter=contact)
Can also exclude specific instance: --filter=temperature,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--warning>

Set warning threshold for 'temperature', 'humidity', 'contact' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for 'temperature', 'humidity', 'contact' (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,50'

=back

=cut
    
