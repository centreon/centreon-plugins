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

package storage::purestorage::flashblade::v2::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{modes} = {
        'alerts'           => 'storage::purestorage::flashblade::v2::restapi::mode::alerts',
        'arrays'           => 'storage::purestorage::flashblade::v2::restapi::mode::arrays',
        'filesystems'      => 'storage::purestorage::flashblade::v2::restapi::mode::filesystems',
        'hardware'         => 'storage::purestorage::flashblade::v2::restapi::mode::hardware',
        'list-arrays'      => 'storage::purestorage::flashblade::v2::restapi::mode::listarrays',
        'list-filesystems' => 'storage::purestorage::flashblade::v2::restapi::mode::listfilesystems'
    };

    $self->{custom_modes}->{api} = 'storage::purestorage::flashblade::v2::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Pure Storage FlashBlade through HTTP/REST API v2.

=cut
