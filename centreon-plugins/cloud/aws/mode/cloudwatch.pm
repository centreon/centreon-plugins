#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package cloud::aws::mode::cloudwatch;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use POSIX;
use JSON;

my $CloudwatchMetrics = {
    cpu              => "cloud::aws::mode::metrics::ec2instancecpu",
    traffic          => "cloud::aws::mode::metrics::ec2instancenetwork",
    cpucreditusage   => "cloud::aws::mode::metrics::ec2instancecpucreditusage",
    cpucreditbalance => "cloud::aws::mode::metrics::ec2instancecpucreditbalance",
    bucketsize       => "cloud::aws::mode::metrics::s3bucketsize",
    rdscpu           => "cloud::aws::mode::metrics::rdsinstancecpu",
};

my $StatisticsType = "Average,Minimum,Maximum,Sum,SampleCount";
my $def_endtime    = time();

my $apiRequest = {
    'command'    => 'cloudwatch',
    'subcommand' => 'get-metric-statistics',
};

sub new
{
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '0.1';

    $options{options}->add_options(
        arguments => {
            "metric:s"             => {name => 'metric'},
            "period:s"             => {name => 'period', default => 300},
            "starttime:s"          => {name => 'starttime'},
            "endtime:s"            => {name => 'endtime'},
            "statistics:s"         => {name => 'statistics', default => 'Average'},
            "exclude-statistics:s" => {name => 'exclude-statistics'},
            "object:s"             => {name => 'object'},
            "warning:s"            => {name => 'warning'},
            "critical:s"           => {name => 'critical'},
        }
    );
    $self->{result} = {};

    return $self;
}

sub check_options
{
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{option_results}->{def_endtime} = $def_endtime;

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0)
    {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0)
    {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{metric}))
    {
        $self->{output}->add_option_msg(
            severity  => 'UNKNOWN',
            short_msg => "Please give a metric to watch (cpu, disk, ...)."
        );
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{object}))
    {
        $self->{output}->add_option_msg(
            severity  => 'UNKNOWN',
            short_msg => "Please give the object to request (instanceid, ...)."
        );
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{endtime}))
    {
        $self->{option_results}->{endtime} = strftime("%FT%H:%M:%S.000Z", gmtime($self->{option_results}->{def_endtime}));
    }

    if (!defined($self->{option_results}->{starttime}))
    {
        $self->{option_results}->{starttime} = strftime("%FT%H:%M:%S.000Z", gmtime($self->{option_results}->{def_endtime} - 600));
    }

    # Getting some parameters
    # statistics
    if ($self->{option_results}->{statistics} eq 'all')
    {
        @{$self->{option_results}->{statisticstab}} = split(/,/, $StatisticsType);
    }
    else
    {
        @{$self->{option_results}->{statisticstab}} = split(/,/, $self->{option_results}->{statistics});
        foreach my $curstate (@{$self->{option_results}->{statisticstab}})
        {
            if (!grep { /^$curstate$/ } split(/,/, $StatisticsType))
            {
                $self->{output}->add_option_msg(
                    severity  => 'UNKNOWN',
                    short_msg => "The statistic $curstate doesn't exist."
                );
                $self->{output}->option_exit();
            }
        }
    }

    # exclusions
    if (defined($self->{option_results}->{'exclude-statistics'}))
    {
        my @excludetab = split(/,/, $self->{option_results}->{'exclude-statistics'});
        my %array1 = map { $_ => 1 } @excludetab;
        @{$self->{option_results}->{statisticstab}} = grep { not $array1{$_} } @{$self->{option_results}->{statisticstab}};
    }

    # Force Average statistic
    if (!grep $_ eq 'Average', @{$self->{option_results}->{statisticstab}})
    {
        my $statistics = join(',', @{$self->{option_results}->{statisticstab}});
        if (!$statistics eq '')
        {
            $statistics = $statistics . ',Average';
        }
        else
        {
            $statistics = 'Average';
        }
        @{$self->{option_results}->{statisticstab}} = split(/,/, $statistics);
    }
}

