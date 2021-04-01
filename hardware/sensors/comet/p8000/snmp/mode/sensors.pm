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

package hardware::sensors::comet::p8000::snmp::mode::sensors;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_temperature_perfdata {
    my ($self, %options) = @_;

    my ($extra_label, $unit) = ('', 'C');
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(
        label => $self->{label} . $extra_label, unit => $unit,
        value => $self->{result_values}->{$self->{label} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display}),
    );
}

sub custom_humidity_perfdata {
    my ($self, %options) = @_;

    my ($extra_label, $unit) = ('', '%');
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    $self->{output}->perfdata_add(
        label => $self->{label} . $extra_label, unit => $unit,
        value => $self->{result_values}->{$self->{label} },
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display}),
        min => 0, max => 100,
    );
}

sub custom_sensor_threshold {
    my ($self, %options) = @_;
    
    my $warn_limit;
    if (defined($self->{instance_mode}->{option_results}->{'warning-' . $self->{label}}) && $self->{instance_mode}->{option_results}->{'warning-' . $self->{label}} ne '') {
        $warn_limit = $self->{instance_mode}->{option_results}->{'warning-' . $self->{label}};
    }
    $self->{perfdata}->threshold_validate(label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display}, value => $warn_limit);

    my $crit_limit = $self->{result_values}->{limit_lo} . ':' . $self->{result_values}->{limit_hi};
    if (defined($self->{instance_mode}->{option_results}->{'critical-' . $self->{label}}) && $self->{instance_mode}->{option_results}->{'critical-' . $self->{label}} ne '') {
        $crit_limit = $self->{instance_mode}->{option_results}->{'critical-' . $self->{label}};
    }
    $self->{perfdata}->threshold_validate(label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display}, value => $crit_limit);
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{$self->{label} },
        threshold => [ { label => 'critical-' . $self->{label} . '_' . $self->{result_values}->{display}, exit_litteral => 'critical' },
                       { label => 'warning-' . $self->{label} . '_' . $self->{result_values}->{display}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'channel', type => 1, cb_prefix_output => 'prefix_channel_output', message_multiple => 'All channels are ok', skipped_code => { -10 => 1 } },
    ];
    
    $self->{maps_counters}->{channel} = [
        { label => 'temperature', set => {
                key_values => [ { name => 'temperature' }, { name => 'limit_hi' }, { name => 'limit_lo' }, { name => 'display' } ],
                output_template => 'Temperature: %.2f C',                
                closure_custom_perfdata => $self->can('custom_temperature_perfdata'),
                closure_custom_threshold_check => $self->can('custom_sensor_threshold'),
            }
        },
        { label => 'humidity', set => {
                key_values => [ { name => 'humidity' }, { name => 'limit_hi' }, { name => 'limit_lo' }, { name => 'display' } ],
                output_template => 'Humidity: %.2f %%',                
                closure_custom_perfdata => $self->can('custom_humidity_perfdata'),
                closure_custom_threshold_check => $self->can('custom_sensor_threshold'),
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });
    
    return $self;
}

sub prefix_channel_output {
    my ($self, %options) = @_;

    return "Channel '" . $options{instance_value}->{display} . "' ";
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $oid_channels    = '.1.3.6.1.4.1.22626.1.5.2';
    my $chName_suffix   = '1.0';
    my $chVal_suffix    = '2.0';
    my $chLimHi_suffix  = '5.0';
    my $chLimLo_suffix  = '6.0';
    my $chUnit_suffix   = '9.0';

    my $snmp_result = $options{snmp}->get_table(oid => $oid_channels, nothing_quit => 1);
    $self->{channel} = {};
    for my $channel ((1, 2, 3, 4)) {
        next if (!defined($snmp_result->{$oid_channels . '.' . $channel . '.' . $chName_suffix}));
        
        my $value = $snmp_result->{$oid_channels . '.' . $channel . '.' . $chVal_suffix};
        # sensor not configured (n/a)
        next if ($value !~ /[0-9\.]/);
        
        my $name = $snmp_result->{$oid_channels . '.' . $channel . '.' . $chName_suffix};
        my $unit = $snmp_result->{$oid_channels . '.' . $channel . '.' . $chUnit_suffix};
        my $limit_hi = $snmp_result->{$oid_channels . '.' . $channel . '.' . $chLimHi_suffix};
        my $limit_lo = $snmp_result->{$oid_channels . '.' . $channel . '.' . $chLimLo_suffix};
        
        $limit_hi /= 10;
        $limit_lo /= 10;
        if ($unit =~ /F/i) {
            $value = sprintf("%.2f", ($value - 32) / 1.8);
            $limit_hi = sprintf("%.2f", ($limit_hi - 32) / 1.8);
            $limit_lo = sprintf("%.2f", ($limit_lo - 32) / 1.8);
        }
        
        $self->{channel}->{$channel} = {
            display => $name,
            humidity => ($unit =~ /RH/) ? $value : undef,
            temperature => ($unit =~ /F|C/) ? $value : undef,
            limit_hi => $limit_hi,
            limit_lo => $limit_lo,
        };
    }
}

1;

__END__

=head1 MODE

Check environment channels.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'temperature', 'humidity'.

=item B<--critical-*>

Threshold critical.
Can be: 'temperature', 'humidity'.

=back

=cut
