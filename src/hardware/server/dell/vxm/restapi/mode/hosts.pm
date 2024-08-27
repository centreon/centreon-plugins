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

package hardware::server::dell::vxm::restapi::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_host_output {
    my ($self, %options) = @_;

    return sprintf(
        "host '%s' [sn: %s] ",
        $options{instance_value}->{name},
        $options{instance_value}->{sn}
    );
}

sub host_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "host '%s' [sn: %s]",
        $options{instance_value}->{name},
        $options{instance_value}->{sn}
    );
}

sub prefix_nic_output {
    my ($self, %options) = @_;

    return sprintf(
        "nic '%s' [slot: %s] ",
        $options{instance_value}->{mac},
        $options{instance_value}->{slot}
    );
}

sub prefix_disk_output {
    my ($self, %options) = @_;

    return sprintf(
        "disk '%s' [bay: %s, slot: %s] ",
        $options{instance_value}->{sn},
        $options{instance_value}->{bay},
        $options{instance_value}->{slot}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'number of hosts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } },
        { name => 'hosts', type => 3, cb_prefix_output => 'prefix_host_output', cb_long_output => 'host_long_output', indent_long_output => '    ', message_multiple => 'All hosts are ok', 
            group => [
                { name => 'health', type => 0, skipped_code => { -10 => 1 } },
                { name => 'nics', type => 1, display_long => 1, cb_prefix_output => 'prefix_nic_output', message_multiple => 'All nics are ok', skipped_code => { -10 => 1 } },
                { name => 'disks', type => 1, display_long => 1, cb_prefix_output => 'prefix_disk_output', message_multiple => 'All disks are ok', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'hosts-detected', nlabel => 'hosts.detected.count', set => {
                key_values => [ { name => 'num_hosts' } ],
                output_template => 'detected: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        },
        { label => 'hosts-unhealthy', nlabel => 'hosts.unhealthy.count', set => {
                key_values => [ { name => 'unhealthy' } ],
                output_template => 'unhealthy: %s',
                perfdatas => [
                    { template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{health} = [
        {
            label => 'host-status',
            type => 2,
            warning_default => '%{status} =~ /warning/i',
            critical_default => '%{status} =~ /critical|error/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'sn' }, { name => 'name' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{nics} = [
        {
            label => 'nic-status',
            type => 2,
            set => {
                key_values => [ { name => 'status' }, { name => 'mac' }, { name => 'slot' } ],
                output_template => 'status: %s',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{disks} = [
        {
            label => 'disk-status',
            type => 2,
            critical_default => '%{status} !~ /OK/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'sn' }, { name => 'bay' }, { name => 'slot' } ],
                output_template => 'status: %s',
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
        'filter-host-name:s' => { name => 'filter_host_name' },
        'filter-host-sn:s'   => { name => 'filter_host_sn' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request(endpoint => '/hosts');

    $self->{global} = { num_hosts => 0, unhealthy => 0 };
    $self->{hosts} = {};
    foreach my $entry (@$results) {
        next if (defined($self->{option_results}->{filter_host_sn}) && $self->{option_results}->{filter_host_sn} ne ''
            && $entry->{sn} !~ /$self->{option_results}->{filter_host_sn}/);
        next if (defined($self->{option_results}->{filter_host_name}) && $self->{option_results}->{filter_host_name} ne ''
            && $entry->{name} !~ /$self->{option_results}->{filter_host_name}/);

        $self->{global}->{num_hosts}++;
        $self->{global}->{unhealthy}++ if ($entry->{health} !~ /^Healthy$/i);

        $self->{hosts}->{ $entry->{sn} } = {
            sn => $entry->{sn},
            name => $entry->{name},
            health => { status => $entry->{health}, sn => $entry->{sn}, name => $entry->{name} },
            nics => {},
            disks => {}
        };

        foreach my $nic (@{$entry->{nics}}) {
            $self->{hosts}->{ $entry->{sn} }->{nics}->{ $nic->{mac} } = {
                mac => $nic->{mac},
                slot => $nic->{slot},
                status => $nic->{link_status}
            };
        }

        foreach my $disk (@{$entry->{disks}}) {
            $self->{hosts}->{ $entry->{sn} }->{disks}->{ $disk->{sn} } = {
                sn => $disk->{sn},
                bay => $disk->{bay},
                slot => $disk->{slot},
                status => $disk->{disk_state}
            };
        }
    }
}

1;

__END__

=head1 MODE

Check hosts.

=over 8

=item B<--filter-host-sn>

Filter hosts by serial number (can be a regexp).

=item B<--filter-host-name>

Filter hosts by name (can be a regexp).

=item B<--unknown-host-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{name}, %{sn}

=item B<--warning-host-status>

Define the conditions to match for the status to be WARNING (default: '%{status} =~ /warning/i').
You can use the following variables: %{status}, %{name}, %{sn}

=item B<--critical-host-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /critical|error/i').
You can use the following variables: %{status}, %{name}, %{sn}

=item B<--unknown-nic-status>

Set unknown threshold for nic status.
You can use the following variables:  %{status}, %{mac}, %{slot}

=item B<--warning-nic-status>

Set warning threshold for nic status.
You can use the following variables: %{status}, %{mac}, %{slot}

=item B<--critical-nic-status>

Set critical threshold for nic status
You can use the following variables: %{status}, %{mac}, %{slot}

=item B<--unknown-disk-status>

Define the conditions to match for the status to be UNKNOWN.
You can use the following variables: %{status}, %{sn}, %{bay}, %{slot}

=item B<--warning-disk-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{sn}, %{bay}, %{slot}

=item B<--critical-disk-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /OK/i').
You can use the following variables: %{status}, %{sn}, %{bay}, %{slot}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'hosts-detected', 'hosts-unhealthy'.

=back

=cut
