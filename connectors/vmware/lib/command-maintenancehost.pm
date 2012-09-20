sub maintenancehost_check_args {
	my ($host) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
		return 1;
	}
	return 0;
}

sub maintenancehost_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub maintenancehost_do {
	my ($lhost) = @_;
	my %filters = ('name' => $lhost);
	my @properties = ('runtime.inMaintenanceMode');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = '';

	foreach my $entity_view (@$result) {
		if ($entity_view->{'runtime.inMaintenanceMode'} ne "false") {
			$status |= $MYERRORS_MASK{'CRITICAL'};
			$output = "Server $lhost is on maintenance mode.";
		} else {
			$output = "Server $lhost is not on maintenance mode.";
		}
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
