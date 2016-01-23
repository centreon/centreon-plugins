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

package centreon::common::powershell::exchange::2010::databases;

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::powershell::exchange::2010::powershell;

sub get_powershell {
    my (%options) = @_;
    # options: no_ps, no_mailflow, no_mapi
    my $no_mailflow = (defined($options{no_mailflow})) ? 1 : 0;
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    my $no_mapi = (defined($options{no_mapi})) ? 1 : 0;
    my $no_copystatus = (defined($options{no_copystatus})) ? 1 : 0;
    
    return '' if ($no_ps == 1);
    
    my $ps = centreon::common::powershell::exchange::2010::powershell::powershell_init(%options);
    
    $ps .= '
# Check to make sure all databases are mounted
try { 
    $ErrorActionPreference = "Stop"
';

    if (defined($options{filter_database})) {
        $ps .= '
    $MountedDB = Get-MailboxDatabase -Identity "' . $options{filter_database} . '" -Status
';
    } else {
        $ps .= '
    $MountedDB = Get-MailboxDatabase -Status
';
    }

    $ps .= '
} catch {
    Write-Host $Error[0].Exception
    exit 1
}
Foreach ($DB in $MountedDB) {
    Write-Host "[name=" $DB.Name "][server=" $DB.Server "][mounted=" $DB.Mounted "][size=" $DB.DatabaseSize "][asize=" $DB.AvailableNewMailboxSpace "]" -NoNewline
    
';
    
    if (defined($options{filter_database_test}) && $options{filter_database_test} ne '') {
        $ps .= '
        if (!($DB.Name -match "' . $options{filter_database_test} . '")) {
            Write-Host "[Skip extra test]"
            continue
        }
';
    }
    
    $ps .= '
        If ($DB.Mounted -eq $true) {
';

    if ($no_mapi == 0) {
        $ps .= '
            # Test Mapi Connectivity
            $MapiResult = test-mapiconnectivity -Database $DB.Name
            Write-Host "[mapi=" $MapiResult.Result "]" -NoNewline
';
    }
    
    if ($no_mailflow == 0) {
        $ps .= '
            # Test Mailflow
            $MailflowResult = Test-mailflow -Targetdatabase $DB.Name
            Write-Host "[mailflow=" $MailflowResult.testmailflowresult "][latency=" $MailflowResult.MessageLatencyTime.TotalMilliseconds "]" -NoNewline
';
    }
    if ($no_copystatus == 0) {
        $ps .= '
            # Test CopyStatus
            $tmp_name = $DB.Name + "\" + $DB.Server
            $CopyStatusResult = Get-MailboxDatabaseCopyStatus -Identity $tmp_name
            Write-Host "[contentindexstate=" $CopyStatusResult.ContentIndexState "][[contentindexerrormessage=" $CopyStatusResult.ContentIndexErrorMessage "]]" -NoNewline
';
    }

    $ps .= '
        }
    Write-Host ""
}

exit 0
';

    return centreon::plugins::misc::powershell_encoded($ps);
}

sub check_mapi {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{no_mapi})) {
        $self->{output}->output_add(long_msg => '    Skip MAPI test connectivity');
        return ;
    }
    
    if ($options{line} !~ /\[mapi=(.*?)\]/) {
        $self->{output}->output_add(long_msg => '    Skip MAPI test connectivity (information not found)');
        return ;
    }
    
    $self->{data}->{mapi_result} = centreon::plugins::misc::trim($1);
    $self->{output}->output_add(long_msg => "    MAPI Test connectivity: " . $self->{data}->{mapi_result});
    
    my ($status, $message) = ('ok');
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{option_results}->{critical_mapi}) && $self->{option_results}->{critical_mapi} ne '' &&
            eval "$self->{option_results}->{critical_mapi}") {
            $status = 'critical';
        } elsif (defined($self->{option_results}->{warning_mapi}) && $self->{option_results}->{warning_mapi} ne '' &&
                 eval "$self->{option_results}->{warning_mapi}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $status,
                                    short_msg => sprintf("Server '%s' Database '%s' MAPI connectivity is %s",
                                                         $self->{data}->{server}, $self->{data}->{database}, $self->{data}->{mapi_result}));
    }
}

sub check_mailflow {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{no_mailflow})) {
        $self->{output}->output_add(long_msg => '    Skip Mailflow test');
        return ;
    }
    
    if ($options{line} !~ /\[mailflow=(.*?)\]\[latency=(.*?)\]/) {
        $self->{output}->output_add(long_msg => '    Skip Mailflow test (information not found)');
        return ;
    }
    
    $self->{data}->{mailflow_result} = centreon::plugins::misc::trim($1);
    my $latency = centreon::plugins::misc::trim($2);
    $self->{output}->output_add(long_msg => "    Mailflow Test: " . $self->{data}->{mailflow_result});
    
    my ($status, $message) = ('ok');
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{option_results}->{critical_mailflow}) && $self->{option_results}->{critical_mailflow} ne '' &&
            eval "$self->{option_results}->{critical_mailflow}") {
            $status = 'critical';
        } elsif (defined($self->{option_results}->{warning_mailflow}) && $self->{option_results}->{warning_mailflow} ne '' &&
                 eval "$self->{option_results}->{warning_mailflow}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $status,
                                    short_msg => sprintf("Server '%s' Database '%s' Mailflow test is %s",
                                                         $self->{data}->{server}, $self->{data}->{database}, $self->{data}->{mailflow_result}));
    }
    
    if ($latency =~ /^(\d+)/) {
        $self->{output}->perfdata_add(label => 'latency_' . $self->{data}->{server} . '_' . $self->{data}->{database}, unit => 's',
                                      value => sprintf("%.3f", $1 / 1000),
                                      min => 0);
    }
}

