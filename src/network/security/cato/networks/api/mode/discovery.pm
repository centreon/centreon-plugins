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

package network::security::cato::networks::api::mode::discovery;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

use Data::Dumper;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
            "filter-site-name:s"  => { name => 'filter_site_name', default => '' },
            "filter-site-id:s@"   => { name => 'filter_site_id' },
            "connectivity-details:s" => { name => 'connectivity_details', default => '1' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{$_} = $self->{option_results}->{$_} for qw/filter_site_name connectivity_details/;

    $self->{filter_site_id} = [ map { split /,/ } @{$self->{option_results}->{filter_site_id}} ];

}

sub manage_selection {
    my ($self, %options) = @_;

    #my $results = undef;
    my $results = $options{custom}->list_sites(filter_site_name => $self->{filter_site_name},
                                               filter_site_id => $self->{filter_site_id},
                                               connectivity_details => $self->{connectivity_details});
    foreach my $site (@$results) {
        $self->{sites}->{ $site->{'id'} } = { map { $_ => $site->{$_} } qw/id name description connectivity_status operational_status last_connected connected_since pop_name/ };
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $site (sort values %{$self->{sites}}) {
        $self->{output}->output_add(
            long_msg => join ' ', map { "[$_: ".$site->{$_}.']' } qw/id name description connectivity_status operational_status last_connected connected_since pop_name/
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List sites:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['id', 'name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $site (sort keys %{$self->{sites}}) {
        $self->{output}->add_disco_entry(
            id => $self->{sites}->{$site}->{id},
            name => $self->{sites}->{$site}->{name}
        );
    }
}

1;

__END__

=head1 MODE

List sites.

=over 8

=item B<--filter-site-name>

Filter by site name.

=item B<--filter-site-id>

Filter by site id. This parameter can be used multiple times and values can by separate by a comma.

=item V<--connectivity-datails>

Include connectivity details in discovery data. Use 1 to enable, 0 to disable. (default: 1).

=back

=cut
