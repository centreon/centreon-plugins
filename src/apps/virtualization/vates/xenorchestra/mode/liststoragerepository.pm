#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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
package apps::virtualization::vates::xenorchestra::mode::liststoragerepository;
use strict;
use warnings;
use base qw(centreon::plugins::mode);
use centreon::plugins::misc qw/is_not_empty/;
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

sub run {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api_get(
        endpoint => "srs", get_param => ['fields=*']);

    for my $sr (@{$response}) {
        my $tags = join(', ', grep { is_not_empty($_) } @{$sr->{tags}});
        $self->{output}->output_add(
            long_msg => sprintf(
                "  %s [uuid=%s] [type=%s] [content_type=%s] [allocationStrategy=%s] [inMaintenanceMode=%s] [name_description=%s] [shared=%s] [SR_type=%s] [pool_uuid=%s] [tags=%s]",
                $sr->{name_label},
                $sr->{uuid},
                $sr->{type},
                $sr->{content_type},
                $sr->{allocationStrategy} // '',
                $sr->{inMaintenanceMode},
                $sr->{name_description},
                $sr->{shared},
                $sr->{SR_type},
                $sr->{'$pool'},
                $tags
            )
        );
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List storage repository:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name',
        'uuid',
        'type',
        'content_type',
        'allocationStrategy',
        'inMaintenanceMode',
        'name_description',
        'shared',
        'SR_type',
        'pool_uuid',
        'tags']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $response = $options{custom}->request_api_get(
        endpoint => "srs", get_param => ['fields=*']);
    for my $sr (@{$response}) {
        my $tags = join(', ', grep { is_not_empty($_) } @{$sr->{tags}});
        $self->{output}->add_disco_entry(
            name               => $sr->{name_label},
            uuid               => $sr->{uuid},
            type               => $sr->{type},
            content_type       => $sr->{content_type},
            allocationStrategy => $sr->{allocationStrategy} // '',
            inMaintenanceMode  => $sr->{inMaintenanceMode},
            name_description   => $sr->{name_description},
            shared             => $sr->{shared},
            SR_type            => $sr->{SR_type},
            pool_uuid          => $sr->{'$pool'},
            tags               => $tags,
        );
    }
}
1;

__END__

=head1 MODE

List the storage repositories of a Xen Orchestra pool, for service discovery purposes.

=over 8

=back

=cut