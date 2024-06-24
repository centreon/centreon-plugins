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

package centreon::vmware::common;

use warnings;
use strict;
use Data::Dumper;
use VMware::VIRuntime;
use VMware::VILib;
use ZMQ::LibZMQ4;
use ZMQ::Constants qw(:all);
use JSON::XS;;

my $manager_display = {};
my $manager_response = {};
my $flag = ZMQ_NOBLOCK | ZMQ_SNDMORE;

sub set_response {
    my (%options) = @_;

    $manager_response->{code} = $options{code} if (defined($options{code}));
    $manager_response->{short_message} = $options{short_message} if (defined($options{short_message}));
    $manager_response->{extra_message} = $options{extra_message} if (defined($options{extra_message}));
    $manager_response->{identity} = $options{identity} if (defined($options{identity}));
    $manager_response->{data} = $options{data} if (defined($options{data}));
}

sub init_response {
    my (%options) = @_;

    $manager_response->{code} = 0;
    $manager_response->{vmware_connector_version} = '3.2.6';
    $manager_response->{short_message} = 'OK';
    $manager_response->{extra_message} = '';
    $manager_response->{identity} = $options{identity} if (defined($options{identity}));
    $manager_response->{data} = {};
}

sub free_response {
    $manager_response = {};
}

sub response {
    my (%options) = @_;

    my $response_str = '';
    if (defined($options{force_response})) {
        $response_str = $options{force_response};
    } else {
        eval {
            $response_str = JSON::XS->new->utf8->encode($manager_response);
        };
        if ($@) {
            $response_str = '{ "code": -1, "short_message": "Cannot encode result" }';
        }
    }

    if (defined($options{reinit})) {
         my $context = zmq_init();
         $options{endpoint} = zmq_socket($context, ZMQ_DEALER);
         zmq_connect($options{endpoint}, $options{reinit});
         # we wait 10 seconds after. If not there is a problem... so we can quit
         # dialog from vsphere response to router
         zmq_setsockopt($options{endpoint}, ZMQ_LINGER, 10000); 
    }
    if (defined($options{identity})) {
        my $msg = zmq_msg_init_data($options{identity});
        zmq_msg_send($msg, $options{endpoint}, $flag);
        zmq_msg_close($msg);
    }
    my $msg = zmq_msg_init_data($options{token} . " " . $response_str);
    zmq_msg_send($msg, $options{endpoint}, ZMQ_NOBLOCK);
    zmq_msg_close($msg);
}

sub vmware_error {
    my ($obj_vmware, $lerror) = @_;

    set_response(extra_message => $lerror);
    $obj_vmware->{logger}->writeLogError("'" . $obj_vmware->{whoaim} . "' $lerror");
    if ($lerror =~ /NoPermissionFault/i) {
        set_response(code => -1, short_message => 'VMWare error: not enought permissions');
    } else {
        set_response(code => -1, short_message => 'VMWare error (verbose mode for more details)');
    }
    return undef;
}

sub connect_vsphere {
    my (%options) = @_;

    $options{logger}->writeLogInfo("'$options{whoaim}' Vsphere connection in progress");
    eval {
        $SIG{ALRM} = sub { die('TIMEOUT'); };
        alarm($options{connect_timeout});
        $options{connector}->{session} = Vim->new(service_url => $options{url});
        $options{connector}->{session}->login(
            user_name => $options{username},
            password => $options{password}
        );

        $options{connector}->{service_url} = $options{url};
        #$options{connector}->{session}->save_session(session_file => '/tmp/plop.save');
        #$options{connector}->{session}->unset_logout_on_disconnect();

        get_vsan_vim(%options) if ($options{vsan_enabled} == 1);

        alarm(0);
    };
    if ($@) {
        $options{logger}->writeLogError("'$options{whoaim}' No response from VirtualCenter server") if($@ =~ /TIMEOUT/);
        $options{logger}->writeLogError("'$options{whoaim}' You need to upgrade HTTP::Message!") if($@ =~ /HTTP::Message/);
        $options{logger}->writeLogError("'$options{whoaim}' Login to VirtualCenter server failed: $@");
        return 1;
    }

    return 0;
}

