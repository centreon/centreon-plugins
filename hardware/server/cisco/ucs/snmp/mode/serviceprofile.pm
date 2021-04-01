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

package hardware::server::cisco::ucs::snmp::mode::serviceprofile;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_sp_output {
    my ($self, %options) = @_;

    return sprintf(
        "Service profile '%s' ",
        $options{instance_value}->{dn}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Service profiles ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', cb_prefix_output => 'prefix_global_output', type => 0 },
        { name => 'sp', type => 1, cb_prefix_output => 'prefix_sp_output', message_multiple => 'All service profiles are ok' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'serviceprofiles.total.count', display_ok => 0, set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'online', nlabel => 'serviceprofiles.online.count', display_ok => 0, set => {
                key_values => [ { name => 'online' }, { name => 'total' } ],
                output_template => 'online: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        },
        { label => 'offline', nlabel => 'serviceprofiles.offline.count', display_ok => 0, set => {
                key_values => [ { name => 'offline' }, { name => 'total' } ],
                output_template => 'offline: %s',
                perfdatas => [
                    { template => '%s', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{sp} = [
        {
            label => 'status', type => 2, critical_default => '%{status} eq "offline"',
            set => {
                key_values => [ { name => 'dn' }, { name => 'status' } ],
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

my $map_status = {
    1 => 'online',
    2 => 'offline'
};

my $mapping = {
    dn     => { oid => '.1.3.6.1.4.1.9.9.719.1.26.2.1.2' }, # cucsLsBindingDn
    status => { oid => '.1.3.6.1.4.1.9.9.719.1.26.2.1.10', map => $map_status } # cucsLsBindingOperState
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_multiple_table(
        oids => [ map({ oid => $_->{oid} }, values(%$mapping)) ],
        return_type => 1,
        nothing_quit => 1
    );

    $self->{global} = { total => 0, online => 0, offline => 0 };
    $self->{sp} = {};
    foreach my $oid (keys %$snmp_result) {
        next if ($oid !~ /^$mapping->{dn}->{oid}\.(.*)$/);
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $1);
        $self->{sp}->{ $result->{dn} } = $result;
        $self->{global}->{ $result->{status} }++;
        $self->{global}->{total}++;
    }
}

1;

__END__

=head1 MODE

Check service profiles.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{dn}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "offline"').
Can used special variables like: %{dn}, %{status}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'total', 'online', 'offline'.

=back

=cut
