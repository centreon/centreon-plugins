#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::varnish::local::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
	my ($class, %options) = @_;
	my $self = $class->SUPER::new(package => __PACKAGE__, %options);
	bless $self, $class;

	$self->{version} = '0.1';
	%{$self->{modes}} = (
			'connections'       => 'apps::varnish::local::mode::connections',
			'clients'	    => 'apps::varnish::local::mode::clients',
			'cache'             => 'apps::varnish::local::mode::cache',
			'backend'           => 'apps::varnish::local::mode::backend',
			'sessions'          => 'apps::varnish::local::mode::sessions',
			'fetch'             => 'apps::varnish::local::mode::fetch',
			'workers'           => 'apps::varnish::local::mode::workers',
			'totals'            => 'apps::varnish::local::mode::totals',
			'objects'           => 'apps::varnish::local::mode::objects',
			'uptime'            => 'apps::varnish::local::mode::uptime',
			'bans'              => 'apps::varnish::local::mode::bans',
			'dns'               => 'apps::varnish::local::mode::dns',
			'shm'               => 'apps::varnish::local::mode::shm',
			'vcl'               => 'apps::varnish::local::mode::vcl',
			'n'                 => 'apps::varnish::local::mode::n',
			'sms'               => 'apps::varnish::local::mode::sms',
			'hcb'               => 'apps::varnish::local::mode::hcb',
			'esi'               => 'apps::varnish::local::mode::esi',
			'threads'	    => 'apps::varnish::local::mode::threads',
			);

	return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Varnish Cache with varnishstat Command

=cut
