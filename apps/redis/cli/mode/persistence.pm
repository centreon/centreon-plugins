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

package apps::redis::cli::mode::persistence;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $thresholds = {
    status => [
        ['fail', 'CRITICAL'],
        ['ok', 'OK'],
    ],
    progress => [
        ['stopped', 'WARNING'],
        ['in progress', 'OK'],
    ],
};

my %map_status = (
    0 => 'stopped',
    1 => 'in progress',
);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'changes', set => {
                key_values => [ { name => 'rdb_changes_since_last_save' } ],
                output_template => 'Number of changes since the last dump: %s',
                perfdatas => [
                    { label => 'changes', value => 'rdb_changes_since_last_save_absolute', template => '%s', min => 0 },
                ],
            },
        },
        { label => 'last-save', set => {
                key_values => [ { name => 'rdb_last_save_time' }, { name => 'rdb_last_save_time_sec' } ],
                output_template => 'Time since last successful save: %s',
                perfdatas => [
                    { label => 'last_save', value => 'rdb_last_save_time_sec_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        { label => 'save-size', set => {
                key_values => [ { name => 'rdb_last_cow_size' } ],
                output_template => 'Size of last save: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    { label => 'save_size', value => 'rdb_last_cow_size_absolute', template => '%s', min => 0, unit => 'B' },
                ],
            },
        },
        { label => 'last-save-duration', set => {
                key_values => [ { name => 'rdb_last_bgsave_time' } ],
                output_template => 'Duration of last save: %s s',
                perfdatas => [
                    { label => 'last_save_duration', value => 'rdb_last_bgsave_time_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        { label => 'current-save-duration', set => {
                key_values => [ { name => 'rdb_current_bgsave_time' } ],
                output_template => 'Duration of current save: %s s',
                perfdatas => [
                    { label => 'current_save_duration', value => 'rdb_current_bgsave_time_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';

     $options{options}->add_options(arguments => 
                {
                    "threshold-overload:s@" => { name => 'threshold_overload' },
                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
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

sub manage_selection {
    my ($self, %options) = @_;

    $self->{redis} = $options{custom};
    $self->{results} = $self->{redis}->get_info();

    my @exits;
    
    push @exits, $self->get_severity(section => 'status', value => $self->{results}->{rdb_last_bgsave_status});
    push @exits, $self->get_severity(section => 'progess', value => $map_status{$self->{results}->{rdb_bgsave_in_progress}});
   
    $self->{output}->output_add(short_msg => sprintf("RDB save is in '%s' status", $self->{results}->{rdb_last_bgsave_status}));
    $self->{output}->output_add(short_msg => sprintf("RDB save is '%s'", $map_status{$self->{results}->{rdb_bgsave_in_progress}}));

    $self->{global} = { 'rdb_changes_since_last_save' => $self->{results}->{rdb_changes_since_last_save},
                        'rdb_last_save_time' => centreon::plugins::misc::change_seconds(value => time() - $self->{results}->{rdb_last_save_time}),
                        'rdb_last_save_time_sec' => time() - $self->{results}->{rdb_last_save_time},
                        'rdb_last_cow_size' => $self->{results}->{rdb_last_cow_size},
                        'rdb_last_bgsave_time' => $self->{results}->{rdb_last_bgsave_time_sec},
                        'rdb_current_bgsave_time' => $self->{results}->{rdb_current_bgsave_time_sec}};
    
    my $exit = $self->{output}->get_most_critical(status => \@exits);
    $self->{output}->output_add(severity => $exit);
}

1;

__END__

=head1 MODE

Check RDB persistence status

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
Example: --threshold-overload='status,CRITICAL,ok'
Section can be: 'status', 'progress'

=item B<--warning-changes>

Warning threshold for number of changes since the last dump

=item B<--critical-changes>

Critical threshold for number of changes since the last dump

=item B<--warning-last-save>

Warning threshold for time since last successful save (in second)

=item B<--critical-last-save>

Critical threshold for time since last successful save (in second)

=item B<--warning-save-size>

Warning threshold for size of last save (in bytes)

=item B<--critical-save-size>

Critical threshold for size of last save (in bytes)

=item B<--warning-last-save-duration>

Warning threshold for duration of last save (in second)

=item B<--critical-last-save-duration>

Critical threshold for duration of last save (in second)

=item B<--warning-current-save-duration>

Warning threshold for current of last save (in second)

=item B<--critical-current-save-duration>

Critical threshold for current of last save (in second)

=back

=cut
