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

package centreon::common::jvm::mode::threads;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

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
        '001_started'   => {  set => { key_values => [ { name => 'started', diff => 1 } ],
                        output_template => 'Started : %s',
                        perfdatas => [
                            { label => 'started', value => 'started_absolute', template => '%s', min => 0 },
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
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
 
    foreach my $key (('threads')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(
                                                      statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
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
    
    $self->{statefile_value}->check_options(%options);
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
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "jvm_standard_" . $self->{mode} . '_' .  md5_hex($self->{connector}->{url}));
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters->{threads}}) {
        my $obj = $maps_counters->{threads}->{$_}->{obj};
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global},
                                          new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
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

    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    my $mbean = 'java.lang:type=Threading';
    $self->{request} = [
         { mbean => $mbean, attributes => [ { name => 'TotalStartedThreadCount' }, { name => 'ThreadCount' }, { name => 'DaemonThreadCount' } ] },
    ];
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    
    $self->{global} = {};
    $self->{global}->{started} = $result->{$mbean}->{TotalStartedThreadCount} if (defined($result->{$mbean}->{TotalStartedThreadCount}));
    $self->{global}->{active} = $result->{$mbean}->{ThreadCount} if (defined($result->{$mbean}->{ThreadCount}));
    $self->{global}->{daemon} = $result->{$mbean}->{DaemonThreadCount} if (defined($result->{$mbean}->{DaemonThreadCount}));
}

1;

__END__

=head1 MODE

Check threads.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active', 'started', 'daemon'.

=item B<--critical-*>

Threshold critical.
Can be: 'active', 'started', 'daemon'.

=back

=cut