
sub listhost_check_args {
	return 0;
}

sub listhost_compute_args {
	return undef;
}

sub listhost_do {
	my %filters = ();
	my @properties = ('name');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = 'Host List: ';
	my $output_append = "";

	foreach my $entity_view (@$result) {
		$output .= $output_append . $entity_view->{name};
		$output_append = ', ';
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
