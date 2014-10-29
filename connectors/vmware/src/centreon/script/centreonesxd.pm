#!/usr/bin/perl

package centreon::script::centreonesxd;

use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use ZMQ::LibZMQ3;
use ZMQ::Constants qw(:all);
use File::Basename;
use Digest::MD5 qw(md5_hex);
use POSIX ":sys_wait_h";
use JSON;
use centreon::script;
use centreon::esxd::common;
use centreon::esxd::connector;

my ($centreonesxd, $frontend);

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use base qw(centreon::script);
use vars qw(%centreonesxd_config);

my $VERSION = "1.6.0";
my %handlers = (TERM => {}, HUP => {}, CHLD => {});

my @load_modules = (
    'centreon::esxd::cmdcountvmhost',
    'centreon::esxd::cmdcpuhost',
    'centreon::esxd::cmdcpuvm',
    'centreon::esxd::cmddatastoreio',
    'centreon::esxd::cmddatastoreiops',
    'centreon::esxd::cmddatastorehost',
    'centreon::esxd::cmddatastoresnapshot',
    'centreon::esxd::cmddatastorevm',
    'centreon::esxd::cmddatastoreusage',
    'centreon::esxd::cmdgetmap',
    'centreon::esxd::cmdhealthhost',
    'centreon::esxd::cmdlimitvm',
    'centreon::esxd::cmdlistdatastores',
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
            dynamic_timeout_kill => 86400,
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

    $self->{return_child} = {};
    $self->{stop} = 0;
    $self->{childs_vpshere_pid} = {};
    $self->{counter_stats} = {};
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
    
    foreach (keys %{$self->{childs_vpshere_pid}}) {
        kill('TERM', $_);
        $self->{logger}->writeLogInfo("Send -TERM signal to '" . $self->{childs_vpshere_pid}->{$_} . "' process..");
    }
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

sub load_module {
    my $self = shift;

    for (@_) {
        (my $file = "$_.pm") =~ s{::}{/}g;
        require $file;
        my $obj = $_->new($self->{logger});
        $self->{modules_registry}->{$obj->getCommandName()} = $obj;
    }    
}

sub verify_child_vsphere {
    my $self = shift;
    
    # Some dead process. need to relaunch it
    foreach (keys %{$self->{return_child}}) {
        delete $self->{return_child}->{$_};
        
        if (defined($self->{childs_vpshere_pid}->{$_})) {
            if ($self->{stop} == 0) {
                $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "'???!! we relaunch it!!!");

                if ($self->{centreonesxd_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{dynamic} == 0) {
                    $self->create_vsphere_child(vsphere_name => $self->{childs_vpshere_pid}->{$_}, dynamic => 0);
                } else {
                    $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' is dead. But we don't relaunch it (dynamic sub-process)");
                    delete $self->{centreonesxd_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}};
                }
            } else {
                $self->{logger}->writeLogInfo("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' dead ???!!");
                $self->{centreonesxd_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{running} = 0;
            }
            
            delete $self->{childs_vpshere_pid}->{$_};
        }
    }

    my $count = 0;
    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        if ($self->{centreonesxd_config}->{vsphere_server}->{$_}->{running} == 1) {
            $count++;
        }
        if ($self->{centreonesxd_config}->{vsphere_server}->{$_}->{dynamic} == 1 &&
            time() - $self->{centreonesxd_config}->{dynamic_timeout_kill} > $self->{centreonesxd_config}->{vsphere_server}->{$_}->{last_request}) {
            $self->{logger}->writeLogError("Send TERM signal for process '" . $_ . "': too many times without requests. We clean it.");
            kill('TERM', $self->{centreonesxd_config}->{vsphere_server}->{$_}->{pid});
        }        
    }

    return $count;
}

sub waiting_ready {
    my ($self, %options) = @_;

    return 1 if ($self->{centreonesxd_config}->{vsphere_server}->{$options{container}}->{ready} == 1);
    
    my $time = time();
    # We wait 10 seconds
    while ($self->{centreonesxd_config}->{vsphere_server}->{$options{container}}->{ready} == 0 && 
           time() - $time < 10) {
        zmq_poll($self->{poll}, 5000);
    }
    
    if ($self->{centreonesxd_config}->{vsphere_server}->{$options{container}}->{ready} == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "connector still not ready.");
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return 0;
    }
    
    return 1;
}

