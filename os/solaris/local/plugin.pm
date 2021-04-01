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

package os::solaris::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'prtdiag'              => 'os::solaris::local::mode::prtdiag',
        'cpu'                  => 'os::solaris::local::mode::cpu',
        'fc-connected'         => 'os::solaris::local::mode::fcconnected',
        'hardware-fmadm'       => 'os::solaris::local::mode::fmadm',
        'analyze-disks'        => 'os::solaris::local::mode::analyzedisks',
        'vx-disks'             => 'os::solaris::local::mode::vxdisks',
        'svm-disks'            => 'os::solaris::local::mode::svmdisks',
        'hwraidctl-status'     => 'os::solaris::local::mode::hwraidctl',
        'hwsas2ircu-status'    => 'os::solaris::local::mode::hwsas2ircu',
        'lom-v120-status'      => 'os::solaris::local::mode::lomv120',
        'lom-v1280-status'     => 'os::solaris::local::mode::lomv1280',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Solaris through local commands (the plugin can use SSH):
- mode 'prtdiag' need 'prtdiag' command ;
- mode 'cpu': need 'kstat' command ;
- mode 'fc-connected': need sun/oracle driver and not Emulex/Qlogic ;
- mode 'hardware-fmadm': need at least Solaris 10 and fmadm command ;
- mode 'analyze-disks': need 'format' command ;
- mode 'vx-disks': need 'vxdisk' and 'vxprint' command ;
- mode 'svm-disks': need  'metastat' and 'metadb' command ;
- mode 'hwraidctl-status': need 'raidctl' command ;
- mode 'hwsas2ircu-status': need 'sas2ircu' command ;
- mode 'lom-v120-status': need 'lom' command ;
- mode 'lom-v1280-status': need 'lom' command.

=cut
