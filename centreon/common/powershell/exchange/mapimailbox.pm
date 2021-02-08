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

package centreon::common::powershell::exchange::mapimailbox;

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
    $mapi = test-mapiconnectivity -Identity "' . $options{mailbox} . '"
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Write-Host "[name=" $mapi.Database "][server=" $mapi.Server "][result=" $mapi.Result "][error=" $mapi.Error "]"

exit 0
';

    return $ps;
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][result= Success ][error=...]
   
    if ($options{stdout} !~ /^\[name=(.*?)\]\[server=(.*?)\]\[result=(.*?)\]\[error=(.*)\]$/) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find informations');
        return ;
    }
    $self->{data} = {};
    ($self->{data}->{database}, $self->{data}->{server}, $self->{data}->{result}, $self->{data}->{error}) = 
        (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
         centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4));
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "MAPI connection to '" . $options{mailbox} . "' is '" . $self->{data}->{result} . "'.");
    $self->{output}->output_add(long_msg => sprintf("Database: %s, Server: %s\nError: %s",
                                                    $self->{data}->{database}, $self->{data}->{server}, $self->{data}->{error}));
    
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
                                    short_msg => sprintf("MAPI connection to '%s' is '%s'",
                                                         $options{mailbox}, $self->{data}->{result}));
    }
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange mapi connection on a specific mailbox.

=cut
