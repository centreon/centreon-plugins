#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::statusvm;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = 'status ' . $self->{result_values}->{connection_state};
    return $msg;
}

sub custom_overall_output {
    my ($self, %options) = @_;

    my $msg = 'overall status is ' . $self->{result_values}->{overall_status};
    return $msg;
}

sub custom_overall_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{overall_status} = $options{new_datas}->{$self->{instance} . '_overall_status'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'vm', type => 1, cb_prefix_output => 'prefix_vm_output', message_multiple => 'All virtual machines are ok' },
    ];
    
    $self->{maps_counters}->{vm} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'connection_state' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
        { label => 'overall-status', threshold => 0, set => {
                key_values => [ { name => 'overall_status' } ],
                closure_custom_calc => $self->can('custom_overall_calc'),
                closure_custom_output => $self->can('custom_overall_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_vm_output {
    my ($self, %options) = @_;

    my $msg = "Virtual machine '" . $options{instance_value}->{display} . "'";
    if (defined($options{instance_value}->{config_annotation})) {
        $msg .= ' [annotation: ' . $options{instance_value}->{config_annotation} . ']';
    }
    $msg .= ' : ';
    
    return $msg;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "vm-hostname:s"         => { name => 'vm_hostname' },
        "filter"                => { name => 'filter' },
        "scope-datacenter:s"    => { name => 'scope_datacenter' },
        "scope-cluster:s"       => { name => 'scope_cluster' },
        "scope-host:s"          => { name => 'scope_host' },
        "filter-description:s"  => { name => 'filter_description' },
        "filter-os:s"           => { name => 'filter_os' },
        "filter-uuid:s"         => { name => 'filter_uuid' },
        "display-description"   => { name => 'display_description' },
        "unknown-status:s"      => { name => 'unknown_status', default => '%{connection_state} !~ /^connected$/i' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
        "unknown-overall-status:s"  => { name => 'unknown_overall_status', default => '%{overall_status} =~ /gray/i' },
        "warning-overall-status:s"  => { name => 'warning_overall_status', default => '%{overall_status} =~ /yellow/i' },
        "critical-overall-status:s" => { name => 'critical_overall_status', default => '%{overall_status} =~ /red/i' },
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $self->change_macros(macros => ['unknown_status', 'warning_status', 'critical_status',
        'unknown_overall_status', 'warning_overall_status', 'critical_overall_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{vm} = {};
    my $response = $options{custom}->execute(params => $self->{option_results},
        command => 'statusvm');

    foreach my $vm_id (keys %{$response->{data}}) {
        my $vm_name = $response->{data}->{$vm_id}->{name};
        $self->{vm}->{$vm_name} = {
            display => $vm_name, 
            connection_state => $response->{data}->{$vm_id}->{connection_state},
            overall_status => $response->{data}->{$vm_id}->{overall_status},
        };
        
         if (defined($self->{option_results}->{display_description})) {
            $self->{vm}->{$vm_name}->{config_annotation} = $options{custom}->strip_cr(value => $response->{data}->{$vm_id}->{'config.annotation'});
        }
    }    
}

1;

__END__

=head1 MODE

Check virtual machine global status.

=over 8

=item B<--vm-hostname>

VM hostname to check.
If not set, we check all VMs.

=item B<--filter>

VM hostname is a regexp.

=item B<--filter-description>

Filter also virtual machines description (can be a regexp).

=item B<--filter-os>

Filter also virtual machines OS name (can be a regexp).

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--scope-host>

Search in following host(s) (can be a regexp).

=item B<--unknown-status>

Set warning threshold for status (Default: '%{connection_state} !~ /^connected$/i').
Can used special variables like: %{connection_state}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{connection_state}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{connection_state}

=item B<--unknown-overall-status>

Set warning threshold for status (Default: '%{overall_status} =~ /gray/i').
Can used special variables like: %{overall_status}

=item B<--warning-overall-status>

Set warning threshold for status (Default: '%{overall_status} =~ /yellow/i').
Can used special variables like: %{overall_status}

=item B<--critical-overall-status>

Set critical threshold for status (Default: '%{overall_status} =~ /red/i').
Can used special variables like: %{overall_status}

=back

=cut
