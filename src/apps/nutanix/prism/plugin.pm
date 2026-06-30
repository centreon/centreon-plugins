#
# Copyright 2026 Centreon (http://www.centreon.com/)
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

package apps::nutanix::prism::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'alerts'                  => 'apps::nutanix::prism::mode::alerts',
        'capacity'                => 'apps::nutanix::prism::mode::capacity',
        'cluster-status'          => 'apps::nutanix::prism::mode::clusterstatus',
        'disks-status'            => 'apps::nutanix::prism::mode::disksstatus',
        'health-checks'           => 'apps::nutanix::prism::mode::healthchecks',
        'hosts-usage'             => 'apps::nutanix::prism::mode::hostsusage',
        'snapshots'               => 'apps::nutanix::prism::mode::snapshots',
        'storage-usage'           => 'apps::nutanix::prism::mode::storageusage',
        'vms-count'               => 'apps::nutanix::prism::mode::vmscount',
        'vms-nics'                => 'apps::nutanix::prism::mode::vmsnics',
        'list-hosts'              => 'apps::nutanix::prism::mode::listhosts',
        'list-nics'               => 'apps::nutanix::prism::mode::listnics',
        'list-vms'                => 'apps::nutanix::prism::mode::listvms',
        'vms-performance'         => 'apps::nutanix::prism::mode::vmsperformance',
        'protection-domains'      => 'apps::nutanix::prism::mode::protectiondomains',
        'storage-containers'      => 'apps::nutanix::prism::mode::storagecontainers',
        'tasks'                   => 'apps::nutanix::prism::mode::tasks',
        'list-protection-domains' => 'apps::nutanix::prism::mode::listprotectiondomains',
        'list-storage-containers' => 'apps::nutanix::prism::mode::liststoragecontainers',
    };

    $self->{custom_modes}->{api} = 'apps::nutanix::prism::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Monitor Nutanix infrastructure through Prism REST API.

=cut
