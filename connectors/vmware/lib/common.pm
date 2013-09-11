
package centreon::esxd::common;

use warnings;
use strict;
use Data::Dumper;
use VMware::VIRuntime;
use VMware::VILib;

my %ERRORS = ( "OK" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3, "PENDING" => 4);
my %MYERRORS = (0 => "OK", 1 => "WARNING", 3 => "CRITICAL", 7 => "UNKNOWN");
my %MYERRORS_MASK = ("CRITICAL" => 3, "WARNING" => 1, "UNKNOWN" => 7, "OK" => 0);

sub errors_mask {
    my ($status, $state) = @_;
    
    $status |= $MYERRORS_MASK{$state};
    return $status;
}

sub get_status {
    my ($state) = @_;
    
    return $ERRORS{$MYERRORS{$state}};
}

sub response_client1 {
    my ($obj_esxd, $rh, $current_fileno, $msg) = @_;
    $rh->send($msg);
    delete $obj_esxd->{sockets}->{$current_fileno};
    $obj_esxd->{read_select}->remove($rh);
    close $rh;
}

sub vmware_error {
    my ($obj_esxd, $lerror) = @_;

    $obj_esxd->{logger}->writeLogError("'" . $obj_esxd->{whoaim} . "' $lerror");
    $lerror =~ s/\n/ /g;
    if ($lerror =~ /NoPermissionFault/i) {
        $obj_esxd->print_response("-2|Error: Not enough permissions\n");
    } else {
        $obj_esxd->print_response("-1|Error: " . $lerror . "\n");
    }
    return undef;
}

sub connect_vsphere {
    my ($logger, $whoaim, $timeout_vsphere, $session1, $service_url, $username, $password) = @_;
    $logger->writeLogInfo("'$whoaim' Vsphere connection in progress");
    eval {
        $SIG{ALRM} = sub { die('TIMEOUT'); };
        alarm($timeout_vsphere);
        $$session1 = Vim->new(service_url => $service_url);
        $$session1->login(
                user_name => $username,
                password => $password);
        alarm(0);
    };
    if($@) {
        $logger->writeLogError("'$whoaim' No response from VirtualCentre server") if($@ =~ /TIMEOUT/);
        $logger->writeLogError("'$whoaim' You need to upgrade HTTP::Message!") if($@ =~ /HTTP::Message/);
        $logger->writeLogError("'$whoaim' Login to VirtualCentre server failed: $@");
        return 1;
    }
#    eval {
#        $session_id = Vim::get_session_id();
#    };
#    if($@) {
#        writeLogFile("Can't get session_id: $@\n");
#        return 1;
#    }
    return 0;
}

sub output_add($$$$) {
    my ($output_str, $output_append, $delim, $str) = (shift, shift, shift, shift);
    $$output_str .= $$output_append . $str;
    $$output_append = $delim;
}

sub simplify_number {
    my ($number, $cnt) = @_;
    $cnt = 2 if (!defined($cnt));
    return sprintf("%.${cnt}f", "$number");
}

sub convert_number {
    my ($number) = shift(@_);
    $number =~ s/\,/\./;
    return $number;
}

sub get_views {
    my $obj_esxd = shift;
    my $results;

    eval {
        $results = $obj_esxd->{session1}->get_views(mo_ref_array => $_[0], properties => $_[1]);
    };
    if ($@) {
        vmware_error($obj_esxd, $@);
        return undef;
    }
    return $results;
}

sub get_view {
    my $obj_esxd = shift;
    my $results;

    eval {
        $results = $obj_esxd->{session1}->get_view(mo_ref => $_[0], properties => $_[1]);
    };
    if ($@) {
        vmware_error($obj_esxd, $@);
        return undef;
    }
    return $results;
}

sub search_in_datastore {
    my $obj_esxd = shift;
    my ($ds_browse, $ds_name, $query) = @_;
    my $result;
    
    my $files = FileQueryFlags->new(fileSize => 1,
                                    fileType => 1,
                                    modification => 1,
                                    fileOwner => 1
                                    );
    my $hostdb_search_spec = HostDatastoreBrowserSearchSpec->new(details => $files,
                                                                 query => $query);
    eval {
        $result = $ds_browse->SearchDatastoreSubFolders(datastorePath=> $ds_name,
                                        searchSpec=>$hostdb_search_spec);
    };
    if ($@) {
        vmware_error($obj_esxd, $@);
        return undef;
    }
    return $result;
}

