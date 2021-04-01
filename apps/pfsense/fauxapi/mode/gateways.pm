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

package apps::pfsense::fauxapi::mode::gateways;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf('status: ' . $self->{result_values}->{status});
}

sub prefix_gateway_output {
    my ($self, %options) = @_;
    
    return "Gateway '" . $options{instance_value}->{display} . "' packets ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'gateways', type => 1, cb_prefix_output => 'prefix_gateway_output', message_multiple => 'All gateways are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{gateways} = [
        { label => 'status', type => 2, critical_default => '%{status} !~ /none/i', set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'packets-delay', nlabel => 'gateway.packets.delay.milliseconds', set => {
                key_values => [ { name => 'delay' }, { name => 'display' } ],
                output_template => 'delay: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-loss', nlabel => 'gateway.packets.loss.percentage', set => {
                key_values => [ { name => 'loss' }, { name => 'display' } ],
                output_template => 'loss: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'packets-stddev', nlabel => 'gateway.packets.stddev.milliseconds', set => {
                key_values => [ { name => 'stddev' }, { name => 'display' } ],
                output_template => 'stddev: %.2f ms',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => 'ms', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s' => { name => 'filter_name' }
    });
    
    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(action => 'gateway_status');

    $self->{gateways} = {};
    if (defined($results->{data}->{gateway_status})) {
        foreach (values %{$results->{data}->{gateway_status}}) {
            if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
                $_->{name} !~ /$self->{option_results}->{filter_name}/) {
                $self->{output}->output_add(long_msg => "skipping gateway '" . $_->{name} . "': no matching filter.", debug => 1);
                next;
            }

            my $delay = $_->{delay} =~ /([0-9\.]+)/ ? $1 : undef;
            my $stddev = $_->{stddev} =~ /([0-9\.]+)/ ? $1 : undef;
            my $loss = $_->{loss} =~ /([0-9\.]+)/ ? $1 : undef;
            $self->{gateways}->{ $_->{name} } = {
                display => $_->{name},
                status => $_->{status},
                delay => $delay,
                stddev => $stddev,
                loss => $loss
            };
        }
    }
    
    if (scalar(keys %{$self->{gateways}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'no gateway found');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check gateways.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter gateway name (can be a regexp).

=item B<--unknown-status>

Set unknon threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status (Default: '').
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /none/i').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'packets-delay' (ms), 'packets-loss' (%), 'packets-stddev' (ms).

=back

=cut
