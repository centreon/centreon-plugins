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
# Authors : Thomas Gourdin thomas.gourdin@gmail.com

package hardware::devices::timelinkmicro::tms6001::snmp::mode::antenna;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output { 
    my ($self, %options) = @_;

    return 'antenna status: ' . $self->{result_values}->{status};
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '%{status} =~ /shorted/i' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} =~ /notConnected/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

my $mapping_status = {
    C => 'connected',
    S => 'shorted/poweroff',
    N => 'notConnected'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_tsGNSSAntenna = '.1.3.6.1.4.1.22641.100.4.1.4.0';
    my $snmp_result = $options{snmp}->get_leef(oids => [ $oid_tsGNSSAntenna ], nothing_quit => 1);

    $self->{global} = {
        status => $mapping_status->{ $snmp_result->{$oid_tsGNSSAntenna} }
    };
}

1;

__END__

=head1 MODE

Check antenna.

=over 8

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}

=item B<--warning-status>

Set warning threshold for status (Default: '%{status} =~ /shorted/i').
Can used special variables like: %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} =~ /notConnected/i').
Can used special variables like: %{status}

=back

=cut
