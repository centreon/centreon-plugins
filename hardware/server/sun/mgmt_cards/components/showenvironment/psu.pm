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

package hardware::server::sun::mgmt_cards::components::showenvironment::psu;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));
    
    if ($self->{stdout} =~ /^Power Supplies.*?\n.*?\n.*?\n.*?\n(.*?)\n\n/ims && defined($1)) {
        #Supply  Status          Underspeed  Overtemp  Overvolt  Undervolt  Overcurrent
        #------------------------------------------------------------------------------
        #PS0     OK              OFF         OFF       OFF       OFF        OFF

        foreach (split(/\n/, $1)) {
            next if (! /^([^\s]+)\s+([^\s].*?)(\s{2}|$)/);
            my $ps_status = defined($2) ? $2 : 'unknown';
            my $ps_name = defined($1) ? $1 : 'unknown';
            
            next if ($self->check_filter(section => 'psu', instance => $ps_name));
            
            $self->{components}->{psu}->{total}++;
            $self->{output}->output_add(long_msg => "Power Supplies Sensor Status '" . $ps_name . "' is " . $ps_status);
            my $exit = $self->get_severity(section => 'psu', value => $ps_status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => "Power Supplies Sensor Status '" . $ps_name . "' is " . $ps_status);
            }
        }
    }
}

1;
