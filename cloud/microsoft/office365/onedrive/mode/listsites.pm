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

package cloud::microsoft::office365::onedrive::mode::listsites;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                {
                                    "filter-url:s"      => { name => 'filter_url' },
                                    "filter-owner:s"    => { name => 'filter_owner' },
                                });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->office_get_onedrive_usage(param => "period='D7'");

    foreach my $site (@{$results}) {
        if (defined($self->{option_results}->{filter_url}) && $self->{option_results}->{filter_url} ne '' &&
            $site->{'Site URL'} !~ /$self->{option_results}->{filter_url}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $site->{'Site URL'} . "': no matching filter name.", debug => 1);
            next;
        }
        if (defined($self->{option_results}->{filter_owner}) && $self->{option_results}->{filter_owner} ne '' &&
            $site->{'Owner Display Name'} !~ /$self->{option_results}->{filter_owner}/) {
            $self->{output}->output_add(long_msg => "skipping  '" . $site->{'Owner Display Name'} . "': no matching filter name.", debug => 1);
            next;
        }

        $self->{sites}->{$site->{'Site URL'}} = {
            owner => $site->{'Owner Display Name'},
            url => $site->{'Site URL'},
        }
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $site (sort keys %{$self->{sites}}) { 
        $self->{output}->output_add(long_msg => sprintf("[owner = %s] [url = %s]",
                                                         $self->{sites}->{$site}->{owner},
                                                         $self->{sites}->{$site}->{url}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List sites:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['owner', 'url']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $site (sort keys %{$self->{sites}}) {             
        $self->{output}->add_disco_entry(
            owner => $self->{sites}->{$site}->{owner},
            url => $self->{sites}->{$site}->{url},
        );
    }
}

1;

__END__

=head1 MODE

List sites.

=over 8

=item B<--filter-*>

Filter sites.
Can be: 'url', 'id' (can be a regexp).

=back

=cut
