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

package cloud::microsoft::office365::management::mode::servicestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_threshold {
    my ($self, %options) = @_;

    my $status = catalog_status_threshold_ng($self, %options);
    $self->{instance_mode}->{last_status} = $status;
    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{status} . "'";
    if (!$self->{output}->is_status(value => $self->{instance_mode}->{last_status}, compare => 'ok', litteral => 1)) {
        $msg .= sprintf(
            ' [issue: %s %s %s]',
            $self->{result_values}->{issue_startDateTime},
            $self->{result_values}->{issue_title},
            $self->{result_values}->{classification}
        );
    }
    return $msg;
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{service_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok' }
    ];

    $self->{maps_counters}->{services} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /serviceOperational|serviceRestored/i', set => {
                key_values => [
                    { name => 'status' }, { name => 'service_name' }, { name => 'classification' },
                    { name => 'issue_startDateTime' }, { name => 'issue_title' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-service-name:s' => { name => 'filter_service_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $results = $options{custom}->get_services_health();

    $self->{services} = {};
    foreach my $service (@$results) {
        if (defined($self->{option_results}->{filter_service_name}) && $self->{option_results}->{filter_service_name} ne '' &&
            $service->{service} !~ /$self->{option_results}->{filter_service_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $service->{service} . "': no matching filter name.", debug => 1);
            next;
        }
        $self->{services}->{ $service->{id} }->{service_name} = $service->{service};
        $self->{services}->{ $service->{id} }->{status} = $service->{status};
        $self->{services}->{ $service->{id} }->{issue_startDateTime} = '-';
        $self->{services}->{ $service->{id} }->{issue_title} = '-';
        $self->{services}->{ $service->{id} }->{classification} = '-';
        if (defined($service->{issues}) && scalar(@{$service->{issues}}) > 0) {
            my $issue = pop @{$service->{issues}};
            $self->{services}->{ $service->{id} }->{issue_startDateTime} = $issue->{startDateTime};
            $self->{services}->{ $service->{id} }->{issue_title} = $issue->{title};
            $self->{services}->{ $service->{id} }->{classification} = $issue->{classification};
        }
    }

    if (scalar(keys %{$self->{services}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No services found.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check services status.

=over 8

=item B<--filter-service-name>

Filter services (can be a regexp).

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{service_name}, %{status}, %{classification}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} !~ /serviceOperational|serviceRestored/i').
You can use the following variables: %{service_name}, %{status}, %{classification}

=back

=cut
