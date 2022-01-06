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

package os::windows::wmi::mode::uptime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'  => { name => 'warning', default => '' },
        'critical:s' => { name => 'critical', default => '' },
        'seconds'    => { name => 'seconds' }
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
}

sub run {
    my ($self, %options) = @_;

    my $WQL = 'Select Frequency_Sys100NS,SystemUpTime,Timestamp_Object from Win32_PerfRawData_PerfOS_System';

    my ($result, $exit_code) = $options{custom}->execute_command(
        query => $WQL,
        no_quit => 1
    );
    $result =~ s/\|/;/g;

    #
    #CLASS: Win32_PerfRawData_PerfOS_System
    #Frequency_Sys100NS;SystemUpTime;Timestamp_Object
    #10000000;132847344565000000;132847576466519223
    #
    
    my $uptime = 0;
    while ($result =~ /^(\d+);(\d+);(\d+)$/msg) {
       my ($Frequency_Sys100NS, $SystemUpTime, $Timestamp_Object) = ($1, $2, $3);
       if (!defined($SystemUpTime) || !defined($Timestamp_Object) || !defined($Frequency_Sys100NS)) {
           $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
           $self->{output}->option_exit();
       }
       $uptime = ( $Timestamp_Object - $SystemUpTime ) / $Frequency_Sys100NS; 
    }
    

    my $exit_code = $self->{perfdata}->threshold_check(
        value => floor($uptime),
        threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]
    );
    $self->{output}->perfdata_add(
        label => 'uptime', unit => 's',
        value => floor($uptime),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );

    $self->{output}->output_add(
        severity => $exit_code,
        short_msg => sprintf(
            "System uptime is: %s",
            defined($self->{option_results}->{seconds}) ? floor($uptime) . " seconds" : floor($uptime / 86400) . " days"
        )
    );

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check system uptime.

Command used: cat /proc/uptime 2>&1

=over 8

=item B<--warning>

Threshold warning in seconds.

=item B<--critical>

Threshold critical in seconds.

=item B<--seconds>

Display uptime in seconds.

=back

=cut
