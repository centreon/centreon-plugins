#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

my $instance_mode;

sub custom_status_threshold {
    my ($self, %options) = @_; 
    my $status = 'ok';
    my $message;
    
    eval {
        local $SIG{__WARN__} = sub { $message = $_[0]; };
        local $SIG{__DIE__} = sub { $message = $_[0]; };
        
        if (defined($instance_mode->{option_results}->{critical_status}) && $instance_mode->{option_results}->{critical_status} ne '' &&
            eval "$instance_mode->{option_results}->{critical_status}") {
            $status = 'critical';
        } elsif (defined($instance_mode->{option_results}->{warning_status}) && $instance_mode->{option_results}->{warning_status} ne '' &&
            eval "$instance_mode->{option_results}->{warning_status}") {
            $status = 'warning';
        }
    };
    if (defined($message)) {
        $self->{output}->output_add(long_msg => 'filter status issue: ' . $message);
    }

    return $status;
}

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = "status is '" . $self->{result_values}->{status} . "'";
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub prefix_service_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{service_name} . "' ";
}

sub prefix_feature_output {
    my ($self, %options) = @_;
    
    return "Service '" . $options{instance_value}->{service_name} . "' Feature '" . $options{instance_value}->{feature_name} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'services', type => 3, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services status are ok',
          counters => [ { name => 'features', type => 1, cb_prefix_output => 'prefix_feature_output', message_multiple => 'All features status are ok' } ] },
    ];
    
    $self->{maps_counters}->{services} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'service_name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];    
    $self->{maps_counters}->{features} = [
        { label => 'status', set => {
                key_values => [ { name => 'status' }, { name => 'service_name' }, { name => 'feature_name' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_status_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "filter-service-name:s"     => { name => 'filter_service_name' },
                                    "filter-feature-name:s"     => { name => 'filter_feature_name' },
                                    "warning-status:s"          => { name => 'warning_status' },
                                    "critical-status:s"         => { name => 'critical_status', default => '%{status} !~ /Normal/i' },
                                });
    
    return $self;
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (('warning_status', 'critical_status')) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    
    $instance_mode = $self;
    $self->change_macros();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{services} = {};

    my $results = $options{custom}->office_get_services_status();

    foreach my $service (@{$results->{value}}) {
        if (defined($self->{option_results}->{filter_service_name}) && $self->{option_results}->{filter_service_name} ne '' &&
            $service->{WorkloadDisplayName} !~ /$self->{option_results}->{filter_service_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $service->{WorkloadDisplayName} . "': no matching filter name.", debug => 1);
            next;
        }
        $self->{services}->{$service->{Id}}->{service_name} = $service->{WorkloadDisplayName};
        $self->{services}->{$service->{Id}}->{status} = $service->{StatusDisplayName};
        foreach my $feature (@{$service->{FeatureStatus}}) {
            if (defined($self->{option_results}->{filter_feature_name}) && $self->{option_results}->{filter_feature_name} ne '' &&
                $feature->{FeatureDisplayName} !~ /$self->{option_results}->{filter_feature_name}/) {
                $self->{output}->output_add(long_msg => "skipping  '" . $feature->{FeatureDisplayName} . "': no matching filter name.", debug => 1);
                next;
            }
            $self->{services}->{$service->{Id}}->{features}->{$feature->{FeatureName}}->{service_name} = $service->{WorkloadDisplayName};
            $self->{services}->{$service->{Id}}->{features}->{$feature->{FeatureName}}->{feature_name} = $feature->{FeatureDisplayName};
            $self->{services}->{$service->{Id}}->{features}->{$feature->{FeatureName}}->{status} = $feature->{FeatureServiceStatusDisplayName};
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

Check services and features status.

=over 8

=item B<--filter-*>

Filter services and/or features.
Can be: 'service-name', 'feature-name' (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{service_name}, %{feature_name}, %{status}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /Normal/i').
Can used special variables like: %{service_name}, %{feature_name}, %{status}

=back

=cut
