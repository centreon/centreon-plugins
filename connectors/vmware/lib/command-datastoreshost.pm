sub datastoreshost_check_args {
	my ($lhost, $warn, $crit) = @_;
	if (!defined($lhost) || $lhost eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need host name\n");
		return 1;
	}
	if (defined($warn) && $warn ne "" && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: warn threshold must be a positive number\n");
		return 1;
	}
	if (defined($crit) && $crit ne "" && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: crit threshold must be a positive number\n");
		return 1;
	}
	if (defined($warn) && defined($crit) && $warn ne "" && $crit ne "" && $warn > $crit) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: warn threshold must be lower than crit threshold\n");
		return 1;
	}
	return 0;
}

sub datastoreshost_compute_args {
	my $lhost = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : '');
	my $crit = (defined($_[2]) ? $_[2] : '');
	my $filter_ds = (defined($_[3]) ? $_[3] : '');
	return ($lhost, $warn, $crit, $filter_ds);
}

sub datastoreshost_do {
	my ($lhost, $warn, $crit, $filter_ds) = @_;

	my %valid_ds = ();
	my $filter_ok = 0;
	if ($filter_ds ne '') {
		foreach (split /,/, $filter_ds) {
			$valid_ds{$_} = 1;
		}
	}
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lhost);
	my @properties = ('config.fileSystemVolume.mountInfo');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my %uuid_list = ();
	my %disk_name = ();
	foreach (@{$$result[0]->{'config.fileSystemVolume.mountInfo'}}) {
		if ($_->volume->isa('HostVmfsVolume')) {
			$uuid_list{$_->volume->uuid} = $_->volume->name;
			# Not need. We are on Datastore level (not LUN level)
			#foreach my $extent (@{$_->volume->extent}) {
			#	$disk_name{$extent->diskName} = $_->volume->name;
			#}
		}
		if ($_->volume->isa('HostNasVolume')) {
			$uuid_list{basename($_->mountInfo->path)} = $_->volume->name;
		}
	}

	# Vsphere >= 4.1
	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'datastore.totalReadLatency.average', 'instances' => ['*']},
						{'label' => 'datastore.totalWriteLatency.average', 'instances' => ['*']}],
						$perfcounter_speriod);

	my $status = 0; # OK
	my $output = '';
	my $output_append = '';
	my $output_warning = '';
	my $output_warning_append = '';
	my $output_critical = '';
	my $output_critical_append = '';
	my $perfdata = '';
	foreach (keys %uuid_list) {
		if ($filter_ds ne '' and !defined($valid_ds{$uuid_list{$_}})) {
			next;
		}
		if (defined($values->{$perfcounter_cache{'datastore.totalReadLatency.average'}->{'key'} . ":" . $_}) and
		    defined($values->{$perfcounter_cache{'datastore.totalWriteLatency.average'}->{'key'} . ":" . $_})) {
			my $read_counter = simplify_number(convert_number($values->{$perfcounter_cache{'datastore.totalReadLatency.average'}->{'key'} . ":" . $_}[0]));
			my $write_counter = simplify_number(convert_number($values->{$perfcounter_cache{'datastore.totalWriteLatency.average'}->{'key'} . ":" . $_}[0]));
			if (defined($crit) && $crit ne "" && ($read_counter >= $crit)) {
				output_add(\$output_critical, \$output_critical_append, ", ",
					"read on '" . $uuid_list{$_} . "' is $read_counter ms");
				$status |= $MYERRORS_MASK{'WARNING'};
			} elsif (defined($warn) && $warn ne "" && ($read_counter >= $warn)) {
				output_add(\$output_warning, \$output_warning_append, ", ",
					"read on '" . $uuid_list{$_} . "' is $read_counter ms");
				$status |= $MYERRORS_MASK{'WARNING'};
			}
			if (defined($crit) && $crit ne "" && ($write_counter >= $crit)) {
				output_add(\$output_critical, \$output_critical_append, ", ",
					"write on '" . $uuid_list{$_} . "' is $write_counter ms");
				$status |= $MYERRORS_MASK{'WARNING'};
			} elsif (defined($warn) && $warn ne "" && ($write_counter >= $warn)) {
				output_add(\$output_warning, \$output_warning_append, ", ",
					"write on '" . $uuid_list{$_} . "' is $write_counter ms");
				$status |= $MYERRORS_MASK{'WARNING'};
			}
			
			$filter_ok = 1;
			$perfdata .= " 'trl_" . $uuid_list{$_} . "'=" . $read_counter . "ms 'twl_" . $uuid_list{$_} . "'=" . $write_counter . 'ms';
		}
	}

	if ($filter_ds ne '' and $filter_ok == 0) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Datastore names in filter are unknown.\n");
		return ;
	}
	if ($output_critical ne "") {
		$output .= $output_append . "CRITICAL - Latency counter: $output_critical";
		$output_append = ". ";
	}
	if ($output_warning ne "") {
		$output .= $output_append . "WARNING - Latency counter: $output_warning";
	}
        if ($status == 0) {
                $output = "All Datastore latency counters are ok";
        }
	print_response($ERRORS{$MYERRORS{$status}} . "|$output|$perfdata\n");
}

1;
