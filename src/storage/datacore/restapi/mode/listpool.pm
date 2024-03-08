#
# Copyright 2024 Centreon (http://www.centreon.com/)
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
package storage::datacore::restapi::mode::listpool;
use strict;
use warnings;

use base qw(centreon::plugins::mode);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    $options{options}->add_options(arguments => {
        'filter-name:s' => { name => 'filter_name' },
    });


    return $self;
}
sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    $self->{pools} = ();
    my $pool_list = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/pools');

    if (scalar(@$pool_list) == 0) {
        $self->{output}->add_option_msg(short_msg => "No pool found in api response.");
        $self->{output}->option_exit();
    }
    for my $pool (@$pool_list) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $pool->{Alias} !~ /$self->{option_results}->{filter_name}/);
       push(@{$self->{pools}}, {
            ExtendedCaption => $pool->{ExtendedCaption},
            Caption         => $pool->{Caption},
            Id              => $pool->{Id},
            Alias           => $pool->{Alias}}
        );
    }

}

sub run {
    my ($self, %options) = @_;
    $self->manage_selection(%options);
    if (scalar $self->{pools} == 0) {
        $self->{output}->add_option_msg(short_msg => "No pool found.");
        $self->{output}->option_exit();
    }
    foreach (sort @{$self->{pools}}) {
        $self->{output}->output_add(long_msg => sprintf("[ExtendedCaption = %s] [Caption = %s] [Id = %s]  [Alias = %s]",
            $_->{ExtendedCaption}, $_->{Caption}, $_->{Id}, $_->{Alias}));
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List pools : '
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['ExtendedCaption', 'Caption', 'Id', 'Alias']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);

    foreach (sort @{$self->{pools}}) {
        $self->{output}->add_disco_entry(ExtendedCaption => $_->{ExtendedCaption}, Caption => $_->{Caption},
            Id => $_->{Id}, Id => $_->{Id}, Alias => $_->{Alias});
    }
}
1;

=head1 MODE

List pools.

=over 8

=item B<--filter-name>

Filter pool name (can be a regexp).

=back

=cut