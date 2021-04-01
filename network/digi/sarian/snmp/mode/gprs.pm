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

package network::digi::sarian::snmp::mode::gprs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    my $msg;

    $msg = 'Attachement : ' . $self->{result_values}->{attachement};
    $msg .= ', Registration : ' . $self->{result_values}->{registered};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{registered} = $options{new_datas}->{$self->{instance} . '_registered'};
    $self->{result_values}->{attachement} = $options{new_datas}->{$self->{instance} . '_attachement'};
    return 0;
}

sub custom_tech_output {
    my ($self, %options) = @_;
    my $msg;

    $msg = 'Technology : ' . $self->{result_values}->{technology};
    return $msg;
}

sub custom_tech_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{technology} = $options{new_datas}->{$self->{instance} . '_technology'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'gprs', type => 0 },
    ];
    $self->{maps_counters}->{gprs} = [
        { label => 'signal', set => {
                key_values => [ { name => 'signal' } ],
                output_template => 'Signal : %d dBm',
                perfdatas => [
                    { label => 'signal_strenght', value => 'signal', template => '%s',
                      unit => 'dBm' },
                ],
            }
        },
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'registered' }, { name => 'attachement' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'technology', threshold => 0, set => {
                key_values => [ { name => 'technology' } ],
                closure_custom_calc => $self->can('custom_tech_calc'),
                closure_custom_output => $self->can('custom_tech_output'),
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
                                  "warning-status:s"            => { name => 'warning_status', default => '' },
                                  "critical-status:s"           => { name => 'critical_status', default => '%{attachement} eq "notAttached" or %{registered} !~ /registeredHostNetwork|registeredRoaming/' },
                                  "warning-technology:s"    => { name => 'warning_technology', default => '' },
                                  "critical-technology:s"   => { name => 'critical_technology', default => '%{technology} !~ /2G|3G|4G/' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'warning_technology', 'critical_technology']);
}

my %map_gprs_registration = (
    0 => 'notRegisteredNotSearching',
    1 => 'registeredHostNetwork',
    2 => 'notRegisteredSearching',
    3 => 'registrationDenied',
    4 => 'unknown',
    5 => 'registeredRoaming',
    6 => 'unrecognised',
);

my %map_gprs_attachement = (
    0 => 'notAtached',
    1 => 'attached',
);

my %map_gprs_technology = (
    1 => 'unknown',
    2 => 'GPRS(2G)',
    3 => 'EDGE(2G)',
    4 => 'UMTS(3G)',
    5 => 'HSDPA(3G)',
    6 => 'HSUPA(3G)',
    7 => 'DC-HSPA+(3G)',
    8 => 'LTE(4G)',
);

my $oid_gprsSignalStrength = '.1.3.6.1.4.1.16378.10000.2.1.0';
my $oid_gprsRegistered = '.1.3.6.1.4.1.16378.10000.2.2.0';
my $oid_gprsAttached = '.1.3.6.1.4.1.16378.10000.2.3.0';
my $oid_gprsNetworkTechnology = '.1.3.6.1.4.1.16378.10000.2.7.0';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{gprs} = {};
    $self->{results} = $options{snmp}->get_leef(oids => [ $oid_gprsSignalStrength, $oid_gprsRegistered,
                                                          $oid_gprsAttached, $oid_gprsNetworkTechnology ],
                                                nothing_quit => 1);

    $self->{gprs} = { signal => $self->{results}->{$oid_gprsSignalStrength},
                      registered => $map_gprs_registration{$self->{results}->{$oid_gprsRegistered}},
                      attachement => $map_gprs_attachement{$self->{results}->{$oid_gprsAttached}},
                      technology => $map_gprs_technology{$self->{results}->{$oid_gprsNetworkTechnology}},
                    };

}

1;

__END__

=head1 MODE

Check GPRS status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='signal|technology'

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{registered}, %{attachement}

=item B<--critical-status>

Set critical threshold for status (Default: '%{attachement} eq "attached" and %{registered} !~ /registeredHostNetwork|registeredRoaming/'
Can used special variables like: %{registered}, %{attachement}

=item B<--warning-technology>

Set warning threshold for technology.
Use special variables %{technology}.

=item B<--critical-technology>

Set critical threshold for technology (Default: '%{technology} !~ /2G|3G|4G/'
Use special variables %{technology}.

=item B<--warning-signal>

Threshold warning for signal strength.

=item B<--critical-signal>

Threshold critical  for signal strength.

=back

=cut
