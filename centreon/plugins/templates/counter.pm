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

package centreon::plugins::templates::counter;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::misc;

my $sort_subs = {
    num => sub { $a <=> $b },
    cmp => sub { $a cmp $b },
};

sub set_counters {
    my ($self, %options) = @_;
    
    if (!defined($self->{maps_counters})) {
        $self->{maps_counters} = {};
    }
    
    $self->{maps_counters_type} = [];
    
    # 0 = mode total
    # 1 = mode instances
    #push @{$self->{maps_counters_type}}, { 
    #    name => 'global', type => 0, message_separator => ', ', cb_prefix_output => undef, cb_init => undef,
    #};

    #$self->{maps_counters}->{global} = [
    #    { label => 'client', set => {
    #           key_values => [ { name => 'client' } ],
    #           output_template => 'Current client connections : %s',
    #           perfdatas => [
    #               { label => 'Client', value => 'client', template => '%s', 
    #                 min => 0, unit => 'con' },
    #           ],
    #       }
    #    },
    #];
    
    # Example for instances
    #push @{$self->{maps_counters_type}}, { 
    #    name => 'cpu', type => 1, message_separator => ', ', cb_prefix_output => undef, cb_init => undef,
    #    message_multiple => 'All CPU usages are ok',
    #};    
}

sub get_callback {
    my ($self, %options) = @_;

    if (defined($options{method_name})) {
        return $self->can($options{method_name});
    }
    
    return undef;
}

sub call_object_callback {
    my ($self, %options) = @_;
    
    if (defined($options{method_name})) {
        my $method = $self->can($options{method_name});
        if ($method) {
            return $self->$method(%options);
        }
    }
    
    return undef;
}