sub heartbeat {
    my (%options) = @_;
    my $stime;

    eval {
        $stime = $options{connector}->{session}->get_service_instance()->CurrentTime();
        $options{connector}->{keeper_session_time} = time();
    };
    if ($@) {
        $options{connector}->{logger}->writeLogError("$@");
        # Try a second time
        eval {
            $stime = $options{connector}->{session}->get_service_instance()->CurrentTime();
            $options{connector}->{keeper_session_time} = time();
        };
        if ($@) {
            $options{connector}->{logger}->writeLogError("$@");
            $options{connector}->{logger}->writeLogError("'" . $options{connector}->{whoaim} . "' Ask a new connection");
            # Ask a new connection
            $options{connector}->{last_time_check} = time();
        }
    }

    $options{connector}->{logger}->writeLogInfo("'" . $options{connector}->{whoaim} . "' Get current time = " . Data::Dumper::Dumper($stime));
}

sub simplify_number {
    my ($number, $cnt) = @_;
    $cnt = 2 if (!defined($cnt));
    return sprintf("%.${cnt}f", "$number");
}

sub convert_number {
    my ($number) = shift(@_);
    # Avoid error counter empty. But should manage it in code the 'undef'.
    $number = 0 if (!defined($number));
    $number =~ s/\,/\./;
    return $number;
}

sub get_views {
    my $obj_vmware = shift;
    my $results;

    eval {
        $results = $obj_vmware->{session}->get_views(mo_ref_array => $_[0], properties => $_[1]);
    };
    if ($@) {
        vmware_error($obj_vmware, $@);
        return undef;
    }
    return $results;
}

sub get_view {
    my $obj_vmware = shift;
    my $results;

    eval {
        $results = $obj_vmware->{session}->get_view(mo_ref => $_[0], properties => $_[1]);
    };
    if ($@) {
        vmware_error($obj_vmware, $@);
        return undef;
    }
    return $results;
}

sub search_in_datastore {
    my (%options) = @_;
    my $result;

    my $files = FileQueryFlags->new(
        fileSize => 1,
        fileType => 1,
        modification => 1,
        fileOwner => 1
    );
    my $hostdb_search_spec = HostDatastoreBrowserSearchSpec->new(
        details => $files,
        searchCaseInsensitive => $options{searchCaseInsensitive},
        matchPattern => $options{matchPattern},
        query => $options{query}
    );
    eval {
        $result = $options{browse_ds}->SearchDatastoreSubFolders(
            datastorePath => $options{ds_name},
            searchSpec => $hostdb_search_spec
        );
    };
    if ($@) {
        return (undef, $@) if (defined($options{return}) && $options{return} == 1);
        vmware_error($options{connector}, $@);
        return undef;
    }
    return $result;
}

sub get_perf_metric_ids {
    my (%options) = @_;
    my $filtered_list = [];

    foreach (@{$options{metrics}}) {
        if (defined($options{connector}->{perfcounter_cache}->{$_->{label}})) {
            if ($options{interval} != 20 && $options{connector}->{perfcounter_cache}->{$_->{label}}{level} > $options{connector}->{sampling_periods}->{$options{interval}}->{level}) {
                set_response(
                    code => -1,
                    short_message => sprintf(
                        "Cannot get counter '%s' for the sampling period '%s' (counter level: %s, sampling level: %s)",
                        $_->{label}, $options{interval}, 
                        $options{connector}->{perfcounter_cache}->{$_->{label}}{level},
                        $options{connector}->{sampling_periods}->{$options{interval}}->{level}
                    )
                );
                return undef;
            }
            foreach my $instance (@{$_->{instances}}) {    
                my $metric = PerfMetricId->new(
                    counterId => $options{connector}->{perfcounter_cache}->{$_->{label}}{key},
                    instance => $instance
                );
                push @$filtered_list, $metric;
            }
        } else {
            $options{connector}->{logger}->writeLogError("Metric '" . $_->{label} . "' unavailable.");
            set_response(code => -1, short_message => "Counter doesn't exist. VMware version can be too old.");
            return undef;
        }
    }
    return $filtered_list;
}

