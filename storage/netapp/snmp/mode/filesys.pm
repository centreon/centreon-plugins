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

package storage::netapp::snmp::mode::filesys;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    '000_usage' => { set => {
                        key_values => [ { name => 'name' }, { name => 'used' }, { name => 'total' }, 
                                        { name => 'dfCompressSavedPercent' }, { name => 'dfDedupeSavedPercent' } ],
                        closure_custom_calc => \&custom_usage_calc,
                        closure_custom_output => \&custom_usage_output,
                        closure_custom_perfdata => \&custom_usage_perfdata,
                        closure_custom_threshold_check => \&custom_usage_threshold,
                    }
               },
};

my $instance_mode;

sub custom_usage_perfdata {
    my ($self, %options) = @_;
    
    return if ($self->{result_values}->{total} <= 0);
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if (defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{name} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
    if (defined($self->{result_values}->{dfCompressSavedPercent}) && $self->{result_values}->{dfCompressSavedPercent} ne '' &&
        $self->{result_values}->{dfCompressSavedPercent} >= 0) {
        $self->{output}->perfdata_add(label => 'compresssaved' . $extra_label, unit => '%',
                                      value => $self->{result_values}->{dfCompressSavedPercent},
                                      min => 0, max => 100);
    }
    if (defined($self->{result_values}->{dfDedupeSavedPercent}) && $self->{result_values}->{dfDedupeSavedPercent} ne '' &&
        $self->{result_values}->{dfDedupeSavedPercent} >= 0) {
        $self->{output}->perfdata_add(label => 'dedupsaved' . $extra_label, unit => '%',
                                      value => $self->{result_values}->{dfDedupeSavedPercent},
                                      min => 0, max => 100);
    }
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    return 'ok' if ($self->{result_values}->{total} <= 0);
    my ($exit, $threshold_value);
    $threshold_value = $self->{result_values}->{used};
    $threshold_value = $self->{result_values}->{free} if (defined($instance_mode->{option_results}->{free}));
    if ($instance_mode->{option_results}->{units} eq '%') {
        $threshold_value = $self->{result_values}->{prct_used};
        $threshold_value = $self->{result_values}->{prct_free} if (defined($instance_mode->{option_results}->{free}));
    }
    $exit = $self->{perfdata}->threshold_check(value => $threshold_value, threshold => [ { label => 'critical-' . $self->{label}, exit_litteral => 'critical' }, { label => 'warning-'. $self->{label}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my $msg;
    if ($self->{result_values}->{total} == 0) {
        $msg = 'skipping: total size is 0';
    } elsif ($self->{result_values}->{total} < 0) {
        $msg = 'skipping: negative total value (maybe use snmp v2c)';
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

    $self->{result_values}->{name} = $options{new_datas}->{$self->{instance} . '_name'};    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{dfCompressSavedPercent} = $options{new_datas}->{$self->{instance} . '_dfCompressSavedPercent'};
    $self->{result_values}->{dfDedupeSavedPercent} = $options{new_datas}->{$self->{instance} . '_dfDedupeSavedPercent'};

    return 0 if ($options{new_datas}->{$self->{instance} . '_total'} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};

    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    # snapshot can be over 100%
    if ($self->{result_values}->{free} < 0) {
        $self->{result_values}->{free} = 0;
        $self->{result_values}->{prct_free} = 0;
    }
    
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "units:s"               => { name => 'units', default => '%' },
                                  "free"                  => { name => 'free' },
                                  "filter-name:s"         => { name => 'filter_name' },
                                  "filter-type:s"         => { name => 'filter_type' },
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
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }
    
    $instance_mode = $self;
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{filesys_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All filesys usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{filesys_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{filesys_selected}->{$id});

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

        $self->{output}->output_add(long_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Filesys '" . $self->{filesys_selected}->{$id}->{name} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

my %map_types = (
    1 => 'traditionalVolume',
    2 => 'flexibleVolume',
    3 => 'aggregate',
    4 => 'stripedAggregate',
    5 => 'stripedVolume'
);
my $mapping = {
    dfType      => { oid => '.1.3.6.1.4.1.789.1.5.4.1.23', map => \%map_types },
};
my $mapping2 = {
    dfKBytesTotal   => { oid => '.1.3.6.1.4.1.789.1.5.4.1.3' },
    dfKBytesUsed    => { oid => '.1.3.6.1.4.1.789.1.5.4.1.4' },
    df64TotalKBytes => { oid => '.1.3.6.1.4.1.789.1.5.4.1.29' },
    df64UsedKBytes  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.30' },
    dfCompressSavedPercent  => { oid => '.1.3.6.1.4.1.789.1.5.4.1.38' },
    dfDedupeSavedPercent    => { oid => '.1.3.6.1.4.1.789.1.5.4.1.40' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_dfFileSys = '.1.3.6.1.4.1.789.1.5.4.1.2';
    
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                       { oid => $oid_dfFileSys },
                                                       { oid => $mapping->{dfType}->{oid} },
                                                    ], nothing_quit => 1);
    $self->{filesys_selected} = {};
    foreach my $oid (keys %{$results->{$oid_dfFileSys}}) {
        $oid =~ /^$oid_dfFileSys\.(\d+)/;
        my $instance = $1;
        my $name = $results->{$oid_dfFileSys}->{$oid};
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results->{$mapping->{dfType}->{oid}}, instance => $instance);
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $name . "': no matching filter name.");
            next;
        }
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $result->{dfType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{dfType} . "': no matching filter type.");
            next;
        }
    
        $self->{filesys_selected}->{$instance} = { name => $name }; 
    }
    
    if (scalar(keys %{$self->{filesys_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
    
    my $instances = [keys %{$self->{filesys_selected}}];
    if (!$self->{snmp}->is_snmpv1()) {
        $self->{snmp}->load(oids => [$mapping2->{df64TotalKBytes}->{oid}, $mapping2->{df64UsedKBytes}->{oid}], instances => $instances);
    }
    $self->{snmp}->load(oids => [$mapping2->{dfKBytesTotal}->{oid}, $mapping2->{dfKBytesUsed}->{oid}, 
                                 $mapping2->{dfDedupeSavedPercent}->{oid}, $mapping2->{dfCompressSavedPercent}->{oid}], instances => $instances);
    my $result = $self->{snmp}->get_leef();
    foreach (@$instances) {
        my $result = $self->{snmp}->map_instance(mapping => $mapping2, results => $result, instance => $_);
        $self->{filesys_selected}->{$_}->{total} = $result->{dfKBytesTotal} * 1024;
        $self->{filesys_selected}->{$_}->{used} = $result->{dfKBytesUsed} * 1024;
        if (defined($result->{df64TotalKBytes}) && $result->{df64TotalKBytes} > 0) {
            $self->{filesys_selected}->{$_}->{total} = $result->{df64TotalKBytes} * 1024;
            $self->{filesys_selected}->{$_}->{used} = $result->{df64UsedKBytes} * 1024;
        }
        $self->{filesys_selected}->{$_}->{dfCompressSavedPercent} = $result->{dfCompressSavedPercent};
        $self->{filesys_selected}->{$_}->{dfDedupeSavedPercent} = $result->{dfDedupeSavedPercent};
    }
}

1;

__END__

=head1 MODE

Check filesystem usage (volumes, snapshots and aggregates also).

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-name>

Filter by filesystem name (can be a regexp).

=item B<--filter-type>

Filter filesystem type (can be a regexp. Example: 'flexibleVolume|aggregate').

=back

=cut