sub get_threshold_prefix {
    my ($self, %options) = @_;
    
    my $prefix = '';
    END_LOOP: foreach (@{$self->{maps_counters_type}}) {
        if ($_->{name} eq $options{name}) {
            $prefix = 'instance-' if ($_->{type} == 1);
            last;
        }
        
        if ($_->{type} == 3) {
            foreach (@{$_->{group}}) {
                if ($_->{name} eq $options{name}) {
                    $prefix = 'instance-' if ($_->{type} == 0);
                    $prefix = 'subinstance-' if ($_->{type} == 1);
                    last END_LOOP;
                }
            }
        }
    }

    return $prefix;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'filter-counters-block:s' => { name => 'filter_counters_block' },
        'filter-counters:s'       => { name => 'filter_counters' },
        'display-ok-counters:s'   => { name => 'display_ok_counters' },
        'list-counters'           => { name => 'list_counters' }
    });
    $self->{statefile_value} = undef;
    if (defined($options{statefile}) && $options{statefile}) {
        centreon::plugins::misc::mymodule_load(
            output => $self->{output},
            module => 'centreon::plugins::statefile',
            error_msg => "Cannot load module 'centreon::plugins::statefile'."
        );
        $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    }
    
    $self->{maps_counters} = {} if (!defined($self->{maps_counters}));
    $self->set_counters(%options);
    
    foreach my $key (keys %{$self->{maps_counters}}) {
        foreach (@{$self->{maps_counters}->{$key}}) {
            my $label = $_->{label};
            my $thlabel = $label;
            if ($self->{output}->use_new_perfdata() && defined($_->{nlabel})) {
                $label = $_->{nlabel};
                $thlabel = $self->get_threshold_prefix(name => $key) . $label;
            }
            $thlabel =~ s/\./-/g;

            if (!defined($_->{threshold}) || $_->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                    'unknown-' . $thlabel . ':s'  => { name => 'unknown-' . $thlabel, default => $_->{unknown_default} },
                    'warning-' . $thlabel . ':s'  => { name => 'warning-' . $thlabel, default => $_->{warning_default} },
                    'critical-' . $thlabel . ':s' => { name => 'critical-' . $thlabel, default => $_->{critical_default} }
                });

                if (defined($_->{nlabel})) {
                    $options{options}->add_options(arguments => {
                        'unknown-' . $_->{label} . ':s'  => { name => 'unknown-' . $_->{label}, redirect => 'unknown-' . $thlabel },
                        'warning-' . $_->{label} . ':s'  => { name => 'warning-' . $_->{label}, redirect => 'warning-' . $thlabel },
                        'critical-' . $_->{label} . ':s' => { name => 'critical-' . $_->{label}, redirect => 'critical-' . $thlabel }
                    });
                }
            }

            $_->{obj} = centreon::plugins::values->new(
                statefile => $self->{statefile_value},
                output => $self->{output}, perfdata => $self->{perfdata},
                label => $_->{label}, nlabel => $_->{nlabel}, thlabel => $thlabel
            );
            $_->{obj}->set(%{$_->{set}});
        }
    }

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{list_counters})) {
        my $list_counter = 'counter list:';
        my $th_counter = '';
        foreach my $key (keys %{$self->{maps_counters}}) {
            foreach (@{$self->{maps_counters}->{$key}}) {
                my $label = $_->{label};
                $label =~ s/-//g;
                $list_counter .= " " . $_->{label};
                $th_counter .= " --warning-$_->{label}='\$_SERVICEWARNING" . uc($label) . "\$' --critical-$_->{label}='\$_SERVICECRITICAL" . uc($label) . "\$'";  
            }
        }
        $self->{output}->output_add(short_msg => $list_counter);
        $self->{output}->output_add(long_msg => 'configuration: ' . $th_counter); 
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
        $self->{output}->exit();
    }

    my $change_macros_opt = [];
    foreach my $key (keys %{$self->{maps_counters}}) {
        foreach (@{$self->{maps_counters}->{$key}}) {
            push @$change_macros_opt, 'unknown-' . $_->{label}, 'warning-' . $_->{label}, 'critical-' . $_->{label}
                if (defined($_->{type}) && $_->{type} == 2);
            $_->{obj}->{instance_mode} = $self;
            $_->{obj}->init(option_results => $self->{option_results}) if (!defined($_->{type}) || $_->{type} != 2);
        }
    }

    $self->change_macros(macros => $change_macros_opt) if (scalar(@$change_macros_opt) > 0);

    if (defined($self->{statefile_value})) {
        $self->{statefile_value}->check_options(%options);
    }
}

