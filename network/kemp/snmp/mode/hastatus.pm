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

package network::kemp::snmp::mode::hastatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_hastatus_output {
    my ($self, %options) = @_;
    
    my $msg = 'HA status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_syncstatus_output {
    my ($self, %options) = @_;
    
    my $msg = 'Synchronization l4 status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_hastatus_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_hAstate'};
    $self->{result_values}->{label} = 'ha_status';
    return 0;
}

sub custom_syncstatus_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_daemonState'};
    $self->{result_values}->{label} = 'sync_status';
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'ha-status', threshold => 0, set => {
                key_values => [ { name => 'hAstate' } ],
                closure_custom_calc => $self->can('custom_hastatus_calc'),
                closure_custom_output => $self->can('custom_hastatus_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'sync-status', threshold => 0, set => {
                key_values => [ { name => 'daemonState' } ],
                closure_custom_calc => $self->can('custom_syncstatus_calc'),
                closure_custom_output => $self->can('custom_syncstatus_output'),
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
                                  "warning-ha-status:s"        => { name => 'warning_ha_status', default => '' },
                                  "critical-ha-status:s"       => { name => 'critical_ha_status', default => '' },
                                  "warning-sync-status:s"        => { name => 'warning_sync_status', default => '' },
                                  "critical-sync-status:s"       => { name => 'critical_sync_status', default => '' },
                                });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_ha_status', 'critical_ha_status', 'warning_sync_status', 'critical_sync_status']);
}

my %map_daemon_state = (
    0 => 'none',
    1 => 'master',
    2 => 'backup',
);
my %map_ha_state = (
    0 => 'none',
    1 => 'master',
    2 => 'standby',
    3 => 'passive',
);
my $mapping = {
    daemonState     => { oid => '.1.3.6.1.4.1.12196.13.0.7', map => \%map_daemon_state },
    hAstate         => { oid => '.1.3.6.1.4.1.12196.13.0.9', map => \%map_ha_state },
};

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vs} = {};
    my $snmp_result = $options{snmp}->get_leef(oids => [ $mapping->{daemonState}->{oid} . '.0', $mapping->{hAstate}->{oid} . '.0' ],
                                               nothing_quit => 1);
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');

    $self->{global} = { %$result };
}

1;

__END__

=head1 MODE

Check ha status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='^ha-status$'

=item B<--warning-ha-status>

Set warning threshold for status (Default: none).
Can used special variables like: %{status}, %{display}

=item B<--critical-ha-status>

Set critical threshold for status (Default: none).
Can used special variables like: %{status}, %{display}

=item B<--warning-sync-status>

Set warning threshold for status (Default: none).
Can used special variables like: %{status}, %{display}

=item B<--critical-sync-status>

Set critical threshold for status (Default: none).
Can used special variables like: %{status}, %{display}

=back

=cut
