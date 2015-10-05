#!/usr/bin/perl
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

package centreon::script::centreon_vmware;

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
use centreon::vmware::common;
use centreon::vmware::connector;

my ($centreon_vmware, $frontend);

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use base qw(centreon::script);
use vars qw(%centreon_vmware_config);

my $VERSION = "2.0.0";
my %handlers = (TERM => {}, HUP => {}, CHLD => {});

my @load_modules = (
    'centreon::vmware::cmdalarmdatacenter',
    'centreon::vmware::cmdalarmhost',
    'centreon::vmware::cmdcountvmhost',
    'centreon::vmware::cmdcpuhost',
    'centreon::vmware::cmdcpuvm',
    'centreon::vmware::cmddatastorecountvm',
    'centreon::vmware::cmddatastoreio',
    'centreon::vmware::cmddatastoreiops',
    'centreon::vmware::cmddatastorehost',
    'centreon::vmware::cmddatastoresnapshot',
    'centreon::vmware::cmddatastorevm',
    'centreon::vmware::cmddatastoreusage',
    'centreon::vmware::cmdgetmap',
    'centreon::vmware::cmdhealthhost',
    'centreon::vmware::cmdlimitvm',
    'centreon::vmware::cmdlistdatacenters',
    'centreon::vmware::cmdlistdatastores',
    'centreon::vmware::cmdlistnichost',
    'centreon::vmware::cmdmemhost',
    'centreon::vmware::cmdmaintenancehost',
    'centreon::vmware::cmdmemvm',
    'centreon::vmware::cmdnethost',
    'centreon::vmware::cmdsnapshotvm',
    'centreon::vmware::cmdstatushost',
    'centreon::vmware::cmdstatusvm',
    'centreon::vmware::cmdswaphost',
    'centreon::vmware::cmdswapvm',
    'centreon::vmware::cmdthinprovisioningvm',
    'centreon::vmware::cmdtimehost',
    'centreon::vmware::cmdtoolsvm',
    'centreon::vmware::cmduptimehost',
    'centreon::vmware::cmdvmoperationcluster',
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("centreon_vmware",
        centreon_db_conn => 0,
        centstorage_db_conn => 0,
        noconfig => 1
    );

    bless $self, $class;
    $self->add_options(
        "config-extra=s" => \$self->{opt_extra},
    );

    %{$self->{centreon_vmware_default_config}} =
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
            retention_dir => '/var/lib/centreon/centplugins',
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
        $self->{opt_extra} = "/etc/centreon/centreon_vmware.pm";
    }
    if (-f $self->{opt_extra}) {
        require $self->{opt_extra};
    } else {
        $self->{logger}->writeLogInfo("Can't find extra config file $self->{opt_extra}");
    }

    $self->{centreon_vmware_config} = {%{$self->{centreon_vmware_default_config}}, %centreon_vmware_config};

    ##### Load modules
    $self->load_module(@load_modules);

    ##### credstore check #####
    if (defined($self->{centreon_vmware_config}->{credstore_use}) && defined($self->{centreon_vmware_config}->{credstore_file}) &&
        $self->{centreon_vmware_config}->{credstore_use} == 1 && -e "$self->{centreon_vmware_config}->{credstore_file}") {
        eval 'require VMware::VICredStore';
        if ($@) {
            $self->{logger}->writeLogError("Could not load module VMware::VICredStore");
            exit(1);
        }
        require VMware::VICredStore;

        if (VMware::VICredStore::init(filename => $self->{centreon_vmware_config}->{credstore_file}) == 0) {
            $self->{logger}->writeLogError("Credstore init failed: $@");
            exit(1);
        }

        ###
        # Get password
        ###
        foreach (keys %{$self->{centreon_vmware_config}->{vsphere_server}}) {
            my $lpassword = VMware::VICredStore::get_password(server => $_, username => $self->{centreon_vmware_config}->{vsphere_server}->{$_}->{username});
            if (!defined($lpassword)) {
                $self->{logger}->writeLogError("Can't get password for couple host='" . $_ . "', username='" . $self->{centreon_vmware_config}->{vsphere_server}->{$_}->{username} . "' : $@");
                exit(1);
            }
            $self->{centreon_vmware_config}->{vsphere_server}->{$_}->{password} = $lpassword;
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

                if ($self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{dynamic} == 0) {
                    $self->create_vsphere_child(vsphere_name => $self->{childs_vpshere_pid}->{$_}, dynamic => 0);
                } else {
                    $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' is dead. But we don't relaunch it (dynamic sub-process)");
                    delete $self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}};
                }
            } else {
                $self->{logger}->writeLogInfo("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' dead ???!!");
                $self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{running} = 0;
            }
            
            delete $self->{childs_vpshere_pid}->{$_};
        }
    }

    my $count = 0;
    foreach (keys %{$self->{centreon_vmware_config}->{vsphere_server}}) {
        if ($self->{centreon_vmware_config}->{vsphere_server}->{$_}->{running} == 1) {
            $count++;
        }
        if ($self->{centreon_vmware_config}->{vsphere_server}->{$_}->{dynamic} == 1 &&
            time() - $self->{centreon_vmware_config}->{dynamic_timeout_kill} > $self->{centreon_vmware_config}->{vsphere_server}->{$_}->{last_request}) {
            $self->{logger}->writeLogError("Send TERM signal for process '" . $_ . "': too many times without requests. We clean it.");
            kill('TERM', $self->{centreon_vmware_config}->{vsphere_server}->{$_}->{pid});
        }        
    }

    return $count;
}

