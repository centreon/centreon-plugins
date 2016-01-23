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

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::temperature;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{temperatures} = {name => 'temperatures', total => 0};
    $self->{output}->output_add(long_msg => "Checking temperatures");
    return if ($self->check_exclude('temperatures'));
    
    my $oid_tempEntry = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1';
    my $oid_tempDescr = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.2';
    my $oid_tempReading = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.3';
    my $oid_tempCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.6';
    my $oid_tempNonCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.7';
    my $oid_tempCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.9';
    my $oid_tempNonCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.1.2.1.10';
    
    my $result = $self->{snmp}->get_table(oid => $oid_tempEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_tempDescr\.(\d+)$/);
        my $instance = $1;
    
        my $temp_descr = centreon::plugins::misc::trim($result->{$oid_tempDescr . '.' . $instance});
        my $temp_value = $result->{$oid_tempReading . '.' . $instance};
        my $temp_crit_high = $result->{$oid_tempCritLimitHigh . '.' . $instance};
        my $temp_warn_high = $result->{$oid_tempNonCritLimitHigh . '.' . $instance};
        my $temp_crit_low = $result->{$oid_tempCritLimitLow . '.' . $instance};
        my $temp_warn_low = $result->{$oid_tempNonCritLimitLow . '.' . $instance};
        
        my $warn_threshold = '';
        $warn_threshold = $temp_warn_low . ':' . $temp_warn_high;
        my $crit_threshold = '';
        $crit_threshold = $temp_crit_low . ':' . $temp_crit_high;
        
        $self->{perfdata}->threshold_validate(label => 'warning_' . $instance, value => $warn_threshold);
        $self->{perfdata}->threshold_validate(label => 'critical_' . $instance, value => $crit_threshold);
        
        my $exit = $self->{perfdata}->threshold_check(value => $temp_value, threshold => [ { label => 'critical_' . $instance, 'exit_litteral' => 'critical' }, { label => 'warning_' . $instance, exit_litteral => 'warning' } ]);
        
        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Temperature '%s' value is %s C.", 
                                    $temp_descr, $temp_value));
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Temperature '%s' value is %s C", $temp_descr, $temp_value));
        }
        
        $self->{output}->perfdata_add(label => 'temp_' . $temp_descr, unit => 'C',
                                      value => $temp_value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $instance),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $instance),
                                      );
    }
}

1;