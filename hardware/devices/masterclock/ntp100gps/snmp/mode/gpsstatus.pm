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

package hardware::devices::masterclock::ntp100gps::snmp::mode::gpsstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("GPS receiver health : '%s', Satellites seen : '%s', Latitude : '%s', Longitude : '%s'",
        $self->{result_values}->{health},
        $self->{result_values}->{satellites},
        $self->{result_values}->{latitude},
        $self->{result_values}->{longitude});

    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{satellites} = $options{new_datas}->{$self->{instance} . '_satellites'};
    $self->{result_values}->{latitude} = $options{new_datas}->{$self->{instance} . '_latitude'};
    $self->{result_values}->{longitude} = $options{new_datas}->{$self->{instance} . '_longitude'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', set => {
                key_values => [ { name => 'health' }, { name => 'satellites' }, { name => 'latitude' }, { name => 'longitude' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning-status:s"        => { name => 'warning_status', default => '%{satellites} =~ /No satellites in view/' },
                                  "critical-status:s"       => { name => 'critical_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_gps_health = ".1.3.6.1.4.1.45561.1.1.1.26.0";
    my $oid_gps_latitude = ".1.3.6.1.4.1.45561.1.1.1.27.0";
    my $oid_gps_longitude = ".1.3.6.1.4.1.45561.1.1.1.28.0";
    my $oid_gps_satellites = ".1.3.6.1.4.1.45561.1.1.1.29.0";
    
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_gps_health, $oid_gps_latitude, $oid_gps_longitude, $oid_gps_satellites ]);

    $self->{global} = { 
        health => $snmp_result->{$oid_gps_health},
        latitude => $snmp_result->{$oid_gps_latitude},
        longitude => $snmp_result->{$oid_gps_longitude},
        satellites => $snmp_result->{$oid_gps_satellites},
    };
}

1;

__END__

=head1 MODE

Check GPS status

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '%{satellites} =~ /No satellites in view/')
Can used special variables like: %{health}, %{satellites}, %{latitude}, %{longitude}

=item B<--critical-status>

Set critical threshold for status (Default: '')
Can used special variables like: %{health}, %{satellites}, %{latitude}, %{longitude}

=back

=cut
