#!/usr/bin/perl -w

package centreon::esxd::connector;

use strict;
use VMware::VIRuntime;
use VMware::VILib;
use JSON;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);
use File::Basename;
use POSIX ":sys_wait_h";
use centreon::script;
use centreon::esxd::common;

my %handlers = (TERM => {}, HUP => {}, CHLD => {});
my ($connector, $backend);

sub new {
    my ($class, %options) = @_;
    $connector = {};
    bless $connector, $class;

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
    $connector->{childs_vpshere_pid} = {};
    $connector->{session1} = undef;
    
    $connector->{modules_registry} = $options{modules_registry};
    $connector->{logger} = $options{logger};
    $connector->{whoaim} = $options{name};
    $connector->{module_date_parse_loaded} = $options{module_date_parse_loaded};
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
    $self->{logger}->writeLogInfo("$$ Receiving order to stop...");
    $self->{stop} = 1;
}

sub handle_HUP {
    my $self = shift;
    $self->{logger}->writeLogInfo("$$ Receiving order to reload...");
    # TODO
}

sub handle_CHLD {
    my $self = shift;
    my $child_pid;

    while (($child_pid = waitpid(-1, &WNOHANG)) > 0) {
        $self->{return_child}{$child_pid} = {status => 1, rtime => time()};
    }
    $SIG{CHLD} = \&class_handle_CHLD;
}

sub response_router {
    my ($self, %options) = @_;
    
    my $manager = centreon::esxd::common::init_response();
    $manager->{output}->output_add(severity => $options{severity},
                                   short_msg => $options{msg});
    $manager->{output}->{plugin} = $options{identity};
    centreon::esxd::common::response(token => 'RESPSERVER2', endpoint => $backend);
}

sub verify_child {
    my $self = shift;
    my $progress = 0;

    # Verify process
    foreach (keys %{$self->{child_proc}}) {
        # Check ctime
        if (time() - $self->{child_proc}->{$_}->{ctime} > $self->{config_child_timeout}) {
            $self->response_router(severity => 'UNKNOWN', msg => 'Timeout process',
                                   identity => $_);
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
        $result = JSON->new->utf8->decode($options{data});
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
            
            centreon::esxd::common::response(token => 'RESPSERVER2', endpoint => $backend, reinit => 'ipc://routing.ipc');
            exit(0);
        }
    } else {
        $self->response_router(severity => 'UNKNOWN', msg => 'Container connection problem',
                               identity => $result->{identity});
    }
}

sub vsphere_event {
    while (1) {
        # Process all parts of the message
        my $message = zmq_recvmsg($backend);
        my $data = zmq_msg_data($message);
        
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

    my $context = zmq_init();

    $backend = zmq_socket($context, ZMQ_DEALER);
    zmq_setsockopt($backend, ZMQ_IDENTITY, "server-" . $connector->{whoaim});
    zmq_connect($backend, 'ipc://routing.ipc');
    
    # Initialize poll set
    my @poll = (
        {
            socket  => $backend,
            events  => ZMQ_POLLIN,
            callback => \&vsphere_event,
        },
    );

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
                    $connector->{session1}->logout();
                };
            }            
            exit (0);
        }

        ###
        # Manage vpshere connection
        ###
        if (defined($connector->{last_time_vsphere}) && defined($connector->{last_time_check}) 
            && $connector->{last_time_vsphere} < $connector->{last_time_check}) {
            $connector->{logger}->writeLogError("'" . $connector->{whoaim} . "' Disconnect");
            $connector->{vsphere_connected} = 0;
            eval {
                $connector->{session1}->logout();
            };
        }
        
        if ($connector->{vsphere_connected} == 0) {
            if (!centreon::esxd::common::connect_vsphere($connector->{logger},
                                                         $connector->{whoaim},
                                                         $connector->{config_vsphere_connect_timeout},
                                                         \$connector->{session1},
                                                         $connector->{config_vsphere_url}, 
                                                         $connector->{config_vsphere_user},
                                                         $connector->{config_vsphere_pass})) {
                $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Vsphere connection ok");
                $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Create perf counters cache in progress");
                if (!centreon::esxd::common::cache_perf_counters($connector)) {
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
        if (defined($connector->{keeper_session_time}) && 
            (time() - $connector->{keeper_session_time}) > ($connector->{config_vsphere_session_heartbeat} * 60)) {
            my $stime;

            eval {
                $stime = $connector->{session1}->get_service_instance()->CurrentTime();
                $connector->{keeper_session_time} = time();
            };
            if ($@) {
                $connector->{logger}->writeLogError("$@");
                $connector->{logger}->writeLogError("'" . $connector->{whoaim} . "' Ask a new connection");
                # Ask a new connection
                $connector->{last_time_check} = time();
            } else {
                $connector->{logger}->writeLogInfo("'" . $connector->{whoaim} . "' Get current time = " . Data::Dumper::Dumper($stime));
            }
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