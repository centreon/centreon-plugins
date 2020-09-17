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

package hardware::server::hp::oneview::restapi::mode::components::enclosure;

use strict;
use warnings;

sub load {
    my ($self) = @_;

    push @{$self->{requests}}, { label => 'enclosure', uri => '/rest/enclosures?start=0&count=-1' };
}

sub check_subpart {
    my ($self, %options) = @_;

    foreach (@{$options{entries}}) {
        my $instance = $options{enclosure} . ':' . $_->{$options{instance}};

        next if ($self->check_filter(section => 'enclosure.' . $options{section}, instance => $instance));
        next if ($_->{devicePresence} =~ /absent/i);

        my $status = defined($_->{status}) ? $_->{status} : 'n/a';
        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure %s '%s' status is '%s' [instance = %s]",
                $options{section}, $instance, $status, $instance,
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'enclosure.' . $options{section}, value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Enclosure %s '%s' status is '%s'", $options{section}, $instance, $status)
            );
        }
    }
}

sub check {
    my ($self) = @_;

    return if (!defined($self->{results}->{enclosure}));

    $self->{output}->output_add(long_msg => 'checking enclosures');
    $self->{components}->{enclosure} = { name => 'enclosure', total => 0, skip => 0 };
    return if ($self->check_filter(section => 'enclosure'));

    foreach (@{$self->{results}->{enclosure}->{members}}) {
        my $instance = $_->{uuid};
        
        next if ($self->check_filter(section => 'enclosure', instance => $instance));
        $self->{components}->{enclosure}->{total}++;

        my $status = $_->{status};
        $self->{output}->output_add(
            long_msg => sprintf(
                "enclosure '%s' status is '%s' [instance = %s]",
                $instance, $status, $instance,
            )
        );

        my $exit = $self->get_severity(label => 'default', section => 'enclosure', value => $status);
        if (!$self->{output}->is_status(value => $exit, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(
                severity => $exit,
                short_msg => sprintf("Enclosure '%s' status is '%s'", $instance, $status)
            );
        }

        check_subpart(
            $self, 
            entries => $_->{fanBays}, 
            section => 'fan',
            enclosure => $instance,
            instance => 'bayNumber'
        );
        check_subpart(
            $self, 
            entries => $_->{powerSupplyBays}, 
            section => 'psu',
            enclosure => $instance,
            instance => 'bayNumber'
        );
        check_subpart(
            $self, 
            entries => $_->{managerBays}, 
            section => 'manager',
            enclosure => $instance,
            instance => 'bayNumber'
        );
        check_subpart(
            $self, 
            entries => $_->{applianceBays}, 
            section => 'appliance',
            enclosure => $instance,
            instance => 'bayNumber'
        );
    }
}

1;
