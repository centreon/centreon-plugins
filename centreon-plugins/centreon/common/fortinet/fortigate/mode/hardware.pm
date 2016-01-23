#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::fortinet::fortigate::mode::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

my %alarm_map = (
    0 => 'off',
    1 => 'on',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_sysDescr = '.1.3.6.1.2.1.1.1.0';
    my $oid_fgSysVersion = '.1.3.6.1.4.1.12356.101.4.1.1.0';
    my $oid_fgHwSensorCount = '.1.3.6.1.4.1.12356.101.4.3.1.0';
    my $result = $self->{snmp}->get_leef(oids => [$oid_sysDescr, $oid_fgSysVersion, $oid_fgHwSensorCount], nothing_quit => 1);
    
    $self->{output}->output_add(long_msg => sprintf("[System: %s] [Firmware: %s]", $result->{$oid_sysDescr}, 
                                                    defined($result->{$oid_fgSysVersion}) ? $result->{$oid_fgSysVersion} : 'unknown'));
    if (!defined($result->{$oid_fgHwSensorCount}) || $result->{$oid_fgHwSensorCount} == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "No hardware sensors available.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All sensors are ok.");
    
    my $oid_fgHwSensorEntry = '.1.3.6.1.4.1.12356.101.4.3.2.1';
    my $oid_fgHwSensorEntAlarmStatus = '.1.3.6.1.4.1.12356.101.4.3.2.1.4';
    my $oid_fgHwSensorEntName = '.1.3.6.1.4.1.12356.101.4.3.2.1.2';
    my $oid_fgHwSensorEntValue = '.1.3.6.1.4.1.12356.101.4.3.2.1.3';
    $result = $self->{snmp}->get_table(oid => $oid_fgHwSensorEntry);
    
    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_fgHwSensorEntName\.(\d+)/);
        my $index = $1;
        my $name = centreon::plugins::misc::trim($result->{$oid_fgHwSensorEntName . '.' . $index});
        my $value = $result->{$oid_fgHwSensorEntValue . '.' . $index};
        my $alarm_status = centreon::plugins::misc::trim($result->{$oid_fgHwSensorEntAlarmStatus . '.' . $index});
        
        $self->{output}->output_add(long_msg => sprintf("Sensor %s alarm status is %s [value: %s]", 
                                                        $name, $alarm_map{$alarm_status}, $value));
        if ($alarm_map{$alarm_status} eq 'on') {
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Sensor %s alarm status is %s [value: %s]", 
                                                             $name, $alarm_map{$alarm_status}, $value));
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check fortigate hardware sensors (FORTINET-FORTIGATE-MIB).
It's deprecated. Work only for 'FortiGate-5000 Series Chassis'.

=over 8

=back

=cut