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

package network::f5::bigip::snmp::mode::failover;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_syncstatus_output {
    my ($self, %options) = @_;

    return "Sync status is '" . $self->{result_values}->{syncstatus} . "'";
}

sub custom_failoverstatus_output {
    my ($self, %options) = @_;

    return "Failover status is '" . $self->{result_values}->{failoverstatus} . "'";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0, message_separator => ' - ' },
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'sync-status', type => 2, critical_default => '%{syncstatus} =~ /unknown|syncFailed|syncDisconnected|incompatibleVersion/', set => {
                key_values => [ { name => 'syncstatus' } ],
                closure_custom_output => \&custom_syncstatus_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
       { label => 'failover-status', type => 2, critical_default => '%{failoverstatus} =~ /unknown/', set => {
                key_values => [ { name => 'failoverstatus' } ],
                closure_custom_output => \&custom_failoverstatus_output,
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

my %map_boolean = (
    0 => 'false',
    1 => 'true'
);
my %map_sync_status = (
    0 => 'unknown',
    1 => 'syncing',
    2 => 'needManualSync',
    3 => 'inSync',
    4 => 'syncFailed',
    5 => 'syncDisconnected',
    6 => 'standalone',
    7 => 'awaitingInitialSync',
    8 => 'incompatibleVersion',
    9 => 'partialSync'
);
my %map_failover_status = (
    0 => 'unknown',
    1 => 'offline',
    2 => 'forcedOffline',
    3 => 'standby',
    4 => 'active'
);

my $mapping = {
    sysAttrFailoverIsRedundant  => { oid => '.1.3.6.1.4.1.3375.2.1.1.1.1.13', map => \%map_boolean },
    sysAttrModeMaint            => { oid => '.1.3.6.1.4.1.3375.2.1.1.1.1.21', map => \%map_boolean },
    sysCmSyncStatusId           => { oid => '.1.3.6.1.4.1.3375.2.1.14.1.1', map => \%map_sync_status },
    sysCmFailoverStatusId       => { oid => '.1.3.6.1.4.1.3375.2.1.14.3.1', map => \%map_failover_status }
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids => [
            $mapping->{sysAttrFailoverIsRedundant}->{oid} . '.0',
            $mapping->{sysAttrModeMaint}->{oid} . '.0',
            $mapping->{sysCmSyncStatusId}->{oid} . '.0',
            $mapping->{sysCmFailoverStatusId}->{oid} . '.0'
        ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => '0');
    
    if ($result->{sysAttrModeMaint} eq 'true') {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'maintenance mode is active'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    if ($result->{sysAttrFailoverIsRedundant} eq 'false') {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => 'failover mode is disable'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $self->{global} = { 
        syncstatus => $result->{sysCmSyncStatusId},
        failoverstatus => $result->{sysCmFailoverStatusId},
    };
}

1;

__END__

=head1 MODE

Check failover status.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).

=item B<--warning-sync-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{syncstatus}

=item B<--critical-sync-status>

Define the conditions to match for the status to be CRITICAL (default: '%{syncstatus} =~ /unknown|syncFailed|syncDisconnected|incompatibleVersion/').
You can use the following variables: %{syncstatus}

=item B<--warning-failover-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{failoverstatus}

=item B<--critical-failover-status>

Define the conditions to match for the status to be CRITICAL (Default: '%{failoverstatus} =~ /unknown/').
You can use the following variables: %{failoverstatus}

=back

=cut
