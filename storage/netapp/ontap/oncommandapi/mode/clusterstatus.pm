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

package storage::netapp::ontap::oncommandapi::mode::clusterstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;

    my $msg = sprintf("Status is '%s'", $self->{result_values}->{status});
    $msg .= sprintf(", Metro Cluster is '%s' [mode: %s]",
        $self->{result_values}->{metro_cluster_configuration_state},
        $self->{result_values}->{metro_cluster_mode}) if ($self->{result_values}->{metro_cluster_configuration_state} !~ /-/);
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{metro_cluster_mode} = $options{new_datas}->{$self->{instance} . '_metro_cluster_mode'};
    $self->{result_values}->{metro_cluster_configuration_state} = $options{new_datas}->{$self->{instance} . '_metro_cluster_configuration_state'};

    return 0;
}

sub prefix_output {
    my ($self, %options) = @_;

    return "Cluster '" . $options{instance_value}->{name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_output', message_multiple => 'All clusters status are ok' },
    ];
    
    $self->{maps_counters}->{clusters} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'metro_cluster_mode' }, { name => 'metro_cluster_configuration_state' }, { name => 'name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s'     => { name => 'filter_name' },
        'warning-status:s'  => { name => 'warning_status' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /ok/i' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get(path => '/clusters');

    foreach my $cluster (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cluster->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $cluster->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{clusters}->{$cluster->{key}} = {
            name => $cluster->{name},
            status => $cluster->{status},
            metro_cluster_mode => defined($cluster->{metro_cluster_mode}) ? $cluster->{metro_cluster_mode} : "-",
            metro_cluster_configuration_state => defined($cluster->{metro_cluster_configuration_state}) ? $cluster->{metro_cluster_configuration_state} : "-",
        }
    }

    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check NetApp clusters status.

=over 8

=item B<--filter-name>

Filter snapmirror name (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{metro_cluster_mode}, %{metro_cluster_configuration_state}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /ok/i').
Can used special variables like: %{status}, %{metro_cluster_mode}, %{metro_cluster_configuration_state}

=back

=cut
