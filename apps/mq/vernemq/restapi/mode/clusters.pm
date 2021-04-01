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

package apps::mq::vernemq::restapi::mode::clusters;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold catalog_status_calc);

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub prefix_cluster_output {
    my ($self, %options) = @_;
    
    return "Cluster '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'clusters', type => 1, cb_prefix_output => 'prefix_cluster_output', message_multiple => 'All clusters are ok', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'running', nlabel => 'clusters.running.count', display_ok => 0, set => {
                key_values => [ { name => 'running' } ],
                output_template => 'current clusters running: %s',
                perfdatas => [
                    { value => 'running', template => '%s', min => 0 }
                ]
            }
        },
        { label => 'notrunning', nlabel => 'clusters.notrunning.count', display_ok => 0, set => {
                key_values => [ { name => 'notrunning' } ],
                output_template => 'current clusters not running: %s',
                perfdatas => [
                    { value => 'notrunning', template => '%s', min => 0 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{clusters} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' }, { name => 'display' } ],
                closure_custom_calc => \&catalog_status_calc,
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'filter-name:s'     => { name => 'filter_name' },
        'unknown-status:s'  => { name => 'unknown_status', default => '' },
        'warning-status:s'  => { name => 'warning_status', default => '' },
        'critical-status:s' => { name => 'critical_status', default => '%{status} eq "notRunning"' },
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

    my $clusters = $options{custom}->request_api(endpoint => '/cluster/show');

    $self->{global} = { running => 0, notrunning => 0 };
    $self->{clusters} = {};
    foreach (@{$clusters->{table}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $_->{Node} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping cluster '" . $_->{Node} . "': no matching filter.", debug => 1);
            next;
        }

        $_->{Running} ? $self->{global}->{running}++ : $self->{global}->{notrunning}++;
        $self->{clusters}->{$_->{Node}} = {
            display => $_->{Node},
            status => $_->{Running} ? 'running' : 'notRunning'
        };
    }
    
    if (scalar(keys %{$self->{clusters}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No cluster found");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check clusters.

=over 8

=item B<--filter-name>

Filter cluster name (can be a regexp).

=item B<--unknown-status>

Set unknown threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{status}, %{display}

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} eq "notRunning"').
Can used special variables like: %{status}, %{display}

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'running', 'notrunning'.

=back

=cut
