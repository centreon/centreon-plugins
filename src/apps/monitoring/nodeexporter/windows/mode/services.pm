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

package apps::monitoring::nodeexporter::windows::mode::services;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_state_output {
    my ($self, %options) = @_;
    
    my $msg = "Service : '" . $self->{result_values}->{display} . "' [state: '" . $self->{result_values}->{status} . "']" . " [start_mode: '" . $self->{result_values}->{start_mode} . "']";
    return $msg;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'service', type => 1, message_multiple => 'All services are OK' }
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'status', type => 2,
                critical_default => '%{start_mode} =~ /auto/ && %{status} !~ /^running$/',
                set => { key_values => [ { name => 'status' }, { name => 'start_mode' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "service:s"  => { name => 'service' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{service} = {};

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");

    foreach my $metric (keys %{$raw_metrics}) {       
        next if ($metric !~ /windows_service_state|windows_service_start_mode/i);
        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{service}) && $data->{dimensions}->{name} !~ /$self->{option_results}->{service}/i );
            if ($metric =~ /windows_service_state/ && $data->{value} == 1){
                $self->{service}->{$data->{dimensions}->{name}} = { 
                    display => $data->{dimensions}->{name},
                    status => $data->{dimensions}->{state} 
                };
            }
            if ($metric =~ /windows_service_start_mode/ && $data->{value} == 1){
                $self->{service}->{$data->{dimensions}->{name}}->{start_mode} = $data->{dimensions}->{start_mode};
            }
        }
    }
    
    if (scalar(keys %{$self->{service}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No service found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Windows services.

=over 8

=item B<--service>

Specify which service to monitor. Can be a regex.

Default: all services are monitored.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{status}, %{start_mode}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL (default: '%{start_mode} =~ /auto/ && %{status} !~ /^running$/').
You can use the following variables: %{status}, %{start_mode}


=back

=cut
