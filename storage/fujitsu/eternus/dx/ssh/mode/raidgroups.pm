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

package storage::fujitsu::eternus::dx::ssh::mode::raidgroups;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;

sub custom_threshold_output {
    my ($self, %options) = @_;
    
    return $self->{instance_mode}->get_severity(section => 'rg', value => $self->{result_values}->{status});
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{status} = $options{new_datas}->{$self->{instance} . '_status'};
    return 0;
}

sub custom_usage_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        label => 'used', unit => 'B',
        nlabel => $self->{nlabel},
        instances => $self->use_instances(extra_instance => $options{extra_instance}) ? $self->{result_values}->{display} : undef,
        value => $self->{result_values}->{used},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}, total => $self->{result_values}->{total}, cast_int => 1),
        min => 0, max => $self->{result_values}->{total}
    );
}

sub custom_usage_threshold {
    my ($self, %options) = @_;
    
    my $exit = $self->{perfdata}->threshold_check(value => $self->{result_values}->{prct_used}, threshold => [ { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' }, { label => 'warning-' . $self->{thlabel}, exit_litteral => 'warning' } ]);
    return $exit;
}

sub custom_usage_output {
    my ($self, %options) = @_;
    
    my ($total_size_value, $total_size_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{total});
    my ($total_used_value, $total_used_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{used});
    my ($total_free_value, $total_free_unit) = $self->{perfdata}->change_bytes(value => $self->{result_values}->{free});
    
    my $msg = sprintf("Total: %s Used: %s (%.2f%%) Free: %s (%.2f%%)",
                      $total_size_value . " " . $total_size_unit,
                      $total_used_value . " " . $total_used_unit, $self->{result_values}->{prct_used},
                      $total_free_value . " " . $total_free_unit, $self->{result_values}->{prct_free});
    return $msg;
}

sub custom_usage_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{display} = $options{new_datas}->{$self->{instance} . '_display'};
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{used} = $options{new_datas}->{$self->{instance} . '_used'};
    $self->{result_values}->{free} = $self->{result_values}->{total} - $self->{result_values}->{used};
    $self->{result_values}->{prct_free} = $self->{result_values}->{free} * 100 / $self->{result_values}->{total};
    $self->{result_values}->{prct_used} = $self->{result_values}->{used} * 100 / $self->{result_values}->{total};
    return 0;
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'rg', type => 1, cb_prefix_output => 'prefix_rg_output', message_multiple => 'All raid groups are ok' }
    ];
    
    $self->{maps_counters}->{rg} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'status' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                output_template => 'Status : %s', output_error_template => 'Status : %s',
                output_use => 'status',
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => $self->can('custom_threshold_output'),
            }
        },
        { label => 'usage', nlabel => 'raidgroup.space.usage.bytes', set => {
                key_values => [ { name => 'display' }, { name => 'total' }, { name => 'used' } ],
                closure_custom_calc => $self->can('custom_usage_calc'),
                closure_custom_output => $self->can('custom_usage_output'),
                closure_custom_perfdata => $self->can('custom_usage_perfdata'),
                closure_custom_threshold_check => $self->can('custom_usage_threshold'),
            }
        },
    ];
}

sub prefix_rg_output {
    my ($self, %options) = @_;
    
    return "Raid Group '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        "hostname:s"              => { name => 'hostname' },
        "ssh-option:s@"           => { name => 'ssh_option' },
        "ssh-path:s"              => { name => 'ssh_path' },
        "ssh-command:s"           => { name => 'ssh_command', default => 'ssh' },
        "timeout:s"               => { name => 'timeout', default => 30 },
        "command:s"               => { name => 'command', default => 'show' },
        "command-path:s"          => { name => 'command_path' },
        "command-options:s"       => { name => 'command_options', default => 'raid-groups -csv' },
        "threshold-overload:s@"   => { name => 'threshold_overload' },
        "filter-name:s"           => { name => 'filter_name' },
        "filter-level:s"          => { name => 'filter_level' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (defined($self->{option_results}->{hostname}) && $self->{option_results}->{hostname} ne '') {
        $self->{option_results}->{remote} = 1;
    }

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $stdout = centreon::plugins::misc::execute(
        output => $self->{output},
        options => $self->{option_results},
        ssh_pipe => 1,
        command => $self->{option_results}->{command},
        command_path => $self->{option_results}->{command_path},
        command_options => $self->{option_results}->{command_options}
    );
    
    #[RAID Group No.],[RAID Group Name],[RAID Level],[Assigned CM],[Status],[Total Capacity(MB)],[Free Capacity(MB)]
    #1,RAIDGROUP001,RAID1+0,CM#0,Spare in Use,134656,132535
    #2,RAIDGROUP002,RAID5,CM#1,Available,134656,132532
    #3,RAIDGROUP003,RAID5,CM#1,SED Locked,134656,132532
    
    $self->{rg} = {};
    while ($stdout =~ /^(.*?),(.*?),(.*?),.*?,(.*?),(.*?),(.*?)$/msg) {
        my ($raid_num, $raid_name, $raid_level, $raid_status, $raid_total, $raid_free) = ($1, $2, $3, $4, $5, $6);
        next if ($raid_num =~ /\[.*?\]/);
    
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $raid_name !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $raid_name . "': no matching filter name.");
            next;
        }
        if (defined($self->{option_results}->{filter_level}) && $self->{option_results}->{filter_level} ne '' &&
            $raid_level !~ /$self->{option_results}->{filter_level}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $raid_name . "': no matching filter level.");
            next;
        }
        
        $self->{rg}->{$raid_num} = {
            status => $raid_status, total => $raid_total * 1024 * 1024, 
            used => ($raid_total * 1024 * 1024) - ($raid_free * 1024 * 1024), 
            display => $raid_name
        };
    }

    if (scalar(keys %{$self->{rg}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No raid group found.");
        $self->{output}->option_exit();
    }
}

my $thresholds = {
    rg => [
        ['Available', 'OK'],
        ['Spare in Use', 'WARNING'],
    ],
};

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default 
    
    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {            
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {           
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

Check raid groups.

=over 8

=item B<--hostname>

Hostname to query.

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--command>

Command to get information (Default: 'show').
Can be changed if you have output in a file.

=item B<--command-path>

Command path (Default: none).

=item B<--command-options>

Command options (Default: 'raid-groups -csv').

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='rg,CRITICAL,^(?!(Available|Spare)$)'

=item B<--filter-name>

Filter by name (regexp can be used).

=item B<--filter-level>

Filter by raid level (regexp can be used).

=item B<--warning-usage>

Threshold warning (in percent).

=item B<--critical-usage>

Threshold critical (in percent).

=back

=cut
