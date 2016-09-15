#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package snmp_standard::mode::ntp;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use DateTime;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "ntp-hostname:s"          => { name => 'ntp_hostname' },
                                  "ntp-port:s"              => { name => 'ntp_port', default => 123 },
                                  "warning:s"               => { name => 'warning' },
                                  "critical:s"              => { name => 'critical' },
                                  "timezone:s"              => { name => 'timezone' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
    if (defined($self->{option_results}->{ntp_hostname})) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'Net::NTP',
                                               error_msg => "Cannot load module 'Net::NTP'.");
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};

    my ($ref_time, $distant_time);
    my $oid_hrSystemDate = '.1.3.6.1.2.1.25.1.2.0';
    my $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemDate ]);
    if (scalar(keys %$result) == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot get 'hrSystemDate' information.");
        $self->{output}->display();
        $self->{output}->exit();
    }
    if (defined($self->{option_results}->{ntp_hostname})) {
        my %ntp;
        
        eval {
            %ntp = Net::NTP::get_ntp_response($self->{option_results}->{ntp_hostname}, $self->{option_results}->{ntp_port});
        };
        if ($@) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "Couldn't connect to ntp server: " . $@);
            $self->{output}->display();
            $self->{output}->exit();
        }
        
        $ref_time = $ntp{'Transmit Timestamp'};
    } else {
        $ref_time = time();
    }
    
    my @remote_date = unpack 'n C6 a C2', $result->{$oid_hrSystemDate};
    my $timezone = 'UTC';
    if (defined($self->{option_results}->{timezone}) && $self->{option_results}->{timezone} ne '') {
        $timezone = $self->{option_results}->{timezone};
    } elsif (defined($remote_date[9])) {
        $timezone = sprintf("%s%02d%02d", $remote_date[7], $remote_date[8], $remote_date[9]); # format +0630
    }
    
    my $dt = DateTime->new(
      year       => $remote_date[0],
      month      => $remote_date[1],
      day        => $remote_date[2],
      hour       => $remote_date[3],
      minute     => $remote_date[4],
      second     => $remote_date[5],
      time_zone  => $timezone, 
    );
    $distant_time = $dt->epoch;
    
    my $diff = $distant_time - $ref_time;
    my $remote_date_formated = sprintf("%02d-%02d-%02dT%02d:%02d:%02d (%s)", $remote_date[0], $remote_date[1], $remote_date[2],
                                       $remote_date[3], $remote_date[4], $remote_date[5], $timezone);
    
    my $exit = $self->{perfdata}->threshold_check(value => $diff, 
                               threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Time offset %d second(s) : %s", $diff, $remote_date_formated));

    $self->{output}->perfdata_add(label => 'offset', unit => 's',
                                  value => sprintf("%d", $diff),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check time offset of server with ntp server. Use local time if ntp-host option is not set. 
SNMP gives a date with second precision (no milliseconds). Time precision is not very accurate.
Use threshold with (+-) 2 seconds offset (minimum).

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--ntp-hostname>

Set the ntp hostname (if not set, localtime is used).

=item B<--ntp-port>

Set the ntp port (Default: 123).

=item B<--timezone>

Set the timezone of distant server. For Windows, you need to set it.
Can use format: 'Europe/London' or '+0100'.

=back

=cut
