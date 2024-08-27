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
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use File::Basename;
use Digest::MD5 qw(md5_hex);
use POSIX ":sys_wait_h";
use JSON::XS;
use centreon::vmware::script;
use centreon::vmware::common;
use centreon::vmware::connector;

my ($centreon_vmware, $frontend);

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
        IO::Socket::SSL::set_ctx_defaults( SSL_verify_mode => 0, SSL_no_shutdown => 1 );
    };
}

use base qw(centreon::vmware::script);
use vars qw(%centreon_vmware_config);

my $VERSION = '3.2.6';
my %handlers = (TERM => {}, HUP => {}, CHLD => {});

my @load_modules = (
    'centreon::vmware::cmdalarmdatacenter',
    'centreon::vmware::cmdalarmhost',
    'centreon::vmware::cmdcountvmhost',
    'centreon::vmware::cmdcpucluster',
    'centreon::vmware::cmdcpuhost',
    'centreon::vmware::cmdcpuvm',
    'centreon::vmware::cmddatastorecountvm',
    'centreon::vmware::cmddatastoreio',
    'centreon::vmware::cmddatastoreiops',
    'centreon::vmware::cmddatastorehost',
    'centreon::vmware::cmddatastoresnapshot',
    'centreon::vmware::cmddatastorevm',
    'centreon::vmware::cmddatastoreusage',
    'centreon::vmware::cmddevicevm',
    'centreon::vmware::cmddiscovery',
    'centreon::vmware::cmdgetmap',
    'centreon::vmware::cmdhealthhost',
    'centreon::vmware::cmdlicenses',
    'centreon::vmware::cmdlimitvm',
    'centreon::vmware::cmdlistclusters',
    'centreon::vmware::cmdlistdatacenters',
    'centreon::vmware::cmdlistdatastores',
    'centreon::vmware::cmdlistnichost',
    'centreon::vmware::cmdmemhost',
    'centreon::vmware::cmdmaintenancehost',
    'centreon::vmware::cmdmemvm',
    'centreon::vmware::cmdnethost',
    'centreon::vmware::cmdnetvm',
    'centreon::vmware::cmdservicehost',
    'centreon::vmware::cmdsnapshotvm',
    'centreon::vmware::cmdstatuscluster',
    'centreon::vmware::cmdstatushost',
    'centreon::vmware::cmdstatusvm',
    'centreon::vmware::cmdstoragehost',
    'centreon::vmware::cmdswaphost',
    'centreon::vmware::cmdswapvm',
    'centreon::vmware::cmdthinprovisioningvm',
    'centreon::vmware::cmdtimehost',
    'centreon::vmware::cmdtoolsvm',
    'centreon::vmware::cmduptimehost',
    'centreon::vmware::cmdvmoperationcluster',
    'centreon::vmware::cmdvsanclusterusage'
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new('centreon_vmware');

    bless $self, $class;
    $self->add_options(
        'config-extra=s' => \$self->{opt_extra}
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
            bind => '*',
            port => 5700,
            ipc_file => '/tmp/centreon_vmware/routing.ipc',
            case_insensitive => 0,
            vsphere_server => {
                #'default' => {'url' => 'https://XXXXXX/sdk',
                #              'username' => 'XXXXX',
                #              'password' => 'XXXXX'},
                #'testvc' =>  {'url' => 'https://XXXXXX/sdk',
                #              'username' => 'XXXXX',
                #              'password' => 'XXXXXX'}
            },
            vsan_sdk_path => '/usr/local/share/perl5/VMware'
        );

    $self->{return_child} = {};
    $self->{stop} = 0;
    $self->{childs_vpshere_pid} = {};
    $self->{counter_stats} = {};
    $self->{whoaim} = undef; # to know which vsphere to connect
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

    foreach my $name (keys %{$self->{centreon_vmware_config}->{vsphere_server}}) {
        my $iname = lc($name);
        $self->{centreon_vmware_config}->{vsphere_server}->{$iname} = delete $self->{centreon_vmware_config}->{vsphere_server}->{$name};
    }

    ##### Load modules
    $self->load_module(@load_modules);

    $self->{vsan_enabled} = 0;
    eval {
        centreon::vmware::common::load_vsanmgmt_binding_files(
            path => $self->{centreon_vmware_config}->{vsan_sdk_path},
            files => ['VIM25VsanmgmtStub.pm', 'VIM25VsanmgmtRuntime.pm'],
        );
        $self->{vsan_enabled} = 1;
    };

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
        my $obj = $_->new(logger => $self->{logger}, case_insensitive => $self->{centreon_vmware_config}->{case_insensitive});
        $self->{modules_registry}->{ $obj->getCommandName() } = $obj;
    }    
}

