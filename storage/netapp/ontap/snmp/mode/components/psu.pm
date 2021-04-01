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

package storage::netapp::ontap::snmp::mode::components::psu;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

my $oid_enclChannelShelfAddr = '.1.3.6.1.4.1.789.1.21.1.2.1.3';
my $oid_enclPowerSuppliesPresent = '.1.3.6.1.4.1.789.1.21.1.2.1.13';
my $oid_enclPowerSuppliesFailed = '.1.3.6.1.4.1.789.1.21.1.2.1.15';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $oid_enclPowerSuppliesPresent }, { oid => $oid_enclPowerSuppliesFailed };
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = {name => 'psus', total => 0, skip => 0};
    return if ($self->check_filter(section => 'psu'));

    for (my $i = 1; $i <= $self->{number_shelf}; $i++) {
        my $shelf_addr = $self->{shelf_addr}->{$oid_enclChannelShelfAddr . '.' . $i};
        my $present = $self->{results}->{$oid_enclPowerSuppliesPresent}->{$oid_enclPowerSuppliesPresent . '.' . $i};
        my $failed = $self->{results}->{$oid_enclPowerSuppliesFailed}->{$oid_enclPowerSuppliesFailed . '.' . $i};
        
        foreach my $num (split /,/, $present) {
            $num = centreon::plugins::misc::trim($num);
            next if ($num !~ /[0-9]/);
            
            next if ($self->check_filter(section => 'psu', instance => $shelf_addr . '.' . $num));
            $self->{components}->{psu}->{total}++;

            my $status = 'ok';
            if ($failed =~ /(^|,|\s)$num(,|\s|$)/) {
                $status = 'failed';
            }

            $self->{output}->output_add(long_msg => sprintf("Shelve '%s' PSU '%s' is '%s'", 
                                        $shelf_addr, $num, $status));
            my $exit = $self->get_severity(section => 'psu', value => $status);
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(severity => $exit,
                                            short_msg => sprintf("Shelve '%s' PSU '%s' is '%s'", $shelf_addr, $num, $status));
            }
        }
    }
}

1;
