#
# Copyright 2025 Centreon (http://www.centreon.com/)
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

package apps::podman::restapi::mode::listpods;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
                                   {
                                   });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $pods = $options{custom}->list_pods();
    foreach my $pod_id (sort keys %{$pods}) {
        $self->{output}->output_add(long_msg => '[id = ' . $pod_id . "]" .
                                                " [name = '" . $pods->{$pod_id}->{Name} . "']" .
                                                " [status = '" . $pods->{$pod_id}->{Status} . "']"
        );
    }

    $self->{output}->output_add(severity  => 'OK',
                                short_msg => 'Pods:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'id', 'name', 'status' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    my $pods = $options{custom}->list_pods();
    foreach my $pod_id (sort keys %{$pods}) {
        $self->{output}->add_disco_entry(name  => $pods->{$pod_id}->{Name},
                                         state => $pods->{$pod_id}->{Status},
                                         id    => $pod_id,
        );
    }
}

1;

__END__

=head1 MODE

List pods.

=over 8

=back

=cut
    
