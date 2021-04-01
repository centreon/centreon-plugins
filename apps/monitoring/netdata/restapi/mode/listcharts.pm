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

package apps::monitoring::netdata::restapi::mode::listcharts;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-chart:s' => { name => 'filter_chart' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $result = $options{custom}->list_charts();

    foreach my $chart (values %{$result->{charts}}) {
        next if (defined($self->{option_results}->{filter_chart}) && $self->{option_results}->{filter_chart} ne ''
            && $chart->{title} !~ /$self->{option_results}->{filter_chart}/);

        $self->{output}->output_add(
            long_msg => sprintf(
                "[name = %s][title = %s][units = %s]",
                $chart->{name},
                $chart->{title},
                $chart->{units},
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'Netdata Available Charts:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'title', 'units']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->run(%options);
    foreach my $chart (@{$self->{charts}}) {
        $self->{output}->add_disco_entry(
            name    => $chart->{name},
            title   => $chart->{title},
            units   => $chart->{units},
        );
    }
}

1;

__END__

=head1 MODE

List available Netdata charts.

=over 8

=item B<--filter-chart>

Filter on specific chart(s). Regexp can be used.

=back

=cut
