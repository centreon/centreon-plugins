#!/usr/bin/perl -w

package centreon::script::centreonesxd;

use strict;
use VMware::VIRuntime;
use VMware::VILib;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);
use File::Basename;
use POSIX ":sys_wait_h";
use Data::Dumper;
use centreon::script;
use centreon::esxd::common;

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use base qw(centreon::script);
use vars qw(%centreonesxd_config);

my $VERSION = "1.5.6";
my %handlers = (TERM => {}, HUP => {}, CHLD => {});
my @load_modules = ('centreon::esxd::cmdcountvmhost',
                    'centreon::esxd::cmdcpuhost',
                    'centreon::esxd::cmdcpuvm',
                    'centreon::esxd::cmddatastoreio',
                    'centreon::esxd::cmddatastoreiops',
                    'centreon::esxd::cmddatastoreshost',
                    'centreon::esxd::cmddatastoresnapshots',
                    'centreon::esxd::cmddatastoresvm',
                    'centreon::esxd::cmddatastoreusage',
                    'centreon::esxd::cmdgetmap',
                    'centreon::esxd::cmdhealthhost',
                    'centreon::esxd::cmdlimitvm',
                    'centreon::esxd::cmdlistdatastore',
                    'centreon::esxd::cmdlisthost',
                    'centreon::esxd::cmdlistnichost',
                    'centreon::esxd::cmdmemhost',
                    'centreon::esxd::cmdmaintenancehost',
                    'centreon::esxd::cmdmemvm',
                    'centreon::esxd::cmdnethost',
                    'centreon::esxd::cmdsnapshotvm',
                    'centreon::esxd::cmdstatushost',
                    'centreon::esxd::cmdswaphost',
                    'centreon::esxd::cmdswapvm',
                    'centreon::esxd::cmdthinprovisioningvm',
                    'centreon::esxd::cmdtoolsvm',
                    'centreon::esxd::cmduptimehost'
                    );

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("centreonesxd",
        centreon_db_conn => 0,
        centstorage_db_conn => 0,
        noconfig => 1
    );

    bless $self, $class;
    $self->add_options(
        "config-extra=s" => \$self->{opt_extra},
    );

    %{$self->{centreonesxd_default_config}} =
        (
            credstore_use => 0,
            credstore_file => '/root/.vmware/credstore/vicredentials.xml',
            timeout_vsphere => 60,
            timeout => 60,
            timeout_kill => 30,
            refresh_keeper_session => 15,
            port => 5700,
            datastore_state_error => 'UNKNOWN',
            vm_state_error => 'UNKNOWN',
            host_state_error => 'UNKNOWN',
            vsphere_server => {
                #'default' => {'url' => 'https://XXXXXX/sdk',
                #              'username' => 'XXXXX',
                #              'password' => 'XXXXX'},
                #'testvc' =>  {'url' => 'https://XXXXXX/sdk',
                #              'username' => 'XXXXX',
                #              'password' => 'XXXXXX'}
            }
        );

    $self->{session_id} = undef;
    $self->{sockets} = {};
    $self->{child_proc} = {};
    $self->{return_child} = {};
    $self->{vsphere_connected} = 0;
    $self->{last_time_vsphere} = undef;
    $self->{keeper_session_time} = undef;
    $self->{last_time_check} = undef;
    $self->{perfmanager_view} = undef;
    $self->{perfcounter_cache} = {};
    $self->{perfcounter_cache_reverse} = {};
    $self->{perfcounter_refreshrate} = 20;
    $self->{perfcounter_speriod} = -1;
    $self->{stop} = 0;
    $self->{counter_request_id} = 0;
    $self->{child_vpshere_pid} = undef;
    $self->{read_select} = undef;
    $self->{session1} = undef;
    $self->{counter} = 0;
    $self->{global_id} = undef;
    $self->{whoaim} = undef; # to know which vsphere to connect
    $self->{separatorin} = '~';
    $self->{filenos} = {};
    $self->{module_date_parse_loaded} = 0;
    $self->{modules_registry} = {};
    
    return $self;
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    # redefine to avoid out when we try modules
    $SIG{__DIE__} = undef;
    
    if (!defined($self->{opt_extra})) {
        $self->{opt_extra} = "/etc/centreon/centreon_esxd.pm";
    }
    if (-f $self->{opt_extra}) {
        require $self->{opt_extra};
    } else {
        $self->{logger}->writeLogInfo("Can't find extra config file $self->{opt_extra}");
    }

    $self->{centreonesxd_config} = {%{$self->{centreonesxd_default_config}}, %centreonesxd_config};

    ##### Load modules
    $self->load_module(@load_modules);

    ##### credstore check #####
    if (defined($self->{centreonesxd_config}->{credstore_use}) && defined($self->{centreonesxd_config}->{credstore_file}) &&
        $self->{centreonesxd_config}->{credstore_use} == 1 && -e "$self->{centreonesxd_config}->{credstore_file}") {
        eval 'require VMware::VICredStore';
        if ($@) {
            $self->{logger}->writeLogError("Could not load module VMware::VICredStore");
            exit(1);
        }
        require VMware::VICredStore;

        if (VMware::VICredStore::init(filename => $self->{centreonesxd_config}->{credstore_file}) == 0) {
            $self->{logger}->writeLogError("Credstore init failed: $@");
            exit(1);
        }

        ###
        # Get password
        ###
        foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
            my $lpassword = VMware::VICredStore::get_password(server => $_, username => $self->{centreonesxd_config}->{vsphere_server}->{$_}->{username});
            if (!defined($lpassword)) {
                $self->{logger}->writeLogError("Can't get password for couple host='" . $_ . "', username='" . $self->{centreonesxd_config}->{vsphere_server}->{$_}->{username} . "' : $@");
                exit(1);
            }
            $self->{centreonesxd_config}->{vsphere_server}->{$_}->{password} = $lpassword;
        }
    }
    
    eval 'require Date::Parse';
    if (!$@) {
        $self->{module_date_parse_loaded} = 1;
        require Date::Parse;
    }

    $self->set_signal_handlers;
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

