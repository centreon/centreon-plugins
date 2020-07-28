#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package centreon::plugins::values;

use strict;
use warnings;
# Warning message with sprintf and too much arguments.
# Really annoying. Need to disable that warning
no if ($^V gt v5.22.0), 'warnings' => 'redundant';

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{statefile} = $options{statefile};
    $self->{output} = $options{output};
    $self->{perfdata} = $options{perfdata};
    $self->{label} = $options{label};
    $self->{nlabel} = $options{nlabel};
    $self->{thlabel} = defined($options{thlabel}) ? $options{thlabel} : $self->{label};

    $self->{perfdatas} = [];
    
    $self->{output_template} = $self->{label} . ' : %s';
    $self->{output_use} = undef;
    $self->{output_change_bytes} = 0;
    
    $self->{output_error_template} = $self->{label} . ' : %s';
    
    $self->{threshold_use} = undef;
    $self->{threshold_warn} = undef;
    $self->{threshold_crit} = undef;

    $self->{per_second} = 0;
    $self->{manual_keys} = 0;
    $self->{last_timestamp} = undef;

    $self->{result_values} = {};
    
    return $self;
}

sub init {
    my ($self, %options) = @_;
    my $unkn = defined($self->{threshold_unkn}) ? $self->{threshold_unkn} : 'unknown-' . $self->{thlabel};
    my $warn = defined($self->{threshold_warn}) ? $self->{threshold_warn} : 'warning-' . $self->{thlabel};
    my $crit = defined($self->{threshold_crit}) ? $self->{threshold_crit} : 'critical-' . $self->{thlabel}; 

    if (($self->{perfdata}->threshold_validate(label => $unkn, value => $options{option_results}->{$unkn})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong $unkn threshold '" . $options{option_results}->{$unkn} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => $warn, value => $options{option_results}->{$warn})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong $warn threshold '" . $options{option_results}->{$warn} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => $crit, value => $options{option_results}->{$crit})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong $crit threshold '" . $options{option_results}->{$crit} . "'.");
        $self->{output}->option_exit();
    }
}

sub set {
    my ($self, %options) = @_;

    foreach (keys %options) {
        $self->{$_} = $options{$_};
    }
}

sub calc {
    my ($self, %options) = @_;

    # manage only one value ;)
    foreach my $value (@{$self->{key_values}}) {
        if (defined($value->{diff}) && $value->{diff} == 1)  {
            $self->{result_values}->{$value->{name}} = $options{new_datas}->{$self->{instance} . '_' . $value->{name}} - $options{old_datas}->{$self->{instance} . '_' . $value->{name}};
        } elsif (defined($value->{per_second}) && $value->{per_second} == 1) {
            $self->{result_values}->{$value->{name}} = ($options{new_datas}->{$self->{instance} . '_' . $value->{name}} - $options{old_datas}->{$self->{instance} . '_' . $value->{name}}) / $options{delta_time};
        } elsif (defined($value->{per_minute}) && $value->{per_minute} == 1) {
            $self->{result_values}->{$value->{name}} = ($options{new_datas}->{$self->{instance} . '_' . $value->{name}} - $options{old_datas}->{$self->{instance} . '_' . $value->{name}}) / ($options{delta_time} / 60);
        } else {
            $self->{result_values}->{$value->{name}} = $options{new_datas}->{$self->{instance} . '_' . $value->{name}};
        }
    }

    return 0;
}

sub threshold_check {
    my ($self, %options) = @_;
    
    if (defined($self->{closure_custom_threshold_check})) {
        return &{$self->{closure_custom_threshold_check}}($self, %options);
    }

    my $unkn = defined($self->{threshold_unkn}) ? $self->{threshold_unkn} : 'unknown-' . $self->{thlabel};
    my $warn = defined($self->{threshold_warn}) ? $self->{threshold_warn} : 'warning-' . $self->{thlabel};
    my $crit = defined($self->{threshold_crit}) ? $self->{threshold_crit} : 'critical-' . $self->{thlabel};
    
    my $value = '';
    if (defined($self->{threshold_use})) {
        $value = $self->{result_values}->{ $self->{threshold_use} };
    } else {
        $value = defined($self->{key_values}->[0]) ? $self->{result_values}->{ $self->{key_values}->[0]->{name} } : '';
    }

    return $self->{perfdata}->threshold_check(
        value => $value, threshold => [
            { label => $crit, exit_litteral => 'critical' },
            { label => $warn, exit_litteral => 'warning' },
            { label => $unkn, exit_litteral => 'unknown' }
        ]
    );
}

sub output_error {
    my ($self, %options) = @_;

    return sprintf($self->{output_error_template}, $self->{error_msg});
}

sub output {
    my ($self, %options) = @_;
     
    if (defined($self->{closure_custom_output})) {
        return $self->{closure_custom_output}->($self);
    }

    my ($value, $unit, $name) = ('', '');
    if (defined($self->{output_use})) {
        $name = $self->{output_use};
    } else {
        $name = defined($self->{key_values}->[0]) ? $self->{key_values}->[0]->{name} : undef;
    }

    if (defined($name)) {
        $value = $self->{result_values}->{$name};
        if ($self->{output_change_bytes} == 1) {
            ($value, $unit) = $self->{perfdata}->change_bytes(value => $value);
        } elsif ($self->{output_change_bytes} == 2) {
            ($value, $unit) = $self->{perfdata}->change_bytes(value => $value, network => 1);
        }
    }

    return sprintf($self->{output_template}, $value, $unit);
}

sub use_instances {
    my ($self, %options) = @_;

    if (!defined($options{extra_instance}) || $options{extra_instance} != 0 || $self->{output}->use_new_perfdata()) {
        return 1;
    }
    
    return 0;
}

