sub countvmhost_check_args {
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

sub countvmhost_compute_args {
	my $lhost = $_[0];
	my $warn = (defined($_[1]) ? $_[1] : '');
	my $crit = (defined($_[2]) ? $_[2] : '');
	return ($lhost, $warn, $crit);
}

sub countvmhost_do {
	my ($lhost, $warn, $crit) = @_;

	my %filters = ('name' => $lhost);
	my @properties = ('vm');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my @vm_array = ();
	foreach my $entity_view (@$result) {
		if (defined $entity_view->vm) {
			@vm_array = (@vm_array, @{$entity_view->vm});
		}
	}
	@properties = ('runtime.powerState');
	$result = get_views(\@vm_array, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $output = '';
	my $status = 0; # OK
	my $num_poweron = 0;	

	foreach (@$result) {
		my $power_value = lc($_->{'runtime.powerState'}->val);
		if ($power_value eq 'poweredon') {
			$num_poweron++;
		}
	}
	if (defined($crit) && $crit ne "" && ($num_poweron >= $crit)) {
		$output = "CRITICAL: $num_poweron VM running.";
		$status |= $MYERRORS_MASK{'CRITICAL'};
	} elsif (defined($warn) && $warn ne "" && ($num_poweron >= $warn)) {
		$output = "WARNING: $num_poweron VM running.";
		$status |= $MYERRORS_MASK{'WARNING'};
	} else {
		$output = "OK: $num_poweron VM running.";
	}
	
	print_response($ERRORS{$MYERRORS{$status}} . "|$output|count=$num_poweron\n");
}

1;
