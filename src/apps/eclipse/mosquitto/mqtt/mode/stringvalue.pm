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

package apps::eclipse::mosquitto::mqtt::mode::stringvalue;

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
        'topic:s'            => { name => 'topic' },
        'format-custom'      => { name => 'format_custom' },

        'warning-regexp:s'   => { name => 'warning_regexp' },
        'critical-regexp:s'  => { name => 'critical_regexp' },
        'unknown-regexp:s'   => { name => 'unknown_regexp' },
        'regexp-insensitive' => { name => 'use_iregexp' },

        'format-ok:s'        => { name => 'format_ok', default => 'value: %{value}' },
        'format-warning:s'   => { name => 'format_warning', default => 'value: %{value}' },
        'format-critical:s'  => { name => 'format_critical', default => 'value: %{value}' },
        'format-unknown:s'   => { name => 'format_unknown', default => 'value: %{value}' },
    });

    return $self;
}

sub custom_stringvalue_output {
    my ($self, %options) = @_;

    my $value = $self->{result_values}->{stringvalue};

    if (!centreon::plugins::misc::is_empty($self->{instance_mode}->{option_results}->{'format_' . $self->{severity}})) {
        my $format_value = $self->{instance_mode}->{option_results}->{'format_' . $self->{severity}};
        $format_value =~ s/%\{value\}/$value/g;
        $format_value =~ s/%\{(.*?)\}/$format_value->{$1}/g;
        $value = $format_value;
    }

    return $value;
}

sub custom_stringvalue_threshold {
    my ($self, %options) = @_;

    my $severity = 'ok';
    foreach my $check_severity (('critical', 'warning', 'unknown')) {
        next if (centreon::plugins::misc::is_empty($self->{option_results}->{$check_severity . '_regexp'}));
        my $regexp = $self->{option_results}->{$check_severity . '_regexp'};
        if (defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/i) {
            $severity = $check_severity;
        } elsif (!defined($self->{option_results}->{use_iregexp}) && $options{value} =~ /$regexp/) {
            $severity = $check_severity;
        }
    }
    $self->{severity} = $severity;
    return $severity;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'generic',
          set   => {
              key_values                     => [{ name => 'stringvalue' }],
              closure_custom_output          => $self->can('custom_stringvalue_output'),
              closure_custom_threshold_check => \&custom_stringvalue_threshold
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

    if (!centreon::plugins::misc::is_empty($self->{option_results}->{format_custom})) {
        if ($value =~ /$self->{option_results}->{format_custom}/ && defined($1)) {
            $value = $1;
        }
    }

    if (!defined($value)) {
        $self->{output}->add_option_msg(short_msg => "Cannot find information");
        $self->{output}->option_exit();
    }

    $self->{global} = { stringvalue => $value };
}

1;

__END__

=head1 MODE

Check an Eclipse Mosquitto MQTT topic value against regular expression.

=over 8

=item B<--topic>

Topic value to check.

=item B<--format-custom>

Apply a custom change on the value.

=item B<--warning-regexp>

Return Warning if the topic value match the regexp.

=item B<--critical-regexp>

Return Critical if the topic value match the regexp.

=item B<--regexp-insensitive>

Allows to use case-insensitive regexp.

=item B<--format-*>

Output format according to the threshold.
Can be:
'ok' (default: 'value: %{value}'),
'warning' (default: 'value: %{value}'),
'critical' (default: 'value: %{value}'),
'unknown' (default: 'value: %{value}').

=item B<--format-custom>

Apply a custom change on the value.

=back

=cut