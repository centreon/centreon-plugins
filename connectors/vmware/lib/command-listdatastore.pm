sub listdatastore_check_args {
	return 0;
}

sub listdatastore_compute_args {
	return undef;
}

sub listdatastore_do {
	my ($ds, $warn, $crit) = @_;
	my %filters = ();
	my @properties = ('datastore');

	my $result = get_entities_host('Datacenter', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my @ds_array = ();
	foreach my $entity_view (@$result) {
		if (defined $entity_view->datastore) {
	 		   @ds_array = (@ds_array, @{$entity_view->datastore});
		}
	}

	@properties = ('summary');
	$result = get_views(\@ds_array, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = 'Datastore List: ';
	my $output_append = "";
	foreach my $datastore (@$result) {
		if ($datastore->summary->accessible) {
			$output .= $output_append . "'" . $datastore->summary->name . "'";
			$output_append = ', ';
		}
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
