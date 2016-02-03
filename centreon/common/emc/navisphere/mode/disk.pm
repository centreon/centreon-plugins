#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package centreon::common::emc::navisphere::mode::disk;

sub get_absolute {
    my ($self, %options) = @_;
    my $name = $options{instance} . '_' . $options{label};
    my $value;
    
    $self->{new_datas}->{$name} = $1;

    $self->{old_datas}->{$name} = $self->{statefile_value}->get(name => $name);
    return undef if (!defined($self->{old_datas}->{$name}));
    
    # Reward... put to 0
    if ($self->{old_datas}->{$name} > $self->{new_datas}->{$name}) {
        $self->{old_datas}->{$name} = 0;
    }
    
    $value = ($self->{new_datas}->{$name} - $self->{old_datas}->{$name});
    
    return ($value, $value);
}

sub get_bytes_per_seconds {
    my ($self, %options) = @_;
    my $name = $options{instance} . '_' . $options{label};
    my $value;
    
    $self->{new_datas}->{$name} = $1;
    if (!defined($self->{old_datas}->{last_timestamp})) {
        $self->{old_datas}->{last_timestamp} = $self->{statefile_value}->get(name => 'last_timestamp');
    }
    $self->{old_datas}->{$name} = $self->{statefile_value}->get(name => $name);
    return undef if (!defined($self->{old_datas}->{last_timestamp}) || !defined($self->{old_datas}->{$name}));
    
    # Reward... put to 0
    if ($self->{old_datas}->{$name} > $self->{new_datas}->{$name}) {
        $self->{old_datas}->{$name} = 0;
    }
    # At least one second
    my $delta_time = $self->{new_datas}->{last_timestamp} - $self->{old_datas}->{last_timestamp};
    if ($delta_time <= 0) {
        $delta_time = 1;
    }
    
    $value = ($self->{new_datas}->{$name} - $self->{old_datas}->{$name}) / $delta_time;
    my ($scale_value, $scale_unit) = $self->{perfdata}->change_bytes(value => $value);
    
    return ($value, $scale_value . ' ' . $scale_unit);
}

sub get_utils {
    my ($self, %options) = @_;
    my $name = $options{instance} . '_' . $options{label};
    my $value;
    
    $self->{new_datas}->{$name . '_busy'} = $1;
    $self->{new_datas}->{$name . '_idle'} = $2;

    $self->{old_datas}->{$name . '_busy'} = $self->{statefile_value}->get(name => $name . '_busy');
    $self->{old_datas}->{$name . '_idle'} = $self->{statefile_value}->get(name => $name . '_idle');
    return undef if (!defined($self->{old_datas}->{$name . '_busy'}) || !defined($self->{old_datas}->{$name . '_idle'}));
    
    # Reward... put to 0
    if ($self->{old_datas}->{$name . '_busy'} > $self->{new_datas}->{$name . '_busy'}) {
        $self->{old_datas}->{$name . '_busy'} = 0;
    }
    if ($self->{old_datas}->{$name . '_idle'} > $self->{new_datas}->{$name . '_idle'}) {
        $self->{old_datas}->{$name . '_idle'} = 0;
    }
    
    my $total_ticks = ($self->{new_datas}->{$name . '_idle'} - $self->{old_datas}->{$name . '_idle'}) + 
                      ($self->{new_datas}->{$name . '_busy'} - $self->{old_datas}->{$name . '_busy'});
    if ($total_ticks <= 0) {
        return (0, 0);
    }
    $value = ($self->{new_datas}->{$name . '_busy'} - $self->{old_datas}->{$name . '_busy'}) * 100 / $total_ticks;
    
    return ($value, $value);
}

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::misc;

