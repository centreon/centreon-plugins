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

package cloud::cloudfoundry::restapi::mode::listspaces;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "filter-name:s"             => { name => 'filter_name' },
                                    "filter-organization:s"     => { name => 'filter_organization' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my %orgs;
    my $result = $options{custom}->get_object(url_path => '/spaces');

    foreach my $space (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $space->{entity}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping space '" . $space->{entity}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        next if ($space->{entity}->{organization_url} !~ /^\/v2(.*)/);
        my $organization_url = $1;
        if (!defined($orgs{$organization_url})) {
            my $org = $options{custom}->get_object(url_path => $organization_url);
            $orgs{$organization_url}->{name} = $org->{entity}->{name};
        }

        if (defined($self->{option_results}->{filter_organization}) && $self->{option_results}->{filter_organization} ne '' &&
            $orgs{$organization_url}->{name} !~ /$self->{option_results}->{filter_organization}/) {
            $self->{output}->output_add(long_msg => "skipping organization '" . $orgs{$organization_url}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{spaces}->{$space->{metadata}->{guid}} = {
            name => $space->{entity}->{name},
            organization => $orgs{$organization_url}->{name},
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $space (sort keys %{$self->{spaces}}) { 
        $self->{output}->output_add(long_msg => sprintf("[guid = %s] [name = %s] [organization = %s]",
                                                         $space,
                                                         $self->{spaces}->{$space}->{name},
                                                         $self->{spaces}->{$space}->{organization}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List spaces:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['guid', 'name', 'organization']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $space (sort keys %{$self->{spaces}}) {             
        $self->{output}->add_disco_entry(
            guid => $space,
            name => $self->{spaces}->{$space}->{name},
            organization => $self->{spaces}->{$space}->{organization},
        );
    }
}

1;

__END__

=head1 MODE

List spaces.

=over 8

=item B<--filter-name>

Filter spaces name (can be a regexp).

=item B<--filter-organization>

Filter organizations name (can be a regexp).

=back

=cut
