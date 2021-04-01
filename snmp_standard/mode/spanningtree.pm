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

package snmp_standard::mode::spanningtree;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "spanning tree state is '%s' [op status: '%s'] [admin status: '%s'] [index: '%s']",
        $self->{result_values}->{state}, $self->{result_values}->{op_status},
        $self->{result_values}->{admin_status}, $self->{result_values}->{index}
    )
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{port} = $options{new_datas}->{$self->{instance} . '_description'};
    $self->{result_values}->{state} = $options{new_datas}->{$self->{instance} . '_state'};
    $self->{result_values}->{admin_status} = $options{new_datas}->{$self->{instance} . '_admin_status'};
    $self->{result_values}->{op_status} = $options{new_datas}->{$self->{instance} . '_op_status'};
    $self->{result_values}->{index} = $options{new_datas}->{$self->{instance} . '_index'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'spanningtrees', type => 1, cb_prefix_output => 'prefix_peers_output', message_multiple => 'All spanning trees are ok' },
    ];

    $self->{maps_counters}->{spanningtrees} = [
        { label => 'status', threshold => 0, set => {
                key_values => [
                    { name => 'state' }, { name => 'admin_status' }, { name => 'op_status' },
                    { name => 'index' }, { name => 'description' }
                ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_peers_output {
    my ($self, %options) = @_;

    return "Port '" . $options{instance_value}->{description} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-port:s'     => { name => 'filter_port' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{op_status} =~ /up/ && %{state} =~ /blocking|broken/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

my $mapping_state = {
    1 => 'disabled',
    2 => 'blocking',
    3 => 'listening',
    4 => 'learning',
    5 => 'forwarding',
    6 => 'broken',
    10 => 'not defined'
};
my $mapping_status = {
    1 => 'enabled',
    2 => 'disabled'
};

my $mapping = {
    dot1dStpPortState   => { oid => '.1.3.6.1.2.1.17.2.15.1.3', map => $mapping_state },
    dot1dStpPortEnable  => { oid => '.1.3.6.1.2.1.17.2.15.1.4', map => $mapping_status }
};
my $oid_dot1dStpPortEntry = '.1.3.6.1.2.1.17.2.15.1';

my $oid_dot1dBasePortIfIndex = '.1.3.6.1.2.1.17.1.4.1.2';

my $mapping_if_status = {
    1 => 'up', 2 => 'down', 3 => 'testing', 4 => 'unknown',
    5 => 'dormant', 6 => 'notPresent', 7 => 'lowerLayerDown',
    100 => 'notfound'
};
my $oid_ifDesc = '.1.3.6.1.2.1.2.2.1.2';
my $oid_ifAdminStatus = '.1.3.6.1.2.1.2.2.1.7';
my $oid_ifOpStatus = '.1.3.6.1.2.1.2.2.1.8';

sub manage_selection {
    my ($self, %options) = @_;

    $self->{spanningtrees} = {};
    my $results = $options{snmp}->get_table(oid => $oid_dot1dStpPortEntry, start => $mapping->{dot1dStpPortState}->{oid}, end => $mapping->{dot1dStpPortEnable}->{oid}, nothing_quit => 1);

    my @instances = ();
    foreach my $oid (keys %$results) {
        next if ($oid !~ /^$mapping->{dot1dStpPortState}->{oid}\.(.*)/);
        my $instance = $1;
        my $map_result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        if ($map_result->{dot1dStpPortEnable} =~ /disabled/) {
            $self->{output}->output_add(long_msg => sprintf("skipping interface '%d': Stp port disabled", $instance), debug => 1);
            next;
        }
        push @instances, $instance;
    }

    $options{snmp}->load(oids => [ $oid_dot1dBasePortIfIndex ], instances => [ @instances ]);
    my $result = $options{snmp}->get_leef(nothing_quit => 1);

    foreach my $oid (keys %$result) {
        next if ($oid !~ /^$oid_dot1dBasePortIfIndex\./ || !defined($result->{$oid}));
        $options{snmp}->load(oids => [ $oid_ifDesc . "." . $result->{$oid}, $oid_ifAdminStatus . "." . $result->{$oid}, $oid_ifOpStatus . "." . $result->{$oid} ]);
    }
    my $result_if = $options{snmp}->get_leef();

    foreach my $instance (@instances) {
        my $map_result = $options{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);

        my $state = (defined($map_result->{dot1dStpPortState})) ? $map_result->{dot1dStpPortState} : 'not defined';
        my $description = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifDesc . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : $instance . '.unknown';
        my $admin_status = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifAdminStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifAdminStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 100;
        my $op_status = (defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance}) && defined($result_if->{$oid_ifOpStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}})) ?
            $result_if->{$oid_ifOpStatus . '.' . $result->{$oid_dot1dBasePortIfIndex . '.' . $instance}} : 100;

        if (defined($self->{option_results}->{filter_port}) && $self->{option_results}->{filter_port} ne '' &&
            $description !~ /$self->{option_results}->{filter_port}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping interface '%s': filtered with options", $description), debug => 1);
            next;
        }

        if (!defined($result->{$oid_dot1dBasePortIfIndex . '.' . $instance})) {
            $self->{output}->output_add(long_msg => sprintf("skipping spanning '%s': filtered with options", $instance), debug => 1);
            next;
        }

        $self->{spanningtrees}->{$instance} = {
            state => $state,
            admin_status => $mapping_if_status->{$admin_status},
            op_status => $mapping_if_status->{$op_status},
            index => $result->{$oid_dot1dBasePortIfIndex . '.' . $instance},
            description => $description
        };
    }

    if (scalar(keys %{$self->{spanningtrees}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No port with Spanning Tree Protocol found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check port Spanning Tree Protocol current state (BRIDGE-MIB).

=over 8

=item B<--filter-port>

Filter on port description (can be a regexp).

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{state}, %{op_status},
%{admin_status}, %{port}, %{index}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{op_status} =~ /up/ && %{state} =~ /blocking|broken/').
Can used special variables like: %{state}, %{op_status},
%{admin_status}, %{port}, %{index}.

=back

=cut
