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

package centreon::common::powershell::windows::pendingreboot;

use strict;
use warnings;
use centreon::common::powershell::functions;

sub get_powershell {
    my (%options) = @_;

    my $ps = '
$culture = new-object "System.Globalization.CultureInfo" "en-us"    
[System.Threading.Thread]::CurrentThread.CurrentUICulture = $culture
';

    $ps .= centreon::common::powershell::functions::escape_jsonstring(%options);
    $ps .= centreon::common::powershell::functions::convert_to_json(%options);

    $ps .= '
$ProgressPreference = "SilentlyContinue"

Try {
    $ErrorActionPreference = "Stop"

    $ComputerName = "$env:COMPUTERNAME"
    $CompPendRen,$PendFileRename,$Pending,$SCCM = $false,$false,$false,$false

    ## Setting CBSRebootPend to null since not all versions of Windows has this value 
    $CBSRebootPend = $null 

    ## Making registry connection to the local/remote computer 
    $HKLM = [UInt32] "0x80000002" 
    $WMI_Reg = [WMIClass] "\\\\$ComputerName\\root\\default:StdRegProv" 

    $RegSubKeysCBS = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Component Based Servicing\\")
    If ($RegSubKeysCBS.ReturnValue -eq 0) {
        $CBSRebootPend = $RegSubKeysCBS.sNames -contains "RebootPending"     
    } 

    ## Query WUAU from the registry 
    $RegWUAURebootReq = $WMI_Reg.EnumKey($HKLM,"SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\WindowsUpdate\\Auto Update\\") 
    $WUAURebootReq = $RegWUAURebootReq.sNames -contains "RebootRequired" 

    ## Query PendingFileRenameOperations from the registry 
    $RegSubKeySM = $WMI_Reg.GetMultiStringValue($HKLM,"SYSTEM\\CurrentControlSet\\Control\\Session Manager\\","PendingFileRenameOperations") 
    $RegValuePFRO = $RegSubKeySM.sValue 

    ## Query ComputerName and ActiveComputerName from the registry 
    $ActCompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ActiveComputerName\\","ComputerName")       
	$CompNm = $WMI_Reg.GetStringValue($HKLM,"SYSTEM\\CurrentControlSet\\Control\\ComputerName\\ComputerName\\","ComputerName") 
	If ($ActCompNm -ne $CompNm) {
        $CompPendRen = $true 
    } 

    ## If PendingFileRenameOperations has a value set $RegValuePFRO variable to $true 
    If ($RegValuePFRO) { 
        $PendFileRename = $true 
    }

    ## Determine SCCM 2012 Client Reboot Pending Status 
    ## To avoid nested "if" statements and unneeded WMI calls to determine if the CCM_ClientUtilities class exist, setting EA = 0 
    $CCMClientSDK = $null 
    $CCMSplat = @{ 
        NameSpace="ROOT\\ccm\\ClientSDK" 
        Class="CCM_ClientUtilities" 
        Name="DetermineIfRebootPending" 
        ComputerName=$ComputerName 
        ErrorAction="Stop" 
    } 
    ## Try CCMClientSDK 
    Try { 
        $CCMClientSDK = Invoke-WmiMethod @CCMSplat 
    } Catch [System.UnauthorizedAccessException] { 
        $CcmStatus = Get-Service -Name CcmExec -ComputerName $ComputerName -ErrorAction SilentlyContinue 
        If ($CcmStatus.Status -ne "Running") { 
            Write-Warning "$ComputerName`: Error - CcmExec service is not running." 
            $CCMClientSDK = $null 
        } 
    } Catch { 
        $CCMClientSDK = $null 
    } 

    If ($CCMClientSDK) { 
        If ($CCMClientSDK.ReturnValue -ne 0) { 
            Write-Warning "Error: DetermineIfRebootPending returned error code $($CCMClientSDK.ReturnValue)"     
        } 
        If ($CCMClientSDK.IsHardRebootPending -or $CCMClientSDK.RebootPending) { 
            $SCCM = $true 
        } 
    } Else { 
        $SCCM = $null 
    }

    $WindowsVersion = (Get-WmiObject -class Win32_OperatingSystem).Caption;

    $item = @{
        WindowsVersion = $WindowsVersion;
        CBServicing = $CBSRebootPend;
        WindowsUpdate = $WUAURebootReq;
        CCMClientSDK = $SCCM;
        PendComputerRename = $CompPendRen;
        PendFileRename = $PendFileRename;
        RebootPending = ($CompPendRen -or $CBSRebootPend -or $WUAURebootReq -or $SCCM -or $PendFileRename)
    }

    $jsonString = $item | ConvertTo-JSON-20
    Write-Host $jsonString
} Catch {
    Write-Host $Error[0].Exception
    exit 1
}

exit 0
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Method to get pending reboot informations.

=cut
