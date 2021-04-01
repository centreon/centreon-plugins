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

package centreon::plugins::templates::hardware;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    #$self->{regexp_threshold_numeric_check_section_option} = '';
    #$self->{cb_threshold_numeric_check_section_option} = 'callbackname';

    # Some callbacks 
    #$self->{cb_hook1} = 'callbackname'; # before the loads
    #$self->{cb_hook2} = 'callbackname'; # between loads and requests
    #$self->{cb_hook3} = 'callbackname'; # after requests
    #$self->{cb_hook4} = 'callbackname'; # after output

    # Example for threshold:
    #$self->{thresholds} = {
    #    fan => [
    #        ['bad', 'CRITICAL'],
    #        ['good', 'OK'],
    #        ['notPresent', 'OK'],
    #    ],
    #};
    
    # Unset the call to load components
    #$self->{components_exec_load} = 0;

    # Set the path_info
    #$self->{components_path} = 'network::xxxx::mode::components';

    # Set the components
    #$self->{components_module} = ['cpu', 'memory', ...];
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

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments => {
        'component:s'            => { name => 'component', default => '.*' },
        'no-component:s'         => { name => 'no_component' },
        'threshold-overload:s@'  => { name => 'threshold_overload' },
        'add-name-instance'      => { name => 'add_name_instance' },
        'no-component-count'     => { name => 'no_component_count' }
    });

    $self->{performance} = (defined($options{no_performance}) && $options{no_performance} == 1) ?
        0 : 1;
    if ($self->{performance} == 1) {
        $options{options}->add_options(arguments => {
            'warning:s@'  => { name => 'warning' },
            'critical:s@' => { name => 'critical' }
        });
    }

    $self->{filter_exclude} = (defined($options{no_filter_exclude}) && $options{no_filter_exclude} == 1) ?
        0 : 1;
    if ($self->{filter_exclude} == 1) {
        $options{options}->add_options(arguments => {
            'exclude:s'     => { name => 'exclude' },
            'filter:s@'     => { name => 'filter' }
        });
    }
    $self->{absent} = (defined($options{no_absent}) && $options{no_absent} == 1) ?
        0 : 1;
    if ($self->{absent} == 1) {
        $options{options}->add_options(arguments => {
            'absent-problem:s@' => { name => 'absent_problem' }
        });
    }

    $self->{load_components} = (defined($options{no_load_components}) && $options{no_load_components} == 1) ?
        0 : 1;
    $self->{components} = {};
    $self->{no_components} = undef;

    $self->{components_module} = [];
    $self->{components_exec_load} = 1;
    $self->set_system();

    $self->{count} = (defined($options{no_count}) && $options{no_count} == 1) ? 0 : 1;
    if ($self->{count} == 1) {
        foreach my $component (@{$self->{components_module}}) {
            $options{options}->add_options(arguments => {
                'unknown-count-' . $component . ':s'  => { name => 'unknown_count_' . $component },
                'warning-count-' . $component . ':s'  => { name => 'warning_count_' . $component },
                'critical-count-' . $component . ':s' => { name => 'critical_count_' . $component }
            });
        }
    }

    $self->{request} = [];

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (defined($self->{option_results}->{no_component})) {
        if ($self->{option_results}->{no_component} ne '') {
            $self->{no_components} = $self->{option_results}->{no_component};
        } else {
            $self->{no_components} = 'critical';
        }
    }

    if ($self->{filter_exclude} == 1) {
        $self->{filter} = [];
        foreach my $val (@{$self->{option_results}->{filter}}) {
            next if (!defined($val) || $val eq '');
            my @values = split (/,/, $val);
            push @{$self->{filter}}, { filter => $values[0], instance => $values[1] }; 
        }
    }

    if ($self->{absent} == 1) {
        $self->{absent_problem} = [];
        foreach my $val (@{$self->{option_results}->{absent_problem}}) {
            next if (!defined($val) || $val eq '');
            my @values = split (/,/, $val);
            push @{$self->{absent_problem}}, { filter => $values[0], instance => $values[1] }; 
        }
    }

    $self->{overload_th} = [];
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        next if (!defined($val) || $val eq '');
        my @values = split (/,/, $val);
        if (scalar(@values) < 3) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $instance, $status, $filter);
        if (scalar(@values) == 3) {
            ($section, $status, $filter) = @values;
            $instance = '.*';
        } else {
             ($section, $instance, $status, $filter) = @values;
        }

        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        push @{$self->{overload_th}}, { section => $section, filter => $filter, status => $status, instance => $instance };
    }

    if ($self->{performance} == 1) {
        $self->{numeric_threshold} = {};
        foreach my $option (('warning', 'critical')) {
            foreach my $val (@{$self->{option_results}->{$option}}) {
                next if (!defined($val) || $val eq '');
                if ($val !~ /^(.*?),(.*?),(.*)$/) {
                    $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                    $self->{output}->option_exit();
                }
                my ($section, $instance, $value) = ($1, $2, $3);                
                if (defined($self->{regexp_threshold_numeric_check_section_option}) && 
                    $section !~ /$self->{regexp_threshold_numeric_check_section_option}/) {
                    $self->{output}->add_option_msg(short_msg => "Wrong $option option '" . $val . "'.");
                    $self->{output}->option_exit();
                }   
                $self->call_object_callback(
                    method_name => $self->{cb_threshold_numeric_check_section_option}, 
                    section => $section,
                    option_name => $option,
                    option_value => $val
                );

                my $position = 0;
                if (defined($self->{numeric_threshold}->{$section})) {
                    $position = scalar(@{$self->{numeric_threshold}->{$section}});
                }
                if (($self->{perfdata}->threshold_validate(label => $option . '-' . $section . '-' . $position, value => $value)) == 0) {
                    $self->{output}->add_option_msg(short_msg => "Wrong $option threshold '" . $value . "'.");
                    $self->{output}->option_exit();
                }
                $self->{numeric_threshold}->{$section} = [] if (!defined($self->{numeric_threshold}->{$section}));
                push @{$self->{numeric_threshold}->{$section}}, { label => $option . '-' . $section . '-' . $position, threshold => $option, instance => $instance };
            }
        }
    }

    if ($self->{count} == 1) {
        foreach my $comp (@{$self->{components_module}}) {
            foreach my $threshold (('warning', 'critical', 'unknown')) {
                if (($self->{perfdata}->threshold_validate(label => $threshold . '-count-' . $comp, value => $self->{option_results}->{$threshold . '_count_' . $comp})) == 0) {
                    $self->{output}->add_option_msg(short_msg => "Wrong " . $threshold . " threshold '" . $self->{option_results}->{$threshold . '_count_' . $comp} . "'.");
                    $self->{output}->option_exit();
                }
            }
        }
    }
}

