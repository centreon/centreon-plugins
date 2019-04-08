#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::voip::3cx::restapi::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{single} = $options{custom}->api_single_status();
    $self->{system} = $options{custom}->api_system_status();
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $item (sort keys %{$self->{single}}) {
        $self->{output}->output_add(severity => $self->{single}->{$item} ? 'OK' : 'CRITICAL',
                                    short_msg => $item);
    }
    $self->{output}->output_add(severity => $self->{system}->{HasNotRunningServices} ? 'CRITICAL' : 'OK',
                                short_msg => 'Services');
    $self->{output}->output_add(severity => $self->{system}->{HasUnregisteredSystemExtensions} ? 'CRITICAL' : 'OK',
                                short_msg => 'Extensions');

    $self->{output}->perfdata_add(label => "CallsActive", unit => '', value => $self->{system}->{CallsActive});
    $self->{output}->perfdata_add(label => "ExtensionsRegistered", unit => '', value => $self->{system}->{ExtensionsRegistered});

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

List status

=over 8

=back

=cut
