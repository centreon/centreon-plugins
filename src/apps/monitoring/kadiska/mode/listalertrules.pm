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

package apps::monitoring::kadiska::mode::listalertrules;

use base qw(centreon::plugins::mode);

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
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

        my $raw_form_post = {
        "select" => [
            {
                "rule_id:group" => "rule_id"
            },
            {
                "rule_name:any" => ["any","rule_name"]
            },
            {
                ["any","rule_name"] => ["any","rule_id"]
            }
        ],
        "from" => "alert",
        "groupby" => [
            "rule_id:group"
        ],
        "orderby" => [
            ["rule_name:any","desc"]
        ],
        "offset" => 0,
        "limit" => 61
    };

    my $results = $options{custom}->request_api(
    method => 'POST',
    endpoint => 'query',
    query_form_post => $raw_form_post
    );

    #Check if bad API request is submit
    if (!exists $results->{data}) {
        $self->{output}->add_option_msg(short_msg => 'No data result in API request.');
        $self->{output}->option_exit();
    }

    foreach (@{$results->{data}}) {
        my $rule = $_;
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne '' &&
             $rule->{'rule_name:any'} !~ /$self->{option_results}->{filter_name}/);

        my @tags;
        foreach my $tag (@{$rule->{tags}}) {
            push @tags, (keys %{$tag})[0] . ':' . (values %{$tag})[0];
        }

        $self->{rules}->{$rule->{'rule_id:group'}} = {
            id   => $rule->{'rule_id:group'},
            name => $rule->{'rule_name:any'}
        }
    }

    if (scalar(keys %{$self->{rules}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No rule found.');
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $rule (sort keys %{$self->{rules}}) {
        $self->{output}->output_add(long_msg => sprintf("[name = %s] [id = %s]",
                                                         $self->{rules}->{$rule}->{name},
                                                         $self->{rules}->{$rule}->{id}));
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'List alert rules:');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name', 'id']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach my $rule (sort keys %{$self->{rules}}) {
        $self->{output}->add_disco_entry(
            name => $self->{rules}->{$rule}->{name},
            id => $self->{rules}->{$rule}->{id}
        );
    }
}

1;

__END__

=head1 MODE

List kadiska alert rules.

=over 8

=item B<--filter-name>

Filter rule name (can be a regexp).

=back

=cut