sub get_perf_metric_ids {
    my $obj_esxd = shift;
    my $perf_names = $_[0];
    my $filtered_list = [];
   
    foreach (@$perf_names) {
        if (defined($obj_esxd->{perfcounter_cache}->{$_->{'label'}})) {
            foreach my $instance (@{$_->{'instances'}}) {
                my $metric = PerfMetricId->new(counterId => $obj_esxd->{perfcounter_cache}->{$_->{'label'}}{'key'},
                                   instance => $instance);
                push @$filtered_list, $metric;
            }
        } else {
            $obj_esxd->{logger}->writeLogError("Metric '" . $_->{'label'} . "' unavailable.");
            $obj_esxd->print_response("-3|Error: Counter doesn't exist. VMware version can be too old.\n");
            return undef;
        }
    }
    return $filtered_list;
}

sub generic_performance_values_historic {
    my ($obj_esxd, $view, $perfs, $interval) = @_;
    my $counter = 0;
    my %results;

    eval {
        my $perf_metric_ids = get_perf_metric_ids($obj_esxd, $perfs);
        return undef if (!defined($perf_metric_ids));

        my $perf_query_spec;
        my $tstamp = time();
        my (@t) = gmtime($tstamp - $interval);
        my $startTime = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
                (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]);
        (@t) = gmtime($tstamp);
        my $endTime = sprintf("%04d-%02d-%02dT%02d:%02d:%02dZ",
                (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]);
        
        if ($interval == 20) {
            $perf_query_spec = PerfQuerySpec->new(entity => $view,
                                  metricId => $perf_metric_ids,
                                  format => 'normal',
                                  intervalId => 20,
                                  startTime => $startTime,
                                  endTime => $endTime,
                                  maxSample => 1);
        } else {
            $perf_query_spec = PerfQuerySpec->new(entity => $view,
                         metricId => $perf_metric_ids,
                         format => 'normal',
                         intervalId => $interval,
                         startTime => $startTime,
                         endTime => $endTime
                        );
                        #maxSample => 1);
        }
        my $perfdata = $obj_esxd->{perfmanager_view}->QueryPerf(querySpec => $perf_query_spec);
        if (!$$perfdata[0]) {
            $obj_esxd->print_response("-3|Error: Cannot get value for couters. Maybe there is time sync problem (check the esxd server and the target also).\n");
            return undef;
        }
        foreach (@{$$perfdata[0]->value}) {
            $results{$_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = $_->value;
            if (!defined($_->value)) {
                $obj_esxd->print_response("-3|Error: Cannot get value for couters. Maybe there is time sync problem (check the esxd server and the target also).\n");
                return undef;
            }
        }
    };
    if ($@) {
        $obj_esxd->{logger}->writeLogError("'" . $obj_esxd->{whoaim} . "' $@");
        return undef;
    }
    return \%results;
}

sub cache_perf_counters {
    my $obj_esxd = shift;

    eval {
        $obj_esxd->{perfmanager_view} = $obj_esxd->{session1}->get_view(mo_ref => $obj_esxd->{session1}->get_service_content()->perfManager, properties => ['perfCounter', 'historicalInterval']);
        foreach (@{$obj_esxd->{perfmanager_view}->perfCounter}) {
            my $label = $_->groupInfo->key . "." . $_->nameInfo->key . "." . $_->rollupType->val;
            $obj_esxd->{perfcounter_cache}->{$label} = {'key' => $_->key, 'unitkey' => $_->unitInfo->key};
            $obj_esxd->{perfcounter_cache_reverse}->{$_->key} = $label;
        }

        my $historical_intervals = $obj_esxd->{perfmanager_view}->historicalInterval;

        foreach (@$historical_intervals) {
            if ($obj_esxd->{perfcounter_speriod} == -1 || $obj_esxd->{perfcounter_speriod} > $_->samplingPeriod) {
                $obj_esxd->{perfcounter_speriod} = $_->samplingPeriod;
            }
        }

        # Put refresh = 20 (for ESX check)
        if ($obj_esxd->{perfcounter_speriod} == -1) {
            $obj_esxd->{perfcounter_speriod} = 20;
        }
    };
    if ($@) {
        $obj_esxd->{logger}->writeLogError("'" . $obj_esxd->{whoaim} . "' $@");
        return 1;
    }
    return 0;
}

