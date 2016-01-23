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

package hardware::ups::standard::rfc1628::snmp::mode::batterystatus;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my %battery_status = (
    1 => ['unknown', 'UNKNOWN'], 
    2 => ['normal', 'OK'], 
    3 => ['low', 'WARNING'], 
    4 => ['depleted', 'CRITICAL'],
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    my $oid_upsBattery = '.1.3.6.1.2.1.33.1.2';
    my $oid_upsBatteryStatus = '.1.3.6.1.2.1.33.1.2.1.0';
    my $oid_upsEstimatedMinutesRemaining = '.1.3.6.1.2.1.33.1.2.3.0';
    my $oid_upsEstimatedChargeRemaining = '.1.3.6.1.2.1.33.1.2.4.0';
    my $oid_upsBatteryVoltage = '.1.3.6.1.2.1.33.1.2.5.0'; # in dV
    my $oid_upsBatteryCurrent = '.1.3.6.1.2.1.33.1.2.6.0'; # in dA
    my $oid_upsBatteryTemperature = '.1.3.6.1.2.1.33.1.2.7.0'; # in degrees Centigrade
    
    my $result = $self->{snmp}->get_table(oid => $oid_upsBattery, nothing_quit => 1);

    my $current = (defined($result->{$oid_upsBatteryCurrent}) && $result->{$oid_upsBatteryCurrent} =~ /\d/) ? 
        $result->{$oid_upsBatteryCurrent} * 0.1 : 0;
    my $voltage = (defined($result->{$oid_upsBatteryVoltage}) && $result->{$oid_upsBatteryVoltage} =~ /\d/) ? 
        $result->{$oid_upsBatteryVoltage} * 0.1 : 0;
    my $temp = defined($result->{$oid_upsBatteryTemperature}) ? $result->{$oid_upsBatteryTemperature} : 0;
    my $min_remain = (defined($result->{$oid_upsEstimatedMinutesRemaining}) && $result->{$oid_upsEstimatedMinutesRemaining} =~ /\d/) ? 
        $result->{$oid_upsEstimatedMinutesRemaining} : 'unknown';
    my $charge_remain = (defined($result->{$oid_upsEstimatedChargeRemaining}) && $result->{$oid_upsEstimatedChargeRemaining} =~ /\d/) ? 
        $result->{$oid_upsEstimatedChargeRemaining} : 'unknown';
    my $status = defined($result->{$oid_upsBatteryStatus}) ? $result->{$oid_upsBatteryStatus} : 1; # we put unknown ???
  
    $self->{output}->output_add(severity => ${$battery_status{$status}}[1],
                                short_msg => sprintf("Battery status is %s", ${$battery_status{$status}}[0]));
    my $exit_code = 'ok';
    if ($charge_remain ne 'unknown') {
        $exit_code = $self->{perfdata}->threshold_check(value => $charge_remain, 
                                                        threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->perfdata_add(label => 'load', unit => '%',
                                      value => $charge_remain,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
    }
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("Charge remaining: %s%% (%s minutes remaining)", $charge_remain, $min_remain));
    
    if ($current != 0) {
        $self->{output}->perfdata_add(label => 'current', unit => 'A',
                                      value => $current,
                                      );
    }
    if ($voltage != 0) {
        $self->{output}->perfdata_add(label => 'voltage', unit => 'V',
                                      value => $voltage,
                                      );
    }
    if ($temp != 0) {
        $self->{output}->perfdata_add(label => 'temp', unit => 'C',
                                      value => $temp,
                                      );
    }
                                  
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Battery Status and battery charge remaining.

=over 8

=item B<--warning>

Threshold warning in percent of charge remaining.

=item B<--critical>

Threshold critical in percent of charge remaining.

=back

=cut
