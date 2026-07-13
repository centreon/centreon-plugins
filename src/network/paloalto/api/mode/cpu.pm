#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package network::paloalto::api::mode::cpu;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::constants qw(:counters);
use centreon::plugins::misc qw(is_excluded);

sub custom_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel},
        instances => ['dp' . $self->{result_values}->{dpNum}, 'cpu' . $self->{result_values}->{cpuNum}],
        value => sprintf('%.2f', $self->{result_values}->{ $self->{key_values}->[0]->{name} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0,
        max => 100,
        unit => '%'
    );
}

sub prefix_cpu_core_output {
    my ($self, %options) = @_;

    return "CPU '" . $options{instance_value}->{cpuNum} . "' ";
}

sub long_dp_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking data processor '%s'",
        $options{instance_value}->{dpNum}
    );
}

sub prefix_dp_output {
    my ($self, %options) = @_;

    return sprintf(
        "data processor '%s' ",
        $options{instance_value}->{dpNum}
    );
}

sub set_counters {
    my ($self, %options) = @_;

     $self->{maps_counters_type} = [
        { name => 'dp', type => COUNTER_TYPE_MULTIPLE, cb_prefix_output => 'prefix_dp_output', cb_long_output => 'long_dp_output',
          message_multiple => 'All data processors are ok', indent_long_output => '    ',
            group => [
                { name => 'cpu_cores', display_long => 1, cb_prefix_output => 'prefix_cpu_core_output', message_multiple => 'All CPU cores are ok', type => COUNTER_MULTIPLE_SUBINSTANCE, sort_method => 'num' }
            ]
        }
    ];

    $self->{maps_counters}->{cpu_cores} = [
        { label => 'average-1m', nlabel => 'core.cpu.utilization.1m.percentage', set => {
                key_values => [ { name => 'average_1m' }, { name => 'dpNum' }, { name => 'cpuNum' } ],
                output_template => '%.2f %% (1m)',
                closure_custom_perfdata => $self->can('custom_perfdata')
            }
        },
        { label => 'average-5m', nlabel => 'core.cpu.utilization.5m.percentage', set => {
                key_values => [ { name => 'average_5m' }, { name => 'dpNum' }, { name => 'cpuNum' } ],
                output_template => '%.2f %% (5m)',
                closure_custom_perfdata => $self->can('custom_perfdata'),
            }
        },
        { label => 'average-15m', nlabel => 'core.cpu.utilization.15m.percentage', set => {
                key_values => [ { name => 'average_15m' }, { name => 'dpNum' }, { name => 'cpuNum' } ],
                output_template => '%.2f %% (15m)',
                closure_custom_perfdata => $self->can('custom_perfdata')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'include-dp-name:s'  => { name => 'include_dp_name',  default => '' },
        'exclude-dp-name:s'  => { name => 'exclude_dp_name',  default => '' }
    });

    return $self;
}

sub compute_cpu_average {
    my ($self, %options) = @_;

    my $value = 0;
    for (my $i = 0; $i < $options{sampling}; $i++) {
        $value += $options{dataset}->[$i];
    }

    $value /= $options{sampling};

    return $value;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(
        type       => 'op',
        cmd        => '<show><running><resource-monitor></resource-monitor></running></show>',
        ForceArray => ['entry']
    );

    $self->{dp} = {};
    foreach my $dp (keys %{$result->{'resource-monitor'}->{'data-processors'}}) {
        next if ($dp !~ /dp(\d+)/);
        my $dp_num = $1;

        next if is_excluded($dp_num, $self->{option_results}->{include_dp_name}, $self->{option_results}->{exclude_dp_name});

        $self->{dp}->{$dp_num} = { dpNum => $dp_num, cpu_cores => {} };

        foreach my $core (@{$result->{'resource-monitor'}->{'data-processors'}->{$dp}->{minute}->{'cpu-load-average'}->{entry}}) {
            my @datas = split(/,/, $core->{value});
            $self->{dp}->{$dp_num}->{cpu_cores}->{ $core->{coreid} } = {
                dpNum => $dp_num,
                cpuNum => $core->{coreid},
                average_1m  => $self->compute_cpu_average(dataset => \@datas, sampling => 1),
                average_5m  => $self->compute_cpu_average(dataset => \@datas, sampling => 5),
                average_15m => $self->compute_cpu_average(dataset => \@datas, sampling => 15)
            };
        }
    }
}

1;

__END__

=head1 MODE

Check data processors.

=over 8

=item B<--include-dp-name>

Include data processor names (regexp).

=item B<--exclude-dp-name>

Exclude data processor names (regexp).

=item B<--warning-average-1m>

Warning threshold for data processor 1 minute average usage in percent.

=item B<--critical-average-1m>

Critical threshold for data processor 1 minute average usage in percent.

=item B<--warning-average-5m>

Warning threshold for data processor 5 minutes average usage in percent.

=item B<--critical-average-5m>

Critical threshold for data processor 5 minutes average usage in percent.

=item B<--warning-average-15m>

Warning threshold for data processor 15 minutes average usage in percent.

=item B<--critical-average-15m>

Critical threshold for data processor 15 minutes average usage in percent.

=back

=cut