my $maps_counters = {
    hard_read_errors   => { thresholds => {
                                warning_hard_read_errors  =>  { label => 'warning-hard-read-errors', exit_value => 'warning' },
                                critical_hard_read_errors =>  { label => 'critical-hard-read-errors', exit_value => 'critical' },
                          },
                matching => 'Hard Read Errors:\s+(\d+)', closure => \&get_absolute,
                output_msg => 'Hard Read Errors : %d', perfdata => '%s',
                unit => '',
               },
    hard_write_errors   => { thresholds => {
                                warning_hard_write_errors  =>  { label => 'warning-hard-write-errors', exit_value => 'warning' },
                                critical_hard_write_errors =>  { label => 'critical-hard-write-errors', exit_value => 'critical' },
                          },
                matching => 'Hard Write Errors:\s+(\d+)', closure => \&get_absolute,
                output_msg => 'Hard Write Errors : %d', perfdata => '%s', 
                unit => '',
               },
    write_io => { thresholds => {
                                warning_write_io    =>  { label => 'warning-write-io', exit_value => 'warning' },
                                critical_write_io   =>  { label => 'critical-write-io', exit_value => 'critical' },
                                },
                 matching => 'Kbytes Written:\s+(\d+)', closure => \&get_bytes_per_seconds,
                 output_msg => 'Write I/O : %s', perfdata => '%d',
                 unit => 'B',
               },
    read_io => { thresholds => {
                                warning_read_io    =>  { label => 'warning-read-io', exit_value => 'warning' },
                                critical_read_io   =>  { label => 'critical-read-io', exit_value => 'critical' },
                                },
                 matching => 'Kbytes Read:\s+(\d+)', closure => \&get_bytes_per_seconds,
                 output_msg => 'Read I/O : %s', perfdata => '%d',
                 unit => 'B',
               },
    utils => { thresholds => {
                                warning_utils    =>  { label => 'warning-utils', exit_value => 'warning' },
                                critical_utils   =>  { label => 'critical-utils', exit_value => 'critical' },
                                },
                 matching => 'Busy Ticks:\s+(\d+).*Idle Ticks:\s+(\d+)', closure => \&get_utils,
                 output_msg => 'Utils : %.2f %%', perfdata => '%.2f',
                 unit => '%',
               },
};

my @states = (
    ['^enabled$'         , 'OK'],
    ['^binding$'         , 'OK'],
    ['^expanding$'       , 'OK'],
    ['^ready$'           , 'OK'],
    ['^unbound$'         , 'OK'],
    ['^empty$'           , 'OK'],
    ['^hot spare ready$' , 'OK'],
    ['^powering up$' , 'OK'],
    ['^requested bypass$', 'WARNING'],
    ['^equalizing$'  , 'WARNING'],
    ['^formatting$'  , 'WARNING'],
    ['^removed$'     , 'WARNING'],
    ['^unformatted$' , 'WARNING'],
    ['^failed$'      , 'CRITICAL'],
    ['^off$'         , 'CRITICAL'],
    ['^unsupported$' , 'CRITICAL'],
    ['^.*$'          , 'CRITICAL'], 
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "threshold-overload:s@"     => { name => 'threshold_overload' },
                                "filter-raidgroupid:s"      => { name => 'filter_raidgroupid', },
                                "filter-disk:s"             => { name => 'filter_disk', },
                                });

    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            $options{options}->add_options(arguments => {
                                                         $maps_counters->{$_}->{thresholds}->{$name}->{label} . ':s'    => { name => $name },
                                                        });
        }
    }
    
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
            if (($self->{perfdata}->threshold_validate(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, value => $self->{option_results}->{$name})) == 0) {
                $self->{output}->add_option_msg(short_msg => "Wrong " . $maps_counters->{$_}->{thresholds}->{$name}->{label} . " threshold '" . $self->{option_results}->{$name} . "'.");
                $self->{output}->option_exit();
            }
        }
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /(.*?)=(.*)/) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }

        my ($filter, $threshold) = ($1, $2);
        if ($self->{output}->is_litteral_status(status => $threshold) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong treshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$filter} = $threshold;
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'unknown';
    
    foreach my $entry (@states) {
        if ($options{value} =~ /${$entry}[0]/i) {
            $status = ${$entry}[1];
            foreach my $filter (keys %{$self->{overload_th}}) {
                if (${$entry}[0] =~ /$filter/i) {
                    $status = $self->{overload_th}->{$filter};
                    last;
                }
            }
            last;
        }
    }

    return $status;
}

