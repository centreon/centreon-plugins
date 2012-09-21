
sub toolsvm_check_args {
	my ($vm) = @_;
	if (!defined($vm) || $vm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm hostname\n");
		return 1;
	}
	return 0;
}

sub toolsvm_compute_args {
	my $lvm = $_[0];
	return ($lvm);
}

sub toolsvm_do {
	my ($lvm) = @_;

	my %filters = ('name' => $lvm);
	my @properties = ('summary.guest.toolsStatus');
	my $result = get_entities_host('VirtualMachine', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}
	
	my $status = 0; # OK
	my $output = '';

	my $tools_status = lc($$result[0]->{'summary.guest.toolsStatus'}->val);
	if ($tools_status eq 'toolsnotinstalled') {
		$output = "VMTools not installed on VM '$lvm'.";
		$status |= $MYERRORS_MASK{'CRITICAL'};
	} elsif ($tools_status eq 'toolsnotrunning') {
		$output = "VMTools not running on VM '$lvm'.";
		$status |= $MYERRORS_MASK{'CRITICAL'};
	} elsif ($tools_status eq 'toolsold') {
		$output = "VMTools not up-to-date on VM '$lvm'.";
		$status |= $MYERRORS_MASK{'WARNING'};
	} else {
		$output = "VMTools are OK on VM '$lvm'.";
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
