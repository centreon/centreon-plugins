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

package hardware::server::dell::cmc::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;
use centreon::plugins::misc;

sub set_system {
    my ($self, %options) = @_;

    $self->{regexp_threshold_numeric_check_section_option} = '^(temperature|psu\.(voltage|power|current)|chassis\.(power|current))$';
    
    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {        
        health => [
            ['other', 'UNKNOWN'],
            ['unknown', 'UNKNOWN'],
            ['ok', 'OK'],
            ['nonCritical', 'WARNING'],
            ['critical', 'CRITICAL'],
            ['nonRecoverable', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::server::dell::cmc::snmp::mode::components';
    $self->{components_module} = ['health', 'chassis', 'temperature', 'psu'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{request});
    $self->display_system_information();
}

sub display_system_information {
    my ($self, %options) = @_;

    my $oid_drsProductShortName = '.1.3.6.1.4.1.674.10892.2.1.1.2.0';
    my $oid_drsChassisServiceTag = '.1.3.6.1.4.1.674.10892.2.1.1.6.0';
    my $oid_drsFirmwareVersion = '.1.3.6.1.4.1.674.10892.2.1.2.1.0';

    my $snmp_result = $self->{snmp}->get_leef(oids => [$oid_drsProductShortName, $oid_drsChassisServiceTag, $oid_drsFirmwareVersion]);
    $self->{output}->output_add(
        long_msg => sprintf("Product Name: %s, Service Tag: %s, Firmware Version: %s", 
            defined($snmp_result->{$oid_drsProductShortName}) ? centreon::plugins::misc::trim($snmp_result->{$oid_drsProductShortName}) : 'unknown', 
            defined($snmp_result->{$oid_drsChassisServiceTag}) ? $snmp_result->{$oid_drsChassisServiceTag} : 'unknown',
            defined($snmp_result->{$oid_drsFirmwareVersion}) ? $snmp_result->{$oid_drsFirmwareVersion} : 'unknown'
        )
    );
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check Hardware (Health, Temperatures, Power supplies metrics and chassis metrics).

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'health', 'temperature', 'chassis', 'psu'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=fan)
Can also exclude specific instance: --filter=health,2

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='health,CRITICAL,^(?!(ok)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,regexp,threshold)
Example: --warning='temperature,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,regexp,threshold)
Example: --critical='temperature,.*,40'

=back

=cut
