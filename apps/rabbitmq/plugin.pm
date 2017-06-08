#
# Copyright 2015 Centreon (http://www.centreon.com/)
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

package apps::rabbitmq::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '0.1';
    %{$self->{modes}} = (
                         'aliveness'    => 'apps::rabbitmq::mode::aliveness',
                         'cluster'      => 'apps::rabbitmq::mode::cluster',
                         'listobjects'  => 'apps::rabbitmq::mode::listobjects',
                         'node'         => 'apps::rabbitmq::mode::node',
                         'objects'      => 'apps::rabbitmq::mode::objects',
                         'queue'        => 'apps::rabbitmq::mode::queue',
                        );

    return $self;
}


1;

__END__

=head1 PLUGIN DESCRIPTION

Check RabbitMQ through its API (with Management Plugin : https://www.rabbitmq.com/management.html)
Requirements: RabbitMQ 3.5.5 and RabbitMQ Management Plugin

=cut