sub run {
    my ($self, %options) = @_;
    my $clariion = $options{custom};

    my $response = $clariion->execute_command(cmd => 'getdisk -state -bytrd -bytwrt -hw -hr -busyticks -idleticks -rg');

    my ($total_num_disks, $skip_num_disks) = (0, 0);
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "cache_clariion_" . $clariion->{hostname}  . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();

    #Bus 1 Enclosure 7  Disk 13
    #State:                   Enabled
    #Kbytes Read:             1109878030
    #Kbytes Written:          0
    #Hard Write Errors:       0
    #Hard Read Errors:        0
    #Busy Ticks:              462350
    #Idle Ticks:              388743630
    #Raid Group ID:           0

    # Add a "\n" for the end.
    $response .= "\n";
    while ($response =~ /^Bus\s+(\S+)\s+Enclosure\s+(\S+)\s+Disk\s+(\S+)(.*?)\n\n/msgi) {
        my $disk_instance = "$1_$2_$3";
        my $values = $4;
        
        # First Filters
        if (defined($self->{option_results}->{filter_disk}) && $self->{option_results}->{filter_disk} ne '' &&
            $disk_instance !~ /$self->{option_results}->{filter_disk}/) {
            $skip_num_disks++;
            $self->{output}->output_add(long_msg => "Skipping disk '" . $disk_instance . "': no matching filter disk");
            next;
        }
        if (defined($self->{option_results}->{filter_raidgroupid}) && $self->{option_results}->{filter_raidgroupid} ne '' &&
            $values =~ /^Raid Group ID:\s+(\S+)/mi && $1 !~ /$self->{option_results}->{filter_raidgroupid}/) {
            $skip_num_disks++;
            $self->{output}->output_add(long_msg => "Skipping disk '" . $disk_instance . "': no matching filter raid group id");
            next;
        }
        
        $total_num_disks++;
        $values =~ /^State:\s+(.*?)(\n|$)/msi;
        
        my $state = centreon::plugins::misc::trim($1);
        my $exit = $self->get_severity(value => $state);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Disk '%s' state is %s", 
                                                            $disk_instance, $state));
            # Don't check values if in critical/warning
            next;
        }
        
        # Work on values. No check if in 'Hot Spare Ready' or 'Unbound'
        next if ($state =~ /^(Hot Spare Ready|Unbound)$/i);
        
        my ($short_msg, $long_msg) = ('', '');
        my @exits;
        foreach (keys %{$maps_counters}) {
            next if ($values !~ /$maps_counters->{$_}->{matching}/msi);
            my ($value_check, $value_output) = &{$maps_counters->{$_}->{closure}}($self, 
                                                               instance => $disk_instance, label => $_);
            next if (!defined($value_check));
            my ($warning, $critical);
            
            foreach my $name (keys %{$maps_counters->{$_}->{thresholds}}) {
                my $exit2 = $self->{perfdata}->threshold_check(value => $value_check, threshold => [ { label => $maps_counters->{$_}->{thresholds}->{$name}->{label}, 'exit_litteral' => $maps_counters->{$_}->{thresholds}->{$name}->{exit_value} }]);
                $long_msg .= ' ' . sprintf($maps_counters->{$_}->{output_msg}, $value_output);
                if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                    $short_msg .= ' ' . sprintf($maps_counters->{$_}->{output_msg}, $value_output);
                }
                push @exits, $exit2;
                
                $warning = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'warning');
                $critical = $self->{perfdata}->get_perfdata_for_output(label => $maps_counters->{$_}->{thresholds}->{$name}->{label}) if ($maps_counters->{$_}->{thresholds}->{$name}->{exit_value} eq 'critical');
            }
            
            $self->{output}->perfdata_add(label => $_ . '_' . $disk_instance, unit => $maps_counters->{$_}->{unit},
                                          value => sprintf($maps_counters->{$_}->{perfdata}, $value_check),
                                          warning => $warning,
                                          critical => $critical,
                                          min => 0);
        }

        $self->{output}->output_add(long_msg => "Disk '$disk_instance':$long_msg");
        $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Disk '$disk_instance':$short_msg"
                                        );
        }
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All %s disks are ok.", 
                                                     $total_num_disks . '/' . $skip_num_disks)
                                );
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the status of the physical disks.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'read-errors', 'write-errors', 'read-io', 'write-io', 'utils'.

=item B<--critical-*>

Threshold critical.
Can be: 'read-errors', 'write-errors', 'read-io', 'write-io', 'utils'.

=item B<--threshold-overload>

Set to overload default threshold value.
Example: --threshold-overload='(enabled)=critical'

=item B<--filter-disk>

Filter Disk (regexp can be used).
Example: 1_7_14 ([BUS]_[ENCLOSURE]_[DISK]).

=item B<--filter-raidgroupid>

Filter Raid Group ID (regexp can be used).
Example: N/A or a number.

=back

=cut