sub load_components {
    my ($self, %options) = @_;

    foreach (@{$self->{components_module}}) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::$_";
            centreon::plugins::misc::mymodule_load(
                output => $self->{output}, module => $mod_name,
                error_msg => "Cannot load module '$mod_name'.") if ($self->{load_components} == 1);
            $self->{loaded} = 1;
            if ($self->{components_exec_load} == 1) {
                my $func = $mod_name->can('load');
                $func->($self);
            }
        }
    }
}

sub exec_components {
    my ($self, %options) = @_;

    foreach (@{$self->{components_module}}) {
        if (/$self->{option_results}->{component}/) {
            my $mod_name = $self->{components_path} . "::$_";
            my $func = $mod_name->can('check');
            $func->($self); 
        }
    }
}

sub display {
    my ($self, %options) = @_;

    my $total_components = 0;
    my $display_by_component = '';
    my $display_by_component_append = '';
    my $exit = 'OK';
    my $exits = [];
    my ($warn, $crit);

    foreach my $comp (sort(keys %{$self->{components}})) {
        # Skipping short msg when no components
        next if (!defined($self->{option_results}->{no_component_count}) && $self->{components}->{$comp}->{total} == 0 && $self->{components}->{$comp}->{skip} == 0);

        if ($self->{count} == 1) {
            ($exit, $warn, $crit) = $self->get_severity_count(label => $comp, value => $self->{components}->{$comp}->{total});
            if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
                $self->{output}->output_add(
                    severity => $exit,
                    short_msg => sprintf(
                        "'%s' components '%s' checked",
                        $self->{components}->{$comp}->{total},
                        $comp
                    )
                );
            }
            $self->{output}->perfdata_add(
                label => 'count_' . $comp,
                nlabel => 'hardware.' . $comp . '.count',
                value => $self->{components}->{$comp}->{total},
                warning => $warn,
                critical => $crit
            );
            push @{$exits}, $exit;
        }

        $total_components += $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip};
        my $count_by_components = $self->{components}->{$comp}->{total} + $self->{components}->{$comp}->{skip}; 
        $display_by_component .= $display_by_component_append . $self->{components}->{$comp}->{total} . '/' . $count_by_components . ' ' . $self->{components}->{$comp}->{name};
        $display_by_component_append = ', ';
    }

    $exit = $self->{output}->get_most_critical(status => $exits) if (scalar(@{$exits}) > 0);

    if ($self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            short_msg => sprintf(
                'All %s components are ok [%s].', 
                $total_components,
                $display_by_component
            )
        );
    }

    if (defined($self->{option_results}->{no_component}) && $total_components == 0) {
        $self->{output}->output_add(
            severity => $self->{no_components},
            short_msg => 'No components are checked.'
        );
    }
}