sub performance_builder_specific {
    my (%options) = @_;

    my $time_shift = defined($options{time_shift}) ? $options{time_shift} : 0;
    my @perf_query_spec;
    foreach my $entry (@{$options{metrics}}) {
        my $perf_metric_ids = get_perf_metric_ids(
            connector => $options{connector}, 
            metrics => $entry->{metrics}, 
            interval => $options{interval}
        );
        return undef if (!defined($perf_metric_ids));

        my $tstamp = time();
        my (@t) = gmtime($tstamp - $options{interval} - $time_shift);
        my $startTime = sprintf(
            "%04d-%02d-%02dT%02d:%02d:%02dZ",
            (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
        );
        (@t) = gmtime($tstamp);
        my $endTime = sprintf(
            "%04d-%02d-%02dT%02d:%02d:%02dZ",
            (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
        );
        if ($options{interval} == 20) {
            push @perf_query_spec, PerfQuerySpec->new(
                entity => $entry->{entity},
                metricId => $perf_metric_ids,
                format => 'normal',
                intervalId => 20,
                startTime => $startTime,
                endTime => $endTime
            );
            #maxSample => 1);
        } else {
            push @perf_query_spec, PerfQuerySpec->new(
                entity => $entry->{entity},
                metricId => $perf_metric_ids,
                format => 'normal',
                intervalId => $options{interval},
                startTime => $startTime,
                endTime => $endTime
            );
            #maxSample => 1);
        }
    }

    return $options{connector}->{perfmanager_view}->QueryPerf(querySpec => \@perf_query_spec);
}

sub performance_builder_global {
    my (%options) = @_;

    my $time_shift = defined($options{time_shift}) ? $options{time_shift} : 0;
    my @perf_query_spec;
    my $perf_metric_ids = get_perf_metric_ids(
        connector => $options{connector}, 
        metrics => $options{metrics}, 
        interval => $options{interval}
    );
    return undef if (!defined($perf_metric_ids));

    my $tstamp = time();
    my (@t) = gmtime($tstamp - $options{interval} - $time_shift);
    my $startTime = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02dZ",
        (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
    );
    (@t) = gmtime($tstamp);
    my $endTime = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02dZ",
        (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
    );

    foreach (@{$options{views}}) {
        if ($options{interval} == 20) {
            push @perf_query_spec, PerfQuerySpec->new(
                entity => $_,
                metricId => $perf_metric_ids,
                format => 'normal',
                intervalId => 20,
                startTime => $startTime,
                endTime => $endTime
            );
            #maxSample => 1);
        } else {
            push @perf_query_spec, PerfQuerySpec->new(
                entity => $_,
                metricId => $perf_metric_ids,
                format => 'normal',
                intervalId => $options{interval},
                startTime => $startTime,
                endTime => $endTime
            );
            #maxSample => 1);
        }
    }

    return $options{connector}->{perfmanager_view}->QueryPerf(querySpec => \@perf_query_spec);
}

sub generic_performance_values_historic {
    my ($obj_vmware, $views, $perfs, $interval, %options) = @_;
    my $counter = 0;
    my %results;

    # overload the default sampling choosen
    if (defined($options{sampling_period}) && $options{sampling_period} ne '') {
        $interval = $options{sampling_period};
    }
    # check sampling period exist (period 20 is not listed)
    if ($interval != 20 && !defined($obj_vmware->{sampling_periods}->{$interval})) {
        set_response(code => -1, short_message => sprintf("Sampling period '%s' not managed.", $interval));
        return undef;
    }
    if ($interval != 20 && $obj_vmware->{sampling_periods}->{$interval}->{enabled} != 1) {
        set_response(code => -1, short_message => sprintf("Sampling period '%s' collection data no enabled.", $interval));
        return undef;
    }
    eval {
        my $perfdata;

        if (defined($views)) {
            $perfdata = performance_builder_global(
                connector => $obj_vmware,
                views => $views,
                metrics => $perfs,
                interval => $interval,
                time_shift => $options{time_shift}
            );
        } else {
            $perfdata = performance_builder_specific(
                connector => $obj_vmware,
                metrics => $perfs,
                interval => $interval,
                time_shift => $options{time_shift}
            );
        }
        return undef if (!defined($perfdata));

        if (!$$perfdata[0] || !defined($$perfdata[0]->value)) {
            set_response(code => -1, short_message => 'Cannot get value for counters (Maybe, object(s) cannot be reached: disconnected, not running, time not synced (see time-host mode) check option --time-shift and ensure this specific metric is retrieved and not late in the vcenter)');
            return undef;
        }
        foreach my $val (@$perfdata) {
            foreach (@{$val->{value}}) {
                if (defined($options{skip_undef_counter}) && $options{skip_undef_counter} == 1 && !defined($_->value)) {
                    $results{$_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = undef;
                    next;
                } elsif (!defined($_->value)) {
                    set_response(code => -1, short_message => 'Cannot get value for counters. Maybe there is time sync problem (check the esxd server and the target also)');
                    return undef;
                }

                my $aggregated_counter_value = 0;
                foreach my $counter_value (@{$_->value}) {
                    $aggregated_counter_value += $counter_value;
                }
                if (scalar(@{$_->value}) > 1) {
                    $aggregated_counter_value /= scalar(@{$_->value});
                }

                if (defined($options{multiples}) && $options{multiples} == 1) {
                    if (defined($options{multiples_result_by_entity}) && $options{multiples_result_by_entity} == 1) {
                        $results{$val->{entity}->{value}} = {} if (!defined($results{$val->{entity}->{value}}));
                        $results{$val->{entity}->{value}}->{$_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = $aggregated_counter_value;
                    } else {
                        $results{$val->{entity}->{value} . ":" . $_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = $aggregated_counter_value;
                    }
                } else {
                    $results{$_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = $aggregated_counter_value;
                }
            }
        }
    };
    if ($@) {
        if ($@ =~ /querySpec.interval.*InvalidArgumentFault/msi) {
            set_response(
                code => -1,
                short_message => sprintf(
                    "Interval '%s' is surely not supported for the managed entity (caller: %s)",
                    $interval,
                    join('--', caller)
                )
            );
        } else {
            $obj_vmware->{logger}->writeLogError("'" . $obj_vmware->{whoaim} . "' $@");
        }
        return undef;
    }
    return \%results;
}

sub cache_perf_counters {
    my $obj_vmware = shift;

    eval {
        $obj_vmware->{perfmanager_view} = $obj_vmware->{session}->get_view(mo_ref => $obj_vmware->{session}->get_service_content()->perfManager, properties => ['perfCounter', 'historicalInterval']);
        foreach (@{$obj_vmware->{perfmanager_view}->perfCounter}) {
            my $label = $_->groupInfo->key . "." . $_->nameInfo->key . "." . $_->rollupType->val;
            $obj_vmware->{perfcounter_cache}->{$label} = { key => $_->key, unitkey => $_->unitInfo->key, level => $_->level };
            $obj_vmware->{perfcounter_cache_reverse}->{$_->key} = $label;
        }

        my $historical_intervals = $obj_vmware->{perfmanager_view}->historicalInterval;
        $obj_vmware->{sampling_periods} = {};

        foreach (@$historical_intervals) {
            if ($obj_vmware->{perfcounter_speriod} == -1 || $obj_vmware->{perfcounter_speriod} > $_->samplingPeriod) {
                $obj_vmware->{perfcounter_speriod} = $_->samplingPeriod;
            }
            $obj_vmware->{sampling_periods}->{$_->samplingPeriod} = $_;
        }

        # Put refresh = 20 (for ESX check)
        if ($obj_vmware->{perfcounter_speriod} == -1) {
            $obj_vmware->{perfcounter_speriod} = 20;
        }
    };

    if ($@) {
        $obj_vmware->{logger}->writeLogError("'" . $obj_vmware->{whoaim} . "' $@");
        return 1;
    }

    return 0;
}

sub search_entities {
    my (%options) = @_;
    my $properties = ['name'];
    my $begin_views = [];

    foreach my $scope (['scope_datacenter', 'Datacenter'], ['scope_cluster', 'ClusterComputeResource'], ['scope_host', 'HostSystem']) {
        if (defined($options{command}->{$scope->[0]}) && $options{command}->{$scope->[0]} ne '') {
            my $filters = { name => qr/$options{command}->{$scope->[0]}/ };
            if (scalar(@$begin_views) > 0) {
                my $temp_views = [];
                while ((my $view = shift @$begin_views)) {
                    my ($status, $views) = find_entity_views(
                        connector => $options{command}->{connector},
                        view_type => $scope->[1],
                        properties => $properties,
                        filter => $filters, 
                        begin_entity => $view,
                        output_message => 0
                    );
                    next if ($status == 0);
                    return undef if ($status == -1);
                    push @$temp_views, @$views;
                }

                if (scalar(@$temp_views) == 0) {
                    set_response(code => 1, short_message => "Cannot find '$scope->[1]' object");
                    return undef;
                }
                push @$begin_views, @$temp_views;
            } else {
                my ($status, $views) = find_entity_views(connector => $options{command}->{connector}, view_type => $scope->[1], properties => $properties, filter => $filters);
                # We quit. No scope find
                return undef if ($status <= 0);
                push @$begin_views, @$views;
            }
        }
    }

    if (scalar(@$begin_views) > 0) {
        my $results = [];
        foreach my $view (@$begin_views) {
            my ($status, $views) = find_entity_views(
                connector => $options{command}->{connector},
                view_type => $options{view_type},
                properties => $options{properties},
                filter => $options{filter}, 
                begin_entity => $view,
                output_message => 0
            );
            next if ($status == 0);
            return undef if ($status == -1);
            push @$results, @$views;
        }
        if (scalar(@$results) == 0) {
            set_response(code => 1, short_message => "Cannot find '$options{view_type}' object");
            return undef;
        }
        return $results;
    } else {
        my ($status, $views) = find_entity_views(
            connector => $options{command}->{connector},
            view_type => $options{view_type},
            properties => $options{properties},
            filter => $options{filter},
            empty_continue => $options{command}->{empty_continue}
        );
        return $views;
    }
}

sub find_entity_views {
    my (%options) = @_;
    my $entity_views;

    eval {
        if (defined($options{begin_entity})) {
            $entity_views = $options{connector}->{session}->find_entity_views(view_type => $options{view_type}, properties => $options{properties}, filter => $options{filter}, begin_entity => $options{begin_entity});
        } else {
            $entity_views = $options{connector}->{session}->find_entity_views(view_type => $options{view_type}, properties => $options{properties}, filter => $options{filter});
        }
    };
    if ($@) {
        $options{connector}->{logger}->writeLogError("'" . $options{connector}->{whoaim} . "' $@");
        eval {
            if (defined($options{begin_entity})) {
                $entity_views = $options{connector}->{session}->find_entity_views(view_type => $options{view_type}, properties => $options{properties}, filter => $options{filter}, begin_entity => $options{begin_entity});
            } else {
                $entity_views = $options{connector}->{session}->find_entity_views(view_type => $options{view_type}, properties => $options{properties}, filter => $options{filter});
            }
        };
        if ($@) {
            vmware_error($options{connector}, $@);
            return (-1, undef);
        }
    }
    if (!defined($entity_views) || scalar(@$entity_views) == 0) {
        my $status = 0;
        if (defined($options{empty_continue})) {
            return (1, []);
        }
        if (!defined($options{output_message}) || $options{output_message} != 0) {
            set_response(code => 1, short_message => "Cannot find '$options{view_type}' object");
        }
        return (0, undef);
    }
    #eval {
    #    $$entity_views[0]->update_view_data(properties => $properties);
    #};
    #if ($@) {
    #    writeLogFile("$@");
    #    return undef;
    #}
    return (1, $entity_views);
}

sub performance_errors {
    my ($obj_vmware, $values) = @_;

    # Error counter not available or other from function
    return 1 if (!defined($values) || scalar(keys(%$values)) <= 0);
    return 0;
}

sub get_interval_min  {
    my (%options) = @_;

    my $interval = $options{speriod};
    my $time_shift = defined($options{time_shift}) ? $options{time_shift} : 0;
    if (defined($options{sampling_period}) && $options{sampling_period} ne '') {
        $interval = $options{sampling_period};
    }

    return int(($interval + $time_shift) / 60);
}

sub is_accessible {
    my (%options) = @_;

    if ($options{accessible} !~ /^true|1$/) {
        return 0;
    }
    return 1;
}

sub is_connected {
    my (%options) = @_;

    if ($options{state} !~ /^connected$/i) {
        return 0;
    }
    return 1;
}

sub is_running {
    my (%options) = @_;

    if ($options{power} !~ /^poweredOn$/i) {
        return 0;
    }
    return 1;
}

sub is_maintenance {
    my (%options) = @_;

    if ($options{maintenance} =~ /^true|1$/) {
        return 0;
    }
    return 1;
}

sub substitute_name {
    my (%options) = @_;

    $options{value} =~ s/%2f/\//g;
    return $options{value};
}

sub strip_cr {
    my (%options) = @_;

    $options{value} =~ s/^\s+.*\s+$//mg;
    $options{value} =~ s/\r//mg;
    $options{value} =~ s/\n/ -- /mg;
    return $options{value};
}

sub stats_info {
    my (%options) = @_;

    my $data = {};
    foreach my $container (keys %{$options{counters}}) {
        $data->{$container} = { requests => $options{counters}->{$container} };
    }
    set_response(data => $data);
}

#
# Vsan
#

sub load_vsanmgmt_binding_files {
    my (%options) = @_;

    my @stub = ();
    local $/;
    for (@{$options{files}}) {
        open(STUB, $options{path} . '/' . $_) or die $!;
        push @stub, split /\n####+?\n/, <STUB>;
        close STUB or die $!;
    }
    for (@stub) {
        my ($package) = /\bpackage\s+(\w+)/;
        $VIMRuntime::stub_class{$package} = $_ if (defined($package));
    }
    eval $VIMRuntime::stub_class{'VimService'};
}

sub get_vsan_vim {
    my (%options) = @_;

    require URI::URL;
    my $session_id = $options{connector}->{session}->get_session_id();
    my $url = URI::URL->new($options{connector}->{session}->get_service_url());
    my $api_type = $options{connector}->{session}->get_service_content()->about->apiType;

    my $service_url_path = "sdk/vimService";
    my $path = "vsanHealth";
    if ($api_type eq "HostAgent") {
        $service_url_path = "sdk";
        $path = "vsan";
    }

    $options{connector}->{vsan_vim} = Vim->new(
        service_url =>
        'https://' . $url->host . '/' . $service_url_path,
        server => $url->host,
        protocol => "https",
        path => $path,
        port => '443'
    );

    $options{connector}->{vsan_vim}->{vim_service} = VimService->new($options{connector}->{vsan_vim}->{service_url});
    $options{connector}->{vsan_vim}->{vim_service}->load_session_id($session_id);
    $options{connector}->{vsan_vim}->unset_logout_on_disconnect;
}

sub vsan_create_mo_view {
    my (%options) = @_;

    my $moref = ManagedObjectReference->new(
        type => $options{type},
        value => $options{value},
    );
    my $view_type = $moref->type;
    my $mo_view = $view_type->new($moref, $options{vsan_vim});
    return $mo_view;
}

sub vsan_get_performances {
    my (%options) = @_;

    my $time_shift = defined($options{time_shift}) ? $options{time_shift} : 0;
    my $tstamp = time();
    my (@t) = gmtime($tstamp - $options{interval} - $time_shift);
    my $startTime = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02dZ",
        (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
    );
    (@t) = gmtime($tstamp);
    my $endTime = sprintf(
        "%04d-%02d-%02dT%02d:%02d:%02dZ",
        (1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1],$t[0]
    );
    my $querySpec = VsanPerfQuerySpec->new(
        entityRefId => $options{entityRefId}, # for example: 'virtual-machine:*'
        labels => $options{labels}, # for example: ['iopsRead, iopsWrite']
        startTime => $startTime,
        endTime => $endTime,
    );
    my $values = $options{vsan_performance_mgr}->VsanPerfQueryPerf(
        querySpecs => [$querySpec],
        cluster => $options{cluster},
    );

    my $result = {};
    foreach (@$values) {
        $result->{$_->{entityRefId}} = {};
        foreach my $perf (@{$_->{value}}) {
            my ($counter, $i) = (0, 0);
            foreach my $val (split /,/, $perf->{values}) {
                $counter += $val;
                $i++;
            }
            $result->{$_->{entityRefId}}->{$perf->{metricId}->{label}} = $counter / $i;
        }
    }

    return $result;
}

1;
