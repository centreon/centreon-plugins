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

package cloud::kubernetes::mode::cronjobstatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(
        label => 'active',
        nlabel => 'cronjob.jobs.active.count',
        value => $self->{result_values}->{active},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{name} : undef,
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf("Jobs Active: %s, Last schedule time: %s ago (%s)",
        $self->{result_values}->{active},
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{last_schedule}),
        $self->{result_values}->{last_schedule_time});
}

sub custom_status_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};
    $self->{result_values}->{namespace} = $options{new_datas}->{$self->{instance} . '_namespace'};
    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{last_schedule_time} = $options{new_datas}->{$self->{instance} . '_last_schedule_time'};
    # 2021-03-09T11:01:00Z, UTC timezone
    if ($self->{result_values}->{last_schedule_time} =~ /^\s*(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)Z/) {
        my $dt = DateTime->new(
            year       => $1,
            month      => $2,
            day        => $3,
            hour       => $4,
            minute     => $5,
            second     => $6
        );
        $self->{result_values}->{last_schedule} = time() - $dt->epoch;
    }

    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'cronjobs', type => 1, cb_prefix_output => 'prefix_cronjob_output',
            message_multiple => 'All CronJobs status are ok', skipped_code => { -11 => 1 } },
    ];

    $self->{maps_counters}->{cronjobs} = [
        { label => 'status', set => {
                key_values => [ { name => 'active' }, { name => 'last_schedule_time' }, { name => 'name' },
                                { name => 'namespace' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => $self->can('custom_status_perfdata'),
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub prefix_cronjob_output {
    my ($self, %options) = @_;

    return "CronJob '" . $options{instance_value}->{name} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s"         => { name => 'filter_name' },
        "filter-namespace:s"    => { name => 'filter_namespace' },
        "warning-status:s"      => { name => 'warning_status', default => '' },
        "critical-status:s"     => { name => 'critical_status', default => '' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{cronjobs} = {};

    my $results = $options{custom}->kubernetes_list_cronjobs();
    
    foreach my $cronjob (@{$results}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $cronjob->{metadata}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $cronjob->{metadata}->{name} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_namespace}) && $self->{option_results}->{filter_namespace} ne '' &&
            $cronjob->{metadata}->{namespace} !~ /$self->{option_results}->{filter_namespace}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $cronjob->{metadata}->{namespace} . "': no matching filter namespace.", debug => 1);
            next;
        }
        
        $self->{cronjobs}->{$cronjob->{metadata}->{uid}} = {
            name => $cronjob->{metadata}->{name},
            namespace => $cronjob->{metadata}->{namespace},
            active => (defined($cronjob->{status}->{active})) ? scalar(@{$cronjob->{status}->{active}}) : 0,
            last_schedule_time => $cronjob->{status}->{lastScheduleTime}            
        }
    }
    
    if (scalar(keys %{$self->{cronjobs}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No CronJobs found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check CronJob status.

=over 8

=item B<--filter-name>

Filter CronJob name (can be a regexp).

=item B<--filter-namespace>

Filter CronJob namespace (can be a regexp).

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{name}, %{namespace}, %{active},
%{last_schedule}.

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{name}, %{namespace}, %{active},
%{last_schedule}.

=back

=cut
