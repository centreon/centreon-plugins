
sub snapshotvm_check_args {
	my ($vm, $older) = @_;
	if (!defined($vm) || $vm eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need vm hostname\n");
		return 1;
	}
	if (defined($older) && $older ne '' && $older !~ /^-?(?:\d+\.?|\.\d)\d*\z/) {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: older arg must be a positive number\n");
		return 1;
        }
	return 0;
}

sub snapshotvm_compute_args {
	my $lvm = $_[0];
	my $older = ((defined($_[1]) and $_[1] ne '') ? $_[1] : -1);
	my $warn = ((defined($_[2]) and $_[2] ne '') ? $_[2] : 0);
	my $crit = ((defined($_[3]) and $_[3] ne '') ? $_[3] : 0);
	return ($lvm, $older, $warn, $crit);
}

sub snapshotvm_do {
	my ($lvm, $older, $warn, $crit) = @_;

	if ($older != -1 && $module_date_parse_loaded == 0) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
		print_response($ERRORS{$MYERRORS{$status}} . "|Need to install DateTime::Format::ISO8601 CPAN Module.\n");
		return ;
	}

	my %filters = ('name' => $lvm);
	my @properties = ('snapshot.rootSnapshotList');
	my $result = get_entities_host('VirtualMachine', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = 'Snapshot(s) OK';

	if (!defined($$result[0]->{'snapshot.rootSnapshotList'})) {
		$output = 'No current snapshot.';
		print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
		return ;
	}
	
	foreach my $snapshot (@{$$result[0]->{'snapshot.rootSnapshotList'}}) {
		if ($older != -1 && time() - $create_time->epoch > $older) {
            # 2012-09-21T14:16:17.540469Z
            my $create_time = DateTime::Format::ISO8601->parse_datetime($snapshot->createTime);
			if ($warn == 1) {
				$output = 'Older snapshot problem (' . $snapshot->createTime . ').';
				$status |= $MYERRORS_MASK{'WARNING'};
			}
			if ($crit == 1) {
				$output = 'Older snapshot problem (' . $snapshot->createTime . ').';
				$status |= $MYERRORS_MASK{'CRITICAL'};
			}
		} elsif ($older == -1) {
			if ($warn == 1) {
				$output = 'There is at least one snapshot.';
				$status |= $MYERRORS_MASK{'WARNING'};
			}
			if ($crit == 1) {
				$output = 'There is at least one snapshot.';
				$status |= $MYERRORS_MASK{'CRITICAL'};
			}
		}
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