sub print_response {
    my $self = shift;

    print $self->{global_id} . "|" . $_[0];
}

sub load_module {
    my $self = shift;

    for (@_) {
        (my $file = "$_.pm") =~ s{::}{/}g;
        require $file;
        my $obj = $_->new($self->{logger}, $self);
        $self->{modules_registry}->{$obj->getCommandName()} = $obj;
    }    
}

sub verify_child_vsphere {
    my $self = shift;
    
    # Don't need that. We need to quit. Don't want to recreate sub-process :)
    return if ($self->{stop} != 0);
    
    # Some dead process. need to relaunch it
    foreach (keys %{$self->{return_child}}) {
        delete $self->{return_child}->{$_};
        if (defined($self->{centreonesxd_config}->{vsphere_server}->{$_})) {
            $self->{logger}->writeLogError("Sub-process for '" . $self->{centreonesxd_config}->{vsphere_server}->{$_}->{name} . "' dead ???!! We relaunch it");
            
            $self->create_vsphere_child(vsphere_name => $self->{centreonesxd_config}->{vsphere_server}->{$_}->{name});
            delete $self->{centreonesxd_config}->{vsphere_server}->{$_};
        }
    }
}

sub verify_child {
    my $self = shift;
    my $progress = 0;

    # Verify process
    foreach (keys %{$self->{child_proc}}) {
        # Check ctime
        if (time() - $self->{child_proc}->{$_}->{ctime} > $self->{centreonesxd_config}->{timeout}) {
            print "===timeout papa===\n";
            #print $handle_writer_pipe "$_|-1|Timeout Process.\n";
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

sub vsphere_handler {
    my $self = shift;
    my $timeout_process;

    my $context = zmq_init();

    my $backend  = zmq_socket($context, ZMQ_DEALER);
    #zmq_setsockopt($backend, ZMQ_IDENTITY, "server-" . $self->{whoaim});
    #zmq_connect($backend, 'ipc://routing.ipc');
    #zmq_sendmsg($backend, 'ready');

    while (1) {
        my $progress = $self->verify_child();

        #####
        # Manage ending
        #####
        if ($self->{stop} && $timeout_process > $self->{centreonesxd_config}->{timeout_kill}) {
            $self->{logger}->writeLogError("'" . $self->{whoaim} . "' Kill child not gently.");
            foreach (keys %{$self->{child_proc}}) {
                kill('INT', $self->{child_proc}->{$_}->{pid});
            }
            $progress = 0;
        }
        if ($self->{stop} && !$progress) {
            if ($self->{vsphere_connected}) {
                eval {
                    $self->{session1}->logout();
                };
            }            
            exit (0);
        }

        ###
        # Manage vpshere connection
        ###
        if (defined($self->{last_time_vsphere}) && defined($self->{last_time_check}) && $self->{last_time_vsphere} < $self->{last_time_check}) {
            $self->{logger}->writeLogError("'" . $self->{whoaim} . "' Disconnect");
            $self->{vsphere_connected} = 0;
            eval {
                $self->{session1}->logout();
            };
        }
        if ($self->{vsphere_connected} == 0) {
            if (!centreon::esxd::common::connect_vsphere($self->{logger},
                                                         $self->{whoaim},
                                                         $self->{centreonesxd_config}->{timeout_vsphere},
                                                         \$self->{session1},
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{url}, 
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{username},
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{password})) {
                $self->{logger}->writeLogInfo("'" . $self->{whoaim} . "' Vsphere connection ok");
                $self->{logger}->writeLogInfo("'" . $self->{whoaim} . "' Create perf counters cache in progress");
                if (!centreon::esxd::common::cache_perf_counters($self)) {
                    $self->{last_time_vsphere} = time();
                    $self->{keeper_session_time} = time();
                    $self->{vsphere_connected} = 1;
                    $self->{logger}->writeLogInfo("'" . $self->{whoaim} . "' Create perf counters cache done");
                }
            }
        }

        ###
        # Manage session time
        ###
        if (defined($self->{keeper_session_time}) && (time() - $self->{keeper_session_time}) > ($self->{centreonesxd_config}->{refresh_keeper_session} * 60)) {
            my $stime;

            eval {
                $stime = $self->{session1}->get_service_instance()->CurrentTime();
                $self->{keeper_session_time} = time();
            };
            if ($@) {
                $self->{logger}->writeLogError("$@");
                $self->{logger}->writeLogError("'" . $self->{whoaim} . "' Ask a new connection");
                # Ask a new connection
                $self->{last_time_check} = time();
            } else {
                $self->{logger}->writeLogInfo("'" . $self->{whoaim} . "' Get current time = " . Data::Dumper::Dumper($stime));
            }
        }

        my $data_element;
        my @rh_set;
        if ($self->{vsphere_connected} == 0) {
            sleep(5);
        }
        if ($self->{stop} != 0) {
            sleep(1);
            next;
        }
        
        my $message = zmq_recvmsg($backend, ZMQ_DONTWAIT);
        if (defined($message)) {
            if ($self->{vsphere_connected}) {                
                $self->{logger}->writeLogInfo("vpshere '" . $self->{whoaim} . "' handler asking: $message");

                $self->{child_proc}->{pid} = fork;
                if (!$self->{child_proc}->{pid}) {
                    # Child
                    $self->{logger}->{log_mode} = 1 if ($self->{logger}->{log_mode} == 0);
                    my ($id, $name, @args) = split /\Q$self->{separatorin}\E/, $data_element;
                    $self->{global_id} = $id;
                    $self->{modules_registry}->{$name}->initArgs(@args);
                    $self->{modules_registry}->{$name}->run();
                    exit(0);
                }
            } else {
                #print $handle_writer_pipe "$id|-1|Vsphere connection error.\n";
            }
        } 
    }
}

sub create_vsphere_child {
    my ($self, %options) = @_;
    
    $self->{logger}->writeLogInfo("Create vsphere sub-process for '" . $options{vsphere_name} . "'");   
    $self->{whoaim} = $options{vsphere_name};

    $self->{child_vpshere_pid} = fork();
    if (!$self->{child_vpshere_pid}) {
        $self->vsphere_handler();
        exit(0);
    }
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 1;
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{child_vpshere_pid}} = { name => $self->{whoaim} };
}

sub run {
    my $self = shift;

    $self->SUPER::run();
    $self->{logger}->redirect_output();

    $self->{logger}->writeLogDebug("centreonesxd launched....");
    $self->{logger}->writeLogDebug("PID: $$");

    my $context = zmq_init();
    my $frontend = zmq_socket($context, ZMQ_ROUTER);

    zmq_bind($frontend, 'tcp://*:5700');
    zmq_bind($frontend, 'ipc://routing.ipc');
    
    if (!defined($frontend)) {
        $self->{logger}->writeLogError("Can't setup server: $!");
        exit(1);
    }
    
    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        $self->create_vsphere_child(vsphere_name => $_);
    }

    $self->{logger}->writeLogInfo("[Server accepting clients]");
    
    # Initialize poll set
    my @poll = (
        {
            socket  => $frontend,
            events  => ZMQ_POLLIN,
            callback => sub {
                while (1) {
                    # Process all parts of the message
                    my $message = zmq_recvmsg($frontend);
                    print "=== " . Data::Dumper::Dumper(zmq_msg_data($message)) . " ===\n";
                    $message = zmq_recvmsg($frontend);
                    print "=== " . Data::Dumper::Dumper(zmq_msg_data($message)) . " ===\n";
                                       
                    my $more = zmq_getsockopt($frontend, ZMQ_RCVMORE);
                    
                    #zmq_sendmsg($backend, $message, $more ? ZMQ_SNDMORE : 0);
                    last unless $more;
                    return 1;
                }
            }
        },
    );

    # Switch messages between sockets
    while (1) {
        #if ($self->{stop} == 1) {
            # No childs
        #    if (scalar(keys %{$self->{centreonesxd_config}->{vsphere_server}}) == 0) {
        #        $self->{logger}->writeLogInfo("Quit main process");
        #        exit(0);
        #    }
        #    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        #        $self->{logger}->writeLogInfo("Send STOP command to '$_' child.");
        #        my $send_msg = zmq_msg_init_data($_ . " STOP");
        #        zmq_msg_send($send_msg, $publisher, 0);
        #    }
        #    $self->{stop} = 2;
        #}
    
        zmq_poll(\@poll, 1000);
    }
}

1;

__END__