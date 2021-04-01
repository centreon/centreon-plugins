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

package centreon::plugins::perfdata;

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{output} = $options{output};
    # Typical Nagios Perfdata 'with ~ @ ..'
    $self->{threshold_label} = {};
    $self->{float_precision} = defined($self->{output}->{option_results}->{float_precision}) && $self->{output}->{option_results}->{float_precision} =~ /\d+/ ?  
        int($self->{output}->{option_results}->{float_precision}) : 8;

    return $self;
}

sub get_perfdata_for_output {
    my ($self, %options) = @_;
    # $options{label} : threshold label
    # $options{total} : percent threshold to transform in global
    # $options{cast_int} : cast absolute to int
    # $options{op} : operator to apply to start/end value (uses with 'value'})
    # $options{value} : value to apply with 'op' option
    
    if (!defined($self->{threshold_label}->{$options{label}}->{value}) || $self->{threshold_label}->{$options{label}}->{value} eq '') {
        return '';
    }
    
    my %perf_value = %{$self->{threshold_label}->{$options{label}}};
    
    if (defined($options{op}) && defined($options{value})) {
        eval "\$perf_value{start} = \$perf_value{start} $options{op} \$options{value}" if ($perf_value{infinite_neg} == 0);
        eval "\$perf_value{end} = \$perf_value{end} $options{op} \$options{value}" if ($perf_value{infinite_pos} == 0);
    }
    if (defined($options{total})) {
        $perf_value{start} = $perf_value{start} * $options{total} / 100 if ($perf_value{infinite_neg} == 0);
        $perf_value{end} = $perf_value{end} * $options{total} / 100 if ($perf_value{infinite_pos} == 0);
        $perf_value{start} = sprintf("%.2f", $perf_value{start}) if ($perf_value{infinite_neg} == 0 && (!defined($options{cast_int}) || $options{cast_int} != 1));
        $perf_value{end} = sprintf("%.2f", $perf_value{end}) if ($perf_value{infinite_pos} == 0 && (!defined($options{cast_int}) || $options{cast_int} != 1));
    }
    
    $perf_value{start} = int($perf_value{start}) if ($perf_value{infinite_neg} == 0 && defined($options{cast_int}) && $options{cast_int} == 1);
    $perf_value{end} = int($perf_value{end}) if ($perf_value{infinite_pos} == 0 && defined($options{cast_int}) && $options{cast_int} == 1);
    
    my $perf_output = ($perf_value{arobase} == 1 ? '@' : '') . 
                      (($perf_value{infinite_neg} == 0) ? $perf_value{start} : '~') . 
                      ':' . 
                      (($perf_value{infinite_pos} == 0) ? $perf_value{end} : '');

    return $perf_output;
}

sub threshold_validate {
    my ($self, %options) = @_;
    # $options{label} : threshold label
    # $options{value} : threshold value

    my $status = 1;
    $self->{threshold_label}->{$options{label}} = { value => $options{value}, start => undef, end => undef, arobase => undef, infinite_neg => undef, infinite_pos => undef };
    if (!defined($options{value}) || $options{value} eq '') {
        return $status;
    }

    ($status, my $result_perf) = 
        centreon::plugins::misc::parse_threshold(threshold => $options{value});
    $self->{threshold_label}->{$options{label}} = { %{$self->{threshold_label}->{$options{label}}}, %$result_perf };
    
    $self->{threshold_label}->{$options{label}}->{start_precision} = $self->{threshold_label}->{$options{label}}->{start};
    if ($self->{threshold_label}->{$options{label}}->{start} =~ /[.,]/) {
        $self->{threshold_label}->{$options{label}}->{start_precision} = sprintf("%.$self->{output}->{option_results}->{float_precision}f", $self->{threshold_label}->{$options{label}}->{start});
    }
    
    $self->{threshold_label}->{$options{label}}->{end_precision} = $self->{threshold_label}->{$options{label}}->{end};
    if ($self->{threshold_label}->{$options{label}}->{end} =~ /[.,]/) {
        $self->{threshold_label}->{$options{label}}->{end_precision} = sprintf("%.$self->{output}->{option_results}->{float_precision}f", $self->{threshold_label}->{$options{label}}->{end});
    }
    
    return $status;
}

sub threshold_check {
    my ($self, %options) = @_;
    # Can check multiple threshold. First match: out. Order is important
    # options{value}: value to compare
    # options{threshold}: ref to an array (example: [ {label => 'warning', exit_litteral => 'warning' }, {label => 'critical', exit_litteral => 'critical'} ]
    if ($options{value} =~ /[.,]/) {
        $options{value} = sprintf("%.$self->{output}->{option_results}->{float_precision}f", $options{value});
    }
    
    foreach (@{$options{threshold}}) {
        next if (!defined($self->{threshold_label}->{$_->{label}}));
        next if (!defined($self->{threshold_label}->{$_->{label}}->{value}) || $self->{threshold_label}->{$_->{label}}->{value} eq '');
        if ($self->{threshold_label}->{$_->{label}}->{arobase} == 0 && ($options{value} < $self->{threshold_label}->{$_->{label}}->{start_precision} || $options{value} > $self->{threshold_label}->{$_->{label}}->{end_precision})) {
            return $_->{exit_litteral};
        } elsif ($self->{threshold_label}->{$_->{label}}->{arobase}  == 1 && ($options{value} >= $self->{threshold_label}->{$_->{label}}->{start_precision} && $options{value} <= $self->{threshold_label}->{$_->{label}}->{end_precision})) {
            return $_->{exit_litteral};
        }
    }

    return 'ok';
}

sub trim {
    my ($self, $value) = @_;
    
    $value =~ s/^[ \t]+//;
    $value =~ s/[ \t]+$//;
    return $value;
}

sub change_bytes {
    my ($self, %options) = @_;

    my $value = $options{value};
    my $divide = defined($options{network}) ? 1000 : 1024;
    my @units = ('K', 'M', 'G', 'T');
    my $unit = '';
    my $sign = '';

    $sign = '-' if ($value != abs($value));
    $value = abs($value);
    
    for (my $i = 0; $i < scalar(@units); $i++) {
        last if (($value / $divide) < 1);
        $unit = $units[$i];
        $value = $value / $divide;
    }

    return (sprintf('%.2f', $sign . $value), $unit . (defined($options{network}) ? 'b' : 'B'));
}

1;

__END__

=head1 NAME

Perfdata class

=head1 SYNOPSIS

-

=head1 DESCRIPTION

B<perfdata>.

=cut
