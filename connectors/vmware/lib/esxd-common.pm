sub writeLogFile($$) {
	if (($log_crit & $_[0]) == 0) {
		return ;
	}

	if ($log_mode == 0) {
		print $_[1];
	} elsif ($log_mode == 1) {
		my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
		open (LOG, ">> ".$LOG) || print "can't write $LOG: $!";
		printf LOG "%04d-%02d-%02d %02d:%02d:%02d - %s", $year+1900, $mon+1, $mday, $hour, $min, $sec, $_[1];
		close LOG;
	} elsif ($log_mode == 2) {
		syslog($syslog_err_priority, $_[1]) if ($_[0] == LOG_ESXD_ERROR);
		syslog($syslog_info_priority, $_[1]) if ($_[0] == LOG_ESXD_INFO);
	}
}

sub connect_vsphere {
	writeLogFile(LOG_ESXD_INFO, "Vsphere connection in progress\n");
	eval {
		$SIG{ALRM} = sub { die('TIMEOUT'); };
		alarm($TIMEOUT_VSPHERE);
		$session1 = Vim->new(service_url => $service_url);
		$session1->login(
        		user_name => $username,
        		password => $password);
		alarm(0);
	};
	if($@) {
		writeLogFile(LOG_ESXD_ERROR, "No response from VirtualCentre server\n") if($@ =~ /TIMEOUT/);
		writeLogFile(LOG_ESXD_ERROR, "You need to upgrade HTTP::Message!\n") if($@ =~ /HTTP::Message/);
		writeLogFile(LOG_ESXD_ERROR, "Login to VirtualCentre server failed: $@");
		return 1;
	}
#	eval {
#		$session_id = Vim::get_session_id();
#	};
#	if($@) {
#		writeLogFile("Can't get session_id: $@\n");
#		return 1;
#	}
	return 0;
}

sub print_response {
	print "$global_id|" . $_[0];
}

sub output_add($$$$) {
	my ($output_str, $output_append, $delim, $str) = (shift, shift, shift, shift);
	$$output_str .= $$output_append . $str;
	$$output_append = $delim;
}

sub simplify_number{
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
	my $results;

	eval {
		$results = $session1->get_views(mo_ref_array => $_[0], properties => $_[1]);
	};
	if ($@) {
		writeLogFile(LOG_ESXD_ERROR, "$@");
		my $lerror = $@;
		$lerror =~ s/\n/ /g;
		print_response("-1|Error: " . $lerror . "\n");
		return undef;
	}
	return $results;
}

sub get_perf_metric_ids {
	my $perf_names = $_[0];
	my @filtered_list;
   
	foreach (@$perf_names) {
		if (defined($perfcounter_cache{$_->{'label'}})) {
			foreach my $instance (@{$_->{'instances'}}) {
				my $metric = PerfMetricId->new(counterId => $perfcounter_cache{$_->{'label'}}{'key'},
							       instance => $instance);
				push @filtered_list, $metric;
			}
		} else {
			writeLogFile(LOG_ESXD_ERROR, "Metric '" . $_->{'label'} . "' unavailable.\n");
		}
	}
	return \@filtered_list;
}

sub generic_performance_values_historic {
	my ($view, $perfs, $interval) = @_;
	my $counter = 0;
	my %results;

	eval {
		my @perf_metric_ids = get_perf_metric_ids($perfs);

		my (@t) = gmtime(time() - $interval);
		my $start = sprintf("%04d-%02d-%02dT%02d:%02d:00Z",
			(1900+$t[5]),(1+$t[4]),$t[3],$t[2],$t[1]);
 		my $perf_query_spec = PerfQuerySpec->new(entity => $view,
					 metricId => @perf_metric_ids,
					 format => 'normal',
					 intervalId => $interval,
					 startTime => $start
					);
					#maxSample => 1);
		my $perfdata = $perfmanager_view->QueryPerf(querySpec => $perf_query_spec);
		foreach (@{$$perfdata[0]->value}) {
			$results{$_->id->counterId . ":" . (defined($_->id->instance) ? $_->id->instance : "")} = $_->value;
		}
	};
	if ($@) {
		writeLogFile(LOG_ESXD_ERROR, "$@");
		return undef;
	}
	return \%results;
}

sub cache_perf_counters {
	eval {
		$perfmanager_view = $session1->get_view(mo_ref => $session1->get_service_content()->perfManager, properties => ['perfCounter', 'historicalInterval']);
		foreach (@{$perfmanager_view->perfCounter}) {
			my $label = $_->groupInfo->key . "." . $_->nameInfo->key . "." . $_->rollupType->val;
			$perfcounter_cache{$label} = {'key' => $_->key, 'unitkey' => $_->unitInfo->key};
			$perfcounter_cache_reverse{$_->key} = $label;
		}

		my $historical_intervals = $perfmanager_view->historicalInterval;

		foreach (@$historical_intervals) {
			if ($perfcounter_speriod == -1 || $perfcounter_speriod > $_->samplingPeriod) {
				$perfcounter_speriod = $_->samplingPeriod;
			}
		}
	};
	if ($@) {
		writeLogFile(LOG_ESXD_ERROR, "$@");
		return 1;
	}
	return 0;
}

sub get_entities_host {
	my ($view_type, $filters, $properties) = @_;
	my $entity_views;

	eval {
		$entity_views = $session1->find_entity_views(view_type => $view_type, properties => $properties, filter => $filters);
	};
	if ($@ =~ /decryption failed or bad record mac/) {
		writeLogFile(LOG_ESXD_ERROR, "$@");
		eval {
			$entity_views = $session1->find_entity_views(view_type => $view_type, properties => $properties, filter => $filters);
		};
		if ($@) {
			writeLogFile(LOG_ESXD_ERROR, "$@");
			my $lerror = $@;
			$lerror =~ s/\n/ /g;
			print_response("-1|Error: " . Data::Dumper::Dumper($lerror) . "\n");
			return undef;
		}
	} elsif ($@) {
		writeLogFile(LOG_ESXD_ERROR, "$@");
		my $lerror = $@;
		$lerror =~ s/\n/ /g;
		print_response("-1|Error: " . $lerror . "\n");
		return undef;
	}
	if (!@$entity_views) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Object $view_type does not exist.\n");
		return undef;
	}
	#eval {
	#	$$entity_views[0]->update_view_data(properties => $properties);
	#};
	#if ($@) {
	#	writeLogFile("$@");
	#	my $lerror = $@;
	#	$lerror =~ s/\n/ /g;
	#	print "-1|Error: " . $lerror . "\n";
	#	return undef;
	#}
	return $entity_views;
}

1;
