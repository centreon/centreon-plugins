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

package apps::microsoft::iis::restapi::mode::applicationpools;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);
use Digest::MD5 qw(md5_hex);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        'status: %s [auto start: %s]',
        $self->{result_values}->{status},
        $self->{result_values}->{auto_start}
    );
}

sub prefix_pool_output {
    my ($self, %options) = @_;
    
    return "Application pool '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'pools', type => 1, cb_prefix_output => 'prefix_pool_output', message_multiple => 'All application pools are ok', skipped_code => { -10 => 1 } }
    ];
    
    $self->{maps_counters}->{pools} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'auto_start' }, { name => 'display' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        },
        { label => 'requests', nlabel => 'applicationpool.requests.persecond', set => {
                key_values => [ { name => 'requests_total', per_second => 1 }, { name => 'display' } ],
                output_template => 'requests: %.2f/s',
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
        'critical-status:s' => { name => 'critical_status', default => '%{auto_start} eq "true" and %{status} !~ /starting|started/' }
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

    my $results = $options{custom}->get_application_pools(filter_name => $self->{option_results}->{filter_name});

    $self->{pools} = {};
    foreach (values %$results) {
        $self->{pools}->{$_->{name}} = {
            display => $_->{name},
            status => $_->{status},
            auto_start => $_->{auto_start} ? 'true' : 'false',
            requests_total => $_->{requests}->{total}
        };
    }

    $self->{cache_name} = 'iis_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
        (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all')) . '_' .
        (defined($self->{option_results}->{filter_name}) ? md5_hex($self->{option_results}->{filter_name}) : md5_hex('all'));
}

1;

__END__

=head1 MODE

Check application pools.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example: --filter-counters='status'

=item B<--filter-name>

Filter application pool name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{auto_start}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{auto_start}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{auto_start} eq "true" and %{status} !~ /starting|started/').
Can used special variables like: %{status}, %{auto_start}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'requests'.

=back

=cut