sub manage_selection
{
    my ($self, $metric) = @_;
    my @result;

    my @Dimensions = (
        {
            'Value' => $self->{option_results}->{object},
            'Name'  => $metric->{ObjectName}
        }
    );

    if (defined($metric->{ExtraDimensions}))
    {
        push @Dimensions, $metric->{ExtraDimensions};
    }

    $apiRequest->{json} = {
        'StartTime'  => $self->{option_results}->{starttime},
        'EndTime'    => $self->{option_results}->{endtime},
        'Period'     => $self->{option_results}->{period},
        'MetricName' => $metric->{MetricName},
        'Unit'       => $metric->{Unit},
        'Statistics' => $self->{option_results}->{statisticstab},
        'Dimensions' => [@Dimensions],
        'Namespace'  => $metric->{NameSpace}
    };
}

sub run
{
    my ($self, %options) = @_;

    my ($msg, $exit_code, $awsapi);

    if ( defined( $CloudwatchMetrics->{ $self->{option_results}->{metric} } ) ) {
        centreon::plugins::misc::mymodule_load(output => $options{output}, module => $CloudwatchMetrics->{$self->{option_results}->{metric}},
                                               error_msg => "Cannot load module '" . $CloudwatchMetrics->{$self->{option_results}->{metric}} . "'.");
        my $func = $CloudwatchMetrics->{$self->{option_results}->{metric}}->can('cloudwatchCheck');
        $func->($self);
    } else {
        $self->{output}->add_option_msg( short_msg => "Wrong option. Cannot find metric '" . $self->{option_results}->{metric} . "'." );
        $self->{output}->option_exit();
    }

    foreach my $metric (@{$self->{metric}})
    {
        $self->manage_selection($metric);
        $awsapi = $options{custom};
        $self->{command_return} = $awsapi->execReq($apiRequest);
        $self->{output}->perfdata_add(
            label => sprintf($metric->{Labels}->{PerfData}, unit => $metric->{Labels}->{Unit}),
            value => sprintf($metric->{Labels}->{Value}, $self->{command_return}->{Datapoints}[0]->{Average}),
            warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
            critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),

            #min => 0,
            #max => 100
        );
        $exit_code = $self->{perfdata}->threshold_check(
            value     => $self->{command_return}->{Datapoints}[0]->{Average},
            threshold => [{label => 'critical', 'exit_litteral' => 'critical'}, {label => 'warning', exit_litteral => 'warning'}]
        );

        $self->{output}->output_add(long_msg => sprintf($metric->{Labels}->{LongOutput}, $self->{command_return}->{Datapoints}[0]->{Average}));

        $self->{output}->output_add(
            severity  => $exit_code,
            short_msg => sprintf($metric->{Labels}->{ShortOutput}, $self->{command_return}->{Datapoints}[0]->{Average})
        );
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Get cloudwatch metrics.
This doc is partly based on the official AWS CLI documentation.

=over 8

=item B<--exclude-statistics>

(optional) Statistics to exclude from the query. 'Average' can't be excluded.

=item B<--metric>

Metric to query.

=item B<--period>

(optional) The granularity, in seconds, of the returned datapoints. period must be at least 60 seconds and must be a multiple of 60. The default value is 300.

=item B<--start-time>

(optional) The time stamp to use for determining the first datapoint to return. The value specified is inclusive; results include datapoints with the time stamp specified.
exemple: 2014-04-09T23:18:00

=item B<--end-time>

(optional) The time stamp to use for determining the last datapoint to return. The value specified is exclusive; results will include datapoints up to the time stamp specified.
exemple: 2014-04-09T23:18:00

=item B<--statistics>

(optional) The metric statistics to return. For information about specific statistics returned by GetMetricStatistics, go to statistics in the Amazon CloudWatch Developer Guide.
Valid Values: Average | Sum | SampleCount | Maximum | Minimum
Average is the default and always included.
'all' for all statistics values.

=item B<--object>

Name of the object to request (InstanceId for an EC2 instance, for exemple).

=item B<--warning>

(optional) Threshold warning.

=item B<--critical>

(optional) Threshold critical.

=back

=cut
