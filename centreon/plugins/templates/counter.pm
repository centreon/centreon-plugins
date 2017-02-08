#
# Copyright 2017 Centreon (http://www.centreon.com/)
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
    #               { label => 'Client', value => 'client_absolute', template => '%s', 
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
    $options{options}->add_options(arguments =>
                                {
                                "filter-counters:s" => { name => 'filter_counters' },
                                "list-counters"     => { name => 'list_counters' },
                                });
    $self->{statefile_value} = undef;
    if (defined($options{statefile}) && $options{statefile}) {
        centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'centreon::plugins::statefile',
                                               error_msg => "Cannot load module 'centreon::plugins::statefile'.");
        $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    }
    
    $self->{maps_counters} = {} if (!defined($self->{maps_counters}));
    $self->set_counters();
    
    foreach my $key (keys %{$self->{maps_counters}}) {
        foreach (@{$self->{maps_counters}->{$key}}) {
            if (!defined($_->{threshold}) || $_->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $_->{label} . ':s'    => { name => 'warning-' . $_->{label} },
                                                    'critical-' . $_->{label} . ':s'    => { name => 'critical-' . $_->{label} },
                                               });
            }
            $_->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                       output => $self->{output}, perfdata => $self->{perfdata},
                                                       label => $_->{label});
            $_->{obj}->set(%{$_->{set}});
        }
    }
                                
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    if (defined($self->{option_results}->{list_counters})) {
        my $list_counter = "Counter list:";
        foreach my $key (keys %{$self->{maps_counters}}) {
            foreach (@{$self->{maps_counters}->{$key}}) {
                $list_counter .= " " . $_->{label};
            }
        }
        $self->{output}->output_add(short_msg => $list_counter);
        $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
        $self->{output}->exit();
    }
    foreach my $key (keys %{$self->{maps_counters}}) {
        foreach (@{$self->{maps_counters}->{$key}}) {
            $_->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    if (defined($self->{statefile_value})) {
        $self->{statefile_value}->check_options(%options);
    }
}

sub run_global {
    my ($self, %options) = @_;
    
    return undef if (defined($options{config}->{cb_init}) && $self->call_object_callback(method_name => $options{config}->{cb_init}) == 1);
    
    my $message_separator = defined($options{config}->{message_separator}) ? 
        $options{config}->{message_separator}: ', ';
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (@{$self->{maps_counters}->{$options{config}->{name}}}) {
        my $obj = $_->{obj};

        next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
            $_->{label} !~ /$self->{option_results}->{filter_counters}/);
        
        $obj->set(instance => $options{config}->{name});
    
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
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = $message_separator;
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = $message_separator;
        }
        
        $obj->perfdata();
    }

    my ($prefix_output, $suffix_output);
    $prefix_output = $self->call_object_callback(method_name => $options{config}->{cb_prefix_output}) 
        if (defined($options{config}->{cb_prefix_output}));
    $prefix_output = '' if (!defined($prefix_output));
    
    $suffix_output = $self->call_object_callback(method_name => $options{config}->{cb_suffix_output}) 
        if (defined($options{config}->{cb_suffix_output}));
    $suffix_output = '' if (!defined($suffix_output));
    
    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "${prefix_output}${short_msg}${suffix_output}"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "${prefix_output}${long_msg}${suffix_output}") if ($long_msg ne '');
    }
}

sub run_instances {
    my ($self, %options) = @_;
    
    return undef if (defined($options{config}->{cb_init}) && $self->call_object_callback(method_name => $options{config}->{cb_init}) == 1);
    my $display_status_lo = defined($options{display_status_long_output}) && $options{display_status_long_output} == 1 ? 1 : 0;
    my $resume = defined($options{resume}) && $options{resume} == 1 ? 1 : 0;
    
    $self->{lproblems} = 0;
    $self->{multiple} = 1;
    if (scalar(keys %{$self->{$options{config}->{name}}}) == 1) {
        $self->{multiple} = 0;
    }
    
    if ($self->{multiple} == 1 && $resume == 0) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $options{config}->{message_multiple});
    }
    
    my $message_separator = defined($options{config}->{message_separator}) ? 
        $options{config}->{message_separator}: ', ';
    foreach my $id (sort keys %{$self->{$options{config}->{name}}}) {
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (@{$self->{maps_counters}->{$options{config}->{name}}}) {
            my $obj = $_->{obj};
            
            next if (defined($self->{option_results}->{filter_counters}) && $self->{option_results}->{filter_counters} ne '' &&
                $_->{label} !~ /$self->{option_results}->{filter_counters}/);
            
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(new_datas => $self->{new_datas},
                                              values => $self->{$options{config}->{name}}->{$id});
            next if (defined($options{config}->{skipped_code}) && defined($options{config}->{skipped_code}->{$value_check}));
            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = $message_separator;
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = $message_separator;
            
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
        $self->{output}->output_add(long_msg => ($display_status_lo == 1 ? lc($exit) . ': ' : '') . "${prefix_output}${long_msg}${suffix_output}");
        if ($resume == 1) {
            $self->{most_critical_instance} = $self->{output}->get_most_critical(status => [ $self->{most_critical_instance},  $exit ]);  
            next;
        }
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "${prefix_output}${short_msg}${suffix_output}"
                                        );
        }
        
        if ($self->{multiple} == 0) {
            $self->{output}->output_add(short_msg => "${prefix_output}${long_msg}${suffix_output}");
        }
    }
}

sub run_group {
    my ($self, %options) = @_;

    my $multiple = 1;
    if (scalar(keys %{$self->{$options{config}->{name}}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => $options{config}->{message_multiple});
    }
    
    my ($global_exit, $total_problems) = ([], 0);
    foreach my $id (sort keys %{$self->{$options{config}->{name}}}) {
        $self->{most_critical_instance} = 'ok';
        if (defined($options{config}->{cb_long_output})) {
            $self->{output}->output_add(long_msg => $self->call_object_callback(method_name => $options{config}->{cb_long_output},
                                                                                instance_value => $self->{$options{config}->{name}}->{$id}));
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
            
            if ($multiple == 0) {
                $self->{output}->output_add(severity => $self->{most_critical_instance},
                                            short_msg => "${prefix_output}$self->{lproblems} problem(s) detected");
            }
        }
    }
    
    if ($multiple == 1) {
        my $exit = $self->{output}->get_most_critical(status => [ @{$global_exit} ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "$total_problems problem(s) detected");
        }
    }
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