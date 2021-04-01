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

package apps::voip::3cx::restapi::mode::system;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output { 
    my ($self, %options) = @_;

    my $msg = '';
    if ($self->{result_values}->{service} !~ /^Has[A-Z]/) {
        $msg .= 'error';
    }
    $msg .= ': ' . $self->{result_values}->{error};
    return $msg;
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
                output_template => 'calls active: %s',
                perfdatas => [
                    { label => 'calls_active', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'extensions-registered', nlabel => 'system.extensions.registered.current', set => {
                key_values => [ { name => 'extensions_registered' } ],
                output_template => 'extensions registered: %s',
                perfdatas => [
                    { label => 'extensions_registered', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{service} = [
        { label => 'status', type => 2, critical_default => '%{error} =~ /true/', set => {
                key_values => [ { name => 'error' }, { name => 'service' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub prefix_service_output {
    my ($self, %options) = @_;

    return "3CX '" . $options{instance_value}->{service} ."' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $single = $options{custom}->api_single_status();
    my $system = $options{custom}->api_system_status();
    my $update = $options{custom}->api_update_checker();

    $self->{service} = {};
    foreach my $item (keys %$single) {
        # As of 3CX 15.5 / 16, we have Firewall, Phones, Trunks
        $self->{service}->{$item} = { 
            service => $item, 
            error => $single->{$item} ? 'false' : 'true',
        };
    }
    # As per 3CX support, $single->{Trunks} does not trigger if TrunksRegistered != TrunksTotal,
    # but only if "trunk is unsupported", so let's workaround
    $self->{service}->{HasUnregisteredTrunks} = { 
        service => 'HasUnregisteredTrunks', 
        error => ($system->{TrunksRegistered} < $system->{TrunksTotal}) ? 'true' : 'false',
    };
    $self->{service}->{HasNotRunningServices} = {
        service => 'HasNotRunningServices',
        error => $system->{HasNotRunningServices} ? 'true' : 'false',
    };
    $self->{service}->{HasUnregisteredSystemExtensions} = {
        service => 'HasUnregisteredSystemExtensions', 
        error => $system->{HasUnregisteredSystemExtensions} ? 'true' : 'false',
    };
    $self->{service}->{HasUpdatesAvailable} = {
        service => 'HasUpdatesAvailable', 
        error => scalar(@$update) ? 'true' : 'false',
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

Set unknown threshold for status.
Can used special variables like: %{error}, %{service}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{error}, %{service}

=item B<--critical-status>

Set critical threshold for status (Default: '%{error} =~ /false/').
Can used special variables like: %{error}, %{service}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'calls-active', 'extensions-registered'.

=back

=cut
