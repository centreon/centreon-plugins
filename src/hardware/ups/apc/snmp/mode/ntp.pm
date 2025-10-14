#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package hardware::ups::apc::snmp::mode::ntp;

use base qw(snmp_standard::mode::ntp);

use strict;
use warnings;
use Date::Parse;
use DateTime::TimeZone;
use centreon::plugins::misc qw/value_of/;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    return $self;
}

sub get_target_time {
    my ($self, %options) = @_;

    my $oid_mconfigClockDate = '.1.3.6.1.4.1.318.2.1.6.1.0';
    my $oid_mconfigClockTime = '.1.3.6.1.4.1.318.2.1.6.2.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_mconfigClockDate, $oid_mconfigClockTime ], nothing_quit => 1);

    my $timezone = value_of($self, '->{option_results}->{timezone}');
    $timezone = 'UTC' if $timezone eq '';
    $self->{output}->option_exit(short_msg => "Timezone '$timezone' does not exist.")
        unless DateTime::TimeZone->is_valid_name($timezone);

    my $epoch = Date::Parse::str2time(
        $snmp_result->{$oid_mconfigClockDate} . ' ' . $snmp_result->{$oid_mconfigClockTime},
        $timezone);
    return $self->get_from_epoch(date => $epoch);
}

1;

__END__

=head1 MODE

Check time offset of server with NTP server. Use local time if C<--ntp-host> option is not set. 
SNMP gives a date with second precision (no milliseconds). Time precision is not very accurate.
Use threshold with (+-) 2 seconds offset (minimum).

=over 8

=item B<--warning-offset>

Time offset warning threshold (in seconds).

=item B<--critical-offset>

Time offset critical Threshold (in seconds).

=item B<--ntp-hostname>

Set the NTP hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the NTP port (default: 123).

=item B<--timezone>

Set the timezone of distant server. For Windows, you need to set it.
Can use format: 'Europe/London'.

=back

=cut
