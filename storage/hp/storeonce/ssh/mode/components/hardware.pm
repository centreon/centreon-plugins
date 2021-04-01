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

package storage::hp::storeonce::ssh::mode::components::hardware;

use strict;
use warnings;
use centreon::plugins::misc;

sub load {
    my ($self) = @_;
    
    #Name
    #------------------------------------------------------------------
    #hp80239e8624-1
    #     Dev-id                 = 31343337-3338-5A43-3235-323430375631
    #     Status                 = OK
    #     message                = -
    #     type                   = server
    #     model                  = ProLiant DL380p Gen8
    #     serialNumber           = CZ252407V1
    #     firmwareVersion        = P70 07/01/2015
    #     location               = -
    #     warrantySerialNumber   = CZ35283EK4
    #     warrantyPartNumber     = BB896A
    #     SKU                    = 734183-B21
    #
    #hp80239e8624-2
    #     Dev-id                 = 31343337-3338-5A43-3235-323431303648
    #     Status                 = OK
    #     message                = -
    #     type                   = server
    #     model                  = ProLiant DL380p Gen8
    #     serialNumber           = CZ2524106H
    #     firmwareVersion        = P70 07/01/2015
    #     location               = -
    #     warrantySerialNumber   = CZ35283EK4
    #     warrantyPartNumber     = BB896A
    #     SKU                    = 734183-B21

    push @{$self->{commands}}, "hardware show status details";
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking hardwares");
    $self->{components}->{hardware} = {name => 'hardwares', total => 0, skip => 0};
    return if ($self->check_filter(section => 'hardware'));
    
    return if ($self->{result} !~ /[>#]\s*hardware show status details(.*?)\n[>#]/msi);
    my $content = $1;
    
    while ($content =~ /^(\S+[^\n]*?)\n\s+(.*?)\n\s*?\n/msgi) {
        my ($name, $details) = (centreon::plugins::misc::trim($1), $2);
        
        $details =~ /type.*?=\s*(.*?)\n/msi;
        my $type = centreon::plugins::misc::trim($1);
        $details =~ /Status.*?=\s*(.*?)\n/msi;
        my $status = centreon::plugins::misc::trim($1);
        $details =~ /Dev-id.*?=\s*(.*?)\n/msi;
        my $dev_id = centreon::plugins::misc::trim($1);
        
        next if ($self->check_filter(section => 'hardware', instance => $type . '.' . $dev_id));
        $self->{components}->{hardware}->{total}++;
        
        $self->{output}->output_add(long_msg => sprintf("%s '%s' status is '%s' [instance: %s, name: %s].",
                                    $type, $dev_id, $status,
                                    $type . '.' . $dev_id, $name
                                    ));
        my $exit = $self->get_severity(section => 'hardware', instance => $type . '.' . $dev_id, value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("%s '%s' status is '%s'",
                                                             $type, $dev_id, $status));
        }        
    }
}

1;