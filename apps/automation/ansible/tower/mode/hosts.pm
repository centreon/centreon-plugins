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

package apps::automation::ansible::tower::mode::hosts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Hosts ';
}

sub prefix_output_host {
    my ($self, %options) = @_;

    return "Host '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' },
        { name => 'hosts', type => 1, cb_prefix_output => 'prefix_output_host', message_multiple => 'All hosts are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'hosts.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 }
                ]
            }
        },
        { label => 'failed', nlabel => 'hosts.failed.count', set => {
                key_values => [ { name => 'failed' }, { name => 'total' } ],
                output_template => 'failed: %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        }
    ];

    $self->{maps_counters}->{hosts} = [
        {
            label => 'job-status', type => 2,
            unknown_default => '%{last_job_status} =~ /default/',
            critical_default => '%{last_job_status} =~ /failed/',
            set => {
                key_values => [ { name => 'last_job_status' }, { name => 'display' } ],
                output_template => "last job status is '%s'",
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'        => { name => 'filter_name' },
        'display-failed-hosts' => { name => 'display_failed_hosts' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $hosts = $options{custom}->tower_list_hosts();

    $self->{global} = {
        total => scalar(@$hosts),
        failed => 0
    };
    $self->{hosts} = {};

    my $failed_hosts = [];
    foreach my $host (@$hosts) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $host->{name} !~ /$self->{option_results}->{filter_name}/);

        $self->{hosts}->{ $host->{id} } = {
            display => $host->{name},
            last_job_status => $host->{summary_fields}->{last_job}->{status}
        };

        if ($host->{has_active_failures}) {
            $self->{global}->{failed}++; 
            push @$failed_hosts, $host->{name};
        }
    }

    if (defined($self->{option_results}->{display_failed_hosts})) {
        $self->{output}->output_add(long_msg => 'Failed hosts list: ' . join(', ', @$failed_hosts)); 
    }
}

1;

__END__

=head1 MODE

Check hosts.

=over 8

=item B<--filter-name>

Filter host name (Can use regexp).

=item B<--display-failed-hosts>

Display failed hosts list in verbose output.

=item B<--unknown-job-status>

Set unknown threshold for status (Default: '%{last_job_status} =~ /default/').
Can used special variables like: %{last_job_status}, %{display}

=item B<--warning-job-status>

Set warning threshold for status.
Can used special variables like: %{last_job_status}, %{display}

=item B<--critical-job-status>

Set critical threshold for status (Default: '%{last_job_status} =~ /failed/').
Can used special variables like: %{last_job_status}, %{display}

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total', 'failed'.

=back

=cut