sub run_global {
    my ($self, %options) = @_;

    return undef if (defined($self->{option_results}->{filter_counters_block}) && $self->{option_results}->{filter_counters_block} ne '' 
        && $options{config}->{name} =~ /$self->{option_results}->{filter_counters_block}/);
    return undef if (defined($options{config}->{cb_init}) && $self->call_object_callback(method_name => $options{config}->{cb_init}) == 1);
    my $resume = defined($options{resume}) && $options{resume} == 1 ? 1 : 0;
    # Can be set when it comes from type 3 counters
    my $called_multiple = defined($options{called_multiple}) && $options{called_multiple} == 1 ? 1 : 0;
    my $multiple_parent = defined($options{multiple_parent}) && $options{multiple_parent} == 1 ? 1 : 0;
    my $force_instance = defined($options{force_instance}) ? $options{force_instance} : undef;

    my $message_separator = defined($options{config}->{message_separator}) ? 
        $options{config}->{message_separator}: ', ';
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (@{$self->{maps_counters}->{$options{config}->{name}}}) {
        my $obj = $_->{obj};

        next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
            $_->{label} !~ /$self->{option_results}->{filter_counters}/);

        $obj->set(instance => defined($force_instance) ? $force_instance : $options{config}->{name});

        my ($value_check) = $obj->execute(new_datas => $self->{new_datas}, values => $self->{$options{config}->{name}});

        next if (defined($options{config}->{skipped_code}) && defined($options{config}->{skipped_code}->{$value_check}));
        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = $message_separator;
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        if (!defined($_->{display_ok}) || $_->{display_ok} != 0 ||
            (defined($self->{option_results}->{display_ok_counters}) && $self->{option_results}->{display_ok_counters} ne '' &&
             $_->{label} =~ /$self->{option_results}->{display_ok_counters}/)) {
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = $message_separator;
        }

        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = $message_separator;
        }

        $obj->perfdata(extra_instance => $multiple_parent);
    }

    my ($prefix_output, $suffix_output);
    $prefix_output = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}, instance_value => $self->{$options{config}->{name}}) 
        if (defined($options{config}->{cb_prefix_output}));
    $prefix_output = '' if (!defined($prefix_output));

    $suffix_output = $self->call_object_callback(method_name => $options{config}->{cb_suffix_output}, instance_value => $self->{$options{config}->{name}}) 
        if (defined($options{config}->{cb_suffix_output}));
    $suffix_output = '' if (!defined($suffix_output));

    if ($called_multiple == 1 && $long_msg ne '') {
        $self->{output}->output_add(long_msg => $options{indent_long_output} . $prefix_output. $long_msg . $suffix_output);
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        if ($called_multiple == 0) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => $prefix_output . $short_msg . $suffix_output
            );
        } else {
            $self->run_multiple_prefix_output(
                severity => $exit,
                short_msg => $prefix_output . $short_msg . $suffix_output
            );
        }
    } else {
        if ($long_msg ne '' && $multiple_parent == 0) {
            if ($called_multiple == 0) {
                $self->{output}->output_add(short_msg => $prefix_output . $long_msg . $suffix_output) ;
            } else {
                $self->run_multiple_prefix_output(
                    severity => 'ok',
                    short_msg => $prefix_output . $long_msg . $suffix_output
                );
            }
        }
    }
}

sub run_instances {
    my ($self, %options) = @_;

    return undef if (defined($self->{option_results}->{filter_counters_block}) && $self->{option_results}->{filter_counters_block} ne '' 
        && $options{config}->{name} =~ /$self->{option_results}->{filter_counters_block}/);
    return undef if (defined($options{config}->{cb_init}) && $self->call_object_callback(method_name => $options{config}->{cb_init}) == 1);
    my $cb_init_counters = $self->get_callback(method_name => $options{config}->{cb_init_counters});
    my $display_status_lo = defined($options{display_status_long_output}) && $options{display_status_long_output} == 1 ? 1 : 0;
    my $resume = defined($options{resume}) && $options{resume} == 1 ? 1 : 0;
    my $no_message_multiple = 1;
    
    $self->{lproblems} = 0;
    $self->{multiple} = 1;
    if (scalar(keys %{$self->{$options{config}->{name}}}) <= 1) {
        $self->{multiple} = 0;
    }
    
    my $message_separator = defined($options{config}->{message_separator}) ? 
        $options{config}->{message_separator}: ', ';

    my $sort_method = 'cmp';
    $sort_method = $options{config}->{sort_method}
        if (defined($options{config}->{sort_method}));
    foreach my $id (sort { $sort_subs->{$sort_method}->() } keys %{$self->{$options{config}->{name}}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (@{$self->{maps_counters}->{$options{config}->{name}}}) {
            my $obj = $_->{obj};

            next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
                $_->{label} !~ /$self->{option_results}->{filter_counters}/);
            next if ($cb_init_counters && $self->$cb_init_counters(%$_) == 1);

            $no_message_multiple = 0;
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(
                new_datas => $self->{new_datas},
                values => $self->{$options{config}->{name}}->{$id}
            );
            next if (defined($options{config}->{skipped_code}) && defined($options{config}->{skipped_code}->{$value_check}));
            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = $message_separator;
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            if (!defined($_->{display_ok}) || $_->{display_ok} != 0 ||
                (defined($self->{option_results}->{display_ok_counters}) && $self->{option_results}->{display_ok_counters} ne '' &&
                 $_->{label} =~ /$self->{option_results}->{display_ok_counters}/)) {
                $long_msg .= $long_msg_append . $output;
                $long_msg_append = $message_separator;
            }
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $self->{lproblems}++;
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = $message_separator;
            }
            
            $obj->perfdata(extra_instance => $self->{multiple});
        }

        my ($prefix_output, $suffix_output);
        $prefix_output = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}, instance_value => $self->{$options{config}->{name}}->{$id})
            if (defined($options{config}->{cb_prefix_output}));
        $prefix_output = '' if (!defined($prefix_output));
        
        $suffix_output = $self->call_object_callback(method_name => $options{config}->{cb_suffix_output}) 
        if (defined($options{config}->{cb_suffix_output}));
        $suffix_output = '' if (!defined($suffix_output));

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        # in mode grouped, we don't display 'ok'
        my $debug = 0;
        $debug = 1 if ($display_status_lo == 1 && $self->{output}->is_status(value => $exit, compare => 'OK', litteral => 1));
        if (scalar @{$self->{maps_counters}->{$options{config}->{name}}} > 0 && $long_msg ne '') {
            $self->{output}->output_add(long_msg => ($display_status_lo == 1 ? lc($exit) . ': ' : '') . $prefix_output . $long_msg . $suffix_output, debug => $debug);
        }
        if ($resume == 1) {
            $self->{most_critical_instance} = $self->{output}->get_most_critical(status => [ $self->{most_critical_instance},  $exit ]);  
            next;
        }
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => $prefix_output . $short_msg . $suffix_output
            );
        }
        
        if ($self->{multiple} == 0)  {
            $self->{output}->output_add(short_msg => $prefix_output . $long_msg . $suffix_output);
        }
    }
    
    if ($no_message_multiple == 0 && $self->{multiple} == 1 && $resume == 0) {
        $self->{output}->output_add(short_msg => $options{config}->{message_multiple});
    }
}

