#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::elasticsearch::mode::indices;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;
use Data::Dumper;

my $thresholds = {
    indices => [
        ['green', 'OK'],
        ['yellow', 'WARNING'],
        ['red', 'CRITICAL'],
    ],
};

my %map_states_indices = (
    OK => 'green',
    WARNING => 'yellow',
    CRITICAL => 'red',
);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
        {
            "hostname:s"              => { name => 'hostname' },
            "port:s"                  => { name => 'port', default => 9200 },
            "proto:s"                 => { name => 'proto' },
            "urlpath:s"               => { name => 'url_path', default => '/_cluster/health' },
            "credentials"             => { name => 'credentials' },
            "username:s"              => { name => 'username' },
            "password:s"              => { name => 'password' },
            "timeout:s"               => { name => 'timeout' },
            "threshold-overload:s@"   => { name => 'threshold_overload' },
        });

    $self->{http} = centreon::plugins::http->new(output => $self->{output});
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ($1, $2, $3);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }

    $self->{option_results}->{get_param} = [ 'level=indices' ];
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_severity {
    my ($self, %options) = @_;
    my $status = 'UNKNOWN'; # default

    if (defined($self->{overload_th}->{$options{section}})) {
        foreach (@{$self->{overload_th}->{$options{section}}}) {
            if ($options{value} =~ /$_->{filter}/i) {
                $status = $_->{status};
                return $status;
            }
        }
    }
    foreach (@{$thresholds->{$options{section}}}) {
        if ($options{value} =~ /$$_[0]/i) {
            $status = $$_[1];
            return $status;
        }
    }

    return $status;
}

sub run {
    my ($self, %options) = @_;

    my $jsoncontent = $self->{http}->request();

    my $json = JSON->new;
    my $webcontent;

    eval {
        $webcontent = $json->decode($jsoncontent);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(severity => 'OK',
                                short_msg => sprintf("All indices are in green state."));
    my $exit = 'OK';
    foreach my $indicename (sort (keys %{$webcontent->{indices}})) {
        my $tmp_exit = $self->get_severity(section => 'indices', value => $webcontent->{indices}->{$indicename}->{status});
        $exit = $self->{output}->get_most_critical(status => [ $tmp_exit, $exit ]);
        if (!$self->{output}->is_status(value => $tmp_exit, compare => 'OK', litteral => 1)) {
            $self->{output}->output_add(long_msg => sprintf("Indice %s status is in %s state",
                                                            $indicename, $webcontent->{indices}->{$indicename}->{status}));
        }
    }

    if (!$self->{output}->is_status(value => $exit, compare => 'OK', litteral => 1)) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => sprintf("Some indices are in wrong state"));
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Elasticsearch indices health

=over 8

=item B<--hostname>

IP Addr/FQDN of the Elasticsearch host

=item B<--port>

Port used by Elasticsearch API (Default: '9200')

=item B<--proto>

Specify https if needed (Default: 'http')

=item B<--urlpath>

Set path to get Elasticsearch information (Default: '/_cluster/health')

=item B<--credentials>

Specify this option if you access webpage over basic authentification

=item B<--username>

Specify username for API authentification

=item B<--password>

Specify password for API authentification

=item B<--threshold-overload>

Set to overload default threshold values (syntax: section,status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='indices,CRITICAL,^(?!(on)$)'

=item B<--timeout>

Threshold for HTTP timeout (Default: 3)

=back

=cut
