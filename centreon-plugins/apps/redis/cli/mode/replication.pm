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

package apps::redis::cli::mode::replication;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my $thresholds = {
    link => [
        ['down', 'CRITICAL'],
        ['up', 'OK'],
    ],
    sync => [
        ['stopped', 'OK'],
        ['in progress', 'WARNING'],
    ],
};

my %map_sync = (
    0 => 'stopped',
    1 => 'in progress',
);

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'global', type => 0 },
        { name => 'master', type => 0 },
        { name => 'slave', type => 0 }
    ];
    
    $self->{maps_counters}->{global} = [
        { label => 'connected-slaves', set => {
                key_values => [ { name => 'connected_slaves' } ],
                output_template => 'Number of connected slaves: %s',
                perfdatas => [
                    { label => 'connected_slaves', value => 'connected_slaves_absolute', template => '%s', min => 0 },
                ],
            },
        },
    ];

    $self->{maps_counters}->{master} = [
        {  label => 'master-repl-offset', set => {
                key_values => [ { name => 'master_repl_offset' } ],
                output_template => 'Master replication offset: %s s',
                perfdatas => [
                    { label => 'master_repl_offset', value => 'master_repl_offset_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
    ];

    $self->{maps_counters}->{slave} = [
        {  label => 'master-last-io', set => {
                key_values => [ { name => 'master_last_io_seconds_ago' } ],
                output_template => 'Last interaction with master: %s s',
                perfdatas => [
                    { label => 'master_last_io', value => 'master_last_io_seconds_ago_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        {  label => 'slave-repl-offset', set => {
                key_values => [ { name => 'slave_repl_offset' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_repl_offset', value => 'slave_repl_offset_absolute', template => '%s', min => 0, unit => 's' },
                ],
            },
        },
        {  label => 'slave-priority', set => {
                key_values => [ { name => 'slave_priority' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_priority', value => 'slave_priority_absolute', template => '%s' },
                ],
            },
        },
        {  label => 'slave-read-only', set => {
                key_values => [ { name => 'slave_read_only' } ],
                output_template => 'Slave replication offset: %s s',
                perfdatas => [
                    { label => 'slave_read_only', value => 'slave_read_only_absolute', template => '%s' },
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
    
    $self->{output}->output_add(short_msg => sprintf("Node is '%s'", $self->{results}->{role}));

    $self->{global} = { 'connected_slaves' => $self->{results}->{connected_slaves} };

    if ($self->{results}->{role} =~ /master/) {
        $self->{master} = { 'master_repl_offset' => $self->{results}->{master_repl_offset} };
    } elsif ($self->{results}->{role} =~ /slave/) {
        $self->{output}->output_add(short_msg => sprintf("Link with master '%s:%s' is '%s', Sync is '%s'", 
            $self->{results}->{master_host}, 
            $self->{results}->{master_port}, 
            $self->{results}->{master_link_status},
            $map_sync{$self->{results}->{master_sync_in_progress}}));

        push @exits, $self->get_severity(section => 'link', value => $self->{results}->{master_link_status});
        push @exits, $self->get_severity(section => 'sync', value => $map_sync{$self->{results}->{master_sync_in_progress}});
        
        $self->{slave} = {  'master_last_io_seconds_ago' => $self->{results}->{master_last_io_seconds_ago},
                            'slave_repl_offset' => $self->{results}->{slave_repl_offset},
                            'slave_priority' => $self->{results}->{slave_priority},
                            'slave_read_only' => $self->{results}->{slave_read_only} };
    }
 
    my $exit = $self->{output}->get_most_critical(status => \@exits);
    $self->{output}->output_add(severity => $exit);
}

1;

__END__

=head1 MODE

Check replication status

=over 8

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
Example: --threshold-overload='link,OK,down'
Section can be: 'link', 'sync'

=item B<--warning-connected-slaves>

Warning threshold for number of connected slave

=item B<--critical-connected-slaves>

Critical threshold for number of connected slave

=item B<--warning-master-repl-offset>

Warning threshold for master replication offset (in second)

=item B<--critical-master-repl-offset>

Critical threshold for master replication offset (in second)

=item B<--warning-master-last-io>

Warning threshold for last interaction with master (in second)

=item B<--critical-master-last-io>

Critical threshold for last interaction with master (in second)

=item B<--warning-slave-priority>

Warning threshold for slave priority

=item B<--critical-slave-priority>

Critical threshold for slave priority

=item B<--warning-slave-read-only>

Warning threshold for slave being in read-only

=item B<--critical-slave-read-only>

Critical threshold for slave being in read-only

=back

=cut