sub run_group {
    my ($self, %options) = @_;

    my $multiple = 1;
    return if (scalar(keys %{$self->{$options{config}->{name}}}) <= 0);
    if (scalar(keys %{$self->{$options{config}->{name}}}) <= 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $options{config}->{message_multiple}
        );
    }

    my $format_output = defined($options{config}->{format_output}) ? $options{config}->{format_output} : '%s problem(s) detected';

    my ($global_exit, $total_problems) = ([], 0);
    foreach my $id (sort keys %{$self->{$options{config}->{name}}}) {
        $self->{most_critical_instance} = 'ok';
        if (defined($options{config}->{cb_long_output})) {
            $self->{output}->output_add(
                long_msg => $self->call_object_callback(
                    method_name => $options{config}->{cb_long_output},
                    instance_value => $self->{$options{config}->{name}}->{$id}
                )
            );
        }

        foreach my $group (@{$options{config}->{group}}) {
            $self->{$group->{name}} = $self->{$options{config}->{name}}->{$id}->{$group->{name}};
            
            # we resume datas
            $self->run_instances(config => $group, display_status_long_output => 1, resume => 1);
            
            push @{$global_exit}, $self->{most_critical_instance};
            $total_problems += $self->{lproblems};
            
            my $prefix_output;
            $prefix_output = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}, instance_value => $self->{$options{config}->{name}}->{$id})
            if (defined($options{config}->{cb_prefix_output}));
            $prefix_output = '' if (!defined($prefix_output));
            
            if ($multiple == 0 && (!defined($group->{display}) || $group->{display} != 0)) {
                $self->{output}->output_add(
                    severity => $self->{most_critical_instance},
                    short_msg => sprintf("${prefix_output}" . $format_output, $self->{lproblems})
                );
            }
        }
    }
    
    if ($multiple == 1) {
        my $exit = $self->{output}->get_most_critical(status => [ @{$global_exit} ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf($format_output, $total_problems)
            );
        }
    }
    
    if (defined($options{config}->{display_counter_problem})) {
        $self->{output}->perfdata_add(
            label => $options{config}->{display_counter_problem}->{label},
            nlabel => $options{config}->{display_counter_problem}->{nlabel},
            unit => $options{config}->{display_counter_problem}->{unit},
            value => $total_problems,
            min => $options{config}->{display_counter_problem}->{min}, max => $options{config}->{display_counter_problem}->{max}
        );
    }
}

