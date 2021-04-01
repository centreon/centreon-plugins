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

package apps::rudder::restapi::mode::listrules;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "filter-name:s" => { name => 'filter_name' },
    });
   
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $results = $options{custom}->request_api(url_path => '/rules');
    
    foreach my $rule (@{$results->{rules}}) {
        if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
            $rule->{displayName} !~ /$self->{option_results}->{filter_name}/) {
            $self->{output}->output_add(long_msg => "skipping '" . $rule->{hostname} . "': no matching filter name.", debug => 1);
            next;
        }

        my @tags;
        foreach my $tag (@{$rule->{tags}}) {
            push @tags, (keys %{$tag})[0] . ':' . (values %{$tag})[0];
        }

        $self->{rules}->{$rule->{id}} = {
            name => $rule->{displayName},
            tags => join(',', @tags),
            enabled => $rule->{enabled},
            id => $rule->{id},
        }            
    }
}

sub run {
    my ($self, %options) = @_;
  
    $self->manage_selection(%options);
    foreach my $rule (sort keys %{$self->{rules}}) { 
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [tags = %s] [enabled = %s] [id = %s]",
                                                         $self->{rules}->{$rule}->{name},
                                                         $self->{rules}->{$rule}->{tags},
                                                         $self->{rules}->{$rule}->{enabled},
                                                         $self->{rules}->{$rule}->{id}));
    }
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List rules:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;  
    
    $self->{output}->add_disco_format(elements => ['name', 'tags', 'enabled', 'id']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $rule (sort keys %{$self->{rules}}) {             
        $self->{output}->add_disco_entry(
            name => $self->{rules}->{$rule}->{name},
            tags => $self->{rules}->{$rule}->{tags},
            enabled => $self->{rules}->{$rule}->{enabled},
            id => $self->{rules}->{$rule}->{id},
        );
    }
}

1;

__END__

=head1 MODE

List rules.

=over 8

=item B<--filter-name>

Filter rule name (can be a regexp).

=back

=cut
