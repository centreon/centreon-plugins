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

package os::windows::wsman::mode::uptime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;
use Time::HiRes qw(time);

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_uptime_output { 
    my ($self, %options) = @_;

    return sprintf(
        'System uptime is: %s',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{uptime}, start => 'd')
    );
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => 'system.uptime.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_uptime_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{uptime} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'uptime', set => {
                key_values => [ { name => 'uptime' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'unit:s' => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{wsman}->request(
        uri => 'http://schemas.microsoft.com/wbem/wsman/1/wmi/root/cimv2/*',
        wql_filter => "Select Frequency_Sys100NS,SystemUpTime,Timestamp_Object from Win32_PerfRawData_PerfOS_System",
        result_type => 'array'
    );

    #
    #CLASS: Win32_PerfRawData_PerfOS_System
    #Frequency_Sys100NS;SystemUpTime;Timestamp_Object
    #10000000;132847344565000000;132847576466519223
    #    
    my $uptime = 0;
    foreach my $result (@$results) {
        my $Frequency_Sys100NS = $result->{Frequency_Sys100NS};
        my $SystemUpTime = $result->{SystemUpTime};
        my $Timestamp_Object = $result->{Timestamp_Object};
        if (!defined($result->{SystemUpTime}) || !defined($result->{Timestamp_Object}) || !defined($result->{Frequency_Sys100NS})) {
            $self->{output}->add_option_msg(short_msg => 'Some informations missing.');
            $self->{output}->option_exit();
        }

        $self->{global} = { uptime => ($result->{Timestamp_Object} - $result->{SystemUpTime}) / $result->{Frequency_Sys100NS} };
    }
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

=item B<--unit>

Select the unit for performance data and thresholds. May be 's' for seconds, 'm' for minutes,
'h' for hours, 'd' for days, 'w' for weeks.  Default is seconds

=back

=cut