sub run_multiple_instances {
    my ($self, %options) = @_;

    return undef if (defined($self->{option_results}->{filter_counters_block}) && $self->{option_results}->{filter_counters_block} ne '' 
        && $options{config}->{name} =~ /$self->{option_results}->{filter_counters_block}/);
    return undef if (defined($options{config}->{cb_init}) && $self->call_object_callback(method_name => $options{config}->{cb_init}) == 1);
    my $use_new_perfdata = $self->{output}->use_new_perfdata();
    my $multiple_parent = defined($options{multiple_parent}) && $options{multiple_parent} == 1 ? $options{multiple_parent} : 0;
    my $indent_long_output = defined($options{indent_long_output}) ? $options{indent_long_output} : '';
    my $no_message_multiple = 1;
    my $display_long = (!defined($options{config}->{display_long}) || $options{config}->{display_long} != 0) ? 1 : 0;
    my $display_short = (!defined($options{config}->{display_short}) || $options{config}->{display_short} != 0) ? 1 : 0;

    my $multiple = 1;
    if (scalar(keys %{$self->{$options{config}->{name}}}) <= 1) {
        $multiple = 0;
    }

    my $message_separator = defined($options{config}->{message_separator}) ? 
        $options{config}->{message_separator} : ', ';
    my $sort_method = 'cmp';
    $sort_method = $options{config}->{sort_method}
        if (defined($options{config}->{sort_method}));
    foreach my $id (sort { $sort_subs->{$sort_method}->() } keys %{$self->{$options{config}->{name}}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (@{$self->{maps_counters}->{$options{config}->{name}}}) {
            my $obj = $_->{obj};
            
            next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
                $_->{label} !~ /$self->{option_results}->{filter_counters}/);
            
            my $instance = $id;
            if ($use_new_perfdata || ($multiple_parent == 1 && $multiple == 1)) {
                $instance = $options{instance_parent} . ($self->{output}->get_instance_perfdata_separator()) . $id;
            } elsif ($multiple_parent == 1 && $multiple == 0) {
                $instance = $options{instance_parent};
            }
            
            $no_message_multiple = 0;
            $obj->set(instance => $instance);
        
            my ($value_check) = $obj->execute(
                new_datas => $self->{new_datas},
                values => $self->{$options{config}->{name}}->{$id}
            );
            next if (defined($options{config}->{skipped_code}) && defined($options{config}->{skipped_code}->{$value_check}));
            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = $message_separator;
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            if (!defined($_->{display_ok}) || $_->{display_ok} != 0 ||
                (defined($self->{option_results}->{display_ok_counters}) && $self->{option_results}->{display_ok_counters} ne '' &&
                 $_->{label} =~ /$self->{option_results}->{display_ok_counters}/)) {
                $long_msg .= $long_msg_append . $output;
                $long_msg_append = $message_separator;
            }

            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = $message_separator;
            }
            
            if ($multiple_parent == 1 && $multiple == 0) {
                $obj->perfdata(extra_instance => 1);
            } else {
                $obj->perfdata(extra_instance => $multiple);
            }
        }

        my ($prefix_output, $suffix_output);
        $prefix_output = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}, instance_value => $self->{$options{config}->{name}}->{$id})
            if (defined($options{config}->{cb_prefix_output}));
        $prefix_output = '' if (!defined($prefix_output));

        $suffix_output = $self->call_object_callback(method_name => $options{config}->{cb_suffix_output}) 
        if (defined($options{config}->{cb_suffix_output}));
        $suffix_output = '' if (!defined($suffix_output));

        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (scalar @{$self->{maps_counters}->{$options{config}->{name}}} > 0 && $long_msg ne '') {
            $self->{output}->output_add(long_msg => $indent_long_output . $prefix_output . $long_msg . $suffix_output)
                if ($display_long == 1);
        }
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->run_multiple_prefix_output(
                severity => $exit,
                short_msg => $prefix_output . $short_msg . $suffix_output
            );
        }

        if ($multiple == 0 && $multiple_parent == 0) {
            $self->run_multiple_prefix_output(severity => 'ok', short_msg => $prefix_output . $long_msg . $suffix_output)
                if ($display_short == 1);
        }
    }

    if ($no_message_multiple == 0 && $multiple == 1 && $multiple_parent == 0) {
        $self->run_multiple_prefix_output(severity => 'ok', short_msg => $options{config}->{message_multiple})
            if ($display_short == 1);
    }
}

