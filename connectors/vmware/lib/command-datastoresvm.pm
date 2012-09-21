sub datastoresvm_check_args {
	my ($lvm) = @_;
	if (!defined($lvm) || $lvm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm name\n");
		return 1;
	}
	return 0;
}

sub datastoresvm_compute_args {
	my $lvm = $_[0];
	return ($lvm);
}

sub datastoresvm_do {
	my ($lhost, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lhost);
	my @properties = ('datastore');
	my $result = get_entities_host('VirtualMachine', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my @ds_array = ();
	foreach my $entity_view (@$result) {
		if (defined $entity_view->datastore) {
	 		   @ds_array = (@ds_array, @{$entity_view->datastore});
		}
	}
	@properties = ('info');
	my $result2 = get_views(\@ds_array, \@properties);
	if (!defined($result)) {
		return ;
	}

	#my %uuid_list = ();
	my %disk_name = ();
	my %datastore_lun = ();
	foreach (@$result2) {
		writeLogFile(1, Data::Dumper::Dumper($_));
		if ($_->info->vmfs->isa('HostVmfsVolume')) {
			#$uuid_list{$_->volume->uuid} = $_->volume->name;
			# Not need. We are on Datastore level (not LUN level)
			foreach my $extent (@{$_->info->vmfs->extent}) {
				$disk_name{$extent->diskName} = $_->info->vmfs->name;
				if (!defined($datastore_lun{$_->info->vmfs->name})) {
					%{$datastore_lun{$_->info->vmfs->name}} = ();
				}
				$datastore_lun{$_->info->vmfs->name}{$extent->diskName} = 0;
			}
		}
		if ($_->info->vmfs->isa('HostNasVolume')) {
			#$uuid_list{basename($_->mountInfo->path)} = $_->volume->name;
			$disk_name{basename($_->info->mountInfo->path)} = $_->info->vmfs->name;
			if (!defined($datastore_lun{$_->info->vmfs->name})) {
				%{$datastore_lun{$_->info->vmfs->name}} = ();
			}
			$datastore_lun{$_->info->vmfs->name}{basename($_->info->mountInfo->path)} = 0;
		}
	}

	writeLogFile(1, Data::Dumper::Dumper(%datastore_lun));
	
	# Vsphere >= 4.1
	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'datastore.totalReadLatency.average', 'instances' => ['*']},
						{'label' => 'datastore.totalWriteLatency.average', 'instances' => ['*']},
						{'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
						$perfcounter_speriod);

	writeLogFile(1, Data::Dumper::Dumper($values) . "\n");

	my $status = 0; # OK
	my $output = '';
	my $output_append = '';
	my $output_warning = '';
	my $output_warning_append = '';
	my $output_critical = '';
	my $output_critical_append = '';
	my $perfdata = '';
	foreach (keys %uuid_list) {
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
			
			$perfdata .= " 'trl_" . $uuid_list{$_} . "'=" . $read_counter . "ms 'twl_" . $uuid_list{$_} . "'=" . $write_counter . 'ms';
		}
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
