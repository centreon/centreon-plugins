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

package network::paloalto::snmp::mode::panorama;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return "connection status is '" . $self->{result_values}->{status} . "'";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'pan', type => 1, cb_prefix_output => 'prefix_pan_output', message_multiple => 'All panorama connection statuses are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{pan} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_pan_output {
    my ($self, %options) = @_;

    return "panorama '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /not-connected/i' },
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

    my $oid_panMgmtPanoramaConnected = '.1.3.6.1.4.1.25461.2.1.2.4.1.0';
    my $oid_panMgmtPanorama2Connected = '.1.3.6.1.4.1.25461.2.1.2.4.2.0';
    my $snmp_result = $options{snmp}->get_leef(
        oids => [$oid_panMgmtPanoramaConnected, $oid_panMgmtPanorama2Connected],
        nothing_quit => 1
    );

    $self->{pan} = {
        1 => {
            display => 1,
            status => $snmp_result->{$oid_panMgmtPanoramaConnected},
        },
        2 => {
            display => 2,
            status => $snmp_result->{$oid_panMgmtPanorama2Connected},
        }
    };
}

1;

__END__

=head1 MODE

Check panorama connection status.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like:  %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /not-connected/i').
Can used special variables like: %{status}, %{display}

=back

=cut
    