sub run_multiple_prefix_output {
    my ($self, %options) = @_;
    
    my %separator;
    if ($self->{prefix_multiple_output_done}->{lc($options{severity})} == 0) {
        $self->{output}->output_add(severity => $options{severity}, short_msg => $self->{prefix_multiple_output});
        $self->{prefix_multiple_output_done}->{lc($options{severity})} = 1;
        $separator{separator} = '';
    }

    $self->{output}->output_add(severity => $options{severity}, short_msg => $options{short_msg}, %separator);
}

sub run_multiple {
    my ($self, %options) = @_;

    my $multiple = 1;
    if (scalar(keys %{$self->{$options{config}->{name}}}) <= 1) {
        $multiple = 0;
    }

    if ($multiple == 1) {
        $self->{output}->output_add(
            severity => 'OK',
            short_msg => $options{config}->{message_multiple}
        );
    }

    foreach my $instance (sort keys %{$self->{$options{config}->{name}}}) {
        if (defined($options{config}->{cb_long_output})) {
            $self->{output}->output_add(
                long_msg => $self->call_object_callback(
                    method_name => $options{config}->{cb_long_output},
                    instance_value => $self->{$options{config}->{name}}->{$instance}
                )
            );
        }

        $self->{prefix_multiple_output} = '';
        $self->{prefix_multiple_output_done} = { ok => 0, warning => 0, critical => 0, unknown => 0 };
        $self->{prefix_multiple_output} = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}, instance_value => $self->{$options{config}->{name}}->{$instance})
             if (defined($options{config}->{cb_prefix_output}));
        my $indent_long_output = '';
        $indent_long_output = $options{config}->{indent_long_output}
            if (defined($options{config}->{indent_long_output}));

        foreach my $group (@{$options{config}->{group}}) {
            next if (!defined($self->{$options{config}->{name}}->{$instance}->{$group->{name}}));
            $self->{$group->{name}} = $self->{$options{config}->{name}}->{$instance}->{$group->{name}};

            if ($group->{type} == 1) {
                $self->run_multiple_instances(config => $group, multiple_parent => $multiple, instance_parent => $instance, indent_long_output => $indent_long_output);
            } elsif ($group->{type} == 0) {
                $self->run_global(config => $group, multiple_parent => $multiple, called_multiple => 1, force_instance => $instance, indent_long_output => $indent_long_output);
            }
        }
    }
}

sub read_statefile_key {
    my ($self, %options) = @_;

    $self->{statefile_value}->read(statefile => $self->{cache_name});
    return $self->{statefile_value}->get(name => $options{key});
}

