#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::functions;

use strict;
use warnings;

sub escape_jsonstring {
    my (%options) = @_;

    my $ps = q{
function Escape-JSONString($str) {
    if ($str -eq $null) {return ""}
    $str = $str.ToString().Replace('"','\"').Replace('\','\\').Replace("`n",'\n').Replace("`r",'\r').Replace("`t",'\t')
    return $str;
}
};

    return $ps;
}

sub convert_to_json {
    my (%options) = @_;

    my $ps = q{
function ConvertTo-JSON-20($maxDepth = 4,$forceArray = $false) {
    begin {
        $data = @()
    }
    process{
        $data += $_
    }
    
    end{
        if ($data.length -eq 1 -and $forceArray -eq $false) {
            $value = $data[0]
        } else {    
            $value = $data
        }

        if ($value -eq $null) {
            return "null"
        }

        $dataType = $value.GetType().Name
        
        switch -regex ($dataType) {
                'String'  {
                    return  "`"{0}`"" -f (Escape-JSONString $value )
                }
                '(System\.)?DateTime'  {return  "`"{0:yyyy-MM-dd}T{0:HH:mm:ss}`"" -f $value}
                'Int16|Int32|Double' {return  "$value"}
                'Boolean' {return  "$value".ToLower()}
                '(System\.)?Object\[\]' { # array
                    
                    if ($maxDepth -le 0){return "`"$value`""}
                    
                    $jsonResult = ''
                    foreach($elem in $value){
                        #if ($elem -eq $null) {continue}
                        if ($jsonResult.Length -gt 0) {$jsonResult +=','}
                        $jsonResult += ($elem | ConvertTo-JSON-20 -maxDepth ($maxDepth -1))
                    }
                    return "[" + $jsonResult + "]"
                }
                '(System\.)?Hashtable' { # hashtable
                    $jsonResult = ''
                    foreach($key in $value.Keys){
                        if ($jsonResult.Length -gt 0) {$jsonResult +=','}
                        $jsonResult += 
@"
"{0}":{1}
"@ -f $key , ($value[$key] | ConvertTo-JSON-20 -maxDepth ($maxDepth -1) )
                    }
                    return "{" + $jsonResult + "}"
                }
                default { #object
                    if ($maxDepth -le 0){return  "`"{0}`"" -f (Escape-JSONString $value)}
                    
                    return "{" +
                        (($value | Get-Member -MemberType *property | % { 
@"
"{0}":{1}
"@ -f $_.Name , ($value.($_.Name) | ConvertTo-JSON-20 -maxDepth ($maxDepth -1) )
                    
                    }) -join ',') + "}"
                }
        }
    }
}
};

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Powershell common functions.

=cut
