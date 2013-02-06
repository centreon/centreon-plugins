sub cpuhost_check_args {
	my ($host, $warn, $crit, $light_perfdata) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
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

sub cpuhost_compute_args {
	my $lhost = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : 80);
	my $crit = (defined($_[2]) ? $_[2] : 90);
	my $light_perfdata = (defined($_[3]) ? $_[3] : 0);
	return ($lhost, $warn, $crit, $light_perfdata);
}

sub cpuhost_do {
	my ($lhost, $warn, $crit, $light_perfdata) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lhost);
	my @properties = ('name');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my @instances = ('*');

	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'cpu.usage.average', 'instances' => \@instances}],
						$perfcounter_speriod);

	my $status = 0; # OK
	my $output = '';
	my $total_cpu_average = simplify_number(convert_number($values->{$perfcounter_cache{'cpu.usage.average'}->{'key'} . ":"}[0] * 0.01));
	
	if ($total_cpu_average >= $warn) {
		$status |= $MYERRORS_MASK{'WARNING'};
	}
	if ($total_cpu_average >= $crit) {
		$status |= $MYERRORS_MASK{'CRITICAL'};
	}

	$output = "Total Average CPU usage '$total_cpu_average%' on last " . int($perfcounter_speriod / 60) . "min | cpu_total=$total_cpu_average%;$warn;$crit;0;100";

	foreach my $id (sort { my ($cida, $cia) = split /:/, $a;
			       my ($cidb, $cib) = split /:/, $b;
                               $cia = -1 if (!defined($cia) || $cia eq "");
                               $cib = -1 if (!defined($cib) || $cib eq "");
			       $cia <=> $cib} keys %$values) {
		my ($counter_id, $instance) = split /:/, $id;
		if ($instance ne "" and $light_perfdata != 1) {
			$output .= " cpu$instance=" . simplify_number(convert_number($values->{$id}[0]) * 0.01) . "%;;0;100";
		}
	}
	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
