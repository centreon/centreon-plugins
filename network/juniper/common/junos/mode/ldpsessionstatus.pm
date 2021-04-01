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

package network::juniper::common::junos::mode::ldpsessionstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{state} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_jnxMplsLdpSesState'};
    return 0;
}

sub prefix_session_output {
    my ($self, %options) = @_;
    
    return "Session between LDP entity '" . $options{instance_value}->{jnxMplsLdpEntityLdpId} . "' and LDP peer '" . $options{instance_value}->{jnxMplsLdpPeerLdpId} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'sessions', type => 1, cb_prefix_output => 'prefix_session_output', message_multiple => 'All sessions status are ok' },
    ];
    
    $self->{maps_counters}->{sessions} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'jnxMplsLdpSesState' }, { name => 'jnxMplsLdpEntityLdpId' },
                    { name => 'jnxMplsLdpPeerLdpId' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'last-change', set => {
                key_values => [ { name => 'jnxMplsLdpSesStateLastChangeHuman' }, { name => 'jnxMplsLdpSesStateLastChange' },
                    { name => 'label' } ],
                output_template => 'Last change: %s',
                perfdatas => [
                    { label => 'last_change', value => 'jnxMplsLdpSesStateLastChange', template => '%d',
                      min => 0, unit => 's', label_extra_instance => 1, instance_use => 'label' },
                ],
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
                                    "filter-entity:s"           => { name => 'filter_entity' },
                                    "filter-peer:s"             => { name => 'filter_peer' },
                                    "warning-status:s"          => { name => 'warning_status' },
                                    "critical-status:s"         => { name => 'critical_status', default => '%{state} !~ /operational/i' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my %map_state = (
    1 => 'nonexistent',
    2 => 'initialized',
    3 => 'openrec',
    4 => 'opensent',
    5 => 'operational',
);

my $mapping = {
    jnxMplsLdpSesStateLastChange => { oid => '.1.3.6.1.4.1.2636.3.36.1.3.3.1.1' },
    jnxMplsLdpSesState => { oid => '.1.3.6.1.4.1.2636.3.36.1.3.3.1.2', map => \%map_state },
};

my $oid_jnxMplsLdpSessionEntry = '.1.3.6.1.4.1.2636.3.36.1.3.3.1';

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{sessions} = {};

    my $results = $options{snmp}->get_table(oid => $oid_jnxMplsLdpSessionEntry, start => $mapping->{jnxMplsLdpSesStateLastChange}->{oid},
        end => $mapping->{jnxMplsLdpSesState}->{oid}, nothing_quit => 1);
    
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{jnxMplsLdpSesState}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        $instance =~ /^(\d+\.\d+\.\d+\.\d+)\.(\d+)\.\d+\.\d+\.(\d+\.\d+\.\d+\.\d+)\.(\d+)\.\d+$/;
        my $ldp_entity = $1 . ':' . $2;
        my $ldp_peer = $3 . ':' . $4;

        if (defined($self->{option_results}->{filter_entity}) && $self->{option_results}->{filter_entity} ne '' &&
            $ldp_entity !~ /$self->{option_results}->{filter_entity}/) {
            $self->{output}->output_add(long_msg => "skipping entity '" . $ldp_entity . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_peer}) && $self->{option_results}->{filter_peer} ne '' &&
            $ldp_peer !~ /$self->{option_results}->{filter_peer}/) {
            $self->{output}->output_add(long_msg => "skipping peer '" . $ldp_peer . "': no matching filter name.", debug => 1);
            next;
        }
        
        $self->{sessions}->{$instance} = {
            jnxMplsLdpSesStateLastChange => $result->{jnxMplsLdpSesStateLastChange} / 100,
            jnxMplsLdpSesStateLastChangeHuman => centreon::plugins::misc::change_seconds(value => $result->{jnxMplsLdpSesStateLastChange} / 100),
            jnxMplsLdpSesState => $result->{jnxMplsLdpSesState},
            jnxMplsLdpEntityLdpId => $ldp_entity,
            jnxMplsLdpPeerLdpId => $ldp_peer,
            label => $ldp_entity . "_". $ldp_peer,
        }
    }

    if (scalar(keys %{$self->{sessions}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No sessions found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check sessions status between the LDP entities and LDP peers.

=over 8

=item B<--filter-*>

Filter entities and/or peer.
Can be: 'entity', 'peer' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{state} !~ /operational/i').
Can used special variables like: %{state}

=item B<--warning-last-change>

Threshold warning in seconds.

=item B<--critical-last-change>

Threshold critical in seconds.

=back

=cut
