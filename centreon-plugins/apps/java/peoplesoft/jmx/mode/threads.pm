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

package apps::java::peoplesoft::jmx::mode::threads;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $instance_mode;

my $maps_counters = {
    threads => { 
        '000_active'   => {  set => { key_values => [ { name => 'active' } ],
                        output_template => 'Active : %s',
                        perfdatas => [
                            { label => 'active', value => 'active_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '001_idle'   => {  set => { key_values => [ { name => 'idle' } ],
                        output_template => 'Idle : %s',
                        perfdatas => [
                            { label => 'idle', value => 'idle_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '002_total'   => {  set => { key_values => [ { name => 'total' } ],
                        output_template => 'Total : %s',
                        perfdatas => [
                            { label => 'total', value => 'total_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '003_daemon'   => {  set => { key_values => [ { name => 'daemon' } ],
                        output_template => 'Daemon : %s',
                        perfdatas => [
                            { label => 'daemon', value => 'daemon_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        },
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });
 
    foreach my $key (('threads')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('threads')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $instance_mode = $self;
    
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

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};
    
    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{threads}}) {
        my $obj = $maps_counters->{threads}->{$_}->{obj};
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global);

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Threads $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Threads $long_msg");
    }

    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mbean_queuer = 'com.bea:Name=weblogic.socket.Muxer,ServerRuntime=PIA,Type=ExecuteQueueRuntime';
    my $mbean_queue = 'com.bea:Name=weblogic.socket.Muxer,ServerRuntime=PIA,Type=ExecuteQueue';
    $self->{request} = [
         { mbean => $mbean_queuer, attributes => [ { name => 'ExecuteThreadCurrentIdleCount' }, { name => 'ThreadCount' } ] },
         { mbean => $mbean_queue, attributes => [ { name => 'ExecuteThreadTotalCount' } ] },
         { mbean => 'java.lang:type=Threading', attributes => [ { name => 'DaemonThreadCount' } ] },
    ];
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{idle} = $result->{$mbean_queuer}->{ExecuteThreadCurrentIdleCount} if (defined($result->{$mbean_queuer}->{ExecuteThreadCurrentIdleCount}));
    $self->{global}->{active} = $result->{$mbean_queuer}->{ThreadCount} if (defined($result->{$mbean_queuer}->{ThreadCount}));
    $self->{global}->{total} = $result->{$mbean_queue}->{ExecuteThreadTotalCount} if (defined($result->{$mbean_queue}->{ExecuteThreadTotalCount}));
    $self->{global}->{daemon} = $result->{'java.lang:type=Threading'}->{DaemonThreadCount} if (defined($result->{'java.lang:type=Threading'}->{DaemonThreadCount}));
}

1;

__END__

=head1 MODE

Check threads.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'total', 'idle', 'daemon'.

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'total', 'idle', 'daemon'.

=back

=cut
