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

package apps::microsoft::iis::restapi::mode::websites;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s',
        $self->{result_values}->{status}
    );
}

sub prefix_website_output {
    my ($self, %options) = @_;
    
    return "Website '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'websites', type => 1, cb_prefix_output => 'prefix_website_output', message_multiple => 'All websites are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{websites} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'requests', nlabel => 'website.requests.persecond', set => {
                key_values => [ { name => 'requests_total', per_second => 1 }, { name => 'display' } ],
                output_template => 'requests: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-in', nlabel => 'website.traffic.in.bitspersecond', set => {
                key_values => [ { name => 'traffic_in', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic in: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'traffic-out', nlabel => 'website.traffic.out.bitspersecond', set => {
                key_values => [ { name => 'traffic_out', per_second => 1 }, { name => 'display' } ],
                output_template => 'traffic out: %s %s/s',
                output_change_bytes => 2,
                perfdatas => [
                    { template => '%s', min => 0, unit => 'b/s', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-current', nlabel => 'website.connections.current.count', set => {
                key_values => [ { name => 'current_connections' }, { name => 'display' } ],
                output_template => 'current connections: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
                ]
            }
        },
        { label => 'connections-total', nlabel => 'website.connections.total.persecond', set => {
                key_values => [ { name => 'total_connections', per_second => 1 }, { name => 'display' } ],
                output_template => 'total connections: %.2f/s',
                perfdatas => [
                    { template => '%.2f', min => 0, unit => '/s', label_extra_instance => 1 }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, statefile => 1, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} !~ /starting|started/' }
    });
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status', 'unknown_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->get_websites(filter_name => $self->{option_results}->{filter_name});

    $self->{websites} = {};
    foreach (values %$results) {
        $self->{websites}->{$_->{name}} = {
            display => $_->{name},
            status => $_->{status},
            requests_total => $_->{requests}->{total},
            traffic_in => $_->{network}->{total_bytes_recv} * 8,
            traffic_out => $_->{network}->{total_bytes_sent} * 8,
            current_connections => $_->{network}->{current_connections},
            total_connections => $_->{network}->{total_connection_attempts}
        };
    }

    $self->{cache_name} = 'iis_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check websites.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter website name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} !~ /starting|started/').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'requests', 'traffic-in', 'traffic-out',
'connections-current', 'connections-total'.

=back

=cut
