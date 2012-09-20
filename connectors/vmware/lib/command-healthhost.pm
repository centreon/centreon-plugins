sub healthhost_check_args {
	my ($host) = @_;
	if (!defined($host) || $host eq "") {
		writeLogFile(LOG_ESXD_ERROR, "ARGS error: need hostname\n");
		return 1;
	}
	return 0;
}

sub healthhost_compute_args {
	my $lhost = $_[0];
	return ($lhost);
}

sub healthhost_do {
	my ($lhost) = @_;

	my %filters = ('name' => $lhost);
	my @properties = ('runtime.healthSystemRuntime.hardwareStatusInfo.cpuStatusInfo', 'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo');
	my $result = get_entities_host('HostSystem', \%filters, \@properties);
	if (!defined($result)) {
		return ;
	}
	
	my $status = 0; # OK
	my $output_critical = '';
	my $output_critical_append = '';
	my $output_warning = '';
	my $output_warning_append = '';
	my $output = '';
	my $output_append = '';
	my $OKCount = 0;
	my $CAlertCount = 0;
	my $WAlertCount = 0;
	foreach my $entity_view (@$result) {
    		my $cpuStatusInfo = $entity_view->{'runtime.healthSystemRuntime.hardwareStatusInfo.cpuStatusInfo'};
		my $numericSensorInfo = $entity_view->{'runtime.healthSystemRuntime.systemHealthInfo.numericSensorInfo'};
		if (!defined($cpuStatusInfo)) {
			$status |= $MYERRORS_MASK{'CRITICAL'};
			output_add(\$output_critical, \$output_critical_append, ", ",
				"API error - unable to get cpuStatusInfo");
		}
		if (!defined($numericSensorInfo)) {
			$status |= $MYERRORS_MASK{'CRITICAL'};
			output_add(\$output_critical, \$output_critical_append, ", ",
				"API error - unable to get numericSensorInfo");
		}

		# CPU
		foreach (@$cpuStatusInfo) {
			if ($_->status->key =~ /^red$/i) {
				output_add(\$output_critical, \$output_critical_append, ", ",
					$_->name . ": " . $_->status->summary);
				$status |= $MYERRORS_MASK{'CRITICAL'};
				$CAlertCount++;
			} elsif ($_->status->key =~ /^yellow$/i) {
				output_add(\$output_warning, \$output_warning_append, ", ",
					$_->name . ": " . $_->status->summary);
				$status |= $MYERRORS_MASK{'WARNING'};
				$WAlertCount++;
			} else {
				$OKCount++;
			}
		}
		# Sensor
		foreach (@$numericSensorInfo) {
			if ($_->healthState->key =~ /^red$/i) {
				output_add(\$output_critical, \$output_critical_append, ", ",
					$_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
				$status |= $MYERRORS_MASK{'CRITICAL'};
				$CAlertCount++;
			} elsif ($_->healthState->key =~ /^yellow$/i) {
				output_add(\$output_warning, \$output_warning_append, ", ",
					$_->sensorType . " sensor " . $_->name . ": ".$_->healthState->summary);
				$status |= $MYERRORS_MASK{'WARNING'};
				$WAlertCount++;
			} else {
				$OKCount++;
			}
		}
	}

	if ($output_critical ne "") {
		$output .= $output_append . "CRITICAL - $CAlertCount health issue(s) found: $output_critical";
		$output_append = ". ";
	}
	if ($output_warning ne "") {
		$output .= $output_append . "WARNING - $WAlertCount health issue(s) found: $output_warning";
	}
	if ($status == 0) {
		$output = "All $OKCount health checks are green";
	}
	
	print_response($ERRORS{$MYERRORS{$status}} . "|$output\n");
}

1;
