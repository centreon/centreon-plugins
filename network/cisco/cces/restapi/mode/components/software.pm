#
# Copyright 2020 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package network::cisco::cces::restapi::mode::components::software;

use strict;
use warnings;

sub check {
    my ($self) = @_;

    $self->{output}->output_add(long_msg => 'checking software');
    $self->{components}->{software} = { name => 'software', total => 0, skip => 0 }  ;
    return if ($self->check_filter(section => 'software'));

    return if (!defined($self->{results}->{Provisioning}->{Software}->{UpgradeStatus}));

    my $instance = 'upgrade';
    return if ($self->check_filter(section => 'software', instance => $instance));
    $self->{components}->{software}->{total}++;

    $self->{output}->output_add(
        long_msg => sprintf(
            "software '%s' status is '%s' [instance: %s, urgency: %s]",
            $instance,
            $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Status},
            $instance,
            $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Urgency}
        )
    );

    my $exit = $self->get_severity(section => 'software_status', value => $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Status});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("software '%s' status is '%s'", $instance, $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Status})
        );
    }

    $exit = $self->get_severity(section => 'software_urgency', value => $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Urgency});
    if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
        $self->{output}->output_add(
            severity => $exit,
            short_msg => sprintf("software '%s' urgency is '%s'", $instance, $self->{results}->{Provisioning}->{Software}->{UpgradeStatus}->{Urgency})
        );
    }
}

1;
