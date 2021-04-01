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

package apps::mq::rabbitmq::restapi::mode::listvhosts;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use URI::Encode;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $uri = URI::Encode->new({encode_reserved => 1});
    my $result = $options{custom}->query(url_path => '/api/vhosts/?columns=name');
    $self->{vhost} = {};
    foreach (@$result) {
        my $result_alive = $options{custom}->query(url_path => '/api/aliveness-test/' . $uri->encode($_->{name}));
        $self->{vhost}->{$_->{name}} = {
            name => $_->{name},
            status => $result_alive->{status}
        };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (sort keys %{$self->{vhost}}) {
        $self->{output}->output_add(long_msg => sprintf(
            "[name = %s][status = %s]",
            $self->{vhost}->{$_}->{name}, $self->{vhost}->{$_}->{status})
        );
    }
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List vhosts:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (values %{$self->{vhost}}) {
        $self->{output}->add_disco_entry(%$_);
    }
}

1;

__END__

=head1 MODE

List vhosts.

=over 8

=back

=cut
