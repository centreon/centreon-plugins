################################################################################
# Copyright 2005-2014 MERETHIS
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

package network::h3c::snmp::mode::memory;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;

my $oid_entPhysicalEntry = '.1.3.6.1.2.1.47.1.1.1.1';
my $oid_entPhysicalDescr = '.1.3.6.1.2.1.47.1.1.1.1.2';
my $oid_entPhysicalContainedIn = '.1.3.6.1.2.1.47.1.1.1.1.4';
my $oid_entPhysicalClass = '.1.3.6.1.2.1.47.1.1.1.1.5';
my $oid_entPhysicalName = '.1.3.6.1.2.1.47.1.1.1.1.7';

my $maps_counters = {
    '000_usage' => { set => {
                        key_values => [
                                        { name => 'display' }, { name => 'used_prct' }, { name => 'total' },
                                      ],
                        closure_custom_calc => \&custom_usage_calc,
                        closure_custom_output => \&custom_usage_output,
                        closure_custom_perfdata => \&custom_usage_perfdata,
                        closure_custom_threshold_check => \&custom_usage_threshold,
                    }
               },
};

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    my $extra_label = '';
    if (!defined($options{extra_instance}) || $options{extra_instance} != 0) {
        $extra_label .= '_' . $self->{result_values}->{display};
    }
    
    if ($self->{result_values}->{total} == 4294967295) {
        $self->{output}->perfdata_add(label => 'used' . $extra_label, unit => 'B',
                                      value => $self->{result_values}->{used},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                      min => 0, max => $self->{result_values}->{total});
    } else {
        $self->{output}->perfdata_add(label => 'used' . $extra_label, unit => '%',
                                      value => $self->{result_values}->{prtc_used},
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}),
                                      min => 0, max => 100);
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{total} == 4294967295) {
        $msg = sprintf("Used: %.2f%% Free: %.2f%%",
                      $self->{result_values}->{prct_used},
                      $self->{result_values}->{prct_free});
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
        my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
        my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
        $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    }
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_total'} * $options{new_datas}->{$self->{instance} . '_used_prct'} / 100;
    $self->{result_values}->{free} = $options{new_datas}->{$self->{instance} . '_total'} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $options{new_datas}->{$self->{instance} . '_used_prct'};
    $self->{result_values}->{prct_used} = $options{new_datas}->{$self->{instance} . '_used_prct'};
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "reload-cache-time:s"     => { name => 'reload_cache_time', default => 180 },
                                  "display-entity-name"     => { name => 'display_entity_name' },
                                });                         
     
    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        $maps_counters->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }

    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{memory_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All memory usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{memory_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{memory_selected}->{$id});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
            push @exits, $exit2;

            my $output = $maps_counters->{$_}->{obj}->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Memory '" . $self->{memory_selected}->{$id}->{display} . "' $long_msg [entity = '" . $self->{cpu}->{$id}->{name} . "']");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Memory '" . $self->{memory_selected}->{$id}->{display} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Memory '" . $self->{memory_selected}->{$id}->{display} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}


sub check_cache {
    my ($self, %options) = @_;

    $self->{hostname} = $self->{snmp}->get_hostname();
    $self->{snmp_port} = $self->{snmp}->get_port();
    
    # init cache file
    $self->{write_cache} = 0;
    my $has_cache_file = $self->{statefile_cache}->read(statefile => 'cache_h3c_entity_' . $self->{hostname}  . '_' . $self->{snmp_port});
    my $timestamp_cache = $self->{statefile_cache}->get(name => 'last_timestamp');
    if ($has_cache_file == 0 ||
        !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{option_results}->{reload_cache_time}) * 60))) {
        push @{$self->{snmp_request}}, { oid => $oid_entPhysicalEntry, start => $oid_entPhysicalDescr, end => $oid_entPhysicalName };
        $self->{write_cache} = 1;
    }
}

sub write_cache {
    my ($self, %options) = @_;
    
    if ($self->{write_cache} == 1) {
        my $datas = {};
        $datas->{last_timestamp} = time();
        $datas->{oids} = $self->{results}->{$oid_entPhysicalEntry};
        $self->{statefile_cache}->write(data => $datas);
    } else {
        $self->{results}->{$oid_entPhysicalEntry} = $self->{statefile_cache}->get(name => 'oids');
    }
}

sub get_long_name {
    my ($self, %options) = @_;
    
    my @names = ($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $options{instance}});
    my %loop = ($options{instance} => 1);
    my $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $options{instance}};
    while (1) {
        last if (!defined($child) || defined($loop{$child}) || !defined($self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child}));
        
        unshift @names, $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalDescr . '.' . $child};
        $loop{$child} = 1;
        $child = $self->{results}->{$oid_entPhysicalEntry}->{$oid_entPhysicalContainedIn . '.' . $child};
    }
    
    return join(' > ', @names);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_h3cEntityExtStateEntry = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1';
    my $oid_hh3cEntityExtStateEntry = '.1.3.6.1.4.1.25506.2.6.1.1.1.1';
    my $oid_hh3cEntityExtMemUsage = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.8';
    my $oid_hh3cEntityExtMemSize = '.1.3.6.1.4.1.25506.2.6.1.1.1.1.10';
    my $oid_h3cEntityExtMemUsage = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.8';
    my $oid_h3cEntityExtMemSize = '.1.3.6.1.4.1.2011.10.2.6.1.1.1.1.10';

    $self->{snmp_request} = [ 
        { oid => $oid_hh3cEntityExtMemUsage },
        { oid => $oid_hh3cEntityExtMemSize },
        { oid => $oid_h3cEntityExtMemUsage },
        { oid => $oid_h3cEntityExtMemSize },
    ];
    $self->check_cache() if (defined($self->{option_results}->{display_entity_name}));

    $self->{results} = $self->{snmp}->get_multiple_table(oids => $self->{snmp_request},
                                                         nothing_quit => 1);
    $self->write_cache() if (defined($self->{option_results}->{display_entity_name}));
    $self->{branch} = $oid_hh3cEntityExtStateEntry;
    if (defined($self->{results}->{$oid_h3cEntityExtMemUsage}) && scalar(keys %{$self->{results}->{$oid_h3cEntityExtMemUsage}}) > 0) {
        $self->{branch} = $oid_h3cEntityExtStateEntry;
    }
    
    my $mapping = {
        EntityExtMemUsage => { oid => $self->{branch} . '.8' },
    };
    my $mapping2 = {
        EntityExtMemSize => { oid => $self->{branch} . '.10' },
    };
    
    $self->{memory_selected} = {};
    foreach my $oid (keys %{$self->{results}->{$self->{branch} . '.8'}}) {
        next if ($oid !~ /^$self->{branch}\.8\.(\d+)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}->{$self->{branch} . '.8'}, instance => $instance);
        my $result2 = $self->{snmp}->map_instance(mapping => $mapping2, results => $self->{results}->{$self->{branch} . '.10'}, instance => $instance);        
        
        if (defined($result2->{EntityExtMemSize}) && $result2->{EntityExtMemSize} > 0) {
            my $name = '-';
            
            if (defined($self->{option_results}->{display_entity_name})) {
                $name = $self->get_long_name(instance => $instance);
            }
            $self->{memory_selected}->{$instance} = { display => $instance, name => $name, 
                                                      used_prct => $result->{EntityExtMemUsage}, total => $result2->{EntityExtMemSize}};
        }
    }
    
    if (scalar(keys %{$self->{memory_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check memory usages.

=over 8

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).

=item B<--display-entity-name>

Display entity name of the component. A cache file will be used.

=back

=cut
