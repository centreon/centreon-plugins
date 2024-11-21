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

package apps::eclipse::mosquitto::mqtt::mode::numericvalue;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Time::HiRes qw(time);
use POSIX qw(floor);

sub new {
    my ($class, %options) = @_;
    my $self              = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'topic:s'             => { name => 'topic' },
        'warning:s'           => { name => 'warning' },
        'critical:s'          => { name => 'critical' },
        'extracted-pattern:s' => { name => 'extracted_pattern' },
        'format:s'            => { name => 'format' },
        'format-custom:s'     => { name => 'format_custom' },
        'perfdata-unit:s'     => { name => 'perfdata_unit' },
        'perfdata-name:s'     => { name => 'perfdata_name', default => 'value' },
        'perfdata-min:s'      => { name => 'perfdata_min' },
        'perfdata-max:s'      => { name => 'perfdata_max' },
    });

    return $self;
}

sub custom_generic_output {
    my ($self, %options) = @_;

    my $format = $self->{instance_mode}{option_results}->{perfdata_name} . ' is: %s';
    if (defined($self->{instance_mode}{option_results}->{format})) {
        $format = $self->{instance_mode}{option_results}->{format};
    }

    my $value = $self->{result_values}->{numericvalue};
    if (!centreon::plugins::misc::is_empty($self->{instance_mode}{option_results}->{format_custom})) {
        $value = eval "$value $self->{instance_mode}{option_results}->{format_custom}";
    }

    return sprintf($format, $value);
}

sub custom_generic_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label    => $options{option_results}->{perfdata_name},
        unit     => $options{option_results}->{perfdata_unit},
        value    => $self->{result_values}->{numericvalue},
        warning  => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min      => $options{option_results}->{perfdata_min},
        max      => $options{option_results}->{perfdata_max}
    );
}

sub custom_generic_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value     => $self->{result_values}->{numericvalue},
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-' . $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'generic',
          set   => {
              key_values                     => [{ name => 'numericvalue' }],
              closure_custom_output          => $self->can('custom_generic_output'),
              closure_custom_perfdata        => $self->can('custom_generic_perfdata'),
              closure_custom_threshold_check => $self->can('custom_generic_threshold')
          }
        }
    ];
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (centreon::plugins::misc::is_empty($options{option_results}->{topic})) {
        $self->{output}->add_option_msg(short_msg => 'Missing parameter --topic.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $value = $options{mqtt}->query(
        topic => $self->{option_results}->{topic}
    );

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{extracted_pattern})) {
        if ($value =~ /$self->{option_results}->{extracted_pattern}/ && defined($1)) {
            $value = $1;
        }
    }
    if ($value !~ /^-?\d+(?:\.\d+)?$/) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => 'topic value is not numeric (' . $value . ')'
        );
        return;
    }

    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information");
        $self->{output}->option_exit();
    }

    $self->{global} = { numericvalue => $value };
}

1;

__END__

=head1 MODE

Check an Eclipse Mosquitto MQTT topic numeric value.

=over 8

=item B<--topic>

Topic value to check.

=item B<--warning>

Warning threshold.

=item B<--critical>

Critical threshold.

=item B<--extracted-pattern>

Define a pattern to extract a number from the returned string.

=item B<--format>

Output format (default: 'current value is %s')

=item B<--format-custom>

Apply a custom change on the value
(example to multiply the value: --format-custom='* 8').

=item B<--perfdata-unit>

Perfdata unit in perfdata output (default: '')

=item B<--perfdata-name>

Perfdata name in perfdata output (default: 'value')

=item B<--perfdata-min>

Minimum value to add in perfdata output (default: '')

=item B<--perfdata-max>

Maximum value to add in perfdata output (default: '')

=back

=cut