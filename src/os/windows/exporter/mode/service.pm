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

package os::windows::exporter::mode::service;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return 'Number of services ';
}

sub custom_state_output {
    my ($self, %options) = @_;
        
    return sprintf(
        "Service '%s' state is '%s' [status: %s] [start mode: %s]",
            $self->{result_values}->{display_name},
            $self->{result_values}->{state},
            $self->{result_values}->{status},
            $self->{result_values}->{start_mode}
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
            cb_prefix_output => 'prefix_global_output'
        },
        {
            name => 'service',
            type => 1,
            message_multiple => 'All services are OK'
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'total',
            nlabel => 'services.total.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'total' }
                ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'continue_pending',
            nlabel => 'services.continue_pending.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'continue_pending' }
                ],
                output_template => 'continue pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'pause-pending',
            nlabel => 'services.pause_pending.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'pause_pending' }
                ],
                output_template => 'pause pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'paused',
            nlabel => 'services.paused.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'paused' }
                ],
                output_template => 'paused: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'running',
            nlabel => 'services.running.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'running' }
                ],
                output_template => 'running: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'start-pending',
            nlabel => 'services.start_pending.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'start_pending' }
                ],
                output_template => 'start pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'stop-pending',
            nlabel => 'services.stop_pending.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'stop_pending' }
                ],
                output_template => 'stop pending: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'stopped',
            nlabel => 'services.stopped.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'stopped' }
                ],
                output_template => 'stopped: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        },
        {
            label => 'unknown',
            nlabel => 'services.unknown.count',
            display_ok => 0,
            set => {
                key_values => [
                    { name => 'unknown' }
                ],
                output_template => 'unknown: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];
    
    $self->{maps_counters}->{service} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{start_mode} =~ /auto/ && %{state} !~ /^running$/',
            set => {
                key_values => [
                    { name => 'state' },
                    { name => 'status' },
                    { name => 'start_mode' },
                    { name => 'name' },
                    { name => 'display_name' }
                ],
                closure_custom_output => $self->can('custom_state_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng,
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "service:s" => { name => 'service' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub get_services {
    my ($self, %options) = @_;
    
    my %services;

    foreach my $data (@{$options{metrics}->{windows_service_info}->{data}}) {
        $services{$data->{dimensions}->{name}} = $data->{dimensions}->{display_name};
    }

    return \%services;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = {
        total => 0,
        continue_pending => 0,
        pause_pending => 0,
        paused => 0,
        running => 0,
        start_pending => 0,
        stop_pending => 0,
        stopped => 0,
        unknown => 0
    };
    $self->{service} = {};

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'windows_service_',
        %options
    );

    # windows_service_info{display_name="Netlogon",name="netlogon",process_id="728",run_as="LocalSystem"} 1
    # windows_service_start_mode{name="netlogon",start_mode="auto"} 1
    # windows_service_start_mode{name="netlogon",start_mode="boot"} 0
    # windows_service_start_mode{name="netlogon",start_mode="disabled"} 0
    # windows_service_start_mode{name="netlogon",start_mode="manual"} 0
    # windows_service_start_mode{name="netlogon",start_mode="system"} 0
    # windows_service_state{name="netlogon",state="continue pending"} 0
    # windows_service_state{name="netlogon",state="pause pending"} 0
    # windows_service_state{name="netlogon",state="paused"} 0
    # windows_service_state{name="netlogon",state="running"} 1
    # windows_service_state{name="netlogon",state="start pending"} 0
    # windows_service_state{name="netlogon",state="stop pending"} 0
    # windows_service_state{name="netlogon",state="stopped"} 0
    # windows_service_state{name="netlogon",state="unknown"} 0
    # windows_service_status{name="netlogon",status="degraded"} 0
    # windows_service_status{name="netlogon",status="error"} 0
    # windows_service_status{name="netlogon",status="lost comm"} 0
    # windows_service_status{name="netlogon",status="no contact"} 0
    # windows_service_status{name="netlogon",status="nonrecover"} 0
    # windows_service_status{name="netlogon",status="ok"} 1
    # windows_service_status{name="netlogon",status="pred fail"} 0
    # windows_service_status{name="netlogon",status="service"} 0
    # windows_service_status{name="netlogon",status="starting"} 0
    # windows_service_status{name="netlogon",status="stopping"} 0
    # windows_service_status{name="netlogon",status="stressed"} 0
    # windows_service_status{name="netlogon",status="unknown"} 0

    my $services = $self->get_services(metrics => $raw_metrics);

    foreach my $metric (keys %{$raw_metrics}) {       
        next if ($metric !~ /windows_service_start_mode|windows_service_state|windows_service_status/i);

        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{service}) &&
                ($data->{dimensions}->{name} !~ /$self->{option_results}->{service}/i &&
                $services->{$data->{dimensions}->{name}} !~ /$self->{option_results}->{service}/i));
            
            $self->{service}->{$data->{dimensions}->{name}}->{name} = $data->{dimensions}->{name};
            $self->{service}->{$data->{dimensions}->{name}}->{display_name} = $services->{$data->{dimensions}->{name}};

            if ($metric =~ /windows_service_state/ && $data->{value} == 1){
                $self->{service}->{$data->{dimensions}->{name}}->{state} = $data->{dimensions}->{state};
                $self->{global}->{total}++;
                my $state = $data->{dimensions}->{state} =~ s/ /_/gr;
                $self->{global}->{$state}++;
            }
            if ($metric =~ /windows_service_status/ && $data->{value} == 1){
                $self->{service}->{$data->{dimensions}->{name}}->{status} = $data->{dimensions}->{status};
            }
            if ($metric =~ /windows_service_start_mode/ && $data->{value} == 1){
                $self->{service}->{$data->{dimensions}->{name}}->{start_mode} = $data->{dimensions}->{start_mode};
            }
        }
    }
}

1;

__END__

=head1 MODE

Check Windows services.

Uses metrics from https://github.com/prometheus-community/windows_exporter/blob/master/docs/collector.service.md.

=over 8

=item B<--service>

Specify which service to monitor. Can be name or display name. Can be a regex.

Default: all services are monitored.

=item B<--warning-status>

Define the conditions to match for the status to be WARNING (default: '').
You can use the following variables: %{name}, %{display_name}, %{start_mode},
%{status}, %{state}.

=item B<--critical-status>

Define the conditions to match for the status to be
CRITICAL (default: '%{start_mode} =~ /auto/ && %{state} !~ /^running$/').
You can use the following variables: %{name}, %{display_name}, %{start_mode},
%{status}, %{state}.

=back

=cut
