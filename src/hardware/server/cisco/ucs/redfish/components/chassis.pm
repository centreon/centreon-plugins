# Copyright 2024 Centreon (http://www.centreon.com/)
# Licensed under the Apache License, Version 2.0

package hardware::server::cisco::ucs::redfish::mode::components::chassis;

use strict;
use warnings;
use hardware::server::cisco::ucs::redfish::mode::components::resources qw($thresholds_redfish);

sub load {
    my ($self) = @_;
    # Data is pre-loaded by equipment.pm into $self->{data}->{chassis}
}

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'Checking chassis');
    $self->{components}->{chassis} = { name => 'chassis', total => 0, skip => 0 };
    return if $self->check_filter(section => 'chassis');

    for my $chassis (@{$self->{data}->{chassis}}) {
        my $id     = $chassis->{'Id'}   // $chassis->{'@odata.id'} // 'unknown';
        my $name   = $chassis->{'Name'} // $id;
        my $health = $chassis->{Status}->{Health} // 'Unknown';
        my $state  = $chassis->{Status}->{State}  // 'Unknown';

        next if $self->check_filter(section => 'chassis', instance => $id);
        $self->{components}->{chassis}->{total}++;

        $self->{output}->output_add(
            long_msg => sprintf("Chassis '%s' health is '%s' [state: %s].", $name, $health, $state)
        );

        my $threshold = $self->get_severity(
            section   => 'chassis',
            threshold => $thresholds_redfish->{health},
            value     => $health
        );
        if (!$self->{output}->is_status(value => $threshold, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity  => $threshold,
                short_msg => sprintf("Chassis '%s' health is '%s'.", $name, $health)
            );
        }
    }
}

1;
