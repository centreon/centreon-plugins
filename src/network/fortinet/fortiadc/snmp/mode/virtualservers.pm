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

package network::fortinet::fortiadc::snmp::mode::virtualservers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_throughput_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        unit => 'b/s',
        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}],
        value => $self->{result_values}->{throughput},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_connections_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => [$self->{result_values}->{vdom}, $self->{result_values}->{name}],
        value => $self->{result_values}->{connections},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "status: %s [%s]",
        $self->{result_values}->{status},
        $self->{result_values}->{state}
    );
}

sub vs_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking virtual server '%s' [vdom: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{vdom}
    );
}

sub prefix_vs_output {
    my ($self, %options) = @_;

    return sprintf(
        "virtual server '%s' [vdom: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{vdom}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Virtual servers ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', },
        { name => 'vs', type => 3, cb_prefix_output => 'prefix_vs_output', cb_long_output => 'vs_long_output',
          indent_long_output => '    ', message_multiple => 'All virtual servers are ok',
            group => [
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'stats', type => 0, skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'virtualservers-detected', display_ok => 0, nlabel => 'virtual_servers.detected.count', set => {
                key_values => [ { name => 'detected' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'virtualservers-healthy', display_ok => 0, nlabel => 'virtual_servers.healthy.count', set => {
                key_values => [ { name => 'healthy' } ],
                output_template => 'healthy: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} eq "unhealthy"',
            set => {
                key_values => [
                    { name => 'state' }, { name => 'status' },
                    { name => 'name' }, { name => 'vdom' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{stats} = [
        { label => 'virtualserver-connections', nlabel => 'virtual_server.connections.count', set => {
                key_values => [ { name => 'connections' }, { name => 'name' }, { name => 'vdom' } ],
                output_template => 'connections: %s',
                closure_custom_perfdata => $self->can('custom_connections_perfdata')
            }
        },
        { label => 'virtualserver-throughput', nlabel => 'virtual_server.throughput.bitspersecond', set => {
                key_values => [ { name => 'throughput' }, { name => 'name' }, { name => 'vdom' } ],
                output_template => 'throughput: %.2f %s/s',
                output_change_bytes => 2,
                closure_custom_perfdata => $self->can('custom_throughput_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' },
        'filter-vdom:s' => { name => 'filter_vdom' }
    });

    return $self;
}

my $map_plex_status = {
    1 => 'offline', 2 => 'resyncing', 3 => 'online'
};

my $mapping = {
    state       => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.3' }, # fadcVSStatus
    status      => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.4' }, # fadcVSHealth
    connections => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.6' }, # fadcVSConcurrent
    throughput  => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.7' }, # fadcVSThroughputKbps
    vdom        => { oid => '.1.3.6.1.4.1.12356.112.3.2.1.8' }  # fadcVSVdom
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_vsName = '.1.3.6.1.4.1.12356.112.3.2.1.2'; # fadcVSName
    my $snmp_result = $options{snmp}->get_table(oid => $oid_vsName, nothing_quit => 1);

    $self->{global} = { detected => 0, healthy => 0, unhealthy => 0 };
    $self->{vs} = {};
    foreach my $oid (keys %$snmp_result) {
        $oid =~ /^$oid_vsName\.(.*)$/;
        my $instance = $1;
        my $name = $snmp_result->{$oid};

        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping virtual server '" . $name . "'.", debug => 1);
            next;
        }

        $self->{vs}->{$instance} = { name => $name };
    }

    return if (scalar(keys %{$self->{vs}}) <= 0);
    
    $options{snmp}->load(
        oids => [
            map($_->{oid}, values(%$mapping)) 
        ],
        instances => [ map($_, keys %{$self->{vs}}) ],
        instance_regexp => '^(.*)$'
    );
    $snmp_result = $options{snmp}->get_leef();
    
    foreach (keys %{$self->{vs}}) {
        my $result = $options{snmp}->map_instance(mapping => $mapping, results => $snmp_result, instance => $_);
        if (defined($self->{option_results}->{filter_vdom}) && $self->{option_results}->{filter_vdom} ne '' &&
            $result->{vdom} !~ /$self->{option_results}->{filter_vdom}/) {
            $self->{output}->output_add(long_msg => "skipping vdom '" . $result->{vdom} . "'.", debug => 1);
            next;
        }

        $self->{vs}->{$_}->{vdom} = $result->{vdom};
        $self->{vs}->{$_}->{status} = {
            name => $self->{vs}->{$_}->{name},
            state => lc($result->{state}),
            status => lc($result->{status}),
            vdom => $result->{vdom}
        };
        $self->{vs}->{$_}->{stats} = {
            name => $self->{vs}->{$_}->{name},
            vdom => $result->{vdom},
            connections => $result->{connections},
            throughput => $result->{throughput} * 1000
        };

        $self->{global}->{detected}++;
        $self->{global}->{ lc($result->{status}) }++;
    }
}

1;

__END__

=head1 MODE

Check virtual servers.

=over 8

=item B<--filter-name>

Filter virtual servers by name.

=item B<--filter-vdom>

Filter virtual servers by vdom name.

=item B<--unknown-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{state}, %{name}, %{vdom}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{state}, %{name}, %{vdom}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} eq "unhealthy"').
You can use the following variables: %{status}, %{state}, %{name}, %{vdom}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'virtualservers-detected', 'virtualservers-healthy',
'virtualserver-connections', 'virtualserver-throughput'.

=back

=cut
