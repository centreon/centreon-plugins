
sub nethost_check_args {
	my ($host, $pnic, $warn, $crit) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
		return 1;
	}
	if (!defined($pnic) || $pnic eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need physical nic name\n");
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

sub nethost_compute_args {
	my $lhost = $_[0];
	my $pnic = $_[1];
	my $warn = (defined($_[2]) ? $_[2] : 80);
	my $crit = (defined($_[3]) ? $_[3] : 90);
	return ($lhost, $pnic, $warn, $crit);
}

sub nethost_do {
	my ($lhost, $pnic, $warn, $crit) = @_;
	if (!($perfcounter_speriod > 0)) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Can't retrieve perf counters.\n");
		return ;
	}

	my %filters = ('name' => $lhost);
	my @properties = ('config.network.pnic');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}
	my %pnic_def = ();
	foreach (@{$$result[0]->{'config.network.pnic'}}) {
		if (defined($_->linkSpeed)) {
			$pnic_def{$_->device} = $_->linkSpeed->speedMb;
		}
	}

	if (!defined($pnic_def{$pnic})) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
                print $ERRORS{$MYERRORS{$status}} . "|Link '$pnic' not exist or down.\n";
		return ;
	}


	my $values = generic_performance_values_historic($$result[0], 
						[{'label' => 'net.received.average', 'instances' => [$pnic]},
						 {'label' => 'net.transmitted.average', 'instances' => [$pnic]}],
						$perfcounter_speriod);

	my $traffic_in = simplify_number(convert_number($values->{$perfcounter_cache{'net.received.average'}->{'key'} . ":" . $pnic}[0]));	
	my $traffic_out = simplify_number(convert_number($values->{$perfcounter_cache{'net.transmitted.average'}->{'key'} . ":" . $pnic}[0]));
	my $status = 0; # OK
	my $output = '';
	
	if (($traffic_in / 1024 * 8 * 100 / $pnic_def{$pnic}) >= $warn || ($traffic_out / 1024 * 8 * 100 / $pnic_def{$pnic}) >= $warn) {
		$status |= $MYERRORS_MASK{'WARNING'};
	}
	if (($traffic_in / 1024 * 8 * 100 / $pnic_def{$pnic}) >= $crit || ($traffic_out / 1024 * 8 * 100 / $pnic_def{$pnic}) >= $crit) {
		$status |= $MYERRORS_MASK{'CRITICAL'};
	}

	$output = "Traffic In : " . simplify_number($traffic_in / 1024 * 8) . " Mb/s (" . simplify_number($traffic_in / 1024 * 8 * 100 / $pnic_def{$pnic}) . " %), Out : " . simplify_number($traffic_out / 1024 * 8) . " Mb/s (" . simplify_number($traffic_out / 1024 * 8 * 100 / $pnic_def{$pnic}) . " %)";
	$output .= "|traffic_in=" . ($traffic_in * 1024 * 8) . "b/s traffic_out=" . (($traffic_out * 1024 * 8)) . "b/s";

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
