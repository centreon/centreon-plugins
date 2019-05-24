#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::voip::3cx::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = 'health : ' . $self->{result_values}->{health};
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{health} = $options{new_datas}->{$self->{instance} . '_health'};
    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'service', type => 1, cb_prefix_output => 'prefix_service_output', message_multiple => 'All services are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'calls-active', nlabel => 'system.calls.active.current', set => {
                key_values => [ { name => 'calls_active' } ],
                output_template => 'calls active : %s',
                perfdatas => [
                    { label => 'calls_active',  template => '%s', value => 'calls_active_absolute',
                      min => 0 },
                ],
            }
        },
         { label => 'extensions-registered', nlabel => 'system.extensions.registered.current', set => {
                key_values => [ { name => 'extensions_registered' } ],
                output_template => 'extensions registered : %s',
                perfdatas => [
                    { label => 'extensions_registered',  template => '%s', value => 'extensions_registered_absolute',
                      min => 0 },
                ],
            }
        },
    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'health' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "Service '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        "unknown-status:s"  => { name => 'unknown_status', default => '' },
        "warning-status:s"  => { name => 'warning_status', default => '' },
        "critical-status:s" => { name => 'critical_status', default => '%{health} =~ /false/' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => [
        'warning_status', 'critical_status', 'unknown_status',
    ]);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $single = $options{custom}->api_single_status();
    my $system = $options{custom}->api_system_status();

    $self->{service} = {};
    foreach my $item (keys %$single) {
        # As of 3CX 15.5 / 16, we have Firewall, Phones, Trunks
        $self->{service}->{$item} = { display => $item, health => $single->{$item} };
    }
    $self->{service}->{HasNotRunningServices} = {
        display => 'HasNotRunningServices',
        health => $self->{system}->{HasNotRunningServices} ? 'false' : 'true',
    };
    $self->{service}->{HasUnregisteredSystemExtensions} = {
        display => 'HasUnregisteredSystemExtensions', 
        health => $self->{system}->{HasUnregisteredSystemExtensions} ? 'false' : 'true',
    };
    
    $self->{global} = {
        calls_active => $system->{CallsActive},
        extensions_registered => $system->{ExtensionsRegistered},
    };
}

1;

__END__

=head1 MODE

Check system health

=over 8

=item B<--unknown-status>

Set warning threshold for status.
Can used special variables like: %{health}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{health}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{health} =~ /false/').
Can used special variables like: %{health}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'calls-active', 'extensions-registered'.

=back

=cut
