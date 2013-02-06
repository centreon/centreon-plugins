
sub cpuvm_check_args {
	my ($vm, $warn, $crit) = @_;
	if (!defined($vm) || $vm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm hostname\n");
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

sub cpuvm_compute_args {
	my $lvm = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : 80);
	my $crit = (defined($_[2]) ? $_[2] : 90);
	return ($lvm, $warn, $crit);
}

sub cpuvm_do {
	my ($lvm, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lvm);
	my @properties = ('name');
	my $result = get_entities_host('VirtualMachine', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my @instances = ('*');

	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'cpu.usage.average', 'instances' => \@instances},
						 {'label' => 'cpu.usagemhz.average', 'instances' => \@instances}],
						$perfcounter_speriod);

	my $status = 0; # OK
	my $output = '';
	my $total_cpu_average = simplify_number(convert_number($values->{$perfcounter_cache{'cpu.usage.average'}->{'key'} . ":"}[0] * 0.01));
	my $total_cpu_mhz_average = simplify_number(convert_number($values->{$perfcounter_cache{'cpu.usagemhz.average'}->{'key'} . ":"}[0]));
	
	if ($total_cpu_average >= $warn) {
		$status |= $MYERRORS_MASK{'WARNING'};
	}
	if ($total_cpu_average >= $crit) {
		$status |= $MYERRORS_MASK{'CRITICAL'};
	}

	$output = "Total Average CPU usage '$total_cpu_average%', Total Average CPU '" . $total_cpu_mhz_average . "MHz' on last " . int($perfcounter_speriod / 60) . "min | cpu_total=$total_cpu_average%;$warn;$crit;0;100 cpu_total_MHz=" . $total_cpu_mhz_average . "MHz";

	foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
			       my ($cidb, $cib) = split /:/, $b;
                               $cia = -1 if (!defined($cia) || $cia eq "");
                               $cib = -1 if (!defined($cib) || $cib eq "");
			       $cia <=> $cib} keys %$values) {
		my ($counter_id, $instance) = split /:/, $id;
		if ($instance ne "") {
			$output .= " cpu" . $instance . "_MHz=" . simplify_number(convert_number($values->{$id}[0])) . "MHz";
		}
	}
	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
