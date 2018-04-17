#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::aws::billing::mode::estimatedcharges;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_charges_output {
    my ($self, %options) = @_;

    return "Service '" . $self->{option_results}->{service} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'estimatedcharges', type => 0, cb_prefix_output => 'prefix_charges_output' },
    ];

    $self->{maps_counters}->{estimatedcharges} = [
        { label => 'billing', set => {
                key_values => [ { name => 'estimated_charges' }, { name => 'display' } ],
                output_template => 'estimated charges: %.2f USD',
                perfdatas => [
                    { label => 'billing', value => 'estimated_charges_absolute', template => '%.2f',
                      unit => 'USD' },
                ],
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "service:s"      => { name => 'service' },
                                    "currency:s"      => { name => 'currency', default => 'USD' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{service}) || $self->{option_results}->{service} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --service option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{option_results}->{currency}) || $self->{option_results}->{currency} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --currency option.");
        $self->{output}->option_exit();
    }

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 86400;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 60;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $metric_results = $options{custom}->cloudwatch_get_metrics(
        region => $self->{option_results}->{region},
        namespace => 'AWS/Billing',
        dimensions => [ { Name => 'ServiceName', Value => $self->{option_results}->{service} }, { Name => 'Currency',  Value => $self->{option_results}->{currency} } ],
        metrics => ['EstimatedCharges'],
        statistics => ['Maximum'],
        timeframe => $self->{aws_timeframe},
        period => $self->{aws_period},
    );

    $self->{estimatedcharges}->{estimated_charges} = $metric_results->{'EstimatedCharges'}->{'maximum'} if defined($metric_results->{'EstimatedCharges'}->{'maximum'});
    $self->{estimatedcharges}->{display} = $self->{option_results}->{service};

    if (scalar(keys %{$self->{estimatedcharges}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No value.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check Billing estimated charges for a service.

Example:
perl centreon_plugins.pl --plugin=cloud::aws::billing::plugin --custommode=paws --mode=estimated-charges
--region='us-east-1' --service='AWSService' --verbose

See 'https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/billing-metricscollected.html' for more informations.

=over 8

=item B<--service>

Set the Amazon service (Required).

=item B<--warning-billing>

Thresholds warning.

=item B<--critical-billing>

Thresholds critical.

=back

=cut
