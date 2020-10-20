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

package storage::purestorage::restapi::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
    my ( $class, %options ) = @_;
    my $self = $class->SUPER::new( package => __PACKAGE__, %options );
    bless $self, $class;

    $self->{version} = '0.1';
    $self->{modes} = {
        'alarms'             => 'storage::purestorage::restapi::mode::alarms',
        'arrays'             => 'storage::purestorage::restapi::mode::arrays',
        'hardware'           => 'storage::purestorage::restapi::mode::hardware',
        'list-pgroups'       => 'storage::purestorage::restapi::mode::listpgroups',
        'list-volumes'       => 'storage::purestorage::restapi::mode::listvolumes',
        'pgroup-replication' => 'storage::purestorage::restapi::mode::pgroupreplication',
        'volume-usage'       => 'storage::purestorage::restapi::mode::volumeusage'
    };

    $self->{custom_modes}->{api} = 'storage::purestorage::restapi::custom::api';
    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Pure Storage through HTTP/REST API.

=cut
