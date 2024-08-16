# Copyright 2015 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets 
# the needs in IT infrastructure and application monitoring for 
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0  
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

package centreon::vmware::connector;

use strict;
use VMware::VIRuntime;
use VMware::VILib;
use JSON::XS;
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use File::Basename;
use POSIX ":sys_wait_h";
use centreon::vmware::common;

BEGIN {
    # In new version version of LWP (version 6), the backend is now 'IO::Socket::SSL' (instead Crypt::SSLeay)
    # it's a hack if you unset that
    #$ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";

    # The option is not omit to verify the certificate chain. 
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
    
    eval {
        # required for new IO::Socket::SSL versions
        require IO::Socket::SSL;
        IO::Socket::SSL->import();
        IO::Socket::SSL::set_ctx_defaults(SSL_verify_mode => 0);
    };
}

my %handlers = (TERM => {}, HUP => {}, CHLD => {});
my ($connector, $backend);

sub new {
    my ($class, %options) = @_;
    $connector = {};
    bless $connector, $class;
    $connector->set_signal_handlers;

    $connector->{child_proc} = {};
    $connector->{return_child} = {};
    $connector->{vsphere_connected} = 0;
    $connector->{last_time_vsphere} = undef;
    $connector->{keeper_session_time} = undef;
    $connector->{last_time_check} = undef;
    $connector->{perfmanager_view} = undef;
    $connector->{perfcounter_cache} = {};
    $connector->{perfcounter_cache_reverse} = {};
    $connector->{perfcounter_refreshrate} = 20;
    $connector->{perfcounter_speriod} = -1;
    $connector->{stop} = 0;
    $connector->{session} = undef;
    
    $connector->{modules_registry} = $options{modules_registry};
    $connector->{logger} = $options{logger};
    $connector->{whoaim} = $options{name};
    $connector->{vsan_enabled} = $options{vsan_enabled};
    $connector->{config_ipc_file} = $options{config}->{ipc_file};
    $connector->{config_child_timeout} = $options{config}->{timeout};
    $connector->{config_stop_child_timeout} = $options{config}->{timeout_kill};
    $connector->{config_vsphere_session_heartbeat} = $options{config}->{refresh_keeper_session};
    $connector->{config_vsphere_connect_timeout} = $options{config}->{timeout_vsphere};
    $connector->{config_vsphere_url} = $options{config}->{vsphere_server}->{$options{name}}->{url};
    $connector->{config_vsphere_user} = $options{config}->{vsphere_server}->{$options{name}}->{username};
    $connector->{config_vsphere_pass} = $options{config}->{vsphere_server}->{$options{name}}->{password};
    
    return $connector;
}

sub set_signal_handlers {
    my $self = shift;

    $SIG{TERM} = \&class_handle_TERM;
    $handlers{TERM}->{$self} = sub { $self->handle_TERM() };
    $SIG{HUP} = \&class_handle_HUP;
    $handlers{HUP}->{$self} = sub { $self->handle_HUP() };
    $SIG{CHLD} = \&class_handle_CHLD;
    $handlers{CHLD}->{$self} = sub { $self->handle_CHLD() };
}

sub class_handle_TERM {
    foreach (keys %{$handlers{TERM}}) {
        &{$handlers{TERM}->{$_}}();
    }
}

sub class_handle_HUP {
    foreach (keys %{$handlers{HUP}}) {
        &{$handlers{HUP}->{$_}}();
    }
}

sub class_handle_CHLD {
    foreach (keys %{$handlers{CHLD}}) {
        &{$handlers{CHLD}->{$_}}();
    }
}

sub handle_TERM {
    my $self = shift;
    $self->{logger}->writeLogInfo("connector '" . $self->{whoaim} . "' Receiving order to stop...");
    $self->{stop} = 1;
}

sub handle_HUP {
    my $self = shift;
    $self->{logger}->writeLogInfo("connector $$ Receiving order to reload...");
    # TODO
}

sub handle_CHLD {
    my $self = shift;
    my $child_pid;

    while (($child_pid = waitpid(-1, &WNOHANG)) > 0) {
        $self->{return_child}->{$child_pid} = {status => 1, rtime => time()};
    }
    $SIG{CHLD} = \&class_handle_CHLD;
}

sub response_router {
    my ($self, %options) = @_;
    
    centreon::vmware::common::init_response(identity => $options{identity});
    centreon::vmware::common::set_response(code => $options{code}, short_message => $options{msg});
    centreon::vmware::common::response(token => 'RESPSERVER2', endpoint => $backend);
    centreon::vmware::common::free_response();
}

sub verify_child {
    my $self = shift;
    my $progress = 0;

    # Verify process
    foreach (keys %{$self->{child_proc}}) {
        # Check ctime
        if (defined($self->{return_child}->{$self->{child_proc}->{$_}->{pid}})) {
            delete $self->{return_child}->{$self->{child_proc}->{$_}->{pid}};
            delete $self->{child_proc}->{$_};
        } elsif (time() - $self->{child_proc}->{$_}->{ctime} > $self->{config_child_timeout}) {
            $self->response_router(
                code => -1,
                msg => 'Timeout process',
                identity => $_
            );
            kill('INT', $self->{child_proc}->{$_}->{pid});
            delete $self->{child_proc}->{$_};
        } else {
            $progress++;
        }
    }
    
    # Clean old hash CHILD (security)
    foreach (keys %{$self->{return_child}}) {
        if (time() - $self->{return_child}->{$_}->{rtime} > 600) {
            $self->{logger}->writeLogInfo("Clean Old return_child list = " . $_);
            delete $self->{return_child}->{$_};
        }
    }

    return $progress;
}

