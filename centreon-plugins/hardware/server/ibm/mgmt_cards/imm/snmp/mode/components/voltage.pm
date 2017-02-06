#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::voltage;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{voltages} = {name => 'voltages', total => 0};
    $self->{output}->output_add(long_msg => "Checking voltages");
    return if ($self->check_exclude('voltages'));
    
    my $oid_voltEntry = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1';
    my $oid_voltDescr = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.2';
    my $oid_voltReading = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.3';
    my $oid_voltCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.6';
    my $oid_voltNonCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.7';
    my $oid_voltCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.9';
    my $oid_voltNonCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.10';
    
    my $result = $self->{snmp}->get_table(oid => $oid_voltEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_voltDescr\.(\d+)$/);
        my $instance = $1;
    
        my $volt_descr = centreon::plugins::misc::trim($result->{$oid_voltDescr . '.' . $instance});
        my $volt_value = $result->{$oid_voltReading . '.' . $instance};
        my $volt_crit_high = $result->{$oid_voltCritLimitHigh . '.' . $instance};
        my $volt_warn_high = $result->{$oid_voltNonCritLimitHigh . '.' . $instance};
        my $volt_crit_low = $result->{$oid_voltCritLimitLow . '.' . $instance};
        my $volt_warn_low = $result->{$oid_voltNonCritLimitLow . '.' . $instance};
        
        my $warn_threshold = '';
        $warn_threshold = $volt_warn_low . ':' if ($volt_warn_low != 0);
        $warn_threshold .= $volt_warn_high if ($volt_warn_high != 0);
        my $crit_threshold = '';
        $crit_threshold = $volt_crit_low . ':' if ($volt_crit_low != 0);
        $crit_threshold .= $volt_crit_high if ($volt_crit_high != 0);
        
        $self->{perfdata}->threshold_validate(label => 'warning_' . $instance, value => $warn_threshold);
        $self->{perfdata}->threshold_validate(label => 'critical_' . $instance, value => $crit_threshold);
        
        my $exit = $self->{perfdata}->threshold_check(value => $volt_value, threshold => [ { label => 'critical_' . $instance, 'exit_litteral' => 'critical' }, { label => 'warning_' . $instance, exit_litteral => 'warning' } ]);
        
        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' value is %s.", 
                                    $volt_descr, $volt_value));
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' value is %s", $volt_descr, $volt_value));
        }
        
        $self->{output}->perfdata_add(label => 'volt_' . $volt_descr,
                                      value => $volt_value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $instance),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $instance),
                                      );
    }
}

1;