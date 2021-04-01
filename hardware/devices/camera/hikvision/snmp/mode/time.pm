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

package hardware::devices::camera::hikvision::snmp::mode::time;

use base qw(snmp_standard::mode::ntp);

use strict;
use warnings;

sub get_target_time {
    my ($self, %options) = @_;

    my $oid_sysTime = '.1.3.6.1.4.1.39165.1.19.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_sysTime ], nothing_quit => 1);

    # format: "2019-11-18 20:13:17"
    if ($snmp_result->{$oid_sysTime} !~ /^(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/) {
        $self->{output}->add_option_msg(short_msg => 'cannot parse date format: ' . $snmp_result->{$oid_sysTime});
        $self->{output}->option_exit();
    }

    my $remote_date = [$1, $2, $3, $4, $5, $6];

    my $timezone = 'UTC';
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $timezone = $self->{option_results}->{timezone};
    }

    my $tz = centreon::plugins::misc::set_timezone(name => $timezone);
    my $dt = DateTime->new(
      year       => $remote_date->[0],
      month      => $remote_date->[1],
      day        => $remote_date->[2],
      hour       => $remote_date->[3],
      minute     => $remote_date->[4],
      second     => $remote_date->[5],
      %$tz
    );

    return ($dt->epoch, $remote_date, $timezone);
}

1;

__END__

=head1 MODE

Check time offset of server with ntp server. Use local time if ntp-host option is not set. 
SNMP gives a date with second precision (no milliseconds). Time precision is not very accurate.
Use threshold with (+-) 2 seconds offset (minimum).

=over 8

=item B<--warning-offset>

Time offset warning threshold (in seconds).

=item B<--critical-offset>

Time offset critical Threshold (in seconds).

=item B<--ntp-hostname>

Set the ntp hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the ntp port (Default: 123).

=item B<--timezone>

Set the timezone of distant server. For Windows, you need to set it.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
