#!/usr/bin/perl -w

package centreon::script::centreonesxd;

use strict;
use VMware::VIRuntime;
use VMware::VILib;
use IO::Socket;
use File::Basename;
use IO::Select;
use POSIX ":sys_wait_h";
use Data::Dumper;
use centreon::script;
use centreon::esxd::common;

BEGIN {
    $ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
}

use base qw(centreon::script);
use vars qw(%centreonesxd_config);

my %handlers = ('TERM' => {}, 'HUP' => {}, 'CHLD' => {});
my @load_modules = ('centreon::esxd::cmdcountvmhost',
                    'centreon::esxd::cmdcpuhost',
                    'centreon::esxd::cmdcpuvm',
                    'centreon::esxd::cmddatastoreio',
                    'centreon::esxd::cmddatastoreshost',
                    'centreon::esxd::cmddatastoresvm',
                    'centreon::esxd::cmddatastoreusage',
                    'centreon::esxd::cmdgetmap',
                    'centreon::esxd::cmdhealthhost',
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
        "config-extra" => \$self->{opt_extra},
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
    if (defined($self->{credstore_use}) && defined($self->{credstore_file}) &&
        $self->{credstore_use} == 1 && -e "$self->{credstore_file}") {
        eval 'require VMware::VICredStore';
        if ($@) {
            $self->{logger}->writeLogError("Could not load module VMware::VICredStore");
            exit(1);
        }
        require VMware::VICredStore;

        if (VMware::VICredStore::init(filename => $self->{credstore_file}) == 0) {
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
        $self->{return_child}{$child_pid} = {'status' => 1, 'rtime' => time()};
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

sub verify_child {
    my $self = shift;
    my $progress = 0;
    my $handle_writer_pipe = ${$self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_one'}};

    # Verify process
    foreach (keys %{$self->{child_proc}}) {
        # Check ctime
        if (time() - $self->{child_proc}->{$_}->{'ctime'} > $self->{centreonesxd_config}->{timeout}) {
            my $handle = ${$self->{child_proc}->{$_}->{'reading'}};
            print $handle_writer_pipe "$_|-1|Timeout Process.\n";
            kill('INT', $self->{child_proc}->{$_}->{'pid'});
            $self->{read_select}->remove($handle);
            close $handle;
            delete $self->{child_proc}->{$_};
        } else {
            $progress++;
        }
    }
    # Clean old hash CHILD (security)
    foreach (keys %{$self->{return_child}}) {
        if (time() - $self->{return_child}->{$_}->{'rtime'} > 600) {
            $self->{logger}->writeLogInfo("Clean Old return_child list = " . $_);
            delete $self->{return_child}->{$_};
        }
    }

    return $progress;
}

sub vsphere_handler {
    my $self = shift;
    my $timeout_process;

    my $handle_reader_pipe = ${$self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'reader_two'}};
    my $fileno_reader = fileno($handle_reader_pipe);
    my $handle_writer_pipe = ${$self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_one'}};
    $self->{read_select} = new IO::Select();
    $self->{read_select}->add($handle_reader_pipe);
    while (1) {
        my $progress = $self->verify_child();

        #####
        # Manage ending
        #####
        if ($self->{stop} && $timeout_process > $self->{centreonesxd_config}->{timeout_kill}) {
            $self->{logger}->writeLogError("'" . $self->{whoaim} . "' Kill child not gently.");
            foreach (keys %{$self->{child_proc}}) {
                kill('INT', $self->{child_proc}->{$_}->{'pid'});
            }
            $progress = 0;
        }
        if ($self->{stop} && !$progress) {
            if ($self->{vsphere_connected}) {
                eval {
                    $self->{session1}->logout();
                };
            }
            print $handle_writer_pipe "STOPPED|$self->{whoaim}\n";
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
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'url'}, 
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'username'},
                                                         $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'password'})) {
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
        if ($self->{stop} == 0) {
            @rh_set = $self->{read_select}->can_read(30);
        } else {
            sleep(1);
            $timeout_process++;
            @rh_set = $self->{read_select}->can_read(0);
        }
        foreach my $rh (@rh_set) {
            if (fileno($rh) == $fileno_reader && !$self->{stop}) {
                $data_element = <$rh>;
                chomp $data_element;
                if ($data_element =~ /^STOP$/) {
                    $self->{stop} = 1;
                    $timeout_process = 0;
                    next;
                }

                my ($id) = split(/\|/, $data_element);
                if ($self->{vsphere_connected}) {
                    $self->{logger}->writeLogInfo("vpshere '" . $self->{whoaim} . "' handler asking: $data_element");
                    $self->{child_proc}->{$id} = {'ctime' => time()};
                
                    my $reader;
                    my $writer;
                    pipe($reader, $writer);
                    $writer->autoflush(1);

                    $self->{read_select}->add($reader);
                    $self->{child_proc}->{$id}->{'reading'} = \*$reader;
                    $self->{child_proc}->{$id}->{'pid'} = fork;
                    if (!$self->{child_proc}->{$id}->{'pid'}) {
                        # Child    
                        close $reader;
                        open STDOUT, '>&', $writer;
                        # Can't print on stdout
                        $self->{logger}->{log_mode} = 1 if ($self->{logger}->{log_mode} == 0);
                        my ($id, $name, @args) = split /\|/, $data_element;
                        $self->{global_id} = $id;
                        $self->{modules_registry}->{$name}->initArgs(@args);
                        $self->{modules_registry}->{$name}->run();
                        exit(0);
                    } else {
                        # Parent
                        close $writer;
                    }
                } else {
                    print $handle_writer_pipe "$id|-1|Vsphere connection error.\n";
                }
            } else {
                # Read pipe
                my $output = <$rh>;
                $self->{read_select}->remove($rh);
                close $rh;
                $output =~ s/^(.*?)\|//;
                my $lid = $1;
                if ($output =~ /^-1/) {
                    $self->{last_time_check} = $self->{child_proc}->{$lid}->{'ctime'};
                }
                chomp $output;
                print $handle_writer_pipe "$lid|$output\n";
                delete $self->{return_child}->{$self->{child_proc}->{$lid}->{'pid'}};
                delete $self->{child_proc}->{$lid};
            }
        }    
    }
}

sub run {
    my $self = shift;

    $self->SUPER::run();
    $self->{logger}->redirect_output();

    $self->{logger}->writeLogDebug("centreonesxd launched....");
    $self->{logger}->writeLogDebug("PID: $$");

    my $server = IO::Socket::INET->new( Proto => "tcp",
                                        LocalPort => $self->{centreonesxd_config}->{port},
                                        Listen => SOMAXCONN,
                                        Reuse => 1);
    if (!$server) {
        $self->{logger}->writeLogError("Can't setup server: $!");
        exit(1);
    }

    ##
    # Create childs
    ##
    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        my ($reader_pipe_one, $writer_pipe_one);
        my ($reader_pipe_two, $writer_pipe_two);
        $self->{whoaim} = $_;

        pipe($reader_pipe_one, $writer_pipe_one);
        pipe($reader_pipe_two, $writer_pipe_two);
        $writer_pipe_one->autoflush(1);
        $writer_pipe_two->autoflush(1);

        $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'reader_one'} = \*$reader_pipe_one;
        $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_one'} = \*$writer_pipe_one;
        $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'reader_two'} = \*$reader_pipe_two;
        $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_two'} = \*$writer_pipe_two;
        $self->{child_vpshere_pid} = fork();
        if (!$self->{child_vpshere_pid}) {
            close $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'reader_one'};
            close $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_two'};
            $self->vsphere_handler();
            exit(0);
        }
        $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'running'} = 1;
        close $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'writer_one'};
        close $self->{centreonesxd_config}->{vsphere_server}->{$self->{whoaim}}->{'reader_two'};
    }

    $self->{read_select} = new IO::Select();
    $self->{read_select}->add($server);
    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
        $self->{filenos}->{fileno(${$self->{centreonesxd_config}->{vsphere_server}->{$_}->{'reader_one'}})} = 1;
        $self->{read_select}->add(${$self->{centreonesxd_config}->{vsphere_server}->{$_}->{'reader_one'}});
    }
    my $socket_fileno = fileno($server);
    $self->{logger}->writeLogInfo("[Server accepting clients]");
    while (1) {
        my @rh_set = $self->{read_select}->can_read(15);
        if ($self->{stop} == 1) {
            foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
                $self->{logger}->writeLogInfo("Send STOP command to '$_' child.");
                my $writer_handle = $self->{centreonesxd_config}->{vsphere_server}->{$_}->{'writer_two'};
                print $writer_handle "STOP\n";
            }
            $self->{stop} = 2;
        }
        foreach my $rh (@rh_set) {
            my $current_fileno = fileno($rh);
            if (!$self->{stop} && $current_fileno == $socket_fileno) {
                my $client;
                # Connect to accept
                $client = $rh->accept();
                $client->autoflush(1);
                $self->{counter}++;
                $self->{sockets}->{fileno($client)} = {"obj" => \$client, "ctime" => time(), "counter" => $self->{counter}};
                $self->{read_select}->add($client);
                next;
            } elsif (defined($self->{filenos}->{$current_fileno})) {
                # Return to read
                my $data_element = <$rh>;
                chomp $data_element;
                if ($data_element =~ /^STOPPED/) {
                    # We have to wait all childs
                    my ($name, $which_one) = split(/\|/, $data_element);
                    $self->{logger}->writeLogInfo("Thread vsphere '$which_one' has stopped");
                    $self->{centreonesxd_config}->{vsphere_server}->{$which_one}->{'running'} = 0;
                    my $to_stop_or_not = 1;
                    foreach (keys %{$self->{centreonesxd_config}->{vsphere_server}}) {
                        $to_stop_or_not = 0 if ($self->{centreonesxd_config}->{vsphere_server}->{$_}->{'running'} == 1);
                    }
                    if ($to_stop_or_not == 1) {
                        # We quit
                        $self->{logger}->writeLogInfo("Quit main process");
                        exit(0);
                    }
                    next;
                }
                my @results = split(/\|/, $data_element);
                my ($id, $counter) = split(/\./, $results[0]);
                if (!defined($self->{sockets}->{$id}) || $self->{counter} != $self->{sockets}->{$id}->{'counter'}) {
                    $self->{logger}->writeLogInfo("Too much time to get response.");
                    next;
                }

                $self->{logger}->writeLogInfo("response = $data_element");
                $data_element =~ s/^.*?\|//;
                ${$self->{sockets}->{$id}->{'obj'}}->send($data_element . "\n");
                $self->{read_select}->remove(${$self->{sockets}->{$id}->{"obj"}});
                close ${$self->{sockets}->{$id}->{"obj"}};
                delete $self->{sockets}->{$id};
            } else {
                # Socket
                my $line = <$rh>;
                if (defined($line) && $line ne "") {
                    chomp $line;
                    my ($name, $vsphere_name, @args) = split /\|/, $line;
                    
                    if ($name eq 'stats') {
                        centreon::esxd::common::stats_info($self, $rh, $current_fileno, \@args);
                        next;
                    }
                    if (!defined($self->{modules_registry}->{$name})) {
                        centreon::esxd::common::response_client1($self, $rh, $current_fileno, "3|Unknown method name '$name'\n");
                        next;
                    }
                    if ($self->{modules_registry}->{$name}->checkArgs(@args)) {
                        centreon::esxd::common::response_client1($self, $rh, $current_fileno, "3|Params error '$name'\n");
                        next;
                    }

                    $vsphere_name = 'default' if (!defined($vsphere_name) || $vsphere_name eq '');
                    if (!defined($self->{centreonesxd_config}->{vsphere_server}->{$vsphere_name})) {
                        centreon::esxd::common::response_client1($self, $rh, $current_fileno, "3|Vsphere name unknown\n");
                        next;
                    }

                    my $tmp_handle = ${$self->{centreonesxd_config}->{vsphere_server}->{$vsphere_name}->{'writer_two'}};
                    print $tmp_handle $current_fileno . "." . $self->{sockets}->{$current_fileno}->{'counter'} . "|$name|" . join('|', @args) . "\n";
                } else {
                    centreon::esxd::common::response_client1($self, $rh, $current_fileno, "3|Need arguments\n");
                }
            }
        }

        # Verify socket 
        foreach (keys %{$self->{sockets}}) {
            if (time() - $self->{sockets}->{$_}->{'ctime'} > $self->{centreonesxd_config}->{timeout}) {
                $self->{logger}->writeLogInfo("Timeout returns.");
                ${$self->{sockets}->{$_}->{'obj'}}->send("3|TIMEOUT\n");
                $self->{read_select}->remove(${$self->{sockets}->{$_}->{"obj"}});
                close ${$self->{sockets}->{$_}->{"obj"}};
                delete $self->{sockets}->{$_};
            }
        }
    }
}

1;

__END__