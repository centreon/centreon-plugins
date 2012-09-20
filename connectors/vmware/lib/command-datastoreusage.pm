sub datastoreusage_check_args {
	my ($ds, $warn, $crit) = @_;
	if (!defined($ds) || $ds eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need datastore name\n");
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

sub datastoreusage_compute_args {
	my $ds = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : 80);
	my $crit = (defined($_[2]) ? $_[2] : 90);
	return ($ds, $warn, $crit);
}

sub datastoreusage_do {
	my ($ds, $warn, $crit) = @_;
	my %filters = ('name' => $ds);
	my @properties = ('summary');

	my $result = get_entities_host('Datastore', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = "";
	if ($$result[0]->summary->accessible == 1) {
		my $dsName = $$result[0]->summary->name;
		my $capacity = $$result[0]->summary->capacity;
		my $free = $$result[0]->summary->freeSpace;
		my $pct = ($capacity - $free) / $capacity * 100;

		my $usedD = ($capacity - $free) / 1024 / 1024 / 1024;
		my $sizeD = $capacity / 1024 / 1024 / 1024;
	
		$output = "Datastore $dsName - used ".sprintf("%.2f", $usedD)." Go / ".sprintf("%.2f", $sizeD)." Go (".sprintf("%.2f", $pct)." %) |used=".($capacity - $free)."o;;;0;".$capacity." size=".$capacity."o\n";
		if ($pct >= $warn) {
			$status |= $MYERRORS_MASK{'WARNING'};
		}
		if ($pct > $crit) {
			$status |= $MYERRORS_MASK{'CRITICAL'};
		}
	} else {
		$output = "Datastore '$ds' summary not accessible.";
		$status |= $MYERRORS_MASK{'UNKNOWN'};
	}
	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
