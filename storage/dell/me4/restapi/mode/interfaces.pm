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

package storage::dell::me4::restapi::mode::interfaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [health: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{health}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'ports', type => 3, cb_prefix_output => 'prefix_port_output', cb_long_output => 'port_long_output', indent_long_output => '    ', message_multiple => 'All interfaces are ok',
            group => [
                { name => 'port_global', type => 0, skipped_code => { -10 => 1 } },
                { name => 'interfaces', display_long => 1, cb_prefix_output => 'prefix_interface_output',  message_multiple => 'All interfaces are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    $self->{maps_counters}->{port_global} = [
         { label => 'port-status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'health'}, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'read-iops', nlabel => 'port.io.read.usage.iops', set => {
                key_values => [ { name => 'number_of_reads', per_second => 1 }, { name => 'display' } ],
                output_template => 'read iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-iops', nlabel => 'port.io.write.usage.iops', set => {
                key_values => [ { name => 'number_of_writes', per_second => 1 }, { name => 'display' } ],
                output_template => 'write iops: %.2f',
                perfdatas => [
                    { template => '%.2f', unit => 'iops', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'read-traffic', nlabel => 'port.traffic.read.usage.bitspersecond', set => {
                key_values => [ { name => 'data_read_numeric', per_second => 1 }, { name => 'display' } ],
                output_template => 'read traffic: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'write-traffic', nlabel => 'port.traffic.write.usage.bitspersecond', set => {
                key_values => [ { name => 'data_write_numeric', per_second => 1 }, { name => 'display' } ],
                output_template => 'write traffic: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%d', unit => 'b/s', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{interfaces} = [
        { label => 'interface-disparity-errors', nlabel => 'port.interface.disparity.errors.count', set => {
                key_values => [ { name => 'disparity_errors' }, { name => 'display' } ],
                output_template => 'disparity errors: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'interface-lost-dwords', nlabel => 'port.interface.lost.dwords.count', set => {
                key_values => [ { name => 'lost_dwords' }, { name => 'display' } ],
                output_template => 'lost dwords: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'interface-invalid-dwords', nlabel => 'port.interface.invalid.dwords.count', set => {
                key_values => [ { name => 'invalid_dwords' }, { name => 'display' } ],
                output_template => 'invalid dwords: %s',
                perfdatas => [
                    { template => '%d', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub port_long_output {
    my ($self, %options) = @_;

    return "checking port '" . $options{instance_value}->{display} . "'";
}

sub prefix_port_output {
    my ($self, %options) = @_;

    return "port '" . $options{instance_value}->{display} . "' ";
}

sub prefix_interface_output {
    my ($self, %options) = @_;

    return "interface '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-port-name:s'     => { name => 'filter_port_name' },
        'unknown-port-status:s'  => { name => 'unknown_port_status', default => '%{health} =~ /unknown/i' },
        'warning-port-status:s'  => { name => 'warning_port_status', default => '%{health} =~ /degraded/i' },
        'critical-port-status:s' => { name => 'critical_port_status', default => '%{health} =~ /fault/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_port_status', 'critical_port_status', 'unknown_port_status']);
}

my $mapping_status = {
    0 => 'up',
    1 => 'down',
    2 => 'notInstalled'
};
my $mapping_health = {
    0 => 'ok', 1 => 'degraded', 2 => 'fault', 3 => 'unknown', 4 => 'notAvailable'
};

sub manage_selection {
    my ($self, %options) = @_;

    my $result_ports = $options{custom}->request_api(method => 'GET', url_path =>  '/api/show/ports');
    my $result_ports_stats = $options{custom}->request_api(method => 'GET', url_path =>  '/api/show/host-port-statistics');
    my $result_logical_interfaces = $options{custom}->request_api(method => 'GET', url_path =>  '/api/show/host-phy-statistics');

    my $mapping_ports = {};

    $self->{ports} = {};
    foreach my $port (@{$result_ports->{port}}) {
        my $port_name = $port->{port};

        next if (defined($self->{option_results}->{filter_port_name}) && $self->{option_results}->{filter_port_name} ne ''
            && $port_name !~ /$self->{option_results}->{filter_port_name}/);

        $mapping_ports->{ $port->{'durable-id'} } = $port_name;

        $self->{ports}->{$port_name} = {
            display => $port_name,
            port_global => {
                display => $port_name,
                health => $mapping_health->{ $port->{'health-numeric'} },
                status => $mapping_status->{ $port->{'status-numeric'} }
            },
            interfaces => {}
        };
    }

    foreach (@{$result_ports_stats->{'host-port-statistics'}}) {
        next if (!defined($mapping_ports->{ $_->{'durable-id'} }));

        $self->{ports}->{ $mapping_ports->{ $_->{'durable-id'} } }->{port_global}->{number_of_reads} = $_->{'number-of-reads'};
        $self->{ports}->{ $mapping_ports->{ $_->{'durable-id'} } }->{port_global}->{number_of_writes} = $_->{'number-of-writes'};
        $self->{ports}->{ $mapping_ports->{ $_->{'durable-id'} } }->{port_global}->{data_read_numeric} = $_->{'data-read-numeric'};
        $self->{ports}->{ $mapping_ports->{ $_->{'durable-id'} } }->{port_global}->{data_write_numeric} = $_->{'data-write-numeric'};
        
    }

    foreach (@{$result_logical_interfaces->{'sas-host-phy-statistics'}}) {
        next if (!defined($self->{ports}->{ $_->{port} }));

        $self->{ports}->{ $_->{port} }->{interfaces}->{ $_->{phy} } = {
            display => $_->{phy},
            disparity_errors => int($_->{'disparity-errors'}),
            invalid_dwords => int($_->{'invalid-dwords'}),
            lost_dwords => int($_->{'lost-dwords'})
        };
    }

    $self->{cache_name} = 'dell_me4_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_port_name}) ? md5_hex($self->{option_results}->{filter_port_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check interfaces.

=over 8

=item B<--filter-port-name>

Filter port name (Can be a regexp).

=item B<--unknown-port-status>

Set unknown threshold for status (Default: '%{status} =~ /unknown/i').
Can used special variables like: %{status}, %{health}, %{display}

=item B<--warning-port-status>

Set warning threshold for status (Default: '%{status} =~ /degraded/i').
Can used special variables like: %{status}, %{health}, %{display}

=item B<--critical-port-status>

Set critical threshold for status (Default: '%{status} =~ /fault/i').
Can used special variables like: %{status}, %{health}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'read-iops', 'write-iops', 'read-traffic', 'write-traffic',
'interface-disparity-errors', 'interface-lost-dwords', 'interface-invalid-dwords'.

=back

=cut
