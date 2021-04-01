#
# Copyright 2021 Centreon (http://www.centreon.com/)
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

package apps::monitoring::netdata::restapi::mode::listdisks;

use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub run {
    my ($self, %options) = @_;

    my $full_list = $options{custom}->list_charts();

    foreach my $chart (values %{$full_list->{charts}}) {
        next if ($chart->{name} !~ 'disk_space._');
        push @{$self->{fs_list}}, $chart->{name};
        $chart->{name} =~s/disk_space.//;
        $chart->{name} =~ s/_/\//g;
        $self->{output}->output_add(
            long_msg => sprintf(
                "[name = %s][title = %s]",
                $chart->{name},
                $chart->{title},
            )
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'Server disks:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => [ 'name', 'title' ]);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->run(%options);
    foreach my $fs (@{$self->{fs_list}}) {
        $self->{output}->add_disco_entry(
            name   => $fs->{name},
            status => $fs->{title},
        );
    }
}

1;

__END__

=head1 MODE

List system disks using the Netdata agent Restapi.

=back

=cut
