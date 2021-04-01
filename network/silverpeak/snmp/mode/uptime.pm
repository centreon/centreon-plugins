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

package network::silverpeak::snmp::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use Time::HiRes qw(time);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"       => { name => 'warning' },
                                  "critical:s"      => { name => 'critical' },
                                  "force-oid:s"     => { name => 'force_oid' },
                                  "check-overflow"  => { name => 'check_overflow' },
                                });
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
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
    
    $self->{statefile_cache}->check_options(%options);
}

sub check_overflow {
    my ($self, %options) = @_;
    
    return $options{timeticks} if (!defined($self->{option_results}->{check_overflow}));
    
    my $current_time = floor(time() * 100);
    $self->{new_datas} = { last_time => $current_time, uptime => $options{timeticks}, overflow => 0 };
    $self->{statefile_cache}->read(statefile => "cache_" . $self->{snmp}->get_hostname()  . '_' . $self->{snmp}->get_port() . '_' . $self->{mode});
    my $old_uptime = $self->{statefile_cache}->get(name => 'uptime');
    my $last_time = $self->{statefile_cache}->get(name => 'last_time');
    my $overflow = $self->{statefile_cache}->get(name => 'overflow');
    
    if (defined($old_uptime) && $old_uptime < $current_time) {
        my $diff_time = $current_time - $last_time;
        my $overflow = ($old_uptime + $diff_time) % 4294967296;
        my $division = ($old_uptime + $diff_time) / 4294967296;
        if ($division >= 1 && 
            $overflow >= ($options{timeticks} - 5000) &&
            $overflow <= ($options{timeticks} + 5000)) {
            $overflow++;
        }
        
        $options{timeticks} += ($overflow * 4294967296);
    }
    $self->{new_datas}->{overflow} = $overflow if (defined($overflow));
    
    $self->{statefile_cache}->write(data => $self->{new_datas});
    return $options{timeticks};
}

sub run {
    my ($self, %options) = @_;
    $self->{snmp} = $options{snmp};
    
    # spsSystemUptime from SILVERPEAK-MGMT-MIB 8.0
    my $oid_hrSystemUptime = '.1.3.6.1.4.1.23867.3.1.1.1.5.0';
    my ($result, $value);
    
    if (defined($self->{option_results}->{force_oid})) {
        $result = $self->{snmp}->get_leef(oids => [ $self->{option_results}->{force_oid} ], nothing_quit => 1);
        $value = $result->{$self->{option_results}->{force_oid}};
    } else {
        $result = $self->{snmp}->get_leef(oids => [ $oid_hrSystemUptime ], nothing_quit => 1);
        $value = $result->{$oid_hrSystemUptime};
    }
    
    $value = $self->check_overflow(timeticks => $value);
    $value = floor($value / 100);
    
    my $exit_code = $self->{perfdata}->threshold_check(value => $value, 
                              threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);    
    $self->{output}->perfdata_add(label => 'uptime', unit => 's',
                                  value => $value,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);

    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("System uptime is: %s",
                                                     centreon::plugins::misc::change_seconds(value => $value, start => 'd')));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check system uptime.

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--force-oid>

Can choose your oid (numeric format only).

=item B<--check-overflow>

Uptime counter limit is 4294967296 and overflow.
With that option, we manage the counter going back. But there is a few chance we can miss a reboot.

=back

=cut
