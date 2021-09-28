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

package cloud::kubernetes::mode::deploymentstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'desired',
        nlabel => 'deployment.replicas.desired.count',
        value => $self->{result_values}->{desired},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'current',
        nlabel => 'deployment.replicas.current.count',
        value => $self->{result_values}->{current},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'available',
        nlabel => 'deployment.replicas.available.count',
        value => $self->{result_values}->{available},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'ready',
        nlabel => 'deployment.replicas.ready.count',
        value => $self->{result_values}->{ready},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
    $self->{output}->perfdata_add(
        label => 'up_to_date',
        nlabel => 'deployment.replicas.uptodate.count',
        value => $self->{result_values}->{up_to_date},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Replicas Desired: %s, Current: %s, Available: %s, Ready: %s, Up-to-date: %s",
        $self->{result_values}->{desired},
        $self->{result_values}->{current},
        $self->{result_values}->{available},
        $self->{result_values}->{ready},
        $self->{result_values}->{up_to_date});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{namespace} = $options{new_datas}->{$self->{instance} . '_namespace'};
    $self->{result_values}->{desired} = $options{new_datas}->{$self->{instance} . '_desired'};
    $self->{result_values}->{current} = $options{new_datas}->{$self->{instance} . '_current'};
    $self->{result_values}->{available} = $options{new_datas}->{$self->{instance} . '_available'};
    $self->{result_values}->{ready} = $options{new_datas}->{$self->{instance} . '_ready'};
    $self->{result_values}->{up_to_date} = $options{new_datas}->{$self->{instance} . '_up_to_date'};

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'deployments', type => 1, cb_prefix_output => 'prefix_deployment_output',
            message_multiple => 'All Deployments status are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{deployments} = [
        { label => 'status', set => {
                key_values => [ { name => 'desired' }, { name => 'current' }, { name => 'up_to_date' },
                    { name => 'available' }, { name => 'ready' }, { name => 'name' }, { name => 'namespace' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_deployment_output {
    my ($self, %options) = @_;

    return "Deployment '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"         => { name => 'filter_name' },
        "filter-namespace:s"    => { name => 'filter_namespace' },
        "warning-status:s"      => { name => 'warning_status', default => '%{up_to_date} < %{desired}' },
        "critical-status:s"     => { name => 'critical_status', default => '%{available} < %{desired}' },
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

    $self->{deployments} = {};

    my $results = $options{custom}->kubernetes_list_deployments();
    
    foreach my $deployment (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $deployment->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $deployment->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne '' &&
            $deployment->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $deployment->{metadata}->{namespace} . "': no matching filter namespace.", debug => 1);
            next;
        }

        $self->{deployments}->{$deployment->{metadata}->{uid}} = {
            name => $deployment->{metadata}->{name},
            namespace => $deployment->{metadata}->{namespace},
            desired => $deployment->{spec}->{replicas},
            current => (defined($deployment->{status}->{replicas})) && $deployment->{status}->{replicas} =~ /(\d+)/ ? $1 : 0,
            ready => (defined($deployment->{status}->{readyReplicas})) && $deployment->{status}->{readyReplicas} =~ /(\d+)/ ? $1 : 0,
            up_to_date => (defined($deployment->{status}->{updatedReplicas})) && $deployment->{status}->{updatedReplicas} =~ /(\d+)/ ? $1 : 0,
            available => (defined($deployment->{status}->{availableReplicas})) && $deployment->{status}->{availableReplicas} =~ /(\d+)/ ? $1 : 0
        }            
    }
    
    if (scalar(keys %{$self->{deployments}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No Deployments found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check deployment status.

=over 8

=item B<--filter-name>

Filter deployment name (can be a regexp).

=item B<--filter-namespace>

Filter deployment namespace (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '%{up_to_date} < %{desired}')
Can used special variables like: %{name}, %{namespace}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{available} < %{desired}').
Can used special variables like: %{name}, %{namespace}, %{desired}, %{current},
%{available}, %{unavailable}, %{up_to_date}.

=back

=cut
