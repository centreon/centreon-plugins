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

package centreon::common::powershell::exchange::services;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::powershell;

sub get_powershell {
    my (%options) = @_;
    
    my $ps = centreon::common::powershell::exchange::powershell::powershell_init(%options);
    
    $ps .= '
try {
    $ErrorActionPreference = "Stop"    
    $results = Test-ServiceHealth
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Foreach ($result in $results) {
    $servicesrunning = [String]::join(",", $result.ServicesRunning)
    $servicesnotrunning = [String]::join(",", $result.ServicesNotRunning)
    Write-Host "[role=" $result.Role "][requiredservicesrunning=" $result.RequiredServicesRunning "][servicesrunning=" $servicesrunning "][servicesnotrunning=" $servicesnotrunning "]"
}
exit 0
';

    return $ps;
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[role= Mailbox Server Role ][requiredservicesrunning= True ][servicesrunning= IISAdmin,MSExchangeADTopology,MSExchangeSA,... ][servicesnotrunning=  ]
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All role services are ok.");
   
    my $checked = 0;
    $self->{output}->output_add(long_msg => $options{stdout});
    while ($options{stdout} =~ /\[role=(.*?)\]\[requiredservicesrunning=(.*?)\]\[servicesrunning=(.*?)\]\[servicesnotrunning=(.*?)\]/msg) {
        $self->{data} = {};
        ($self->{data}->{role}, $self->{data}->{requiredservicesrunning}, $self->{data}->{servicesrunning}, $self->{data}->{servicesnotrunning}) = 
            ($self->{output}->decode($1), centreon::plugins::misc::trim($2), 
             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4));
        
        $checked++;
        
        my ($status, $message) = ('ok');
        eval {
            local $SIG{__WARN__} = sub { $message = $_[0]; };
            local $SIG{__DIE__} = sub { $message = $_[0]; };
            
            if (defined($self->{option_results}->{critical}) && $self->{option_results}->{critical} ne '' &&
                eval "$self->{option_results}->{critical}") {
                $status = 'critical';
            } elsif (defined($self->{option_results}->{warning}) && $self->{option_results}->{warning} ne '' &&
                     eval "$self->{option_results}->{warning}") {
                $status = 'warning';
            }
        };
        if (defined($message)) {
            $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
        }
        if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $status,
                                        short_msg => sprintf("Role '%s' services problem [services not running: %s]",
                                                             $self->{data}->{role}, $self->{data}->{servicesnotrunning}));
        }
    }
    
    if ($checked == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find informations');
    }
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange services running or not running.

=cut
