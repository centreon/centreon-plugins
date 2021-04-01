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

package apps::kingdee::eas::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_custom);

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;

	$self->{version} = '1.0';
	%{$self->{modes}} = (
        'classloading'        => 'apps::kingdee::eas::mode::classloading',
        'memory'              => 'apps::kingdee::eas::mode::memory',
        'javaruntime'         => 'apps::kingdee::eas::mode::javaruntime',
        'datasource'          => 'apps::kingdee::eas::mode::datasource',
        'handlers'            => 'apps::kingdee::eas::mode::handlers',
        'transaction'         => 'apps::kingdee::eas::mode::transaction',
        'oraclejvmgc'         => 'apps::kingdee::eas::mode::oraclejvmgc',
        'ibmjvmgc'            => 'apps::kingdee::eas::mode::ibmjvmgc',
        'ormrpc'              => 'apps::kingdee::eas::mode::ormrpc',
        'easlicense'          => 'apps::kingdee::eas::mode::easlicense',
        'activeusers'         => 'apps::kingdee::eas::mode::activeusers',
        'oracleversion'       => 'apps::kingdee::eas::mode::oracleversion',
        'oraclesession'       => 'apps::kingdee::eas::mode::oraclesession',
        'oracletable'         => 'apps::kingdee::eas::mode::oracletable',
        'oraclerecyclebin'    => 'apps::kingdee::eas::mode::oraclerecyclebin',
        'oracleksqltemptable' => 'apps::kingdee::eas::mode::oracleksqltemptable',
        'oracleredolog'       => 'apps::kingdee::eas::mode::oracleredolog',
    );

    $self->{custom_modes}{api} = 'apps::kingdee::eas::custom::api';
	return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Kingdee EAS Application & DB Server Status .

=cut
