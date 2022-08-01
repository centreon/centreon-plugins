#
# Copyright 2022 Centreon (http://www.centreon.com/)
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
use Digest::MD5 qw(md5_hex);
use centreon::common::monitoring::openmetrics::scrape;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = 'Service : ' . $self->{result_values}->{display} . ', status : ' . $self->{result_values}->{status};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'service', type => 1, message_multiple => 'All services are OK' }
    ];
    
    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
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
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /ok/i' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

# my %map_state = (
#     1 => 'inService',
#     2 => 'outOfService',
#     4 => 'disabled',
#     5 => 'sorry',
#     6 => 'redirect',
#     7 => 'errormsg',
# );


sub manage_selection {
    my ($self, %options) = @_;

    $self->{service_status} = {};
    $self->{service_starting_mode} = {};

    use Data::Dumper;

    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(%options, strip_chars => "[\"']");

    foreach my $metric (keys %{$raw_metrics}) {       
        next if ($metric !~ /windows_service_status|windows_service_start_mode/i);
        # print Dumper $raw_metrics->{$metric} ;
        foreach my $data (@{$raw_metrics->{$metric}->{data}}) {
            if ($metric =~ /windows_service_status/){
                $self->{service_status}->{$data->{dimensions}->{name}} = $data->{dimensions}->{status} if $data->{value} == 1 ;
            }
            if ($metric =~ /windows_service_start_mode/){
                $self->{service_starting_mode}->{$data->{dimensions}->{name}} = $data->{dimensions}->{start_mode} if $data->{value} == 1 ;
            }

        }
  
    }

    # foreach my $service (keys %{$services}) {
        
    #     # $self->{vs}->{$nom_service} = { };
    # }
    
    # if (scalar(keys %{$self->{service}}) <= 0) {
    #     $self->{output}->add_option_msg(short_msg => "No virtual server found.");
    #     $self->{output}->option_exit();
    # }
}

1;

__END__

=head1 MODE

Check Windows services.

=over 8

=item B<--warning-status>


=item B<--critical-status>


=back

=cut