sub run {
    my ($self, %options) = @_;

    $self->{loaded} = 0;  
    $self->call_object_callback(method_name => $self->{cb_hook1}, %options);

    $self->load_components(%options);
    if ($self->{loaded} == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong option. Cannot find component '" . $self->{option_results}->{component} . "'.");
        $self->{output}->option_exit();
    }

    $self->call_object_callback(method_name => $self->{cb_hook2}, %options);
    $self->exec_components(%options);
    $self->call_object_callback(method_name => $self->{cb_hook3}, %options);

    $self->display();

    $self->call_object_callback(method_name => $self->{cb_hook4}, %options);

    $self->{output}->display();
    $self->{output}->exit();
}

sub check_filter {
    my ($self, %options) = @_;

    # Old compatibility variable. We'll be deleted
    if (defined($self->{option_results}->{exclude})) {
        if (defined($options{instance})) {
            if ($self->{option_results}->{exclude} =~ /(^|\s|,)${options{section}}[^,]*#\Q$options{instance}\E#/) {
                $self->{components}->{$options{section}}->{skip}++;
                $self->{output}->output_add(long_msg => sprintf("skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        } elsif (defined($self->{option_results}->{exclude}) && $self->{option_results}->{exclude} =~ /(^|\s|,)$options{section}(\s|,|$)/) {
            $self->{output}->output_add(long_msg => sprintf("skipping $options{section} section."));
            return 1;
        }
    }

    $options{instance} .= '#' . $options{name} if (defined($self->{option_results}->{add_name_instance}) && defined($options{name}));   
    foreach (@{$self->{filter}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($options{instance}) && !defined($_->{instance})) {
                $self->{output}->output_add(long_msg => sprintf("skipping $options{section} section."));
                return 1;
            } elsif (defined($options{instance}) && $options{instance} =~ /$_->{instance}/) {
                $self->{output}->output_add(long_msg => sprintf("skipping $options{section} section $options{instance} instance."));
                return 1;
            }
        }
    }

    return 0;
}

sub absent_problem {
    my ($self, %options) = @_;

    $options{instance} .= '#' . $options{name} if (defined($self->{option_results}->{add_name_instance}) && defined($options{name}));
    foreach (@{$self->{absent_problem}}) {
        if ($options{section} =~ /$_->{filter}/) {
            if (!defined($_->{instance}) || $options{instance} =~ /$_->{instance}/) {
                $self->{output}->output_add(
                    severity => 'CRITICAL',
                    short_msg => sprintf(
                        "Component '%s' instance '%s' is not present", 
                        $options{section},
                        $options{instance}
                    )
                );
                $self->{output}->output_add(long_msg => sprintf("Skipping $options{section} section $options{instance} instance (not present)"));
                $self->{components}->{$options{section}}->{skip}++;
                return 1;
            }
        }
    }

    return 0;
}

sub get_severity_count {
    my ($self, %options) = @_;
    my $status = 'OK'; # default
    my $thresholds = { warning => undef, critical => undef };

    $status = $self->{perfdata}->threshold_check(
        value => $options{value},
        threshold => [
            { label => 'critical-count-' . $options{label}, exit_litteral => 'critical' }, 
            { label => 'warning-count-' . $options{label}, exit_litteral => 'warning' },
            { label => 'unknown-count-' . $options{label}, exit_litteral => 'unknown' },
        ]
    );
    $thresholds->{critical} = $self->{perfdata}->get_perfdata_for_output(label => 'critical-count-' . $options{label});
    $thresholds->{warning} = $self->{perfdata}->get_perfdata_for_output(label => 'warning-count-' . $options{label});

    return ($status, $thresholds->{warning}, $thresholds->{critical});
}

sub get_severity_numeric {
    my ($self, %options) = @_;
    my $status = 'OK'; # default
    my $thresholds = { warning => undef, critical => undef };
    my $checked = 0;

    $options{instance} .= '#' . $options{name} if (defined($self->{option_results}->{add_name_instance}) && defined($options{name}));
    if (defined($self->{numeric_threshold}->{$options{section}})) {
        my $exits = [];
        foreach (@{$self->{numeric_threshold}->{$options{section}}}) {
            if ($options{instance} =~ /$_->{instance}/) {
                push @{$exits}, $self->{perfdata}->threshold_check(value => $options{value}, threshold => [ { label => $_->{label}, exit_litteral => $_->{threshold} } ]);
                $thresholds->{$_->{threshold}} = $self->{perfdata}->get_perfdata_for_output(label => $_->{label});
                $checked = 1;
            }
        }
        $status = $self->{output}->get_most_critical(status => $exits) if (scalar(@{$exits}) > 0);
    }

    return ($status, $thresholds->{warning}, $thresholds->{critical}, $checked);
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 

     foreach (@{$self->{overload_th}}) {
        if ($options{section} =~ /$_->{section}/i) {
            if ($options{value} =~ /$_->{filter}/i &&
                (!defined($options{instance}) || $options{instance} =~ /$_->{instance}/)) {
                $status = $_->{status};
                return $status;
            }
        }
    }

    my $label = defined($options{label}) ? $options{label} : $options{section};
    foreach (@{$self->{thresholds}->{$label}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}
    
1;

__END__

=head1 MODE

Default template for hardware. Should be extended.

=over 8

=item B<--component>

Which component to check (Default: '.*').
Can be: 'xxx', 'yyy'.

=item B<--filter>

Exclude some parts (comma seperated list) (Example: --filter=xxx --filter=yyyy)
Can also exclude specific instance: --filter=xxxxx,instancevalue

=item B<--absent-problem>

Return an error if an entity is not 'present' (default is skipping) (comma seperated list)
Can be specific or global: --absent-problem=xxxx,instancevalue

=item B<--no-component>

Return an error if no compenents are checked.
If total (with skipped) is 0. (Default: 'critical' returns).

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,[instance,]status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='xxxxx,CRITICAL,^(?!(normal)$)'

=item B<--warning>

Set warning threshold for temperatures (syntax: type,instance,threshold)
Example: --warning='xxxxx,.*,30'

=item B<--critical>

Set critical threshold for temperatures (syntax: type,instance,threshold)
Example: --critical='xxxxx,.*,40'

=item B<--warning-count-xxxx>

Set warning threshold for component count.

=item B<--critical-count-xxxx>

Set critical threshold for component count.

=back

=cut