sub verify_child_vsphere {
    my $self = shift;

    # Some dead process. need to relaunch it
    foreach (keys %{$self->{return_child}}) {
        delete $self->{return_child}->{$_};

        if (defined($self->{childs_vpshere_pid}->{$_})) {
            if ($self->{stop} == 0) {
                my $name = $self->{childs_vpshere_pid}->{$_};
                $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "'???!! we relaunch it!!!");

                if ($self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{dynamic} == 0) {
                    # Can have the same pid (so we delete before)
                    delete $self->{childs_vpshere_pid}->{$_};
                    $self->create_vsphere_child(vsphere_name => $name, dynamic => 0);
                } else {
                    $self->{logger}->writeLogError("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' is dead. But we don't relaunch it (dynamic sub-process)");
                    delete $self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}};
                    delete $self->{childs_vpshere_pid}->{$_};
                }
            } else {
                $self->{logger}->writeLogInfo("Sub-process for '" . $self->{childs_vpshere_pid}->{$_} . "' dead ???!!");
                $self->{centreon_vmware_config}->{vsphere_server}->{$self->{childs_vpshere_pid}->{$_}}->{running} = 0;
                delete $self->{childs_vpshere_pid}->{$_};
            }
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

    # Need to check if we need to relaunch (maybe it can have a problem)
    $self->check_childs();

    my $time = time();
    # We wait 10 seconds
    while ($self->{centreon_vmware_config}->{vsphere_server}->{$options{container}}->{ready} == 0 && 
           time() - $time < 10) {
        zmq_poll($self->{poll}, 5000);
    }

    if ($self->{centreon_vmware_config}->{vsphere_server}->{$options{container}}->{ready} == 0) {
        centreon::vmware::common::set_response(code => -1, short_message => "connector still not ready.");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return 0;
    }

    return 1;
}

sub request_dynamic {
    my ($self, %options) = @_;

    if (!defined($options{result}->{vsphere_username}) || $options{result}->{vsphere_username} eq '' ||
        !defined($options{result}->{vsphere_password}) || $options{result}->{vsphere_password} eq '') {
        centreon::vmware::common::set_response(code => -1, short_message => "Please set vsphere username or password");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }

    my $container = md5_hex($options{result}->{vsphere_address} . $options{result}->{vsphere_username} . $options{result}->{vsphere_password});
    # Need to create fork
    if (!defined($self->{centreon_vmware_config}->{vsphere_server}->{$container})) {
        $self->{centreon_vmware_config}->{vsphere_server}->{$container} = {
            url => 'https://' . $options{result}->{vsphere_address} . '/sdk',
            username => $options{result}->{vsphere_username},
            password => $options{result}->{vsphere_password},
            last_request => time()
        };
        $self->{logger}->writeLogError(
            sprintf(
                "Dynamic creation: identity = %s [address: %s] [username: %s] [password: %s]", 
                $container, $options{result}->{vsphere_address}, $options{result}->{vsphere_username}, $options{result}->{vsphere_password}
            )
        );
        $centreon_vmware->create_vsphere_child(vsphere_name => $container, dynamic => 1);
    }

    return if ($self->waiting_ready(
        container => $container, manager => $options{manager},
        identity => $options{identity}) == 0);

    $self->{centreon_vmware_config}->{vsphere_server}->{$container}->{last_request} = time();

    my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;
    my $msg = zmq_msg_init_data("server-" . $container);
    zmq_msg_send($msg, $frontend, $flag);
    zmq_msg_close($msg);
    $msg = zmq_msg_init_data('REQCLIENT ' . $options{data});
    zmq_msg_send($msg, $frontend, ZMQ_NOBLOCK);
    zmq_msg_close($msg);
}

