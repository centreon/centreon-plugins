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

package hardware::server::cisco::ucs::snmp::mode::mgmtentities;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [role: %s][services status: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{role},
        $self->{result_values}->{services_status}
    );
}

sub prefix_mgmt_output {
    my ($self, %options) = @_;

    return sprintf(
        "Management entity '%s' ",
        $options{instance_value}->{dn}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Management entities ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
        { name => 'mgmt', type => 1, cb_prefix_output => 'prefix_mgmt_output', message_multiple => 'All management entities are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'management_entities.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{mgmt} = [
        {
            label => 'status', type => 2,
            unknown_default => '%{role} =~ /unknown/ or %{status} eq "unknown" or %{services_status} eq "unknown"',
            critical_default => '%{role} =~ /electionFailed|inapplicable/ or %{status} eq "down" or %{services_status} eq "down"',
            set => {
                key_values => [
                    { name => 'dn' }, { name => 'role' },
                    { name => 'services_status' }, { name => 'status' },
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

my $map_role = {
    0 => 'unknown', 1 => 'primary',
    2 => 'subordinate', 3 => 'inapplicable',
    4 => 'electionInProgress', 5 => 'electionFailed'
};
my $map_state = {
    0 => 'unknown', 1 => 'up', 2 => 'down'
};
my $map_services_state = {
    0 => 'unknown', 1 => 'up', 2 => 'unresponsive', 3 => 'down', 4 => 'switchoverInProgress'
};

my $mapping = {
    dn              => { oid => '.1.3.6.1.4.1.9.9.719.1.31.8.1.2' }, # cucsMgmtEntityDn
    role            => { oid => '.1.3.6.1.4.1.9.9.719.1.31.8.1.14', map => $map_role }, # cucsMgmtEntityLeadership
    services_status => { oid => '.1.3.6.1.4.1.9.9.719.1.31.8.1.15', map => $map_services_state }, # cucsMgmtEntityMgmtServicesState
    status          => { oid => '.1.3.6.1.4.1.9.9.719.1.31.8.1.17', map => $map_state } # cucsMgmtEntityState
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ map({ oid => $_->{oid} }, values(%$mapping)) ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{global} = { total => 0, online => 0, offline => 0 };
    $self->{mgmt} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{dn}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $self->{mgmt}->{ $result->{dn} } = $result;
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check management entities.

=over 8

=item B<--unknown-status>

Set unknown threshold for status (Default: '%{role} =~ /unknown/ or %{status} eq "unknown" or %{services_status} eq "unknown"')
Can used special variables like: %{dn}, %{role}, %{services_status}, %{status}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{dn}, %{role}, %{services_status}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{role} =~ /electionFailed|inapplicable/ or %{status} eq "down" or %{services_status} eq "down"').
Can used special variables like: %{dn}, %{role}, %{services_status}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total'.

=back

=cut
