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

package network::stormshield::snmp::mode::uptime;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::constants qw/:counters :values/;
use centreon::plugins::misc;


sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {name => 'global', type => 0, message_separator => "\n", skipped_code => { NO_VALUE() => 1 }}
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
        { label => 'system_name', set => {
                key_values => [ { name => 'system_name' } ],
                output_template => "System Name: %s",
            }
        },
        { label => 'system_node_name', set => {
                key_values => [ { name => 'system_node_name' } ],
                output_template => "System node Name: %s",
            }
        },
        { label => 'model', set => {
                key_values => [ { name => 'model' } ],
                output_template => "Model: %s",
            }
        },
        { label => 'serial_number', set => {
                key_values => [ { name => 'serial_number' } ],
                output_template => "Serial Number: %s",
            }
        },
        { label => 'version', set => {
                key_values => [ { name => 'version' } ],
                perfdatas => [], 
                closure_custom_output => $self->can('custom_version_output'),
            }
        },
        { label => 'bios_version', set => {
                key_values => [ { name => 'bios_version' } ],
                perfdatas => [], 
                closure_custom_output => $self->can('custom_bios_version_output'),                
            }
        },
        { label => 'date', set => {
                key_values => [ { name => 'date' } ],
                output_template => "Date: %s",
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

    $self->{cache_name} = 'fw_stormshield_' . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . md5_hex('all');

    my $oid_system_name = '.1.3.6.1.4.1.11256.1.18.4.0';
    my $oid_system_node_name = '.1.3.6.1.4.1.11256.1.18.16.0';
    my $oid_bios_version = '.1.3.6.1.4.1.11256.1.18.17.0';
    my $oid_model = '.1.3.6.1.4.1.11256.1.18.1.0';
    my $oid_version = '.1.3.6.1.4.1.11256.1.18.2.0';
    my $oid_serial_number = '.1.3.6.1.4.1.11256.1.18.3.0';
    my $oid_date = '.1.3.6.1.4.1.11256.1.10.1.0';
    my $oid_uptime = '.1.3.6.1.4.1.11256.1.10.2.0';

    my $result = $options{snmp}->get_leef(
        oids => [ $oid_system_name, $oid_system_node_name, $oid_bios_version, $oid_model, $oid_version, $oid_serial_number, $oid_date, $oid_uptime ],
        nothing_quit => 1
    );

    my $version = $result->{$oid_version};

    # Used to make sure Perl see this as a string (without dots). Making sure we use an unique separator so it doesn't destroy anything else.
    # With dots, it displays: Argument "x.x.x" isn't numeric in sprintf
    my $version_clean = $version;
    $version_clean =~ s/\./_ç_/g; 


    # Add 'System node Name' if Stormshield firmware version >= 4.8.6 or 4.3.x with x>=40
    # This field was introduced in firmware version 4.8.6 and in 4.3.40
    my $system_node_name = $result->{$oid_system_node_name};
    if (!centreon::plugins::misc::minimal_version($version, '4.8.6') && 
        !(centreon::plugins::misc::minimal_version($version, '4.3.40') && !centreon::plugins::misc::minimal_version($version, '4.4.0'))) {
        $system_node_name = undef;
    }


    # Add 'Bios Version' if Stormshield firmware version >= 4.8.15 or 4.3.x with x>=42
    # This field was introduced in firmware version 4.8.15 and in 4.3.42
    my $bios_version = $result->{$oid_bios_version};
    if (!centreon::plugins::misc::minimal_version($version, '4.8.15') &&
        !(centreon::plugins::misc::minimal_version($version, '4.3.42') && !centreon::plugins::misc::minimal_version($version, '4.4.0'))) {
        $bios_version = undef;
    } else{
        #Same as $version_clean
        $bios_version =~ s/\./_ç_/g; 
    }

    my $uptime_raw = $result->{$oid_uptime};
    my $uptime_seconds = 0;

    if (defined($uptime_raw) && $uptime_raw ne "") {
        my @parts = split(/:/, $uptime_raw);
        
        if (scalar(@parts) == 4) {
            my ($days, $hours, $minutes, $seconds) = @parts;
            $uptime_seconds = ($days * 86400) + ($hours * 3600) + ($minutes * 60) + $seconds;
        } else {
            $self->{output}->message_add(severity => 'CRITICAL', short_msg => "Format d'uptime inattendu: $uptime_raw");
        }
    }

    $self->{global} = {
        system_name      => $result->{$oid_system_name},
        system_node_name => $system_node_name,
        model            => $result->{$oid_model},
        serial_number    => $result->{$oid_serial_number},
        version          => $version_clean,
        bios_version     => $bios_version,
        date             => $result->{$oid_date},
        uptime           => $uptime_seconds,
    };
}

sub custom_version_output {
    my ($self, %options) = @_;
    
    my $val = $self->{result_values}->{version};
    
    # Now, rebuilding the "version" string with dots
    my $display_val = defined($val) ? $val : "N/A";
    $display_val =~ s/_ç_/./g;
    
    return "Version: " . $display_val;
}

sub custom_bios_version_output {
    my ($self, %options) = @_;
    
    my $val = $self->{result_values}->{bios_version};
    
    # Now, rebuilding the "bios_version" string with dots
    my $display_val = defined($val) ? $val : "N/A";
    $display_val =~ s/_ç_/./g;
    
    return "Bios Version: " . $display_val;
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

sub check {
    my ($self, %options) = @_;
    $self->SUPER::check(%options);

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

=item B<--warning-*> B<--critical-*>

Other thresholds (system_name, model, etc.) are not applicable as these are informational only.

=back

=cut
