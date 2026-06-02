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

package network::stormshield::snmp::mode::uptime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc;


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {name => 'global', type => COUNTER_TYPE_GLOBAL, skipped_code => { NO_VALUE() => 1 }}
    ];

    $self->{maps_counters}->{global} = [
        { label => 'uptime', set => {
                key_values => [ { name => 'uptime' } ],
                closure_custom_output => $self->can('custom_uptime_output'),
                closure_custom_perfdata => $self->can('custom_uptime_perfdata'),
                closure_custom_threshold_check => $self->can('custom_uptime_threshold_check'),
                output_template => "Uptime: %s",
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;


    my $oid_snsSystemName = '.1.3.6.1.4.1.11256.1.18.4.0';
    my $oid_snsSystemNodeName = '.1.3.6.1.4.1.11256.1.18.16.0';
    my $oid_snsBiosVersion = '.1.3.6.1.4.1.11256.1.18.17.0';
    my $oid_snsModel = '.1.3.6.1.4.1.11256.1.18.1.0';
    my $oid_snsVersion = '.1.3.6.1.4.1.11256.1.18.2.0';
    my $oid_snsSerialNumber = '.1.3.6.1.4.1.11256.1.18.3.0';
    my $oid_snsDate = '.1.3.6.1.4.1.11256.1.10.1.0';
    my $oid_snsUptime = '.1.3.6.1.4.1.11256.1.10.2.0';

    my $result = $options{snmp}->get_leef(
        oids => [ $oid_snsSystemName, $oid_snsSystemNodeName, $oid_snsBiosVersion, $oid_snsModel, $oid_snsVersion, $oid_snsSerialNumber, $oid_snsDate, $oid_snsUptime ],
        nothing_quit => 1
    );

    my $version = $result->{$oid_snsVersion};

    # Add 'System node Name' if Stormshield firmware version >= 4.8.6 or 4.3.x with x>=40
    # This field was introduced in firmware version 4.8.6 and in 4.3.40
    my $system_node_name = $result->{$oid_snsSystemNodeName};
    if (!centreon::plugins::misc::minimal_version($version, '4.8.6') && 
        !(centreon::plugins::misc::minimal_version($version, '4.3.40') && !centreon::plugins::misc::minimal_version($version, '4.4.0'))) {
        $system_node_name = undef;
    }

    # Add 'Bios Version' if Stormshield firmware version >= 4.8.15 or 4.3.x with x>=42
    # This field was introduced in firmware version 4.8.15 and in 4.3.42
    my $bios_version = $result->{$oid_snsBiosVersion};
    if (!centreon::plugins::misc::minimal_version($version, '4.8.15') &&
        !(centreon::plugins::misc::minimal_version($version, '4.3.42') && !centreon::plugins::misc::minimal_version($version, '4.4.0'))) {
        $bios_version = undef;
    }

    my $uptime_raw = $result->{$oid_snsUptime};
    my $uptime_seconds = 0;

    if (defined($uptime_raw) && $uptime_raw ne "") {
        my @parts = split(/:/, $uptime_raw);
        
        if (scalar(@parts) == 4) {
            my ($days, $hours, $minutes, $seconds) = @parts;
            $uptime_seconds = ($days * 86400) + ($hours * 3600) + ($minutes * 60) + $seconds;
        } else {
            $self->{output}->message_add(severity => 'CRITICAL', short_msg => "Unexpected uptime format: $uptime_raw");
        }
    }

    my $long_msg = "System Name: " . $result->{$oid_snsSystemName} . "\n";
    $long_msg .= "Model: " . $result->{$oid_snsModel} . "\n";
    $long_msg .= "Serial Number: " . $result->{$oid_snsSerialNumber} . "\n";
    $long_msg .= "Version: " . $version . "\n";
    $long_msg .= "Date: " . $result->{$oid_snsDate} . "\n";
    
    if (defined($system_node_name)) {
        $long_msg .= "System Node Name: " . $system_node_name . "\n";
    }
    
    if (defined($bios_version)) {
        $long_msg .= "Bios Version: " . $bios_version . "\n";
    }
    
    $self->{output}->output_add(
        long_msg => $long_msg,
    );

    $self->{global} = {
        uptime => $uptime_seconds,
    };
}

sub custom_uptime_output {
    my ($self, %options) = @_;

    my $uptime_seconds = $self->{result_values}->{uptime};
    
    my $days = $uptime_seconds / 86400;
    my $hours = ($uptime_seconds % 86400) / 3600;
    my $minutes = ($uptime_seconds % 3600) / 60;
    my $seconds = $uptime_seconds % 60;
    
    my $msg = sprintf(
        "Uptime: %d days %02d hours %02d minutes %02d seconds",
        $days, $hours, $minutes, $seconds
    );

    return $msg;
}

sub custom_uptime_perfdata {
    my ($self, %options) = @_;

    my $uptime_seconds = $self->{result_values}->{uptime};

    $self->{output}->perfdata_add(
        label => 'uptime',
        nlabel => 'system.uptime.seconds',
        value => $uptime_seconds,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-uptime'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-uptime'),
        min => 0,
        unit => 's'
    );
}

sub custom_uptime_threshold_check {
    my ($self, %options) = @_;
    my $uptime_seconds = $self->{result_values}->{uptime};

    return $self->{perfdata}->threshold_check(
        value => $uptime_seconds,
        threshold => [
            { label => 'critical-uptime', exit_litteral => 'critical' },
            { label => 'warning-uptime', exit_litteral => 'warning' },
        ]
    );
}

1;

__END__

=head1 MODE

This mode retrieves and displays basic properties of the Stormshield device such as system name, model, version, serial number, and date.
It also monitors the uptime with configurable warning and critical thresholds.

=over 8

=item B<--warning-uptime>

Warning threshold for uptime (in seconds).

=item B<--critical-uptime>

Critical threshold for uptime (in seconds).

=back

=cut
