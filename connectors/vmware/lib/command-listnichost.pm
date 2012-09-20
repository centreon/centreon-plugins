
sub listnichost_check_args {
	my ($host) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
		return 1;
	}
	return 0;
}

sub listnichost_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub listnichost_do {
	my ($lhost) = @_;
	my %filters = ('name' => $lhost);
	my @properties = ('config.network.pnic');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output_up = 'Nic Up List: ';
	my $output_down = 'Nic Down List: ';
	my $output_up_append = "";
	my $output_down_append = "";
	foreach (@{$$result[0]->{'config.network.pnic'}}) {
		if (defined($_->linkSpeed)) {
			$output_up .= $output_up_append . "'" . $_->device . "'";
			$output_up_append = ', ';
		} else {
			$output_down .= $output_down_append . "'" . $_->device . "'";
			$output_down_append = ', ';
		}
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output_up. $output_down.\n");
}

1;