sub run {
    my ($self, %options) = @_;
    
    $self->manage_selection(%options);
    
    $self->{new_datas} = undef;
    if (defined($self->{statefile_value})) {
        $self->{new_datas} = {};
        $self->{statefile_value}->read(statefile => $self->{cache_name}) if (defined($self->{cache_name}));
        $self->{new_datas}->{last_timestamp} = time();
    }

    foreach my $entry (@{$self->{maps_counters_type}}) {
        if ($entry->{type} == 0) {
            $self->run_global(config => $entry);
        } elsif ($entry->{type} == 1) {
            $self->run_instances(config => $entry);
        } elsif ($entry->{type} == 2) {
            $self->run_group(config => $entry);
        } elsif ($entry->{type} == 3) {
            $self->run_multiple(config => $entry);
        }
    }
        
    if (defined($self->{statefile_value})) {
        $self->{statefile_value}->write(data => $self->{new_datas});
    }
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    # example for snmp
    #use Digest::MD5 qw(md5_hex);
    #$self->{cache_name} = "choose_name_" . $options{snmp}->get_hostname()  . '_' . $options{snmp}->get_port() . '_' . $self->{mode} . '_' . 
    #    (defined($self->{option_results}->{filter_counters}) ? md5_hex($self->{option_results}->{filter_counters}) : md5_hex('all'));
}

sub compat_threshold_counter {
    my ($self, %options) = @_;

    foreach ('warning', 'critical') {
        foreach my $th (@{$options{compat}->{th}}) {
            next if (!defined($options{option_results}->{$_ . '-' . $th->[0]}) || $options{option_results}->{$_ . '-' . $th->[0]} eq '');

            my $src_threshold = $options{option_results}->{$_ . '-' . $th->[0]};
            if (defined($options{compat}->{units}) && $options{compat}->{units} eq '%') {
                $options{option_results}->{$_ . '-' . $th->[0]} = undef;
                if (defined($options{compat}->{free})) {
                    $options{option_results}->{$_ . '-' . $th->[0]} = undef;
                    my ($status, $result) = centreon::plugins::misc::parse_threshold(threshold => $src_threshold);
                    next if ($status == 0);

                    my $tmp = { arobase => $result->{arobase}, infinite_pos => 0, infinite_neg => 0, start => $result->{start}, end => $result->{end} };
                    $tmp->{infinite_neg} = 1 if ($result->{infinite_pos} == 1);
                    $tmp->{infinite_pos} = 1 if ($result->{infinite_neg} == 1);

                    if ($result->{start} ne '' && $result->{infinite_neg} == 0) {
                        $tmp->{end} = 100 - $result->{start};
                    }
                    if ($result->{end} ne '' && $result->{infinite_pos} == 0) {
                        $tmp->{start} = 100 - $result->{end};
                    }

                    $options{option_results}->{$_ . '-' . $th->[1]->{prct}} = centreon::plugins::misc::get_threshold_litteral(%$tmp);
                } else {
                    $options{option_results}->{$_ . '-' . $th->[1]->{prct}} = $src_threshold;
                }
            } elsif (defined($options{compat}->{free})) {
                $options{option_results}->{$_ . '-' . $th->[1]->{free}} = $options{option_results}->{$_ . '-' . $th->[0]};
                $options{option_results}->{$_ . '-' . $th->[0]} = undef;
            }
        }
    }
}

sub change_macros {
    my ($self, %options) = @_;

    foreach (@{$options{macros}}) {
        if (defined($self->{option_results}->{$_})) {
            $self->{option_results}->{$_} =~ s/%\{(.*?)\}/\$self->{result_values}->{$1}/g;
        }
    }
}
    
1;

__END__

=head1 MODE

Default template for counters. Should be extended.

=over 8

=item B<--filter-counters>

Only display some counters (regexp can be used).
Example to check SSL connections only : --filter-counters='^xxxx|yyyy$'

=item B<--warning-*>

Threshold warning.
Can be: 'xxx', 'xxx'.

=item B<--critical-*>

Threshold critical.
Can be: 'xxx', 'xxx'.

=back

=cut
