
sub getmap_check_args {
	return 0;
}

sub getmap_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub getmap_do {
	my ($lhost) = @_;
	my %filters = ();
	if (defined($lhost) and $lhost ne "") {
		%filters = ('name' => $lhost);
	}
	my @properties = ('name', 'vm');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}

	my $status = 0; # OK
	my $output = '';
	my $output_append = "";

	foreach my $entity_view (@$result) {
		$output .= $output_append . "ESX Host '" . $entity_view->name . "': ";
		my @vm_array = ();
		if (defined $entity_view->vm) {
	 		   @vm_array = (@vm_array, @{$entity_view->vm});
		}

		@properties = ('name', 'summary.runtime.powerState');
		my $result2 = get_views(\@vm_array, \@properties);
		if (!defined($result)) {
			return ;
		}
		
		my $output_append2 = '';
		foreach my $vm (@$result2) {
			if ($vm->{'summary.runtime.powerState'}->val eq "poweredOn") {
				$output .= $output_append2 . "[" . $vm->name . "]";
				$output_append2 = ', ';
			}
		}
		$output_append = ". ";
	}

	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
