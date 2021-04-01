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

package hardware::server::sun::mgmt_cards::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_simple);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';
    %{$self->{modes}} = (
        'show-faulty'       => 'hardware::server::sun::mgmt_cards::mode::showfaulty',
        'showfaults'        => 'hardware::server::sun::mgmt_cards::mode::showfaults',
        'showstatus'        => 'hardware::server::sun::mgmt_cards::mode::showstatus',
        'showboards'        => 'hardware::server::sun::mgmt_cards::mode::showboards',
        'showenvironment'   => 'hardware::server::sun::mgmt_cards::mode::showenvironment',
        'environment-v8xx'  => 'hardware::server::sun::mgmt_cards::mode::environmentv8xx',
        'environment-v4xx'  => 'hardware::server::sun::mgmt_cards::mode::environmentv4xx',
        'environment-sf2xx' => 'hardware::server::sun::mgmt_cards::mode::environmentsf2xx',
    );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check a variety of Sun Hardware through management cards:
- mode 'show-faulty': ILOM (T3-x, T4-x, T5xxx) (in ssh with 'plink' command) ;
- mode 'showfaults': ALOM4v (in T1xxx, T2xxx) (in ssh with 'plink' command) ;
- mode 'showstatus': XSCF (Mxxxx - M3000, M4000, M5000,...) (in ssh with 'plink' command) ;
- mode 'showboards': ScApp (SFxxxx - sf6900, sf6800, sf3800,...) (in telnet with Net::Telnet or in ssh with 'plink' command) ;
- mode 'showenvironment': ALOM (v240, v440, v245,...) (in telnet with Net::Telnet or in ssh with 'plink' command) ;
- mode 'environment-v8xx': RSC cards (v890, v880) (in telnet with Net::Telnet) ;
- mode 'environment-v4xx': RSC cards (v480, v490) (in telnet with Net::Telnet) ;
- mode 'environment-sf2xx': RSC cards (sf280) (in telnet with Net::Telnet).

=cut
