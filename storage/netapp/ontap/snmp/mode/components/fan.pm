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

package storage::netapp::ontap::snmp::mode::components::fan;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclFansPresent = '.1.3.6.1.4.1.789.1.21.1.2.1.17';
my $oid_enclFansFailed = '.1.3.6.1.4.1.789.1.21.1.2.1.18';
my $oid_enclFansSpeed = '.1.3.6.1.4.1.789.1.21.1.2.1.62';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclFansPresent }, { oid => $oid_enclFansFailed },
        { oid => $oid_enclFansSpeed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking fans");
    $self->{components}->{fan} = {name => 'fans', total => 0, skip => 0};
    return if ($self->check_filter(section => 'fan'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my $present = $self->{results}->{$oid_enclFansPresent}->{$oid_enclFansPresent . '.' . $i};
        my $failed = $self->{results}->{$oid_enclFansFailed}->{$oid_enclFansFailed . '.' . $i};
        my @current_speed = defined($self->{results}->{$oid_enclFansSpeed}->{$oid_enclFansSpeed . '.' . $i}) ? split /,/, $self->{results}->{$oid_enclFansSpeed}->{$oid_enclFansSpeed . '.' . $i} : ();
        
        foreach my $num (split /,/, $present) {
            $num = centreon::plugins::misc::trim($num);
            next if ($num !~ /[0-9]/);
            my $current_value = (defined($current_speed[$num - 1]) && $current_speed[$num - 1] =~ /(^|\s)([0-9]+)/) ? $2 : '';
            
            next if ($self->check_filter(section => 'fan', instance => $shelf_addr . '.' . $num));
            $self->{components}->{fan}->{total}++;

            my $status = 'ok';
            if ($failed =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'failed';
            }

            $self->{output}->output_add(long_msg => sprintf("Shelve '%s' Fan '%s' is '%s'", 
                                        $shelf_addr, $num, $status));
            my $exit = $self->get_severity(section => 'fan', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Shelve '%s' Fan '%s' is '%s'", $shelf_addr, $num, $status));
            }
            
            if ($current_value ne '') {
                my ($exit, $warn, $crit) = $self->get_severity_numeric(section => 'fan', instance => $shelf_addr . '.' . $num, value => $current_value);
                if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                    $self->{output}->output_add(severity => $exit,
                                                short_msg => sprintf("Shelve '%s' Fan '%s' speed is '%s'", $shelf_addr, $num, $current_value));
                }
                
                $self->{output}->perfdata_add(
                    label => "speed", unit => 'rpm',
                    nlabel => 'hardware.fan.speed.rpm',
                    instances => [$shelf_addr, $num],
                    value => $current_value,
                    warning => $warn,
                    critical => $crit,
                    min => 0
                );
            }
        }
    }
}

1;
