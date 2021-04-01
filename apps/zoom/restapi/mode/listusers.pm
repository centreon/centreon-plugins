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

package apps::zoom::restapi::mode::listusers;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my @users;

    my $page = 1;
    while (my $results = $options{custom}->request_api(url_path => '/users?page_size=30&page_number=' . $page)) {
        push @users, @{$results->{users}};
        ($results->{page_number} < $results->{page_count}) ? $page++ : last;
    }
    
    foreach my $user (@users) {
        $self->{users}->{$user->{id}} = {
            first_name => $user->{first_name},
            last_name => $user->{last_name},
            email => $user->{email},
            status => $user->{status},
            id => $user->{id},
        }            
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $user (sort keys %{$self->{users}}) { 
        $self->{output}->output_add(
            long_msg => sprintf("[id = %s] [first_name = %s] [last_name = %s] [email = %s] [status = %s]",
                $self->{users}->{$user}->{id},
                $self->{users}->{$user}->{first_name},
                $self->{users}->{$user}->{last_name},
                $self->{users}->{$user}->{email},
                $self->{users}->{$user}->{status})
        );
    }
    
    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List users:'
    );
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['id', 'first_name', 'last_name', 'email', 'status']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $user (sort keys %{$self->{users}}) {             
        $self->{output}->add_disco_entry(
            id => $self->{users}->{$user}->{id},
            first_name => $self->{users}->{$user}->{first_name},
            last_name => $self->{users}->{$user}->{last_name},
            email => $self->{users}->{$user}->{email},
            status => $self->{users}->{$user}->{status},
        );
    }
}

1;

__END__

=head1 MODE

List users.

=over 8

=back

=cut
