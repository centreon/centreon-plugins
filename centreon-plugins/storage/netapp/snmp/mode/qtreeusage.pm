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

package storage::netapp::snmp::mode::qtreeusage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    '000_usage' => { set => {
                        key_values => [ { name => 'name' }, { name => 'used' }, { name => 'total' } ],
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
    
    my $label = 'used';
    my $value_perf = $self->{result_values}->{used};
    if ($self->{result_values}->{total} > 0 && defined($instance_mode->{option_results}->{free})) {
        $label = 'free';
        $value_perf = $self->{result_values}->{free};
    }
    my $extra_label = '';
    $extra_label = '_' . $self->{result_values}->{name} if (!defined($options{extra_instance}) || $options{extra_instance} != 0);
    my %total_options = ();
    if ($self->{result_values}->{total} > 0 && $instance_mode->{option_results}->{units} eq '%') {
        $total_options{total} = $self->{result_values}->{total};
        $total_options{cast_int} = 1;
    }

    $self->{output}->perfdata_add(label => $label . $extra_label, unit => 'B',
                                  value => $value_perf,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, %total_options),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, %total_options),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    # cannot use '%' or free option with unlimited system 
    return 'ok' if ($self->{result_values}->{total} <= 0 && ($instance_mode->{option_results}->{units} eq '%' || $instance_mode->{option_results}->{free}));
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

    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});    
    my $msg;
    if ($self->{result_values}->{total} <= 0) {
        $msg = sprintf("Used: %s (unlimited)", $total_used_value . " " . $total_used_unit);
    } else {
        my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
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
    
    return 0 if ($self->{result_values}->{total} == 0);
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_free} = 100 - $self->{result_values}->{prct_used};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    # qtree can be over 100%
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
                                  "filter-vserver:s"      => { name => 'filter_vserver' },
                                  "filter-volume:s"       => { name => 'filter_volume' },
                                  "filter-qtree:s"        => { name => 'filter_qtree' },
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
    $self->{snmp} = $options{snmp};

    $self->manage_selection();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{qtree_selected}}) == 1) {
        $multiple = 0;
    }
    
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All qtree usages are ok');
    }
    
    foreach my $id (sort keys %{$self->{qtree_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits;
        foreach (sort keys %{$maps_counters}) {
            $maps_counters->{$_}->{obj}->set(instance => $id);
        
            my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{qtree_selected}->{$id});

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

        $self->{output}->output_add(long_msg => "Qtree '" . $self->{qtree_selected}->{$id}->{name} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Qtree '" . $self->{qtree_selected}->{$id}->{name} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Qtree '" . $self->{qtree_selected}->{$id}->{name} . "' $long_msg");
        }
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    qrV2Tree            => { oid => '.1.3.6.1.4.1.789.1.4.6.1.14' },
    qrV264KBytesUsed    => { oid => '.1.3.6.1.4.1.789.1.4.6.1.25' },
    qrV264KBytesLimit   => { oid => '.1.3.6.1.4.1.789.1.4.6.1.26' },
    qrV2VolumeName      => { oid => '.1.3.6.1.4.1.789.1.4.6.1.29' },
    qrV2Vserver         => { oid => '.1.3.6.1.4.1.789.1.4.6.1.30' },
};

sub manage_selection {
    my ($self, %options) = @_;

    if ($self->{snmp}->is_snmpv1()) {
        $self->{output}->add_option_msg(short_msg => "Need to use SNMP v2c or v3.");
        $self->{output}->option_exit();
    }
    my $results = $self->{snmp}->get_multiple_table(oids => [
                                                       { oid => $mapping->{qrV2Tree}->{oid} },
                                                       { oid => $mapping->{qrV264KBytesUsed}->{oid} },
                                                       { oid => $mapping->{qrV264KBytesLimit}->{oid} },
                                                       { oid => $mapping->{qrV2VolumeName}->{oid} },
                                                       { oid => $mapping->{qrV2Vserver}->{oid} },
                                                    ], return_type => 1, nothing_quit => 1);
    $self->{qtree_selected} = {};
    foreach my $oid (keys %{$results}) {
        next if ($oid !~ /^$mapping->{qrV2Tree}->{oid}\.(.*)/);
        my $instance = $1;
        my $result = $self->{snmp}->map_instance(mapping => $mapping, results => $results, instance => $instance);
        
        if (defined($self->{option_results}->{filter_vserver}) && $self->{option_results}->{filter_vserver} ne '' &&
            $result->{qrV2Vserver} !~ /$self->{option_results}->{filter_vserver}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{qrV2Vserver} . "': no matching vserver name.");
            next;
        }
        if (defined($self->{option_results}->{filter_volume}) && $self->{option_results}->{filter_volume} ne '' &&
            $result->{qrV2VolumeName} !~ /$self->{option_results}->{filter_volume}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{qrV2VolumeName} . "': no matching volume name.");
            next;
        }
        if (defined($self->{option_results}->{filter_qtree}) && $self->{option_results}->{filter_qtree} ne '' &&
            $result->{qrV2Tree} !~ /$self->{option_results}->{filter_qtree}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $result->{qrV2Tree} . "': no matching qtree name.");
            next;
        }
        
        my $name = '';
        $name = $result->{qrV2Vserver} . '/' if (defined($result->{qrV2Vserver}) && $result->{qrV2Vserver} ne ''); 
        $name .= $result->{qrV2VolumeName} . '/' . $result->{qrV2Tree};
        
        $self->{qtree_selected}->{$instance} = { name => $name, used => $result->{qrV264KBytesUsed} * 1024, total => $result->{qrV264KBytesLimit} * 1024 }; 
    }
    
    if (scalar(keys %{$self->{qtree_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No entry found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check qtree quote usage.

=over 8

=item B<--warning-usage>

Threshold warning.

=item B<--critical-usage>

Threshold critical.

=item B<--units>

Units of thresholds (Default: '%') ('%', 'B').

=item B<--free>

Thresholds are on free space left.

=item B<--filter-vserver>

Filter by vserver name (can be a regexp).

=item B<--filter-volume>

Filter by volume name (can be a regexp).

=item B<--filter-qtree>

Filter by qtree name (can be a regexp).

=back

=cut
