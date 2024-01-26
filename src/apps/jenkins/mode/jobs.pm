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

package apps::jenkins::mode::jobs;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_job_output {
    my ($self, %options) = @_;

    return "Job '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'jobs', type => 1, cb_prefix_output => 'prefix_job_output', message_multiple => 'All jobs are ok' }
    ];

    $self->{maps_counters}->{jobs} = [
        { label => 'score', nlabel => 'job.score.percentage', set => {
                key_values => [ { name => 'score' } ],
                output_template => 'score: %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
                ]
            }
        },
        { label => 'violations', nlabel => 'job.violations.count', set => {
                key_values => [ { name => 'violations' } ],
                output_template => 'violations: %s',
                perfdatas => [
                    { template => '%s', min => 0, label_extra_instance => 1 }
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
        'filter-job-name:s' => { name => 'filter_job_name' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $jobs = $options{custom}->request_api(
        endpoint => '/api/json',
        get_param => [
            'tree=jobs[name,buildable,healthReport[description,score],jobs[name,buildable,healthReport[description,score]]]'
        ]
    );

    $self->{jobs} = {};
    foreach my $job (@{$jobs->{jobs}}) {
        my $name = $job->{name};
        if (!defined($self->{option_results}->{filter_job_name}) || $self->{option_results}->{filter_job_name} eq '' ||
            $name =~ /$self->{option_results}->{filter_job_name}/) {
            if (defined($job->{healthReport}->[0]->{score})) {
                $self->{jobs}->{$name} = { score => $job->{healthReport}->[0]->{score}, violations => 0 };
                if ($job->{healthReport}->[0]->{description} =~ /^.+?([0-9]+)/ ) {
                    $self->{jobs}->{$name}->{violations} = $1;
                }
            }
        }

        next if (!defined($job->{jobs}));

        foreach my $subjob (@{$job->{jobs}}) {
            my $subname = $name . '/' . $subjob->{name};
            next if (defined($self->{option_results}->{filter_job_name}) && $self->{option_results}->{filter_job_name} ne '' &&
                $subname !~ /$self->{option_results}->{filter_job_name}/);

            if (defined($subjob->{healthReport}->[0]->{score})) {
                $self->{jobs}->{$subname} = { score => $subjob->{healthReport}->[0]->{score}, violations => 0 };
                if ($subjob->{healthReport}->[0]->{description} =~ /^.+?([0-9]+)/ ) {
                    $self->{jobs}->{$subname}->{violations} = $1;
                }
            }
        }
    }
}

1;

__END__

=head1 MODE

Check jobs.

=over 8

=item B<--filter-job-name>

Filter jobs by name (can be a regexp).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'score', 'violations'.

=back

=cut
