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

package apps::monitoring::dynatrace::restapi::mode::availability;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_synthetic_output {
    my ($self, %options) = @_;

    return sprintf(
        "Synthetick '%s' ", 
        $options{instance_value}->{name}
    );
}

sub synthetic_long_output {
    my ($self, %options) = @_;

    return sprintf(
        "checking Synthetic Monitor '%s'",
        $options{instance_value}->{name}
    );
}

sub prefix_geolocation_output {
    my ($self, %options) = @_;

    return sprintf(
        "Geolocation '%s' ", 
        $options{instance_value}->{geolocation}
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {  name => 'synthetic', type => 3, cb_prefix_output => 'prefix_synthetic_output', 
          cb_long_output => 'synthetic_long_output', indent_long_output => '    ', 
          message_multiple => 'All Synthetic are ok', 
                group => [
                    { name => 'geolocation', type => 1, cb_prefix_output => 'prefix_geolocation_output', message_multiple => 'All geolocation are OK', skipped_code => { -10 => 1 }}
                ]
        }
    ];

    $self->{maps_counters}->{geolocation} = [
        { label => 'availability', nlabel => 'synthetic.monitor.availability.percentage', set => {
                key_values => [ { name => 'availability' }, {name => 'name'} ],
                output_template => 'availability : %.2f %%',
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%', label_extra_instance => 1 }
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
        'filter-geolocation:s' => { name => 'filter_geolocation' },
        'filter-synthetic:s'   => { name => 'filter_synthetic' },
        'relative-time:s'      => { name => 'relative_time', default => '30mins' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->get_synthetic_availability();
    my @synthetic;
    my $synthetic_name;
    my $synthetic_geolocation;

    foreach my $synthetic_mix (keys %{$result->{result}->{dataPoints}}) {
        @synthetic = split(', ', $synthetic_mix);
        $synthetic_name = $result->{result}->{entities}->{$synthetic[0]};
        $synthetic_geolocation = $result->{result}->{entities}->{$synthetic[1]};

        if (defined($self->{option_results}->{filter_synthetic}) && $self->{option_results}->{filter_synthetic} ne '' &&
            $synthetic_name !~ /$self->{option_results}->{filter_synthetic}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $synthetic_name . "': no matching filter.", debug => 1);
            next;
        }

        if (defined($self->{option_results}->{filter_geolocation}) && $self->{option_results}->{filter_geolocation} ne '' &&
            $synthetic_geolocation !~ /$self->{option_results}->{filter_geolocation}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $synthetic_geolocation . "': no matching filter.", debug => 1);
            next;
        }

        if (defined($result->{result}->{dataPoints}->{$synthetic_mix}[0][1])) {
            $self->{synthetic}->{$synthetic_name}->{geolocation}->{$synthetic_geolocation} = {
                name           => $synthetic_name,
                geolocation    => $synthetic_geolocation,
                availability   => $result->{result}->{dataPoints}->{$synthetic_mix}[0][1]
            };
        }
    }

    if (scalar(keys %{$self->{synthetic}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No synthetic monitor found.");
        $self->{output}->option_exit();
    }

    foreach my $syntheticmonitor (keys %{$self->{synthetic}}) {
        $self->{synthetic}->{$syntheticmonitor}->{name} = $syntheticmonitor;
    }
}

1;

__END__

=head1 MODE

Check Synthetic Monitor availability.

=over 8

=item B<--relative-time>

Set request relative time (default: '30min').
Can use: min, 5mins, 10mins, 15mins, 30mins, hour, 2hours, 6hours, day, 3days, week, month.

=item B<--filter-synthetic>

Filter availability by Synthetic Monitor (can be a regexp).

=item B<--filter-geolocation>

Filter availability by geolocation (can be a regexp).

=item B<--warning-availability>

Set warning threshold for availability.

=item B<--critical-availability>

Set critical threshold for availability.

=back

=cut
