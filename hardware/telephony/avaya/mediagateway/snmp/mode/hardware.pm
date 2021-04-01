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

package hardware::telephony::avaya::mediagateway::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';
    
    $self->{thresholds} = {
        alarm => [
            ['enabled', 'CRITICAL'],
            ['disabled', 'OK']
        ]
    };
    
    $self->{components_path} = 'hardware::telephony::avaya::mediagateway::snmp::mode::components';
    $self->{components_module} = ['alarm'];
}

sub snmp_execute {
    my ($self, %options) = @_;
    
    my $oid_cmgHardwareFaultMask = '.1.3.6.1.4.1.6889.2.9.1.1.10.12.0';
    $self->{results} = $options{snmp}->get_leef(oids => [$oid_cmgHardwareFaultMask]);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, no_absent => 1, no_performance => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'alarm'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=alarm)
Can also exclude specific instance: --filter=alarm,1

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='alarm,1,OK,enabled'

=back

=cut
