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

package apps::php::fpm::web::mode::usage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::values;
use centreon::plugins::statefile;

my $maps_counters = {
    fpm => {
        '000_active-processes'   => { set => {
                key_values => [ { name => 'active' }, { name => 'total' } ],
                closure_custom_calc => \&custom_active_calc,
                closure_custom_output => \&custom_active_output,
                threshold_use => 'active_prct',
                closure_custom_perfdata =>  => \&custom_active_perfdata,
            }
        },
        '001_idle-processes'   => { set => {
                key_values => [ { name => 'idle' }, { name => 'total' } ],
                closure_custom_calc => \&custom_idle_calc,
                closure_custom_output => \&custom_idle_output,
                threshold_use => 'idle_prct',
                closure_custom_perfdata =>  => \&custom_idle_perfdata,
            }
        }, 
        '002_listen-queue'   => { set => {
                key_values => [ { name => 'listen_queue' }, { name => 'max_listen_queue' } ],
                output_template => 'Listen queue : %s',
                output_use => 'listen_queue_absolute', threshold_use => 'listen_queue_absolute',
                perfdatas => [
                    { label => 'listen_queue', template => '%s', value => 'listen_queue_absolute',
                      min => 0, max => 'max_listen_queue_absolute' },
                ],
            }
        },
        '003_requests'   => { set => {
                key_values => [ { name => 'request', diff => 1 } ],
                per_second => 1,
                output_template => 'Requests : %.2f/s',
                perfdatas => [
                    { label => 'requests', template => '%.2f', value => 'request_per_second',
                      unit => '/s', min => 0 },
                ],
            }
        },
    },
};

sub custom_active_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{active} = $options{new_datas}->{$self->{instance} . '_active'};
    $self->{result_values}->{active_prct} =  $self->{result_values}->{active} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_active_output {
    my ($self, %options) = @_;

    return sprintf("Active processes: %s (%.2f%%)",
                   $self->{result_values}->{active},
                   $self->{result_values}->{active_prct});
}

sub custom_active_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'active',
                                  value => $self->{result_values}->{active},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub custom_idle_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{total} = $options{new_datas}->{$self->{instance} . '_total'};
    $self->{result_values}->{idle} = $options{new_datas}->{$self->{instance} . '_idle'};
    $self->{result_values}->{idle_prct} =  $self->{result_values}->{idle} * 100 / $self->{result_values}->{total};
    return 0;
}

sub custom_idle_output {
    my ($self, %options) = @_;

    return sprintf("Idle processes: %s (%.2f%%)",
                   $self->{result_values}->{idle},
                   $self->{result_values}->{idle_prct});
}

sub custom_idle_perfdata {
    my ($self, %options) = @_;
    
    $self->{output}->perfdata_add(label => 'idle',
                                  value => $self->{result_values}->{idle},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{label}, total => $self->{result_values}->{total}, cast_int => 1),
                                  min => 0, max => $self->{result_values}->{total});
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                "hostname:s"        => { name => 'hostname' },
                                "port:s"            => { name => 'port', },
                                "proto:s"           => { name => 'proto' },
                                "urlpath:s"         => { name => 'url_path', default => "/fpm-status" },
                                "credentials"       => { name => 'credentials' },
                                "username:s"        => { name => 'username' },
                                "password:s"        => { name => 'password' },
                                "proxyurl:s"        => { name => 'proxyurl' },
                                "timeout:s"         => { name => 'timeout', default => 5 },
                                });
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    
    foreach my $key (('fpm')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                    'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                    'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
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

    foreach my $key (('fpm')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }

    $self->{statefile_value}->check_options(%options);
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
    $self->{webcontent} = $self->{http}->request();

    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "php_fpm_" . $self->{option_results}->{hostname}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    $self->{new_datas}->{last_timestamp} = time();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    
    foreach (sort keys %{$maps_counters->{fpm}}) {
        my $obj = $maps_counters->{fpm}->{$_}->{obj};
                
        $obj->set(instance => 'fpm');
    
        my ($value_check) = $obj->execute(values => $self->{fpm},
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
                                    short_msg => "php-fpm $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "php-fpm $long_msg");
    }
    
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;
    
    $self->{fpm} = { request => undef, listen_queue => undef, max_listen_queue => undef,
                     idle => undef, active => undef, total => undef };
    $self->{fpm}->{request} = $1 if ($self->{webcontent} =~ /accepted\s+conn:\s+(\d+)/msi);
    $self->{fpm}->{listen_queue} = $1 if ($self->{webcontent} =~ /listen\s+queue:\s+(\d+)/msi);
    $self->{fpm}->{max_listen_queue} = $1 if ($self->{webcontent} =~ /max\s+listen\s+queue:\s+(\d+)/msi);
    $self->{fpm}->{idle} = $1 if ($self->{webcontent} =~ /idle\s+processes:\s+(\d+)/msi);
    $self->{fpm}->{active} = $1 if ($self->{webcontent} =~ /active\s+processes:\s+(\d+)/msi);
    $self->{fpm}->{total} = $1 if ($self->{webcontent} =~ /total\s+processes:\s+(\d+)/msi);
}

1;

__END__

=head1 MODE

Check php-fpm usage. 

=over 8

=item B<--hostname>

IP Addr/FQDN of the webserver host

=item B<--port>

Port used by web server

=item B<--proxyurl>

Proxy URL if any

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (Default: '/fpm-status')

=item B<--credentials>

Specify this option if you access server-status page over basic authentification

=item B<--username>

Specify username for basic authentification (Mandatory if --credentials is specidied)

=item B<--password>

Specify password for basic authentification (Mandatory if --credentials is specidied)

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--warning-*>

Threshold warning.
Can be: 'active-processes' (%), 'idle-processes' (%),
'listen-queue', 'requests'.

=item B<--critical-*>

Threshold critical.
Can be: 'active-processes' (%), 'idle-processes' (%), 
'listen-queue', 'requests'.

=back

=cut