sub reqclient {
    my ($self, %options) = @_;

    my $result;
    eval {
        $result = JSON::XS->new->utf8->decode($options{data});
    };
    if ($@) {
        $self->{logger}->writeLogError("Cannot decode JSON: $@ (options{data}");
        return ;
    }
    
    if ($self->{vsphere_connected}) {                
        $self->{logger}->writeLogInfo("vpshere '" . $self->{whoaim} . "' handler asking: $options{data}");

        $self->{child_proc}->{$result->{identity}} = { ctime => time() };
        $self->{child_proc}->{$result->{identity}}->{pid} = fork;
        if (!$self->{child_proc}->{$result->{identity}}->{pid}) {
            $self->{modules_registry}->{$result->{command}}->set_connector(connector => $self);
            $self->{modules_registry}->{$result->{command}}->initArgs(arguments => $result);
            $self->{modules_registry}->{$result->{command}}->run();
            
            centreon::vmware::common::response(token => 'RESPSERVER2', endpoint => $backend, reinit => 'ipc://' . $self->{config_ipc_file});
            zmq_close($backend);
            exit(0);
        }
    } else {
        $self->response_router(
            code => -1,
            msg => 'Container connection problem',
            identity => $result->{identity}
        );
    }
}

sub vsphere_event {
    while (1) {
        # Process all parts of the message
        my $msg = zmq_msg_init();
        my $rv = zmq_msg_recv($msg, $backend, undef);
        if ($rv == -1) {
            $connector->{logger}->writeLogError("zmq_recvmsg error: $!");
            last;
        }
        my $data = zmq_msg_data($msg);
        zmq_msg_close($msg);
        
        if ($data =~ /^REQCLIENT\s+(.*)$/msi) {
            $connector->reqclient(data => $1);
        }
        
        my $more = zmq_getsockopt($backend, ZMQ_RCVMORE);
        last unless $more;
    }
}

sub run {
    my ($connector) = shift;
    my $timeout_process = 0;

    $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' ZMQ init begin");
    my $context = zmq_init();

    $backend = zmq_socket($context, ZMQ_DEALER);
    zmq_setsockopt($backend, ZMQ_IDENTITY, "server-" . $connector->{whoaim});
    zmq_setsockopt($backend, ZMQ_LINGER, 0); # we discard  
    zmq_connect($backend, 'ipc://' . $connector->{config_ipc_file});
    centreon::vmware::common::response(token => 'READY', endpoint => $backend, force_response => '');
    
    # Initialize poll set
    my @poll = (
        {
            socket  => $backend,
            events  => ZMQ_POLLIN,
            callback => \&vsphere_event,
        },
    );

    $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' init done");
    while (1) {
        my $progress = $connector->verify_child();
        
        #####
        # Manage ending
        #####
        if ($connector->{stop} && $timeout_process > $connector->{config_stop_child_timeout}) {
            $connector->{logger}->writeLogError("'" . $connector->{whoaim} . "' Kill child not gently.");
            foreach (keys %{$connector->{child_proc}}) {
                kill('INT', $connector->{child_proc}->{$_}->{pid});
            }
            $progress = 0;
        }
        if ($connector->{stop} && !$progress) {
            if ($connector->{vsphere_connected}) {
                eval {
                    $connector->{session}->logout();
                };
            }
            
            zmq_close($backend);
            exit(0);
        }

        ###
        # Manage vpshere connection
        ###
        if ($connector->{vsphere_connected} == 1 &&
            defined($connector->{last_time_vsphere}) && defined($connector->{last_time_check}) &&
            $connector->{last_time_vsphere} < $connector->{last_time_check}) {
            $connector->{logger}->writeLogError("'" . $connector->{whoaim} . "' Disconnect");
            $connector->{vsphere_connected} = 0;
            eval {
                $connector->{session}->logout();
            };
            delete $connector->{session};
        }
        
        if ($connector->{vsphere_connected} == 0) {
            if (!centreon::vmware::common::connect_vsphere(
                logger => $connector->{logger},
                whoaim => $connector->{whoaim},
                connect_timeout => $connector->{config_vsphere_connect_timeout},
                connector => $connector,
                url => $connector->{config_vsphere_url}, 
                username => $connector->{config_vsphere_user},
                password => $connector->{config_vsphere_pass},
                vsan_enabled => $connector->{vsan_enabled}
                )
               ) {
                $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Vsphere connection ok");
                $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Create perf counters cache in progress");
                if (!centreon::vmware::common::cache_perf_counters($connector)) {
                    $connector->{last_time_vsphere} = time();
                    $connector->{keeper_session_time} = time();
                    $connector->{vsphere_connected} = 1;
                    $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Create perf counters cache done");
                }
            }
        }

        ###
        # Manage session time
        ###
        if ($connector->{vsphere_connected} == 1 &&
            defined($connector->{keeper_session_time}) && 
            (time() - $connector->{keeper_session_time}) > ($connector->{config_vsphere_session_heartbeat} * 60)) {
            centreon::vmware::common::heartbeat(connector => $connector);
        }

        my $data_element;
        my @rh_set;
        if ($connector->{vsphere_connected} == 0) {
            sleep(5);
        }
        if ($connector->{stop} != 0) {
            sleep(1);
            $timeout_process++;
            next;
        }
        
        zmq_poll(\@poll, 5000);
    }
}

1;

__END__
