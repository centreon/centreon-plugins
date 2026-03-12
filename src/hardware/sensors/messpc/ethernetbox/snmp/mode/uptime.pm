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

package hardware::sensors::messpc::ethernetbox::snmp::mode::uptime;

use base qw(snmp_standard::mode::uptime);

use strict;
use warnings;
use POSIX;
use Time::HiRes qw(time);
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_version = '.1.3.6.1.4.1.14848.2.1.1.1.0';
    my $oid_location = '.1.3.6.1.4.1.14848.2.1.1.2.0';
    my @oids = ();
    if (defined($self->{option_results}->{add_sysdesc})) {
        @oids = ($oid_version, $oid_location);
    }

    my $oid_sysUpTime = '.1.3.6.1.4.1.14848.2.1.1.7.0';
    my ($result, $value);

    $result = $options{snmp}->get_leef(oids => [ @oids, $oid_sysUpTime ], nothing_quit => 1);
    $value = $result->{$oid_sysUpTime};
    $value =~ /\((\d+)\)/;

    $value = $self->check_overload(timeticks => $value, snmp => $options{snmp});
    $value = floor($value / 100);

    my $sys_desc = defined($result->{$oid_location}) ? $result->{$oid_location} : "";
    $sys_desc .= defined($result->{$oid_version}) ? ", $result->{$oid_version}" : "";

    $self->{global} = { uptime => $value, sysdesc => defined($sys_desc) ? $sys_desc : '-' };
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

Select the time unit for the performance data and thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=back