sub check_copystatus {
    my ($self, %options) = @_;
    
    if (defined($self->{option_results}->{no_copystatus})) {
        $self->{output}->output_add(long_msg => '    Skip copy status test');
        return ;
    }
    
    if ($options{line} !~ /\[contentindexstate=(.*?)\]\[\[contentindexerrormessage=(.*?)\]\]/) {
        $self->{output}->output_add(long_msg => '    Skip copystatus test (information not found)');
        return ;
    }
    
    ($self->{data}->{copystatus_indexstate}, $self->{data}->{copystatus_indexerror}) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));
    $self->{output}->output_add(long_msg => "    Copystatus state : " . $self->{data}->{copystatus_indexstate});
    
    my ($status, $message) = ('ok');
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($self->{option_results}->{critical_copystatus}) && $self->{option_results}->{critical_copystatus} ne '' &&
            eval "$self->{option_results}->{critical_copystatus}") {
            $status = 'critical';
        } elsif (defined($self->{option_results}->{warning_copystatus}) && $self->{option_results}->{warning_copystatus} ne '' &&
                 eval "$self->{option_results}->{warning_copystatus}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }
    if (!$self->{output}->is_status(value => $status, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(severity => $status,
                                    short_msg => sprintf("Server '%s' Database '%s' copystatus state is %s [error: %s]",
                                                         $self->{data}->{server}, $self->{data}->{database}, $self->{data}->{copystatus_indexstate}, $self->{data}->{copystatus_indexerror}));
    }
}

sub check {
    my ($self, %options) = @_;
    # options: stdout
    
    # Following output:
    #[name= Mailbox Database 0975194476 ][server= SRVI-WIN-TEST ][mounted= True ][size= 136.1 MB (142,671,872 bytes) ][asize= 124.4 MB (130,482,176 bytes) ][mapi= Success ][mailflow= Success ][latency= 50,00 ]
    #...
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Databases are mounted');
    if (!defined($self->{option_results}->{no_mapi})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'MAPI Connectivities are ok');
    }
    if (!defined($self->{option_results}->{no_mailflow})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'Mailflow test are ok');
    }
    
    my $checked = 0;
    foreach my $line (split /\n/, $options{stdout}) {
        next if ($line !~ /^\[name=(.*?)\]\[server=(.*?)\]\[mounted=(.*?)\]\[size=(.*?)\]\[asize=(.*?)\]/);
        $checked++;
        $self->{data} = {};
        ($self->{data}->{database}, $self->{data}->{server}, $self->{data}->{mounted}, $self->{data}->{size}, $self->{data}->{asize}) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));

        $self->{output}->output_add(long_msg => sprintf("Test database '%s' server '%s':", $self->{data}->{database}, $self->{data}->{server}));
        if ($self->{data}->{asize} =~ /\((.*?)\s*bytes/) {
            my $free_bytes = $1;
            $free_bytes =~ s/[.,]//g;
            
            my $total_bytes; 
            if ($self->{data}->{size} =~ /\((.*?)\s*bytes/) {
                $total_bytes = $1;
                $total_bytes =~ s/[.,]//g;
                my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_bytes);
                $self->{output}->output_add(long_msg => sprintf("    Size %s", $total_value . ' ' . $total_unit));
            }
            my $used_bytes = $total_bytes - $free_bytes;
            
            $self->{output}->perfdata_add(label => 'used_' . $self->{data}->{database}, unit => 'B',
                                          value => $used_bytes,
                                          min => 0, max => $total_bytes);
            my ($used_value, $used_unit) = $self->{perfdata}->change_bytes(value => $used_bytes);
            $self->{output}->output_add(long_msg => sprintf("    Used Size %s", $used_value . ' ' . $used_unit));
        }
        
        
        # Check mounted
        if ($self->{data}->{mounted} =~ /False/i) {
            $self->{output}->output_add(long_msg => sprintf("    not mounted\n   Skip mapi/mailflow test"));
            $self->{output}->output_add(severity => 'CRITICAL',
                                        short_msg => sprintf("Database '%s' server '%s' is not mounted", $self->{data}->{database}, $self->{data}->{server}));
            next;
        }
        $self->{output}->output_add(long_msg => sprintf("    mounted"));
        
        check_mapi($self, line => $line);
        check_mailflow($self, line => $line);
        check_copystatus($self, line => $line);
    }
    
    if ($checked == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot find informations');
    }
}

1;

__END__

=head1 DESCRIPTION

Method to check Exchange 2010 databases.

=cut