sub waiting_ready {
    my ($self, %options) = @_;

    return 1 if ($self->{centreon_vmware_config}->{vsphere_server}->{$options{container}}->{ready} == 1);
    
    my $time = time();
    # We wait 10 seconds
    while ($self->{centreon_vmware_config}->{vsphere_server}->{$options{container}}->{ready} == 0 && 
           time() - $time < 10) {
        zmq_poll($self->{poll}, 5000);
    }
    
    if ($self->{centreon_vmware_config}->{vsphere_server}->{$options{container}}->{ready} == 0) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "connector still not ready.");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
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
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    
    my $container = md5_hex($options{result}->{vsphere_address} . $options{result}->{vsphere_username} . $options{result}->{vsphere_password});
    # Need to create fork
    if (!defined($self->{centreon_vmware_config}->{vsphere_server}->{$container})) {
        $self->{centreon_vmware_config}->{vsphere_server}->{$container} = { url => 'https://' . $options{result}->{vsphere_address} . '/sdk',
                                                                         username => $options{result}->{vsphere_username},
                                                                         password => $options{result}->{vsphere_password},
                                                                         last_request => time() };
        $self->{logger}->writeLogError(sprintf("Dynamic creation: identity = %s [address: %s] [username: %s] [password: %s]", 
                                               $container, $options{result}->{vsphere_address}, $options{result}->{vsphere_username}, $options{result}->{vsphere_password}));
        $centreon_vmware->create_vsphere_child(vsphere_name => $container, dynamic => 1);
    }
    
    return if ($self->waiting_ready(container => $container, manager => $options{manager},
                                    identity => $options{identity}) == 0);
    
    $self->{centreon_vmware_config}->{vsphere_server}->{$container}->{last_request} = time();
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
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($result->{command} eq 'stats') {
        centreon::vmware::common::stats_info(manager => $options{manager},
                                           counters => $self->{counter_stats});
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if (!defined($self->{modules_registry}->{$result->{command}})) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                                short_msg => "Unknown method name '$result->{command}'");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($self->{modules_registry}->{$result->{command}}->checkArgs(manager => $options{manager},
                                                                   arguments => $result)) {
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    
    # Mode dynamic
    if (defined($result->{vsphere_address}) && $result->{vsphere_address} ne '') {
        $self->request_dynamic(result => $result, %options);
        return ;
    }
    
    if (!defined($self->{centreon_vmware_config}->{vsphere_server}->{$result->{container}})) {
        $options{manager}->{output}->output_add(severity => 'UNKNOWN',
                                       short_msg => "Unknown container name '$result->{container}'");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
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
    
    centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, 
                                     identity => $identity, stdout => $options{data});
}

sub router_event {
    while (1) {
        # Process all parts of the message
        my $message = zmq_recvmsg($frontend);
        my $identity = zmq_msg_data($message);
        $message = zmq_recvmsg($frontend);
       
        my $data = zmq_msg_data($message);
        
        my $manager = centreon::vmware::common::init_response();
        if ($centreon_vmware->{stop} != 0) {
            # We quit so we say we're leaving ;)
            $manager->{output}->output_add(severity => 'UNKNOWN',
                                           short_msg => 'Daemon is restarting/stopping...');
            centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $identity);
        } elsif ($data =~ /^REQCLIENT\s+(.*)$/msi) {
            $centreon_vmware->request(identity => $identity, data => $1, manager => $manager);
        } elsif ($data =~ /^RESPSERVER2\s+(.*)$/msi) {
            $centreon_vmware->repserver(data => $1, manager => $manager);
        } elsif ($data =~ /^READY/msi) {
            $identity =~ /server-(.*)/;
            $centreon_vmware->{centreon_vmware_config}->{vsphere_server}->{$1}->{ready} = 1;
        }

        my $more = zmq_getsockopt($frontend, ZMQ_RCVMORE);        
        last unless $more;
    }
}

