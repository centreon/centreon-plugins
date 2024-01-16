#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package centreon::common::powershell::backupexec::functions;

use strict;
use warnings;

sub powershell_init {
    my (%options) = @_;

    my $bemcli_file = defined($options{bemcli_file}) && $options{bemcli_file} ne '' ?
        $options{bemcli_file} : 'C:/Program Files/Veritas/Backup Exec/Modules/BEMCLI/bemcli'; 
    my $ps = '
If (@(Get-Module | Where-Object {$_.Name -Match "bemcli"} ).count -eq 0) {
    Import-Module -Name "' . $bemcli_file . '"
}
';

    return $ps;
}

1;

__END__

=head1 DESCRIPTION

Powershell commands

=cut