sub request {
    my ($self, %options) = @_;

    # Decode json
    my $result;
    eval {
        $result = JSON::XS->new->utf8->decode($options{data});
    };
    if ($@) {
        centreon::vmware::common::set_response(code => 1, short_message => "Cannot decode json result: $@");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($result->{command} eq 'stats') {
        centreon::vmware::common::stats_info(counters => $self->{counter_stats});
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if (!defined($self->{modules_registry}->{ $result->{command} })) {
        centreon::vmware::common::set_response(code => 1, short_message => "Unknown method name '$result->{command}'");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }
    if ($self->{modules_registry}->{ $result->{command} }->checkArgs(
            manager => $options{manager},
            arguments => $result)) {
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }

    # Mode dynamic
    if (defined($result->{vsphere_address}) && $result->{vsphere_address} ne '') {
        $self->request_dynamic(result => $result, %options);
        return ;
    }

    $result->{container} = lc($result->{container});
    if (!defined($self->{centreon_vmware_config}->{vsphere_server}->{ $result->{container} })) {
        centreon::vmware::common::set_response(code => 1, short_message => "Unknown container name '$result->{container}'");
        centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $options{identity});
        return ;
    }

    return if ($self->waiting_ready(
        container => $result->{container}, manager => $options{manager},
        identity => $options{identity}) == 0);
    
    $self->{counter_stats}->{ $result->{container} }++;

    my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;
    my $msg = zmq_msg_init_data('server-' . $result->{container});
    zmq_msg_send($msg, $frontend, $flag);
    zmq_msg_close($msg);
    $msg = zmq_msg_init_data('REQCLIENT ' . $options{data});
    zmq_msg_send($msg, $frontend, ZMQ_NOBLOCK);
    zmq_msg_close($msg);
}

sub repserver {
    my ($self, %options) = @_;

    # Decode json
    my $result;
    eval {
        $result = JSON::XS->new->utf8->decode($options{data});
    };
    if ($@) {
        $self->{logger}->writeLogError("Cannot decode JSON: $@ (options{data}");
        return ;
    }

    $result->{identity} =~ /^client-(.*)$/;
    my $identity = 'client-' . pack('H*', $1);

    centreon::vmware::common::response(
        token => 'RESPSERVER', endpoint => $frontend, 
        identity => $identity, force_response => $options{data}
    );
}

sub router_event {
    while (1) {
        # Process all parts of the message
        my $msg = zmq_msg_init();
        zmq_msg_recv($msg, $frontend, ZMQ_DONTWAIT);
        my $identity = zmq_msg_data($msg);
        zmq_msg_close($msg);

        $msg = zmq_msg_init();
        zmq_msg_recv($msg, $frontend, ZMQ_DONTWAIT);
        my $data = zmq_msg_data($msg);
        zmq_msg_close($msg);

        centreon::vmware::common::init_response();
        if ($centreon_vmware->{stop} != 0) {
            # We quit so we say we're leaving ;)
            centreon::vmware::common::set_response(code => -1, short_message => 'Daemon is restarting/stopping...');
            centreon::vmware::common::response(token => 'RESPSERVER', endpoint => $frontend, identity => $identity);
        } elsif ($data =~ /^REQCLIENT\s+(.*)$/msi) {
            $centreon_vmware->request(identity => $identity, data => $1);
        } elsif ($data =~ /^RESPSERVER2\s+(.*)$/msi) {
            $centreon_vmware->repserver(data => $1);
        } elsif ($data =~ /^READY/msi) {
            $identity =~ /server-(.*)/;
            $centreon_vmware->{centreon_vmware_config}->{vsphere_server}->{$1}->{ready} = 1;
        }

        centreon::vmware::common::free_response();
        my $more = zmq_getsockopt($frontend, ZMQ_RCVMORE);        
        last unless $more;
    }
}

sub check_childs {
    my ($self, %options) = @_;

    my $count = $self->verify_child_vsphere();
    if ($self->{stop} == 1) {
        # No childs
        if ($count == 0) {
            $self->{logger}->writeLogInfo("Quit main process");
            zmq_close($frontend);
            exit(0);
        }
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
        my $connector = centreon::vmware::connector->new(
            name => $self->{whoaim},
            modules_registry => $self->{modules_registry},
            config => $self->{centreon_vmware_config},
            logger => $self->{logger},
            vsan_enabled => $self->{vsan_enabled}
        );
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
        $self->{logger}->writeLogError("Maybe directory does not exist. Attempting to create it!!!");
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
    zmq_bind($frontend, 'tcp://' . $centreon_vmware->{centreon_vmware_config}->{bind} . ':' . $centreon_vmware->{centreon_vmware_config}->{port});
    $centreon_vmware->bind_ipc(socket => $frontend, ipc_file => $centreon_vmware->{centreon_vmware_config}->{ipc_file});

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
            callback => \&router_event
        }
    ];

    # Switch messages between sockets
    while (1) {
        $centreon_vmware->check_childs();    
        zmq_poll($centreon_vmware->{poll}, 5000);
    }
}

1;

__END__
