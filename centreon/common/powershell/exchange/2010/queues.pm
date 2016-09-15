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

package centreon::common::powershell::exchange::2010::queues;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::2010::powershell;

sub get_powershell {
    my (%options) = @_;
    # options: no_ps
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    
    return '' if ($no_ps == 1);
    
    my $ps = centreon::common::powershell::exchange::2010::powershell::powershell_init(%options);
    
    $ps .= '
try {
    $ErrorActionPreference = "Stop"    
    $results = Get-Queue
} catch {
    Write-Host $Error[0].Exception
    exit 1
}

Foreach ($result in $results) {
    Write-Host "[identity=" $result.Identity "][deliverytype=" $result.DeliveryType "][status=" $result.Status "][isvalid=" $result.IsValid "][messagecount=" $result.MessageCount "][[error=" $result.LastError "]]"
}
exit 0
';

    return centreon::plugins::misc::powershell_encoded($ps);
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[identity=  ][deliverytype= SmtpRelayWithinAdSite][status= Active ][isvalid= Yes][messagecount= 1 ][[error=...]]
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All Queues are ok.");
   
    my $checked = 0;
    $self->{output}->output_add(long_msg => $options{stdout});
    
    $self->{perfdatas_queues} = {};
    while ($options{stdout} =~ /\[identity=(.*?)\]\[deliverytype=(.*?)\]\[status=(.*?)\]\[isvalid=(.*?)\]\[messagecount=(.*?)\]\[\[error=(.*?)\]\]/msg) {
        $self->{data} = {};
        ($self->{data}->{identity}, $self->{data}->{deliverytype}, $self->{data}->{status}, $self->{data}->{isvalid}, $self->{data}->{messagecount}, $self->{data}->{error}) = 
            ($self->{output}->to_utf8($1), centreon::plugins::misc::trim($2), 
             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5), centreon::plugins::misc::trim($6));
        
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
                                        short_msg => sprintf("Queue '%s' status is '%s' [last error: %s]",
                                                             $self->{data}->{identity}, $self->{data}->{status}, $self->{data}->{error}));
        }
        
        if ($self->{data}->{messagecount} =~ /^(\d+)/) {
            my $num = $1;
            my $identity = $self->{data}->{identity};
            
            $identity = $1 if ($self->{data}->{identity} =~ /^(.*\\)[0-9]+$/);
            $self->{perfdatas_queues}->{$identity} = 0 if (!defined($self->{perfdatas_queues}->{$identity})); 
            $self->{perfdatas_queues}->{$identity} += $num;
        }
    }
    
    foreach (keys %{$self->{perfdatas_queues}}) {
        $self->{output}->perfdata_add(label => 'queue_length_' . $_,
                                      value => $self->{perfdatas_queues}->{$_},
                                      min => 0);
    }
    
    if ($checked == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find informations');
    }
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange 2010 queues.

=cut