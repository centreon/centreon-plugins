#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::efficientip::snmp::mode::status;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return "Status: '" . $self->{result_values}->{status} . "', Role: '" . $self->{result_values}->{role} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => COUNTER_TYPE_GLOBAL }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status', type => COUNTER_KIND_TEXT,
            critical_default => '%{status} =~ /invalid credentials|replication stopped|timeout/',
            warning_default => '%{status} =~ /upgrading|split-brain/',
            unknown_default => '%{status} =~ /not configured|unknown/',
            set => {
                key_values => [ { name => 'status' }, { name => 'role' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { });

    return $self;
}

my $map_role = {
    0 => 'standalone',
    1 => 'master',
    2 => 'hot-standby',
    3 => 'master recovered',
    4 => 'remote managed'
};

my $map_state = {
    0 => 'ok',
    1 => 'not configured',
    2 => 'upgrading',
    3 => 'init standby',
    4 => 'invalid credentials',
    5 => 'remote managed',
    6 => 'timeout',
    7 => 'split-brain',
    8 => 'replication stopped',
    9 => 'init master'
};

my $mapping = {
    role   => { oid => '.1.3.6.1.4.1.2440.1.17.2.1', map => $map_role },  # eipSdsMemberRole
    status => { oid => '.1.3.6.1.4.1.2440.1.17.2.2', map => $map_state }  # eipSdsMemberStatus
};

sub manage_selection {
    my ($self, %options) = @_;

    my $snmp_result = $options{snmp}->get_leef(
        oids         => [ map($_->{oid} . '.0', values(%$mapping)) ],
        nothing_quit => 1
    );
    my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => 0);

    $self->{global} = {
        status => $result->{status},
        role   => $result->{role}
    };
}

1;

__END__

=head1 MODE

Check Efficient IP SOLIDserver role and status.

Values of the variables used in C<--warning-status>, C<--critical-status> and C<--unknown-status>:

%{status}: 'ok', 'not configured', 'upgrading', 'init standby', 'invalid credentials', 'remote managed',
'timeout', 'split-brain', 'replication stopped', 'init master' or 'unknown' (value not known by the plugin).

%{role}: 'standalone', 'master', 'hot-standby', 'master recovered', 'remote managed' or 'unknown'.

=over 8

=item B<--warning-status>

Define the conditions to match for the status to be WARNING. (default: '%{status} =~ /upgrading|split-brain/')
Can be used with special variables like: %{status}, %{role}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL. (default: '%{status} =~ /invalid credentials|replication stopped|timeout/')
Can be used with special variables like: %{status}, %{role}

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN. (default: '%{status} =~ /not configured|unknown/')
Can be used with special variables like: %{status}, %{role}

=back

=cut
