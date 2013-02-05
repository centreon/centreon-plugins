sub memvm_check_args {
	my ($vm, $warn, $crit) = @_;
	if (!defined($vm) || $vm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm name\n");
		return 1;
	}
	if (defined($warn) && $warn !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: warn threshold must be a positive number\n");
		return 1;
	}
	if (defined($crit) && $crit !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: crit threshold must be a positive number\n");
		return 1;
	}
	if (defined($warn) && defined($crit) && $warn > $crit) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: warn threshold must be lower than crit threshold\n");
		return 1;
	}
	return 0;
}

sub memvm_compute_args {
	my $lvm = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : 80);
	my $crit = (defined($_[2]) ? $_[2] : 90);
	return ($lvm, $warn, $crit);
}

sub memvm_do {
	my ($lvm, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lvm);
	my @properties = ('summary.config.memorySizeMB');
	my $result = get_entities_host('VirtualMachine', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $memory_size = $$result[0]->{'summary.config.memorySizeMB'} * 1024 * 1024;

	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'mem.active.average', 'instances' => ['']},
						 {'label' => 'mem.overhead.average', 'instances' => ['']},
						 {'label' => 'mem.vmmemctl.average', 'instances' => ['']},
						 {'label' => 'mem.consumed.average', 'instances' => ['']},
						 {'label' => 'mem.shared.average', 'instances' => ['']}],
						$perfcounter_speriod);

	my $mem_consumed = simplify_number(convert_number($values->{$perfcounter_cache{'mem.consumed.average'}->{'key'} . ":"}[0]));
	my $mem_active = simplify_number(convert_number($values->{$perfcounter_cache{'mem.active.average'}->{'key'} . ":"}[0]));
	my $mem_overhead = simplify_number(convert_number($values->{$perfcounter_cache{'mem.overhead.average'}->{'key'} . ":"}[0]));
	my $mem_ballooning = simplify_number(convert_number($values->{$perfcounter_cache{'mem.vmmemctl.average'}->{'key'} . ":"}[0]));
	my $mem_shared = simplify_number(convert_number($values->{$perfcounter_cache{'mem.shared.average'}->{'key'} . ":"}[0]));
	my $status = 0; # OK
	my $output = '';
	
	if ($mem_consumed * 100 / ($memory_size / 1024) >= $warn) {
		$status |= $MYERRORS_MASK{'WARNING'};
	}
	if ($mem_consumed * 100 / ($memory_size / 1024) >= $crit) {
		$status |= $MYERRORS_MASK{'CRITICAL'};
	}

	$output = "Memory usage : " . simplify_number($mem_consumed / 1024 / 1024) . " Go - size : " . simplify_number($memory_size / 1024 / 1024 / 1024) . " Go - percent : " . simplify_number($mem_consumed * 100 / ($memory_size / 1024)) . " %";
	$output .= "|usage=" . ($mem_consumed * 1024) . "o;" . simplify_number($memory_size * $warn / 100, 0) . ";" . simplify_number($memory_size * $crit / 100, 0) . ";0;" . ($memory_size) . " size=" . $memory_size . "o" . " overhead=" . ($mem_overhead * 1024) . "o" . " ballooning=" . ($mem_ballooning * 1024) . "o" . " shared=" . ($mem_shared * 1024) . "o" . " active=" . ($mem_active * 1024) . "o" ;

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