sub create_vsphere_child {
    my ($self, %options) = @_;

    $self->{whoaim} = $options{vsphere_name};
    $self->{centreon_vmware_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 0;
    $self->{centreon_vmware_config}->{vsphere_server}->{$self->{whoaim}}->{ready} = 0;
    $self->{logger}->writeLogInfo("Create vsphere sub-process for '" . $options{vsphere_name} . "'");

    my $child_vpshere_pid = fork();
    if (!defined($child_vpshere_pid)) {
        $self->{logger}->writeLogError("Cannot fork for '" . $options{vsphere_name} . "': $!");   
        return -1;
    }
    if ($child_vpshere_pid == 0) {
        my $connector = centreon::vmware::connector->new(name => $self->{whoaim},
                                                         modules_registry => $self->{modules_registry},
                                                         module_date_parse_loaded => $self->{module_date_parse_loaded},
                                                         config => $self->{centreon_vmware_config},
                                                         logger => $self->{logger});
        $connector->run();
        exit(0);
    }
    $self->{childs_vpshere_pid}->{$child_vpshere_pid} = $self->{whoaim};
    $self->{centreon_vmware_config}->{vsphere_server}->{$self->{whoaim}}->{running} = 1;
    $self->{centreon_vmware_config}->{vsphere_server}->{$self->{whoaim}}->{dynamic} = $options{dynamic};
    $self->{centreon_vmware_config}->{vsphere_server}->{$self->{whoaim}}->{pid} = $child_vpshere_pid;
}

sub bind_ipc {
    my ($self, %options) = @_;
    
    if (zmq_bind($options{socket}, 'ipc://' . $options{ipc_file}) == -1) {
        $self->{logger}->writeLogError("Cannot bind ipc '$options{ipc_file}': $!");
        # try create dir
        $self->{logger}->writeLogError("Maybe dirctory not exist. We try to create it!!!");
        if (!mkdir(dirname($options{ipc_file}))) {
            zmq_close($options{socket});
            exit(1);
        }
        if (zmq_bind($options{socket}, 'ipc://' . $options{ipc_file}) == -1) {
            zmq_close($options{socket});
            exit(1);
        }
    }
}

sub run {
    $centreon_vmware = shift;

    $centreon_vmware->SUPER::run();
    $centreon_vmware->{logger}->redirect_output();

    $centreon_vmware->{logger}->writeLogDebug("centreon_vmware launched....");
    $centreon_vmware->{logger}->writeLogDebug("PID: $$");

    my $context = zmq_init();
    $frontend = zmq_socket($context, ZMQ_ROUTER);
    if (!defined($frontend)) {
        $centreon_vmware->{logger}->writeLogError("Can't setup server: $!");
        exit(1);
    }

    zmq_setsockopt($frontend, ZMQ_LINGER, 0); # we discard    
    zmq_bind($frontend, 'tcp://*:' . $centreon_vmware->{centreon_vmware_config}->{port});
    $centreon_vmware->bind_ipc(socket => $frontend, ipc_file => '/tmp/centreon_vmware/routing.ipc');

    foreach (keys %{$centreon_vmware->{centreon_vmware_config}->{vsphere_server}}) {
        $centreon_vmware->{counter_stats}->{$_} = 0;
        $centreon_vmware->create_vsphere_child(vsphere_name => $_, dynamic => 0);
    }

    $centreon_vmware->{logger}->writeLogInfo("[Server accepting clients]");
    
    # Initialize poll set
    $centreon_vmware->{poll} = [
        {
            socket  => $frontend,
            events  => ZMQ_POLLIN,
            callback => \&router_event,
        },
    ];

    # Switch messages between sockets
    while (1) {
        my $count = $centreon_vmware->verify_child_vsphere();

        if ($centreon_vmware->{stop} == 1) {
            # No childs
            if ($count == 0) {
                $centreon_vmware->{logger}->writeLogInfo("Quit main process");
                zmq_close($frontend);
                exit(0);
            }
        }
    
        zmq_poll($centreon_vmware->{poll}, 5000);
    }
}

1;

__END__