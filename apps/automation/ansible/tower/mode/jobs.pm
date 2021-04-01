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

package apps::automation::ansible::tower::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Jobs ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'jobs.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { value => 'total', template => '%d', min => 0 }
                ]
            }
        }
    ];

    foreach ((['successful', 1], ['failed', 1], ['running', 1], ['canceled', 0], ['pending', 0], ['default', 0])) {
        push @{$self->{maps_counters}->{global}}, {
                label => $_->[0], nlabel => 'jobs.' . $_->[0] . '.count', display_ok => $_->[1], set => {
                key_values => [ { name => $_->[0] }, { name => 'total' } ],
                output_template => $_->[0] . ': %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-name:s'       => { name => 'filter_name' },
        'display-failed-jobs' => { name => 'display_failed_jobs' },
        'memory'              => { name => 'memory' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->check_options(%options);
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'Date::Parse',
            error_msg => "Cannot load module 'Date::Parse'."
        );
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $last_time;
    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->read(statefile => 'cache_ansible_tower_' . $self->{mode} . '_' . $options{custom}->get_hostname());
        $last_time = $self->{statefile_cache}->get(name => 'last_time');
    }

    my $jobs = $options{custom}->tower_list_unified_jobs();

    $self->{global} = { total => 0, failed => 0, successful => 0, canceled => 0, default => 0, pending => 0, running => 0 };

    my $current_time = time();
    my $failed_jobs = {};
    foreach my $job (@$jobs) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' 
            && $job->{name} !~ /$self->{option_results}->{filter_name}/);

        if (defined($self->{option_results}->{memory}) && defined($job->{finished})) {
            my $finished_time = Date::Parse::str2time($job->{finished});
            if (!defined($finished_time)) {
                $self->{output}->output_add(
                    severity => 'UNKNOWN',
                    short_msg => "Can't parse date '" . $job->{finished} . "'"
                );
                next;
            }
            next if (defined($last_time) && $last_time > $finished_time);
        }

        $self->{global}->{ $job->{status} }++;
        $self->{global}->{total}++;
        if ($job->{status} eq 'failed') {
            $failed_jobs->{ $job->{name} } = 1;
        }
    }

    if (defined($self->{option_results}->{memory})) {
        $self->{statefile_cache}->write(data => { last_time => $current_time });
    }

    if (defined($self->{option_results}->{display_failed_jobs})) {
        $self->{output}->output_add(long_msg => 'Failed jobs list: ' . join(', ', keys %$failed_jobs)); 
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-name>

Filter job name (Can use regexp).

=item B<--display-failed-jobs>

Display failed jobs list in verbose output.

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total', 'successful', 'failed', 'running', 'canceled', 'pending', 'default'.

=back

=cut
