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

package centreon::common::powershell::exchange::replicationhealth;

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
    $results = Test-ReplicationHealth
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Foreach ($result in $results) {
    Write-Host "[server=" $result.Server "][check=" $result.Check "][result=" $result.Result "][isvalid=" $result.IsValid "][[error=" $result.Error "]]"
}
exit 0
';

    return $ps;
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[Server= XXXX ][check= ReplayService][result= Passed ][isvalid= Yes][[error=...]]
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All replication health tests are ok.");
   
    my $checked = 0;
    $self->{output}->output_add(long_msg => $options{stdout});
    while ($options{stdout} =~ /\[server=(.*?)\]\[check=(.*?)\]\[result=(.*?)\]\[isvalid=(.*?)\]\[\[error=(.*?)\]\]/msg) {
        $self->{data} = {};
        ($self->{data}->{server}, $self->{data}->{check}, $self->{data}->{result}, $self->{data}->{isvalid},  $self->{data}->{error}) = 
            ($self->{output}->decode($1), centreon::plugins::misc::trim($2), 
             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));
        
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
                                        short_msg => sprintf("Replication test '%s' status on '%s' is '%s' [error: %s]",
                                                             $self->{data}->{check}, $self->{data}->{server}, $self->{data}->{result}, $self->{data}->{error}));
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

Method to check Exchange queues.

=cut
