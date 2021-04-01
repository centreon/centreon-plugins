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

package cloud::cloudfoundry::restapi::mode::listapps;

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
                                    "filter-space:s"            => { name => 'filter_space' },
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
    my %spaces;
    my $result = $options{custom}->get_object(url_path => '/apps');

    foreach my $app (@{$result}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $app->{entity}->{name} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $app->{entity}->{name} . "': no matching filter name.", debug => 1);
            next;
        }

        next if ($app->{entity}->{space_url} !~ /^\/v2(.*)/);
        my $space_url = $1;
        if (!defined($spaces{$space_url})) {
            my $space = $options{custom}->get_object(url_path => $space_url);
            $spaces{$space_url}->{name} = $space->{entity}->{name};
            $spaces{$space_url}->{organization_url} = $space->{entity}->{organization_url};
        }

        if (defined($self->{option_results}->{filter_space}) && $self->{option_results}->{filter_space} ne '' &&
            $spaces{$space_url}->{name} !~ /$self->{option_results}->{filter_space}/) {
            $self->{output}->output_add(long_msg => "skipping space '" . $spaces{$space_url}->{name} . "': no matching filter name.", debug => 1);
            next;
        }        

        next if ($spaces{$space_url}->{organization_url} !~ /^\/v2(.*)/);
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

        $self->{apps}->{$app->{metadata}->{guid}} = {
            name => $app->{entity}->{name},
            state => $app->{entity}->{state},
            space => $spaces{$space_url}->{name},
            organization => $orgs{$organization_url}->{name},
        };
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $app (sort keys %{$self->{apps}}) { 
        $self->{output}->output_add(long_msg => sprintf("[guid = %s] [name = %s] [state = %s] [space = %s] [organization = %s]",
                                                         $app,
                                                         $self->{apps}->{$app}->{name},
                                                         $self->{apps}->{$app}->{state},
                                                         $self->{apps}->{$app}->{space},
                                                         $self->{apps}->{$app}->{organization}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List apps:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['guid', 'name', 'state', 'space', 'organization']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $app (sort keys %{$self->{apps}}) {             
        $self->{output}->add_disco_entry(
            guid => $app,
            name => $self->{apps}->{$app}->{name},
            state => $self->{apps}->{$app}->{state},
            space => $self->{apps}->{$app}->{space},
            organization => $self->{apps}->{$app}->{organization},
        );
    }
}

1;

__END__

=head1 MODE

List apps.

=over 8

=item B<--filter-name>

Filter apps name (can be a regexp).

=item B<--filter-space>

Filter spaces name (can be a regexp).

=item B<--filter-organization>

Filter organizations name (can be a regexp).

=back

=cut
