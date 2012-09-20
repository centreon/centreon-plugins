sub swaphost_check_args {
	my ($host, $warn, $crit) = @_;
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

sub swaphost_compute_args {
	my $lhost = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : 0.8);
	my $crit = (defined($_[2]) ? $_[2] : 1);
	return ($lhost, $warn, $crit);
}

sub swaphost_do {
	my ($lhost, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lhost);
	#my @properties = ('summary');
	my @properties = ();
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'mem.swapinRate.average', 'instances' => ['']},
						 {'label' => 'mem.swapoutRate.average', 'instances' => ['']}],
						$perfcounter_speriod);

	my $swap_in = simplify_number(convert_number($values->{$perfcounter_cache{'mem.swapinRate.average'}->{'key'} . ":"}[0]));
        my $swap_out = simplify_number(convert_number($values->{$perfcounter_cache{'mem.swapoutRate.average'}->{'key'} . ":"}[0]));
        my $status = 0; # OK
        my $output = '';

        if (($swap_in / 1024) >= $warn || ($swap_out / 1024) >= $warn) {
                $status |= $MYERRORS_MASK{'WARNING'};
        }
        if (($swap_in / 1024) >= $crit || ($swap_out / 1024) >= $crit) {
                $status |= $MYERRORS_MASK{'CRITICAL'};
        }

        $output = "Swap In : " . simplify_number($swap_in / 1024 * 8) . " Mb/s , Swap Out : " . simplify_number($swap_out / 1024 * 8) . " Mb/s ";
        $output .= "|swap_in=" . ($swap_in * 1024 * 8) . "b/s swap_out=" . (($swap_out * 1024 * 8)) . "b/s";

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
