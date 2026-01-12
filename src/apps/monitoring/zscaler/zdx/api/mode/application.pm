#
# Copyright 2025-Present Centreon (http://www.centreon.com/)
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

package apps::monitoring::zscaler::zdx::api::mode::application;

use base qw(centreon::plugins::templates::counter);
use centreon::plugins::constants qw(:values);
use strict;
use warnings;

# All filter parameters that can be used
my @_options = qw/
    application_id
    include_application_name
    exclude_application_name
    location_id
    include_location_name
    exclude_location_name
/;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        ( map { ($_ =~ s/_/-/gr).':s' => { name => $_, default => '' } } @_options ),
        'add-metrics' =>  { name => 'add_metrics'}
    });

    return $self;
}

sub prefix_app_output {
    my ($self, %options) = @_;

    return 'App "' . $options{instance_value}->{name} . '" - ';
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        {
            name             => 'application',
            type             => 1,
            cb_prefix_output => 'prefix_app_output',
            message_multiple => 'All apps are ok',
            skipped_code     => { NO_VALUE() => 1 } }
    ];
    
    $self->{maps_counters}->{application} = [
        {
            label  => 'total-users',
            nlabel => 'application.total-users.count',
            set    => {
                key_values      => [ { name => 'total_users' } ],
                output_template => 'Users count: %s',
                perfdatas       => [ { template => '%d', min => 0, label_extra_instance => 1 } ]
            }
        },
        {
            label  => 'score',
            nlabel => 'application.score.value',
            set    => {
                key_values      => [ { name => 'score' } ],
                output_template => 'Score: %s',
                perfdatas       => [ { template => '%d',min => 0, max => 100, label_extra_instance => 1 } ]
            }
        },
        {
            label  => 'page-fetch-time',
            nlabel => 'application.page-fetch-time.milliseconds',
            set    => {
                key_values      => [ { name => 'pft' } ],
                output_template => 'Page fetch time: %s',
                perfdatas       => [ { template => '%s', min => 0, unit => 'ms',  label_extra_instance => 1 } ]
            }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;

    $self->SUPER::check_options(%options);
    foreach (@_options) {
        $self->{$_} = $self->{option_results}->{$_};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $apps = $options{custom}->get_apps( map {$_ => $self->{$_}} @_options);

    foreach my $app (@$apps) {
        $self->{application}->{$app->{name}} = {
            name        => $app->{name},
            score       => $app->{score},
            total_users => $app->{total_users}
        };
        my $metrics = $options{custom}->get_unique_app_metrics(%options, application_id => $app->{id});
        foreach my $metric_name (keys %$metrics) {
            if ($metrics->{$metric_name} == -1) {
                $self->{output}->add_option_msg(long_msg => 'metric "' . $metric_name .'" is skipped for app "' . $app->{name} . '" because its value is -1');
                next;
            }
            $self->{application}->{$app->{name}}->{$metric_name} = $metrics->{$metric_name};
        }
    }
    return 1;
}

1;

__END__

=head1 MODE

Monitor an application overall stats.

=over 8

=item B<--application-id>

Define the C<appid> to monitor. Using this option is recommended to monitor one app because it will
only retrieves the data related to the targeted app.

=item B<--include-application-name>

Regular expression to include applications to monitor by their name. Using this option is not recommended to monitor
one app because it will first retrieve the list of all apps and then filter to get the targeted app.

=item B<--exclude-application-name>

Regular expression to exclude applications to monitor by their name. Using this option is not recommended to monitor
one app because it will first retrieve the list of all apps and then filter to get the targeted app.

=item B<--location-id>

Narrows the stats calculation to only one location given by its id. Statistics such as page fetch time, total users and
score will be the average value for this location.

=item B<--include-location-name>

Narrows the stats calculation to several locations filtered by their name using this parameter as a regular expression
to include them. Using this option is not recommended to filter one location because it will first retrieve the list of
all locations and then filter to get the targeted location.

=item B<--exclude-location-name>

Narrows the stats calculation to several locations filtered by their name using this parameter as a regular expression
to exclude them. Using this option is not recommended to filter one location because it will first retrieve the list of
all locations and then filter to get the targeted location.

=back

=item B<--warning-score>

Threshold.

=item B<--critical-score>

Threshold.

=item B<--warning-total-users>

Threshold.

=item B<--critical-total-users>

Threshold.

=item B<--add-metrics>

Enables collection of metrics (page fetch time).

=item B<--warning-page-fetch-time>

Threshold in ms.

=item B<--critical-page-fetch-time>

Threshold in ms.

=cut
