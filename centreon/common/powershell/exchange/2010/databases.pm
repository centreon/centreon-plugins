################################################################################
# Copyright 2005-2014 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package centreon::common::powershell::exchange::2010::databases;

use strict;
use warnings;
use centreon::plugins::misc;

sub get_powershell {
    my (%options) = @_;
    # options: no_ps, no_mailflow, no_mapi
    my $no_mailflow = (defined($options{no_mailflow})) ? 1 : 0;
    my $no_ps = (defined($options{no_ps})) ? 1 : 0;
    my $no_mapi = (defined($options{no_mapi})) ? 1 : 0;
    
    return '' if ($no_ps == 1);
    
    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture

If (@(Get-PSSnapin -Registered | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} ).count -eq 1) {
    If (@(Get-PSSnapin | Where-Object {$_.Name -eq "Microsoft.Exchange.Management.PowerShell.E2010"} ).count -eq 0) {
        Try {
            Add-PSSnapin Microsoft.Exchange.Management.PowerShell.E2010 -ErrorAction STOP
        } Catch {
            Write-Host $Error[0].Exception
            exit 1
        }
    } else {
        Write-Host "Snap-In no present or not registered"
        exit 1
    }
} else {
    Write-Host "Snap-In no present or not registered"
    exit 1
}
$ProgressPreference = "SilentlyContinue"

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
    
    my $mapi_result = centreon::plugins::misc::trim($1);
    
    $self->{output}->output_add(long_msg => "    MAPI Test connectivity: " . $mapi_result);
    foreach my $th (('critical_mapi', 'warning_mapi')) {
        next if (!defined($self->{thresholds}->{$th}));
        
        if ($self->{thresholds}->{$th}->{operator} eq '=' && 
            $mapi_result =~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("Server '%s' Database '%s' MAPI connectivity is %s",
                                                            $options{server}, $options{database}, $mapi_result));
        } elsif ($self->{thresholds}->{$th}->{operator} eq '!=' && 
            $mapi_result !~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("Server '%s' Database '%s' MAPI connectivity is %s",
                                                               $options{server}, $options{database}, $mapi_result));
        }
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
    
    my ($mailflow_result, $latency) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2));
    
    $self->{output}->output_add(long_msg => "    Mailflow Test: " . $mailflow_result);
    foreach my $th (('critical_mailflow', 'warning_mailflow')) {
        next if (!defined($self->{thresholds}->{$th}));
        
        if ($self->{thresholds}->{$th}->{operator} eq '=' && 
            $mailflow_result =~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("Server '%s' Database '%s' Mailflow test is %s",
                                                            $options{server}, $options{database}, $mailflow_result));
        } elsif ($self->{thresholds}->{$th}->{operator} eq '!=' && 
            $mailflow_result !~ /$self->{thresholds}->{$th}->{state}/) {
            $self->{output}->output_add(severity => $self->{thresholds}->{$th}->{out},
                                        short_msg => sprintf("Server '%s' Database '%s' Mailflow test is %s",
                                                            $options{server}, $options{database}, $mailflow_result));
        }
    }
    
    if ($latency =~ /^(\d+)/) {
        $self->{output}->perfdata_add(label => 'latency_' . $options{database}, unit => 's',
                                      value => sprintf("%.3f", $1 / 1000),
                                      min => 0);
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
        my ($database, $server, $mounted, $size, $asize) = (centreon::plugins::misc::trim($1), centreon::plugins::misc::trim($2), 
                                             centreon::plugins::misc::trim($3), centreon::plugins::misc::trim($4), centreon::plugins::misc::trim($5));

        $self->{output}->output_add(long_msg => sprintf("Test database '%s' server '%s':", $database, $server));
        if ($size =~ /\((.*?)\s*bytes/) {
            my $total_bytes = $1;
            $total_bytes =~ s/[.,]//g;
            $self->{output}->perfdata_add(label => 'size_' . $database, unit => 'B',
                                          value => $total_bytes,
                                          min => 0);
            my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_bytes);
            $self->{output}->output_add(long_msg => sprintf("    Size %s", $total_value . ' ' . $total_unit));
        }
        if ($asize =~ /\((.*?)\s*bytes/) {
            my $total_bytes = $1;
            $total_bytes =~ s/[.,]//g;
            $self->{output}->perfdata_add(label => 'asize_' . $database, unit => 'B',
                                          value => $total_bytes,
                                          min => 0);
            my ($total_value, $total_unit) = $self->{perfdata}->change_bytes(value => $total_bytes);
            $self->{output}->output_add(long_msg => sprintf("    Available Size %s", $total_value . ' ' . $total_unit));
        }
        
        
        # Check mounted
        if ($mounted =~ /False/i) {
            $self->{output}->output_add(long_msg => sprintf("    not mounted\n   Skip mapi/mailflow test"));
            $self->{output}->output_add(short_msg => 'CRITICAL',
                                        long_msg => sprintf("Database '%s' server '%s' is not mounted", $database, $server));
            next;
        }
        $self->{output}->output_add(long_msg => sprintf("    mounted"));
        
        check_mapi($self, database => $database, server => $server, line => $line);
        check_mailflow($self, database => $database, server => $server, line => $line);
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