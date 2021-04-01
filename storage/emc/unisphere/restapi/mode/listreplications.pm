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

package storage::emc::unisphere::restapi::mode::listreplications;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use storage::emc::unisphere::restapi::mode::components::resources qw($health_status $replication_status);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    return $options{custom}->request_api(url_path => '/api/types/replicationSession/instances?fields=name,health,syncState,srcResourceId,dstResourceId');
}

sub run {
    my ($self, %options) = @_;

    my $replications = $self->manage_selection(%options);
    foreach (@{$replications->{entries}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $_->{content}->{name} !~ /$self->{option_results}->{filter_name}/);
        
        $self->{output}->output_add(
            long_msg => sprintf(
                '[name = %s][health_status = %s][sync_status = %s][source_id = %s][destination_id = %s]',
                $_->{content}->{name},
                $health_status->{ $_->{content}->{health}->{value} },
                $replication_status->{ $_->{content}->{syncState} },
                $_->{content}->{srcResourceId},
                $_->{content}->{dstResourceId}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List replications:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'health_status', 'sync_status', 'source_id', 'destination_id']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $replications = $self->manage_selection(%options);
    foreach (@{$replications->{entries}}) {
        $self->{output}->add_disco_entry(
            name => $_->{content}->{name},
            health_status => $health_status->{ $_->{content}->{health}->{value} },
            sync_status => $replication_status->{ $_->{content}->{syncState} },
            source_id => $_->{content}->{srcResourceId},
            destination_id => $_->{content}->{dstResourceId}
        );
    }
}

1;

__END__

=head1 MODE

List replications.

=over 8

=item B<--filter-name>

Filter replication name (Can be a regexp).

=back

=cut
