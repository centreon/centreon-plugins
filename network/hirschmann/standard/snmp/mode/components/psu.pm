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

package network::hirschmann::standard::snmp::mode::components::psu;

use strict;
use warnings;

my %map_psu_status = (
    1 => 'ok', 
    2 => 'failed', 
    3 => 'notInstalled', 
    4 => 'unknown',
);
my %map_psu_state = (
    1 => 'error', 2 => 'ignore',
);
my %map_psid = (
    1 => 9, # hmDevMonSensePS1State
    2 => 10, # hmDevMonSensePS2State
    3 => 14, # hmDevMonSensePS3State
    4 => 15, # hmDevMonSensePS4State
    5 => 17, # hmDevMonSensePS5State
    6 => 18, # hmDevMonSensePS6State
    7 => 19, # hmDevMonSensePS7State
    8 => 20, # hmDevMonSensePS8State
);

# In MIB 'hmpriv.mib'
my $mapping = {
    hmPSState => { oid => '.1.3.6.1.4.1.248.14.1.2.1.3', map => \%map_psu_status },
};
my $oid_hmDevMonConfigEntry = '.1.3.6.1.4.1.248.14.2.12.3.1';

sub load {
    my ($self) = @_;
    
    push @{$self->{request}}, { oid => $mapping->{hmPSState}->{oid} }, { oid => $oid_hmDevMonConfigEntry };
}

sub check {
    my ($self) = @_;
    
    $self->{output}->output_add(long_msg => "Checking power supplies");
    $self->{components}->{psu} = { name => 'psus', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'psu'));

    foreach my $oid ($self->{snmp}->oid_lex_sort(keys %{$self->{results}->{$mapping->{hmPSState}->{oid}}})) {
        next if ($oid !~ /^$mapping->{hmPSState}->{oid}\.(\d+)\.(\d+)$/);
        my $instance = $1 . '.' . $2;
        my ($sysid, $psid) = ($1, $2);
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$mapping->{hmPSState}->{oid}}, instance => $instance);

        if (defined($map_psid{$psid}) &&
            defined($self->{results}->{$oid_hmDevMonConfigEntry}->{$oid_hmDevMonConfigEntry . '.' . $map_psid{$psid} . '.' . $sysid})) {
            my $state = $map_psu_state{$self->{results}->{$oid_hmDevMonConfigEntry}->{$oid_hmDevMonConfigEntry . '.' . $map_psid{$psid} . '.' . $sysid}};
            $result->{hmPSState} = 'ignore' if ($state eq 'ignore');
        }

        next if ($self->check_filter(section => 'psu', instance => $instance));
        next if ($result->{hmPSState} =~ /notInstalled/i && 
            $self->absent_problem(section => 'psu', instance => $instance));
        $self->{components}->{psu}->{total}++;

        $self->{output}->output_add(long_msg => sprintf("Power supply '%s' status is %s [instance: %s].",
                                    $instance, $result->{hmPSState},
                                    $instance
                                    ));
        my $exit = $self->get_severity(section => 'psu', value => $result->{hmPSState});
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity =>  $exit,
                                        short_msg => sprintf("Power supply '%s' status is %s",
                                                             $instance, $result->{hmPSState}));
        }
    }
}

1;
