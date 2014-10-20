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

my ($centreonesxd, $frontend, $backend);

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
    $self->{childs_vpshere_pid} = {};
    $self->{session1} = undef;
    $self->{counter} = 0;
    $self->{whoaim} = undef; # to know which vsphere to connect
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
    
    # Some dead process. need to relaunch it
    foreach (keys %{$self->{return_child}}) {
        delete $self->{return_child}->{$_};
        
        # We need to quit
        if ($self->{stop} != 0) {
            my $name = $self->{childs_vpshere_pid}->{$_};
            $self->{centreonesxd_config}->{vsphere_server}->{$name}->{running} = 0;            
            next;
        }
        
        if (defined($self->{childs_vpshere_pid}->{$_})) {
            $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' dead ???!! We relaunch it");
            $self->create_vsphere_child(vsphere_name => $self->{childs_vpshere_pid}->{$_});
            delete $self->{childs_vpshere_pid}->{$_};
        }
    }
    
    my $count = 0;
    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        if ($self->{centreonesxd_config}->{vsphere_server}->{$_}->{running} == 1) {
            $count++;
        }
    }
    
    return $count;
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

sub router_event {
    while (1) {
        # Process all parts of the message
        my $message = zmq_recvmsg($frontend);
        my $identity = zmq_msg_data($message);
        $message = zmq_recvmsg($frontend);
       
        my $data = zmq_msg_data($message);
        
        my $manager = centreon::esxd::common::init_response();
        
        if ($centreonesxd->{stop} != 0) {
            # We quit so we say we're leaving ;)
            $manager->{output}->output_add(severity => 'UNKNOWN',
                                           short_msg => 'Daemon is restarting...');
            centreon::esxd::common::response(endpoint => $frontend, identity => $identity);
        } elsif ($data =~ /^REQCLIENT\s+(.*)$/) {
            
            
            
            zmq_sendmsg($frontend, "server-" . $1, ZMQ_SNDMORE);
            zmq_sendmsg($frontend, $data);

            my $manager = centreon::esxd::common::init_response();
            $manager->{output}->output_add(severity => 'OK',
                                           short_msg => 'ma reponse enfin');
            centreon::esxd::common::response(endpoint => $frontend, identity => $identity);
        }
        
        my $more = zmq_getsockopt($frontend, ZMQ_RCVMORE);        
        last unless $more;
    }
}

sub vsphere_event {
    while (1) {
        # Process all parts of the message
        my $message = zmq_recvmsg($backend);
        print "=== " . Data::Dumper::Dumper(zmq_msg_data($message)) . " ===\n";
        
        zmq_sendmsg($backend, 'bien tutu');
        
        print "=PLAPLA=\n";
        my $data = zmq_msg_data($message);
        if (defined($message)) {
            if ($centreonesxd->{vsphere_connected}) {                
                $centreonesxd->{logger}->writeLogInfo("vpshere '" . $centreonesxd->{whoaim} . "' handler asking: $message");

                $centreonesxd->{child_proc}->{pid} = fork;
                if (!$centreonesxd->{child_proc}->{pid}) {
                    # Child
                    $centreonesxd->{logger}->{log_mode} = 1 if ($centreonesxd->{logger}->{log_mode} == 0);
                    my ($id, $name, @args) = split /\Q$centreonesxd->{separatorin}\E/, $message;
                    $centreonesxd->{global_id} = $id;
                    $centreonesxd->{modules_registry}->{$name}->initArgs(@args);
                    $centreonesxd->{modules_registry}->{$name}->run();
                    exit(0);
                }
            } else {
                #print $handle_writer_pipe "$id|-1|Vsphere connection error.\n";
            }
        } 

        my $more = zmq_getsockopt($backend, ZMQ_RCVMORE);
        #zmq_sendmsg($backend, $message, $more ? ZMQ_SNDMORE : 0);
        last unless $more;
    }
}

