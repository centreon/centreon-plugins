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

package cloud::aws::cloudwatch::mode::listmetrics;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'namespace:s' => { name => 'namespace' },
        'metric:s'    => { name => 'metric' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{metrics} = $options{custom}->cloudwatch_list_metrics(
        namespace => $self->{option_results}->{namespace},
        metric => $self->{option_results}->{metric}
    );
}

sub get_dimensions_str {
    my ($self, %options) = @_;

    my $dimensions = '';
    my $append = '';
    foreach (@{$options{dimensions}}) {
        $dimensions .= $append . "Name=$_->{Name},Value=$_->{Value}";
        $append = ',';
    }

    return $dimensions;
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{metrics}}) {
        $self->{output}->output_add(long_msg => sprintf("[Namespace = %s][Dimensions = %s][Metric = %s]",
            $_->{Namespace}, $self->get_dimensions_str(dimensions => $_->{Dimensions}), $_->{MetricName}));
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List metrics:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['namespace', 'metric', 'dimensions']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (@{$self->{metrics}}) {
        $self->{output}->add_disco_entry(
            namespace => $_->{Namespace},
            metric => $_->{MetricName},
            dimensions => $self->get_dimensions_str(dimensions => $_->{Dimensions}),
        );
    }
}

1;

__END__

=head1 MODE

List cloudwatch metrics.

=over 8

=item B<--namespace>

Set cloudwatch namespace.

=item B<--metric>

Set cloudwatch metric.

=back

=cut
    
