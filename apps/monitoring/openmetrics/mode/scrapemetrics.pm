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

package apps::monitoring::openmetrics::mode::scrapemetrics;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::common::monitoring::openmetrics::scrape;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-metrics:s'      => { name => 'filter_metrics' },
        "warning:s"             => { name => 'warning', default => '' },
        "critical:s"            => { name => 'critical', default => '' },
        'instance:s'            => { name => 'instance' },
        'subinstance:s'         => { name => 'subinstance' },
        'filter-instance:s'     => { name => 'filter_instance' },
        'filter-subinstance:s'  => { name => 'filter_subinstance' },
        'new-perfdata'          => { name => 'new_perfdata' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{metrics} = centreon::common::monitoring::openmetrics::scrape::parse(%options);
    
    my @exits;
    my $short_msg = 'All metrics are ok';
    
    my $nometrics = 1;

    foreach my $metric (keys %{$self->{metrics}}) {
        next if (defined($self->{option_results}->{filter_metrics}) && $self->{option_results}->{filter_metrics} ne '' &&
            $metric !~ /$self->{option_results}->{filter_metrics}/);
        
        foreach my $data (@{$self->{metrics}->{$metric}->{data}}) {
            next if (defined($self->{option_results}->{instance}) && $self->{option_results}->{instance} ne '' &&
                !defined($data->{dimensions}->{$self->{option_results}->{instance}}) ||
                defined($self->{option_results}->{filter_instance}) && $self->{option_results}->{filter_instance} ne '' &&
                $data->{dimensions}->{$self->{option_results}->{instance}} !~ /$self->{option_results}->{filter_instance}/);
            next if (defined($self->{option_results}->{subinstance}) && $self->{option_results}->{subinstance} ne '' &&
                !defined($data->{dimensions}->{$self->{option_results}->{subinstance}}) ||
                defined($self->{option_results}->{filter_subinstance}) && $self->{option_results}->{filter_subinstance} ne '' &&
                $data->{dimensions}->{$self->{option_results}->{subinstance}} !~ /$self->{option_results}->{filter_subinstance}/);
            $nometrics = 0;
            my $label = $metric;
            $label =~ s/_/./g if (defined($self->{option_results}->{new_perfdata}));
            $label = $data->{dimensions}->{$self->{option_results}->{instance}} . '#' . $label
                if (defined($self->{option_results}->{instance}) && $self->{option_results}->{instance} ne '' &&
                    defined($data->{dimensions}->{$self->{option_results}->{instance}}) &&
                    !defined($self->{option_results}->{subinstance}));
            $label = $data->{dimensions}->{$self->{option_results}->{instance}} . '~' .
                $data->{dimensions}->{$self->{option_results}->{subinstance}} . '#' . $label
                if (defined($self->{option_results}->{instance}) && $self->{option_results}->{instance} ne '' &&
                    defined($data->{dimensions}->{$self->{option_results}->{instance}}) &&
                    defined($self->{option_results}->{subinstance}) && $self->{option_results}->{subinstance} ne '' &&
                    defined($data->{dimensions}->{$self->{option_results}->{subinstance}}));
            $label =~ s/'//g;

            push @exits, $self->{perfdata}->threshold_check(
                value => $data->{value},
                threshold => [ { label => 'critical', exit_litteral => 'critical' },
                               { label => 'warning', exit_litteral => 'warning' } ]);

            $self->{output}->perfdata_add(
                label => $label,
                value => $data->{value},
                warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
            );

            $self->{output}->output_add(long_msg => sprintf("Metric '%s' value is '%s' [Help: \"%s\"] [Type: '%s'] [Dimensions: \"%s\"]",
                $metric, $data->{value}, 
                (defined($self->{metrics}->{$metric}->{help})) ? $self->{metrics}->{$metric}->{help} : '-',
                (defined($self->{metrics}->{$metric}->{type})) ? $self->{metrics}->{$metric}->{type} : '-',
                $data->{dimensions_string}));
        }
    }

    if ($nometrics == 1) {
        $self->{output}->add_option_msg(short_msg => "No metrics found.");
        $self->{output}->option_exit();
    }
    
    my $exit = $self->{output}->get_most_critical(status => \@exits);
    $short_msg = 'Some metrics are not ok' if ($exit !~ /OK/i);
    $self->{output}->output_add(severity => $exit, short_msg => $short_msg);

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Scrape metrics.

Examples:

# perl centreon_plugins.pl --plugin=apps::monitoring::openmetrics::plugin --mode=scrape-metrics
--custommode=web --hostname=10.2.3.4 --port=9100 --verbose --filter-metrics='node_network_up'
--critical='0:0' --instance='device' --new-perfdata

# perl centreon_plugins.pl --plugin=apps::monitoring::openmetrics::plugin --mode=scrape-metrics
--custommode=web --hostname=10.2.3.4 --port=9100 --verbose --filter-metrics='node_cpu_seconds_total'
--instance='cpu' --subinstance='mode' --filter-subinstance='mode'

# perl centreon_plugins.pl --plugin=apps::monitoring::openmetrics::plugin --mode=scrape-metrics
--custommode=file --command-options='/tmp/metrics' --filter-metrics='cpu' --verbose

# perl centreon_plugins.pl --plugin=apps::monitoring::openmetrics::plugin --mode=scrape-metrics
--custommode=file --hostname=10.2.3.4 --ssh-option='-l=centreon-engine' --ssh-option='-p=52'
--command-options='/my/app/path/metrics' --verbose

=over 8

=item B<--filter-metrics>

Only parse some metrics (regexp can be used).
Example: --filter-metrics='^status$'

=item B<--warning>

Set warning threshold.

=item B<--critical>

Set critical threshold.

=item B<--instance>

Set the label from dimensions to get the instance value from.

=item B<--filter-instance>

Only display some instances.
Example: --filter-instance='0'

=item B<--subinstance>

Set the label from dimensions to get the subinstance value from.

=item B<--filter-subinstance>

Only display some subinstances.
Example: --filter-subinstance='idle'

=item B<--new-perfdata>

Replace the underscore symbol by a point in perfdata.

=back

=cut
