sub statushost_check_args {
	my ($host) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
		return 1;
	}
	return 0;
}

sub statushost_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub statushost_do {
	my ($lhost) = @_;
	my %filters = ('name' => $lhost);
	my @properties = ('summary.overallStatus');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = '';

	my %overallStatus = (
		'gray' => 'status is unknown',
 		'green' => 'is OK',
		'red' => 'has a problem',
		'yellow' => 'might have a problem',
	);
	my %overallStatusReturn = (
		'gray' => 'UNKNOWN',
		'green' => 'OK',
		'red' => 'CRITICAL',
		'yellow' => 'WARNING'
	);

	foreach my $entity_view (@$result) {
		my $status_esx = $entity_view->{'summary.overallStatus'}->val;

		if (defined($status) && $overallStatus{$status_esx}) {
			$output = "The Server '$lhost' " . $overallStatus{$status_esx};
			if ($MYERRORS_MASK{$overallStatusReturn{$status_esx}} != 0) {
				$status |= $MYERRORS_MASK{$overallStatusReturn{$status_esx}};
			}
		} else {
			$output = "Can't interpret data...";
			$status |= $MYERRORS_MASK{'UNKNOWN'};
		}
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