sub vsphere_handler {
    $centreonesxd = shift;
    my $timeout_process;

    my $context = zmq_init();

    $backend = zmq_socket($context, ZMQ_DEALER);
    zmq_setsockopt($backend, ZMQ_IDENTITY, "server-" . $centreonesxd->{whoaim});
    zmq_connect($backend, 'ipc://routing.ipc');
    #zmq_sendmsg($backend, 'ready');
    
    # Initialize poll set
    my @poll = (
        {
            socket  => $backend,
            events  => ZMQ_POLLIN,
            callback => \&vsphere_event,
        },
    );
    
    while (1) {
        my $progress = $centreonesxd->verify_child();

        #####
        # Manage ending
        #####
        if ($centreonesxd->{stop} && $timeout_process > $centreonesxd->{centreonesxd_config}->{timeout_kill}) {
            $centreonesxd->{logger}->writeLogError("'" . $centreonesxd->{whoaim} . "' Kill child not gently.");
            foreach (keys %{$centreonesxd->{child_proc}}) {
                kill('INT', $centreonesxd->{child_proc}->{$_}->{pid});
            }
            $progress = 0;
        }
        if ($centreonesxd->{stop} && !$progress) {
            if ($centreonesxd->{vsphere_connected}) {
                eval {
                    $centreonesxd->{session1}->logout();
                };
            }            
            exit (0);
        }

        ###
        # Manage vpshere connection
        ###
        if (defined($centreonesxd->{last_time_vsphere}) && defined($centreonesxd->{last_time_check}) 
            && $centreonesxd->{last_time_vsphere} < $centreonesxd->{last_time_check}) {
            $centreonesxd->{logger}->writeLogError("'" . $centreonesxd->{whoaim} . "' Disconnect");
            $centreonesxd->{vsphere_connected} = 0;
            eval {
                $centreonesxd->{session1}->logout();
            };
        }
        if ($centreonesxd->{vsphere_connected} == 0) {
            if (!centreon::esxd::common::connect_vsphere($centreonesxd->{logger},
                                                         $centreonesxd->{whoaim},
                                                         $centreonesxd->{centreonesxd_config}->{timeout_vsphere},
                                                         \$centreonesxd->{session1},
                                                         $centreonesxd->{centreonesxd_config}->{vsphere_server}->{$centreonesxd->{whoaim}}->{url}, 
                                                         $centreonesxd->{centreonesxd_config}->{vsphere_server}->{$centreonesxd->{whoaim}}->{username},
                                                         $centreonesxd->{centreonesxd_config}->{vsphere_server}->{$centreonesxd->{whoaim}}->{password})) {
                $centreonesxd->{logger}->writeLogInfo("'" . $centreonesxd->{whoaim} . "' Vsphere connection ok");
                $centreonesxd->{logger}->writeLogInfo("'" . $centreonesxd->{whoaim} . "' Create perf counters cache in progress");
                if (!centreon::esxd::common::cache_perf_counters($centreonesxd)) {
                    $centreonesxd->{last_time_vsphere} = time();
                    $centreonesxd->{keeper_session_time} = time();
                    $centreonesxd->{vsphere_connected} = 1;
                    $centreonesxd->{logger}->writeLogInfo("'" . $centreonesxd->{whoaim} . "' Create perf counters cache done");
                }
            }
        }

        ###
        # Manage session time
        ###
        if (defined($centreonesxd->{keeper_session_time}) && 
            (time() - $centreonesxd->{keeper_session_time}) > ($centreonesxd->{centreonesxd_config}->{refresh_keeper_session} * 60)) {
            my $stime;

            eval {
                $stime = $centreonesxd->{session1}->get_service_instance()->CurrentTime();
                $centreonesxd->{keeper_session_time} = time();
            };
            if ($@) {
                $centreonesxd->{logger}->writeLogError("$@");
                $centreonesxd->{logger}->writeLogError("'" . $centreonesxd->{whoaim} . "' Ask a new connection");
                # Ask a new connection
                $centreonesxd->{last_time_check} = time();
            } else {
                $centreonesxd->{logger}->writeLogInfo("'" . $centreonesxd->{whoaim} . "' Get current time = " . Data::Dumper::Dumper($stime));
            }
        }

        my $data_element;
        my @rh_set;
        if ($centreonesxd->{vsphere_connected} == 0) {
            sleep(5);
        }
        if ($centreonesxd->{stop} != 0) {
            sleep(1);
            next;
        }
        
        print "====chaton===\n";
        zmq_poll(\@poll, 5000);
    }
}

sub create_vsphere_child {
    my ($self, %options) = @_;

    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 0;
    $self->{logger}->writeLogInfo("Create vsphere sub-process for '" . $options{vsphere_name} . "'");   
    $self->{whoaim} = $options{vsphere_name};

    my $child_vpshere_pid = fork();
    if ($child_vpshere_pid == 0) {
        $self->vsphere_handler();
        exit(0);
    }
    $self->{childs_vpshere_pid}->{$child_vpshere_pid} = $self->{whoaim};
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 1;
}

sub run {
    $centreonesxd = shift;

    $centreonesxd->SUPER::run();
    $centreonesxd->{logger}->redirect_output();

    $centreonesxd->{logger}->writeLogDebug("centreonesxd launched....");
    $centreonesxd->{logger}->writeLogDebug("PID: $$");

    my $context = zmq_init();
    $frontend = zmq_socket($context, ZMQ_ROUTER);

    zmq_bind($frontend, 'tcp://*:5700');
    zmq_bind($frontend, 'ipc://routing.ipc');
    
    if (!defined($frontend)) {
        $centreonesxd->{logger}->writeLogError("Can't setup server: $!");
        exit(1);
    }
    
    foreach (keys %{$centreonesxd->{centreonesxd_config}->{vsphere_server}}) {
        $centreonesxd->create_vsphere_child(vsphere_name => $_);
    }

    $centreonesxd->{logger}->writeLogInfo("[Server accepting clients]");
    
    # Initialize poll set
    my @poll = (
        {
            socket  => $frontend,
            events  => ZMQ_POLLIN,
            callback => \&router_event,
        },
    );

    # Switch messages between sockets
    while (1) {
        my $count = $centreonesxd->verify_child_vsphere();

        if ($centreonesxd->{stop} == 1) {
            # No childs
            if ($count == 0) {
                $centreonesxd->{logger}->writeLogInfo("Quit main process");
                exit(0);
            }
            foreach (keys %{$centreonesxd->{centreonesxd_config}->{vsphere_server}}) {
                $centreonesxd->{logger}->writeLogInfo("Send STOP command to '$_' child.");
                zmq_sendmsg($frontend, "server-" . $_, ZMQ_SNDMORE);
                zmq_sendmsg($frontend, "STOP");
            }
            $centreonesxd->{stop} = 2;
        }
    
        zmq_poll(\@poll, 5000);
    }
}

1;

__END__