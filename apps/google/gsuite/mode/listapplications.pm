#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::google::gsuite::mode::listapplications;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;


sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'hostname:s'    => { name => 'hostname', default => 'www.google.com' },
        'port:s'        => { name => 'port', default => '443'},
        'proto:s'       => { name => 'proto', default => 'https' },
        'urlpath:s'     => { name => 'url_path', default => '/appsstatus/json' },
        'language:s'    => { name => 'language', default => 'en' },
        'timeout:s'     => { name => 'timeout', default => '30' },
        'filter-name:s' => { name => 'filter_name' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    $self->{option_results}->{url_path} .= "/" . $self->{option_results}->{language};
    $self->{http}->set_options(%{$self->{option_results}});
}

sub manage_selection {
    my ($self, %options) = @_;

     my $content = $self->{http}->request(%options);
     $content =~ s/dashboard.jsonp\((.+)\)\;$/$1/g;

    if (!defined($content) || $content eq '') {
        $self->{output}->add_option_msg(short_msg => "API returns empty content [code: '" . $self->{http}->get_code() . "'] [message: '" . $self->{http}->get_message() . "']");
        $self->{output}->option_exit();
    }

    my $decoded;
    eval {
        $decoded = JSON::XS->new->utf8->decode($content);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode response (add --debug option to display returned content)");
        $self->{output}->option_exit();
    }
    if (defined($decoded->{error_code})) {
        $self->{output}->output_add(long_msg => "Error message : " . $decoded->{error}, debug => 1);
        $self->{output}->option_exit();
    }
    foreach my $application (@{$decoded->{services}}) {
        next if (defined($self->{option_results}->{filter_name}) && $self->{option_results}->{filter_name} ne ''
            && $application->{name} !~ /$self->{option_results}->{filter_name}/);
        $self->{applications}{$application->{id}} = $application->{name};
    };
}

sub run {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (keys %{$self->{applications}}) {
        $self->{output}->output_add(
            long_msg => sprintf("[name = %s]", $self->{applications}{$_})
        );
    }

    $self->{output}->output_add(severity => 'OK', short_msg => 'Google Gsuite Applications');
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;

    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    $self->manage_selection(%options);
    foreach (keys %{$self->{applications}}) {
        $self->{output}->add_disco_entry(
            name => $self->{applications}{$_}
        );
    }
}

1;

__END__

=head1 MODE

List Google Gsuite applications.

=over 8

=item B<--filter-name>

Filter application name (Can be a regexp).

=back

=cut
