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

package cloud::juniper::mist::restapi::mode::listsites;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

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
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $org_id = $options{custom}->get_org_id();
    my $sites = $options{custom}->request_api(endpoint => "/api/v1/orgs/$org_id/sites");

    $self->{output}->option_exit(short_msg => "Unexpected response for /sites (not an array).")
        if (ref($sites) ne 'ARRAY');

    $self->{sites} = {};
    foreach my $site (@$sites) {
        next if (!defined($site->{id}));
        my $name = $site->{name} // '';
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $name !~ /$self->{option_results}->{filter_name}/i);

        # UTF-8 is handled natively: json_decode returns character strings and
        # the framework's XML::LibXML disco output encodes them correctly, so a
        # site named "S├úo Paulo" comes out as valid XML without any manual
        # binmode or escaping.
        $self->{sites}->{ $site->{id} } = {
            id => $site->{id},
            name => $name,
            country_code => $site->{country_code} // '',
            timezone => $site->{timezone} // ''
        };
    }
}

sub run {
    my ($self, %options) = @_;

    # Site names carry UTF-8 (e.g. "S├úo Paulo"). centreon::plugins::misc::json_decode
    # returns decoded character strings, but output.pm applies an encoding layer
    # only on its JSON and XML paths - the plain-text output path prints as-is,
    # so without an explicit layer these characters degrade to raw Latin-1 and
    # the human listing is corrupted. We therefore set the UTF-8 layer locally
    # for the plain-text case only.
    # This is deliberately scoped: --disco-show/--disco-format serialise through
    # XML::LibXML and --output-format json through JSON::XS, both of which emit
    # correctly-encoded bytes on their own; adding the layer there would
    # double-encode. Hence the guard against the byte-producing output formats.
    binmode(STDOUT, ':encoding(UTF-8)')
        if (!defined($self->{option_results}->{output_json})
            && !defined($self->{option_results}->{output_xml})
            && !defined($self->{option_results}->{output_openmetrics}));

    $self->manage_selection(%options);
    foreach my $id (sort { $self->{sites}->{$a}->{name} cmp $self->{sites}->{$b}->{name} } keys %{$self->{sites}}) {
        $self->{output}->output_add(
            long_msg => sprintf(
                "[id: %s] [name: %s] [country_code: %s] [timezone: %s]",
                $self->{sites}->{$id}->{id},
                $self->{sites}->{$id}->{name},
                $self->{sites}->{$id}->{country_code},
                $self->{sites}->{$id}->{timezone}
            )
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => sprintf('List sites [total: %d]:', scalar(keys %{$self->{sites}}))
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name', 'country_code', 'timezone']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $id (sort keys %{$self->{sites}}) {
        $self->{output}->add_disco_entry(
            id => $self->{sites}->{$id}->{id},
            name => $self->{sites}->{$id}->{name},
            country_code => $self->{sites}->{$id}->{country_code},
            timezone => $self->{sites}->{$id}->{timezone}
        );
    }
}

1;

__END__

=head1 MODE

List the sites of a Juniper Mist organization.

Used for service discovery: pair it with C<--disco-format> to list the available
attributes and C<--disco-show> to return the discovered sites as XML.

=over 8

=item B<--filter-name>

Filter sites by name (can be a regular expression).

=back

=cut
