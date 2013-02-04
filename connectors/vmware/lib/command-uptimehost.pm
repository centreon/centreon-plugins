sub uptimehost_check_args {
	my ($lhost) = @_;
	if (!defined($lhost) || $lhost eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need host name\n");
		return 1;
	}
	return 0;
}

sub uptimehost_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub uptimehost_do {
	my ($lhost) = @_;

	my %filters = ('name' => $lhost);
	my @properties = ('runtime.bootTime');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	if ($module_date_parse_loaded == 0) {
		my $status |= $MYERRORS_MASK{'UNKNOWN'};
                print_response($ERRORS{$MYERRORS{$status}} . "|Need to install DateTime::Format::ISO8601 Perl Module.\n");
		return ;
	}

	my $create_time = DateTime::Format::ISO8601->parse_datetime($$result[0]->{'runtime.bootTime'});
	my $diff_time = time() - $create_time->epoch;
	my $days = int($diff_time / 60 / 60 / 24);

	my $output = '';
	my $status = 0; # OK

	$output = "Uptime (in day): $days|uptime=" . $days . "day(s)\n";

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
