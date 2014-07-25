################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package centreon::plugins::class::bytes;

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    $self->{statefile} = $options{statefile};
    $self->{output} = $options{output};
    $self->{perfdata} = $options{perfdata};
    $self->{label} = $options{label};
    
    $self->{perfdata_template} = '%s';
    $self->{perfdata_use} = 'absolute';
    $self->{perfdata_extra_instance} = 1;
    
    $self->{output_template} = $self->{label} . ': %s %s';
    $self->{output_use} = ['absolute'];
    $self->{output_change_bytes} = 1;
    
    $self->{absolute_unit} = 'B';
    $self->{per_second_unit} = 'B';
    
    $self->{per_second} = 0;
    $self->{last_timestamp} = undef;

    $self->{result_values} = {};
    
    return $self;
}

sub init {
    my ($self, %options) = @_;
    
    if (($self->{perfdata}->threshold_validate(label => 'warning-' . $self->{label}, value => $self->{option_results}->{'warning-' . $self->{label}})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning-" . $self->{label} . " threshold '" . $self->{option_results}->{'warning-' . $self->{label}} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-' . $self->{label}, value => $self->{option_results}->{'critical-' . $self->{label}})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical-" . $self->{label} . " threshold '" . $self->{option_results}->{'warning-' . $self->{label}} . "'.");
        $self->{output}->option_exit();
    }
}

sub set {
    my ($self, %options) = @_;

    $self->{output_template} = $options{output_template} if (defined($options{output_template}));
    $self->{per_second} = $options{per_second} if (defined($options{per_second}));
    $self->{instance} = $options{instance} if (defined($options{instance}));
    $self->{key_values} = $options{key_values} if (defined($options{key_values}));
    $self->{perfdata_extra_instance} = $options{perfdata_extra_instance} if (defined($options{perfdata_extra_instance}));
    $self->{perfdata_template} = $options{perfdata_template} if (defined($options{perfdata_template}));
    $self->{perfdata_use} = $options{perfdata_template} if (defined($options{perfdata_use}));
    $self->{output_change_bytes} = $options{output_change_bytes} if (defined($options{output_change_bytes}));
    $self->{absolute_unit} = $options{absolute_unit} if (defined($options{absolute_unit}));
    $self->{per_second_unit} = $options{per_second_unit} if (defined($options{per_second_unit}));
}

sub calc {
    my ($self, %options) = @_;

    # manage only one value ;)
    my $name = ${$self->{key_values}}[0];
    
    if ($self->{per_second} == 1) {
        $self->{result_values}->{per_second} = ($options{new_datas}->{$self->{instance} . '_' . $name} - $options{old_datas}->{$self->{instance} . '_' . $name}) / $options{delta_time}
    }
    $self->{result_values}->{absolute} = ($options{new_datas}->{$self->{instance} . '_' . $name} - $options{old_datas}->{$self->{instance} . '_' . $name});
    
    return 1;
}

sub check_threshold {
    my ($self, %options) = @_;
    my $value = $self->{result_values}->{absolute};

    if ($self->{per_second} == 1) {
        $value = $self->{result_values}->{per_second};
    }
    return $self->{perfdata}->threshold_check(value => $value, threshold => [ { label => 'warning-' . $self->{label}, 'exit_litteral' => 'critical' },
                                                                              { label => 'critical-' . $self->{label}, 'exit_litteral' => 'warning' }]);
}

sub output {
    my ($self, %options) = @_;
    my ($value, $unit) = ($self->{result_values}->{absolute}, $self->{result_values}->{absolute_unit});
    
    if ($self->{per_second} == 1) {
        $value = $self->{result_values}->{per_second};
        $unit = $self->{per_second_unit};
    }
    if ($self->{output_change_bytes} == 1) {
        ($value, $unit) = $self->{perfdata}->change_bytes(value => $value);
    }
    
    return sprintf($self->{output_template}, $value, $unit);
}

sub perfdata {
    my ($self, %options) = @_;
    my $extra_label = '';
    
    $extra_label .= '_' . $self->{instance} if ($self->{perfdata_extra_instance} == 1);
    $self->{output}->perfdata_add(label => $self->{label} . $extra_label, unit => $self->{perfdata_unit},
                                  value => sprintf($self->{perfdata_template}, $self->{result_values}->{$self->{perfdata_use}}),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                  min => 0);
}

sub execute {
    my ($self, %options) = @_;
    my $old_datas = {};
    
    my $quit = 0;
    foreach my $value (@{$self->{key_values}}) {
        $options{new_datas}->{$self->{instance} . '_' . $value} = $options{values}->{$value};
        $old_datas->{$self->{instance} . '_' . $value} = $self->{statefile}->get(name => $self->{instance} . '_' . $value);
        if (!defined($old_datas->{$self->{instance} . '_' . $value})) {
            $quit = 1;
            next;
        }
        if ($old_datas->{$self->{instance} . '_' . $value} > $options{new_datas}->{$self->{instance} . '_' . $value}) {
            $old_datas->{$self->{instance} . '_' . $value} = 0;
        }
    }

    return undef if ($quit == 1);
    
    if ($self->{per_second} == 1) {
        if (!defined($self->{last_timestamp})) {
            $self->{last_timestamp} = $self->{statefile}->get(name => 'last_timestamp');
        }
        return undef if (!defined($self->{last_timestamp}));
    }
   
    my $delta_time;
    if ($self->{per_second} == 1) {
        $delta_time = $options{new_datas}->{last_timestamp} - $self->{last_timestamp};
        if ($delta_time <= 0) {
            $delta_time = 1;
        }
    }

    return $self->calc(old_datas => $old_datas, new_datas => $options{new_datas}, delta_time => $delta_time);
}

1;

__END__

