sub datastoresvm_check_args {
	my ($lvm, $warn, $crit) = @_;
	if (!defined($lvm) || $lvm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm name\n");
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

sub datastoresvm_compute_args {
	my $lvm = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : '');
	my $crit = (defined($_[2]) ? $_[2] : '');
	return ($lvm, $warn, $crit);
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
	if (!defined($result2)) {
		return ;
	}

	#my %uuid_list = ();
	my %disk_name = ();
	my %datastore_lun = ();
	foreach (@$result2) {
		if ($_->info->isa('VmfsDatastoreInfo')) {
			#$uuid_list{$_->volume->uuid} = $_->volume->name;
			# Not need. We are on Datastore level (not LUN level)
			foreach my $extent (@{$_->info->vmfs->extent}) {
				$disk_name{$extent->diskName} = $_->info->vmfs->name;
				if (!defined($datastore_lun{$_->info->vmfs->name})) {
					%{$datastore_lun{$_->info->vmfs->name}} = ('disk.numberRead.summation' => 0, 'disk.numberWrite.summation'  => 0);
				}
			}
		}
		#if ($_->info->isa('NasDatastoreInfo')) {
			# Zero disk Info
		#}
	}

	# Vsphere >= 4.1
	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'disk.numberRead.summation', 'instances' => ['*']},
						{'label' => 'disk.numberWrite.summation', 'instances' => ['*']}],
						$perfcounter_speriod);

	foreach (keys %$values) {
		my ($id, $disk_name) = split(/:/);
		$datastore_lun{$disk_name{$disk_name}}{$perfcounter_cache_reverse{$id}} += $values->{$_}[0];
	}

	my $status = 0; # OK
	my $output = '';
	my $output_append = '';
	my $output_warning = '';
	my $output_warning_append = '';
	my $output_critical = '';
	my $output_critical_append = '';
	my $perfdata = '';
	foreach (keys %datastore_lun) {
		my $read_counter = simplify_number(convert_number($datastore_lun{$_}{'disk.numberRead.summation'} / $perfcounter_speriod));
		my $write_counter = simplify_number(convert_number($datastore_lun{$_}{'disk.numberWrite.summation'} / $perfcounter_speriod));

		if (defined($crit) && $crit ne "" && ($read_counter >= $crit)) {
			output_add(\$output_critical, \$output_critical_append, ", ",
				"read on '" . $_ . "' is $read_counter ms");
			$status |= $MYERRORS_MASK{'WARNING'};
		} elsif (defined($warn) && $warn ne "" && ($read_counter >= $warn)) {
			output_add(\$output_warning, \$output_warning_append, ", ",
				"read on '" . $_ . "' is $read_counter ms");
			$status |= $MYERRORS_MASK{'WARNING'};
		}
		if (defined($crit) && $crit ne "" && ($write_counter >= $crit)) {
			output_add(\$output_critical, \$output_critical_append, ", ",
				"write on '" . $_ . "' is $write_counter ms");
			$status |= $MYERRORS_MASK{'WARNING'};
		} elsif (defined($warn) && $warn ne "" && ($write_counter >= $warn)) {
			output_add(\$output_warning, \$output_warning_append, ", ",
				"write on '" . $_ . "' is $write_counter ms");
			$status |= $MYERRORS_MASK{'WARNING'};
		}
			
		$perfdata .= " 'riops_" . $_ . "'=" . $read_counter . "iops 'wiops_" . $_ . "'=" . $write_counter . 'iops';
	}

	if ($output_critical ne "") {
		$output .= $output_append . "CRITICAL - Datastore IOPS counter: $output_critical";
		$output_append = ". ";
	}
	if ($output_warning ne "") {
		$output .= $output_append . "WARNING - Datastore IOPS counter: $output_warning";
	}
        if ($status == 0) {
                $output = "All Datastore IOPS counters are ok";
        }
	print_response($ERRORS{$MYERRORS{$status}} . "|$output|$perfdata\n");
}

1;
