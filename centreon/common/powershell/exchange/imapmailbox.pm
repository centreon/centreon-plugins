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

package centreon::common::powershell::exchange::imapmailbox;

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
    $username = "' . $options{mailbox}  . '"
    $password = "' . $options{password}  . '"
    $secstr = New-Object -TypeName System.Security.SecureString
    $password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
    $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr
    
    $results = Test-ImapConnectivity -MailboxCredential $cred
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Foreach ($result in $results) {
    Write-Host "[scenario=" $result.Scenario "][result=" $result.Result "][latency=" $result.Latency.TotalMilliseconds "][[error=" $Result.Error "]]"
}
exit 0
';

    return $ps;
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[scenario= Options ][result= Failure ][latency= 52,00 ][[error=...]]
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "Imap to '" . $options{mailbox} . "' is ok.");
   
    my $checked = 0;
    $self->{output}->output_add(long_msg => $options{stdout});
    while ($options{stdout} =~ /\[scenario=(.*?)\]\[result=(.*?)\]\[latency=(.*?)\]\[\[error=(.*?)\]\]/msg) {
        $self->{data} = {};
        ($self->{data}->{scenario}, $self->{data}->{result}, $self->{data}->{latency}, $self->{data}->{error}) = 
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
                                        short_msg => sprintf("Imap scenario '%s' to '%s' is '%s'",
                                                             $self->{data}->{scenario}, $options{mailbox}, $self->{data}->{result}));
        }
        
        if ($self->{data}->{latency} =~ /^(\d+)/) {
            $self->{output}->perfdata_add(
                label => $self->{data}->{scenario}, unit => 's',
                value => sprintf("%.3f", $1 / 1000),
                min => 0
            );
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

Method to check Exchange 2010 on a specific mailbox.

=cut
