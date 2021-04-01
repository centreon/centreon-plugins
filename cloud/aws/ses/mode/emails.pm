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

package cloud::aws::ses::mode::emails;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %metrics_mapping = (
    'Send' => {
        'output' => 'number of sent emails',
        'label'  => 'emails-sent',
        'nlabel' => 'ses.emails.sent.count',
    },
    'Delivery' => {
        'output' => 'number of emails successfully delivered',
        'label'  => 'emails-delivered',
        'nlabel' => 'ses.emails.delivered.count',
    },
    'Reputation.BounceRate' => {
        'output' => 'rate of rejected sent emails',
        'label'  => 'emails-rejected',
        'nlabel' => 'ses.emails.rejected.rate',
    },
    'Reputation.ComplaintRate' => {
        'output' => 'rate of sent emails marked as spam',
        'label'  => 'emails-spam',
        'nlabel' => 'ses.emails.spam.rate',
    }
);

sub custom_metric_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{timeframe} = $options{new_datas}->{$self->{instance} . '_timeframe'};
    $self->{result_values}->{value} = $options{new_datas}->{$self->{instance} . '_' . $options{extra_options}->{metric}};
    $self->{result_values}->{metric} = $options{extra_options}->{metric};
    return 0;
}

sub custom_metric_threshold {
    my ($self, %options) = @_;

    my $exit = $self->{perfdata}->threshold_check(
        value => $self->{result_values}->{value},
        threshold => [ { label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'critical' },
                       { label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_metric_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        instances   => $self->{instance},
        label       => $metrics_mapping{$self->{result_values}->{metric}}->{label},
        nlabel      => $metrics_mapping{$self->{result_values}->{metric}}->{nlabel},
        value       => $self->{result_values}->{value},
        warning     => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $metrics_mapping{$self->{result_values}->{metric}}->{label}),
        critical    => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $metrics_mapping{$self->{result_values}->{metric}}->{label})
    );
}

sub custom_metric_output {
    my ($self, %options) = @_;
    my $msg = "";
   
    my $value = $self->{result_values}->{value};
    return $msg = sprintf("%s: %.2f", $metrics_mapping{$self->{result_values}->{metric}}->{output}, $value);
}


sub prefix_metric_output {
    my ($self, %options) = @_;

    return "'" . $options{instance_value}->{display} . "' ";
}

sub prefix_statistics_output {
    my ($self, %options) = @_;

    return "Statistic '" . $options{instance_value}->{display} . "' Metrics ";
}

sub long_output {
    my ($self, %options) = @_;

    return "SES '" . $options{instance_value}->{display} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'metrics', type => 3, cb_prefix_output => 'prefix_metric_output', cb_long_output => 'long_output',
          message_multiple => 'All emails metrics are ok', indent_long_output => '    ',
            group => [
                { name => 'statistics', display_long => 1, cb_prefix_output => 'prefix_statistics_output',
                  message_multiple => 'All metrics are ok', type => 1, skipped_code => { -10 => 1 } },
            ]
        }
    ];

    foreach my $metric (keys %metrics_mapping) {
        my $entry = {
            label => $metrics_mapping{$metric}->{label},
            set => {
                key_values => [ { name => $metric }, { name => 'timeframe' }, { name => 'display' } ],
                closure_custom_calc => $self->can('custom_metric_calc'),
                closure_custom_calc_extra_options => { metric => $metric },
                closure_custom_output => $self->can('custom_metric_output'),
                closure_custom_perfdata => $self->can('custom_metric_perfdata'),
                closure_custom_threshold_check => $self->can('custom_metric_threshold'),
            }
        };
        push @{$self->{maps_counters}->{statistics}}, $entry;
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'dimension:s%' => { name => 'dimension' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 172800;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 86400;
    $self->{aws_statistics} = ['Average'];

    foreach my $metric (keys %metrics_mapping) {
        next if (defined($self->{option_results}->{filter_metric}) && $self->{option_results}->{filter_metric} ne ''
            && $metric !~ /$self->{option_results}->{filter_metric}/);
        push @{$self->{aws_metrics}}, $metric;
    }

    $self->{dimension_name} = '';
    my $append = '';
    $self->{aws_dimensions} = [];
    if (defined($self->{option_results}->{dimension})) {
        foreach (keys %{$self->{option_results}->{dimension}}) {
            push @{$self->{aws_dimensions}}, { Name => $_, Value => $self->{option_results}->{dimension}->{$_} };
            $self->{dimension_name} .= $append . $_ . '.' . $self->{option_results}->{dimension}->{$_};
            $append = '-';
            push @{$self->{aws_instance}}, $self->{option_results}->{dimension}->{$_};
        }

    } else {
        $self->{aws_instance} = ["SES"];
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace => 'AWS/SES',
            dimensions => $self->{aws_dimensions},
            metrics => $self->{aws_metrics},
            statistics => $self->{aws_statistics},
            timeframe => $self->{aws_timeframe},
            period => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));

                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} = 
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ? 
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Amazon SES sending activity.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ses::plugin --custommode=awscli --mode=emails --region='eu-west-1' --dimension='DimensionName1=ses-1234abcd' --dimension='DimensionName2=ses-5678efgh'
See 'https://docs.aws.amazon.com/ses/latest/DeveloperGuide/monitor-sending-activity.html' for more information.

=over 8

=item B<--dimension>

Set SES dimensions (Can be multiple). Syntax: 
--dimension='DimensionName1=Value1' --dimension='DimensionName2=Value2'.

=item B<--warning-emails-*>

Set warning threshold where '*' can be 'sent', 'delivered', 'spam' or 'rejected'.

=item B<--critical-emails-*>

Set critical threshold where '*' can be 'sent', 'delivered', 'spam' or 'rejected'.

=back

=cut