sub request_dynamic {
    my ($self, %options) = @_;

    if (!defined($options{result}->{vsphere_username}) || $options{result}->{vsphere_username} eq '' ||
        !defined($options{result}->{vsphere_password}) || $options{result}->{vsphere_password} eq '') {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Please set vsphere username or password");
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    
    my $container = md5_hex($options{result}->{vsphere_address} . $options{result}->{vsphere_username} . $options{result}->{vsphere_password});
    # Need to create fork
    if (!defined($self->{centreonesxd_config}->{vsphere_server}->{$container})) {
        $self->{centreonesxd_config}->{vsphere_server}->{$container} = { url => 'https://' . $options{result}->{vsphere_address} . '/sdk',
                                                                         username => $options{result}->{vsphere_username},
                                                                         password => $options{result}->{vsphere_password},
                                                                         last_request => time() };
        $self->{logger}->writeLogError(sprintf("Dynamic creation: identity = %s [address: %s] [username: %s] [password: %s]", 
                                               $container, $options{result}->{vsphere_address}, $options{result}->{vsphere_username}, $options{result}->{vsphere_password}));
        $centreonesxd->create_vsphere_child(vsphere_name => $container, dynamic => 1);
    }
    
    return if ($self->waiting_ready(container => $container, manager => $options{manager},
                                    identity => $options{identity}) == 0);
    
    $self->{centreonesxd_config}->{vsphere_server}->{$container}->{last_request} = time();
    my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;
    zmq_sendmsg($frontend, "server-" . $container, $flag);
    zmq_sendmsg($frontend, 'REQCLIENT ' . $options{data}, ZMQ_NOBLOCK);
}

sub request {
    my ($self, %options) = @_;
    
    # Decode json
    my $result;
    eval {
        $result = JSON->new->utf8->decode($options{data});
    };
    if ($@) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Cannot decode json result: $@");
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($result->{command} eq 'stats') {
        centreon::esxd::common::stats_info(manager => $options{manager},
                                           counters => $self->{counter_stats});
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if (!defined($self->{modules_registry}->{$result->{command}})) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Unknown method name '$result->{command}'");
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($self->{modules_registry}->{$result->{command}}->checkArgs(manager => $options{manager},
                                                                   arguments => $result)) {
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    
    # Mode dynamic
    if (defined($result->{vsphere_address}) && $result->{vsphere_address} ne '') {
        $self->request_dynamic(result => $result, %options);
        return ;
    }
    
    if (!defined($self->{centreonesxd_config}->{vsphere_server}->{$result->{container}})) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                       short_msg => "Unknown container name '$result->{container}'");
        centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }

    return if ($self->waiting_ready(container => $result->{container}, manager => $options{manager},
                                    identity => $options{identity}) == 0);
    
    $self->{counter_stats}->{$result->{container}}++;
    my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;
    zmq_sendmsg($frontend, "server-" . $result->{container}, $flag);
    zmq_sendmsg($frontend, 'REQCLIENT ' . $options{data}, ZMQ_NOBLOCK);
}

sub repserver {
    my ($self, %options) = @_;
    
    # Decode json
    my $result;
    eval {
        $result = JSON->new->utf8->decode($options{data});
    };
    if ($@) {
        $self->{logger}->writeLogError("Cannot decode JSON: $@ (options{data}");
        return ;
    }
    
    $result->{plugin}->{name} =~ /^client-(.*)$/;
    my $identity = 'client-' . pack('H*', $1);
    
    centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, 
                                     identity => $identity, stdout => $options{data});
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
                                           short_msg => 'Daemon is restarting/stopping...');
            centreon::esxd::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $identity);
        } elsif ($data =~ /^REQCLIENT\s+(.*)$/msi) {
            $centreonesxd->request(identity => $identity, data => $1, manager => $manager);
        } elsif ($data =~ /^RESPSERVER2\s+(.*)$/msi) {
            $centreonesxd->repserver(data => $1, manager => $manager);
        } elsif ($data =~ /^READY/msi) {
            $identity =~ /server-(.*)/;
            $centreonesxd->{centreonesxd_config}->{vsphere_server}->{$1}->{ready} = 1;
        }

        my $more = zmq_getsockopt($frontend, ZMQ_RCVMORE);        
        last unless $more;
    }
}

sub create_vsphere_child {
    my ($self, %options) = @_;

    $self->{whoaim} = $options{vsphere_name};
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 0;
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{ready} = 0;
    $self->{logger}->writeLogInfo("Create vsphere sub-process for '" . $options{vsphere_name} . "'");   

    my $child_vpshere_pid = fork();
    if ($child_vpshere_pid == 0) {
        my $connector = centreon::esxd::connector->new(name => $self->{whoaim},
                                                       modules_registry => $self->{modules_registry},
                                                       module_date_parse_loaded => $self->{module_date_parse_loaded},
                                                       config => $self->{centreonesxd_config},
                                                       logger => $self->{logger});
        $connector->run();
        exit(0);
    }
    $self->{childs_vpshere_pid}->{$child_vpshere_pid} = $self->{whoaim};
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 1;
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{dynamic} = $options{dynamic};
    $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{pid} = $child_vpshere_pid;
}

sub run {
    $centreonesxd = shift;

    $centreonesxd->SUPER::run();
    $centreonesxd->{logger}->redirect_output();

    $centreonesxd->{logger}->writeLogDebug("centreonesxd launched....");
    $centreonesxd->{logger}->writeLogDebug("PID: $$");

    my $context = zmq_init();
    $frontend = zmq_socket($context, ZMQ_ROUTER);

    zmq_setsockopt($frontend, ZMQ_LINGER, 0); # we discard    
    zmq_bind($frontend, 'tcp://*:5700');
    zmq_bind($frontend, 'ipc://routing.ipc');
    
    if (!defined($frontend)) {
        $centreonesxd->{logger}->writeLogError("Can't setup server: $!");
        exit(1);
    }
    
    foreach (keys %{$centreonesxd->{centreonesxd_config}->{vsphere_server}}) {
        $centreonesxd->{counter_stats}->{$_} = 0;
        $centreonesxd->create_vsphere_child(vsphere_name => $_, dynamic => 0);
    }

    $centreonesxd->{logger}->writeLogInfo("[Server accepting clients]");
    
    # Initialize poll set
    $centreonesxd->{poll} = [
        {
            socket  => $frontend,
            events  => ZMQ_POLLIN,
            callback => \&router_event,
        },
    ];

    # Switch messages between sockets
    while (1) {
        my $count = $centreonesxd->verify_child_vsphere();

        if ($centreonesxd->{stop} == 1) {
            # No childs
            if ($count == 0) {
                $centreonesxd->{logger}->writeLogInfo("Quit main process");
                zmq_close($frontend);
                exit(0);
            }
        }
    
        zmq_poll($centreonesxd->{poll}, 5000);
    }
}

1;

__END__