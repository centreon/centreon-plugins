#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package hardware::pdu::sentry::snmp::mode::uptime;

use base qw(snmp_standard::mode::uptime);

use strict;
use warnings;
use centreon::plugins::misc qw(is_not_empty);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'check-overload'  => { name => 'check_overload' },
        'reboot-window:s' => { name => 'reboot_window', default => 5000 },
        'unit:s'          => { name => 'unit', default => 's' },
        'add-sysdesc'     => { name => 'add_sysdesc' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->SUPER::manage_selection(%options);

    my $oid_system_version = '.1.3.6.1.4.1.1718.3.1.1.0';
    my $oid_system_serial_number = '.1.3.6.1.4.1.1718.3.1.2.0';
    my $oid_systemlocation = '.1.3.6.1.4.1.1718.3.1.3.0';

    my $result = $options{snmp}->get_leef(
        oids         =>
            [
                $oid_system_version,
                $oid_system_serial_number,
                $oid_systemlocation
            ],
        nothing_quit => 1
    );

    my $info = "";

    $info .= $result->{$oid_system_version}
        if is_not_empty($result->{$oid_system_version});
    $info .= " [" . $result->{$oid_system_serial_number} . "]"
        if is_not_empty($result->{$oid_system_serial_number}) && $info ne "";
    $info .= " - " . $result->{$oid_systemlocation}
        if is_not_empty($result->{$oid_systemlocation}) && $info ne "";

    $self->{global}->{sysdesc} = $info;

}

1;

__END__

=head1 MODE

Check system uptime.

=over 8

=item B<--warning-uptime>

Warning threshold.

=item B<--critical-uptime>

Critical threshold.

=item B<--add-sysdesc>

Display system description.

=item B<--check-overload>

Uptime counter limit is 4294967296 and overflow.
With that option, we manage the counter going back. But there is a few chance we can miss a reboot.

=item B<--reboot-window>

To be used with check-overload option. Time in milliseconds (default: 5000)
You increase the chance of not missing a reboot if you decrease that value.

=item B<--unit>

Select the time unit for thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back

=cut