sub perfdata {
    my ($self, %options) = @_;
    
    if (defined($self->{closure_custom_perfdata})) {
        return &{$self->{closure_custom_perfdata}}($self, %options);
    }
    
    my $warn = defined($self->{threshold_warn}) ? $self->{threshold_warn} : 'warning-' . $self->{thlabel};
    my $crit = defined($self->{threshold_crit}) ? $self->{threshold_crit} : 'critical-' . $self->{thlabel}; 
    
    foreach my $perf (@{$self->{perfdatas}}) {
        my ($label, $extra_label, $min, $max, $th_total) = ($self->{label}, '');
        my $cast_int = (defined($perf->{cast_int}) && $perf->{cast_int} == 1) ? 1 : 0;
        my $template = '%s';
        
        $template = $perf->{template} if (defined($perf->{template}));
        $label = $perf->{label} if (defined($perf->{label}));
        if (defined($perf->{min})) {
            $min = ($perf->{min} =~ /[^0-9]/) ? $self->{result_values}->{$perf->{min}} : $perf->{min};
        }
        if (defined($perf->{max})) {
            $max = ($perf->{max} =~ /[^0-9]/) ? $self->{result_values}->{$perf->{max}} : $perf->{max};
        }
        if (defined($perf->{threshold_total})) {
            $th_total = ($perf->{threshold_total} =~ /[^0-9]/) ? $self->{result_values}->{$perf->{threshold_total}} : $perf->{threshold_total};
        }
        
        my $instances;
        if (defined($perf->{label_extra_instance}) && $perf->{label_extra_instance} == 1) {
            my $instance = '';
            if (defined($perf->{instance_use})) {
                $instance = $self->{result_values}->{$perf->{instance_use}};
            } else {
                $instance = $self->{instance};
            }
            
            if (!defined($options{extra_instance}) || $options{extra_instance} != 0 || $self->{output}->use_new_perfdata()) {
                $instances = $instance;
            }
        }

        my $value = defined($perf->{value}) ? $perf->{value} : $self->{key_values}->[0]->{name};
        $self->{output}->perfdata_add(
            label => $label,
            instances => $instances,
            nlabel => $self->{nlabel},
            unit => $perf->{unit},
            value => $cast_int == 1 ? int($self->{result_values}->{$value}) : sprintf($template, $self->{result_values}->{$value}),
            warning => $self->{perfdata}->get_perfdata_for_output(label => $warn, total => $th_total, cast_int => $cast_int),
            critical => $self->{perfdata}->get_perfdata_for_output(label => $crit, total => $th_total, cast_int => $cast_int),
            min => $min,
            max => $max
        );
    }
}

sub execute {
    my ($self, %options) = @_;
    my $old_datas = {};

    $self->{result_values} = {},
    $self->{error_msg} = undef;
    my $quit = 0;
    
    $options{new_datas} = {} if (!defined($options{new_datas}));
    foreach my $value (@{$self->{key_values}}) {
        if (!defined($options{values}->{$value->{name}}) || 
            defined($value->{no_value}) && $options{values}->{$value->{name}} eq $value->{no_value}) {
            $quit = 2;
            last;
        }
    
        if ((defined($value->{diff}) && $value->{diff} == 1) ||
            (defined($value->{per_minute}) && $value->{per_minute} == 1) ||
            (defined($value->{per_second}) && $value->{per_second} == 1)) {
            $options{new_datas}->{$self->{instance} . '_' . $value->{name}} = $options{values}->{$value->{name}};
            $old_datas->{$self->{instance} . '_' . $value->{name}} = $self->{statefile}->get(name => $self->{instance} . '_' . $value->{name});
            if (!defined($old_datas->{$self->{instance} . '_' . $value->{name}})) {
                $quit = 1;
                next;
            }
            if ($old_datas->{$self->{instance} . '_' . $value->{name}} > $options{new_datas}->{$self->{instance} . '_' . $value->{name}}) {
                $old_datas->{$self->{instance} . '_' . $value->{name}} = 0;
            }
        } else {
            $options{new_datas}->{$self->{instance} . '_' . $value->{name}} = $options{values}->{$value->{name}};
            if (defined($self->{statefile})) {
                $old_datas->{$self->{instance} . '_' . $value->{name}} = $self->{statefile}->get(name => $self->{instance} . '_' . $value->{name});
            }
        }
    }
    
    # Very manual
    if ($self->{manual_keys} == 1) {
        foreach my $name (keys %{$options{values}}) {
            $options{new_datas}->{$self->{instance} . '_' . $name} = $options{values}->{$name};
            if (defined($self->{statefile})) {
                $old_datas->{$self->{instance} . '_' . $name} = $self->{statefile}->get(name => $self->{instance} . '_' . $name);
            }
        }
    }

    if ($quit == 2) {
        $self->{error_msg} = 'skipped (no value(s))';
        return -10;
    }

    if (defined($self->{statefile})) {
        $self->{last_timestamp} = $self->{statefile}->get(name => 'last_timestamp');
    }

    if ($quit == 1) {
        $self->{error_msg} = 'Buffer creation';
        return -1;
    }

    my $delta_time;
    if (defined($self->{statefile}) && defined($self->{last_timestamp})) {
        $delta_time = $options{new_datas}->{last_timestamp} - $self->{last_timestamp};
        if ($delta_time <= 0) {
            $delta_time = 1;
        }
    }

    if (defined($self->{closure_custom_calc})) {
        return $self->{closure_custom_calc}->(
            $self,
            old_datas => $old_datas,
            new_datas => $options{new_datas},
            delta_time => $delta_time,
            extra_options => $self->{closure_custom_calc_extra_options}
        );
    }
    return $self->calc(old_datas => $old_datas, new_datas => $options{new_datas}, delta_time => $delta_time);
}

1;

__END__

