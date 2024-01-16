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

package apps::monitoring::kadiska::mode::listwatchers;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'prettify' => { name => 'prettify' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my @disco_data;
    my $disco_stats;

    $disco_stats->{start_time} = time();

    my $raw_form_post = {
        "select" => [
            { "watcher_id:group" => "watcher_name" }, 
            { "site:group" => "site_name" }, 
            { "gateway:group" => "gateway_name" }
        ],
        "from" => "rum",
        "groupby" => [
            "watcher_name", 
            "site:group", 
            "gateway:group"
        ],
        "options" => {"sampling" => \1 }
    };  

    my $results = $options{custom}->request_api(
        method => 'POST',
        endpoint => 'query',
        query_form_post => $raw_form_post
    );

    foreach my $watcher (@{$results->{data}}) {
        my %application;
        $application{watcher_name} = $watcher->{'watcher_id:group'};
        $application{watcher_display_name} = $watcher->{'watcher_id:group'};
        $application{watcher_display_name} .= '_' . $watcher->{'site:group'} if defined($watcher->{'site:group'});
        $application{watcher_display_name} .= '_' . $watcher->{'gateway:group'} if defined($watcher->{'gateway:group'});
        $application{site_name} = defined($watcher->{'site:group'}) ? $watcher->{'site:group'} : '';
        $application{gateway_name} = defined($watcher->{'gateway:group'}) ? $watcher->{'gateway:group'} : '';
        $application{wfa} = !defined($watcher->{'gateway:group'}) && !defined($watcher->{'site:group'}) ? '--wfa --verbose' : '';
        push @disco_data, \%application;
    }
    
    $disco_stats->{end_time} = time();
    $disco_stats->{duration} = $disco_stats->{end_time} - $disco_stats->{start_time};
    $disco_stats->{discovered_items} = @disco_data;
    $disco_stats->{results} = \@disco_data;

    return $disco_stats;
}

sub run {
    my ($self, %options) = @_;

    my $encoded_data;

    eval {
        if (defined($self->{option_results}->{prettify})) {
            $encoded_data = JSON::XS->new->utf8->pretty->encode($self->manage_selection(%options));
        } else {
            $encoded_data = JSON::XS->new->utf8->encode($self->manage_selection(%options));
        }
    };
    if ($@) {
        $encoded_data = '{"code":"encode_error","message":"Cannot encode discovered data into JSON format"}';
    }

    $self->{output}->output_add(short_msg => $encoded_data);
    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1);
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Kadiska hosts discovery for watchers/application.

=over 8

=back

=cut
