sub datastoreio_check_args {
	my ($ds, $warn, $crit) = @_;
	if (!defined($ds) || $ds eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need datastore name\n");
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

sub datastoreio_compute_args {
	my $ds = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : '');
	my $crit = (defined($_[2]) ? $_[2] : '');
	return ($ds, $warn, $crit);
}

sub datastoreio_do {
	my ($ds, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('summary.name' => $ds);
	my @properties = ('summary.name');
	my $result = get_entities_host('Datastore', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'datastore.read.average', 'instances' => ['']},
						 {'label' => 'datastore.write.average', 'instances' => ['']}],
						$perfcounter_speriod);

	my $read_counter = simplify_number(convert_number($values->{$perfcounter_cache{'datastore.read.average'}->{'key'} . ":"}[0]));	
	my $write_counter = simplify_number(convert_number($values->{$perfcounter_cache{'datastore.write.average'}->{'key'} . ":"}[0]));

	my $status = 0; # OK
	my $output = '';
	
	if ((defined($warn) && $warn ne "") && ($read_counter >= $warn || $write_counter >= $warn)) {
		$status |= $MYERRORS_MASK{'WARNING'};
	}
	if ((defined($crit) && $crit ne "") && ($read_counter >= $crit || $write_counter >= $crit)) {
		$status |= $MYERRORS_MASK{'CRITICAL'};
	}

	$output = "Rate of reading data : " . simplify_number($read_counter / 1024 * 8) . " Mb/s,  Rate of writing data : " . simplify_number($write_counter / 1024 * 8) . " Mb/s";
	$output .= "|read_rate=" . ($read_counter * 1024 * 8) . "b/s write_rate=" . (($write_counter * 1024 * 8)) . "b/s";

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