sub get_entities_host {
    my ($obj_esxd, $view_type, $filters, $properties) = @_;
    my $entity_views;

    eval {
        $entity_views = $obj_esxd->{session1}->find_entity_views(view_type => $view_type, properties => $properties, filter => $filters);
    };
    if ($@) {
        $obj_esxd->{logger}->writeLogError("'" . $obj_esxd->{whoaim} . "' $@");
        eval {
            $entity_views = $obj_esxd->{session1}->find_entity_views(view_type => $view_type, properties => $properties, filter => $filters);
        };
        if ($@) {
            vmware_error($obj_esxd, $@);
            return undef;
        }
    }
    if (!@$entity_views) {
        my $status = 0;
        $status = errors_mask($status, 'UNKNOWN');
        $obj_esxd->print_response(get_status($status) . "|Object $view_type does not exist.\n");
        return undef;
    }
    #eval {
    #    $$entity_views[0]->update_view_data(properties => $properties);
    #};
    #if ($@) {
    #    writeLogFile("$@");
    #    my $lerror = $@;
    #    $lerror =~ s/\n/ /g;
    #    print "-1|Error: " . $lerror . "\n";
    #    return undef;
    #}
    return $entity_views;
}

sub performance_errors {
    my ($obj_esxd, $values) = @_;

    # Error counter not available or orther from function
    return 1 if (!defined($values) || scalar(keys(%$values)) <= 0);
    return 0;
}

sub is_accessible {
    my ($accessible) = @_;
     
    if ($accessible !~ /^true|1$/) {
        return 0;
    }
    return 1;
}

sub datastore_state {
    my ($obj_esxd, $ds, $accessible) = @_;
    
    if ($accessible !~ /^true|1$/) {
        my $output = "Datastore '" . $ds . "' not accessible. Can be disconnected.";
        my $status = errors_mask(0, $obj_esxd->{centreonesxd_config}->{datastore_state_error});
        $obj_esxd->print_response(get_status($status) . "|$output\n");
        return 0;
    }
    
    return 1;
}

sub vm_state {
    my ($obj_esxd, $vm, $connection_state, $power_state, $nocheck_ps) = @_;
    
    if ($connection_state !~ /^connected$/i) {
        my $output = "VM '" . $vm . "' not connected. Current Connection State: '$connection_state'.";
        my $status = errors_mask(0, $obj_esxd->{centreonesxd_config}->{vm_state_error});
        $obj_esxd->print_response(get_status($status) . "|$output\n");
        return 0;
    }
    
    if (!defined($nocheck_ps) && $power_state !~ /^poweredOn$/i) {
        my $output = "VM '" . $vm . "' not running. Current Power State: '$power_state'.";
        my $status = errors_mask(0, $obj_esxd->{centreonesxd_config}->{vm_state_error});
        $obj_esxd->print_response(get_status($status) . "|$output\n");
        return 0;
    }
    
    return 1;
}

sub host_state {
    my ($obj_esxd, $host, $connection_state) = @_;
    
    if ($connection_state !~ /^connected$/i) {
        my $output = "Host '" . $host . "' not connected. Current Connection State: '$connection_state'.";
        my $status = errors_mask(0, $obj_esxd->{centreonesxd_config}->{host_state_error});
        $obj_esxd->print_response(get_status($status) . "|$output\n");
        return 0;
    }
    
    return 1;
}

sub stats_info {
    my ($obj_esxd, $rh, $current_fileno, $args) = @_;
    my $output;
    my $status = 0;
    
    $$args[0] ='' if (!defined($$args[0]));
    $$args[1] = '' if (!defined($$args[1]));
    
    my $num_connection = scalar(keys(%{$obj_esxd->{sockets}}));
    $output = "'$num_connection' total client connections | connection=$num_connection;$$args[0];$$args[1] requests=" . $obj_esxd->{counter};
    if ($$args[1] ne '' and $num_connection >= $$args[1]) {
        $status = errors_mask($status, 'CRITICAL');
    } elsif ($$args[0] ne '' and $num_connection >= $$args[0]) {
        $status = errors_mask($status, 'WARNING');
    }
    response_client1($obj_esxd, $rh, $current_fileno, get_status($status) . "|$output\n");
}

1;
