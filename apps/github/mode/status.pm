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

package apps::github::mode::status;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;
use JSON;

my $thresholds = {
    status => [
        ['good', 'OK'],
        ['minor', 'WARNING'],
        ['major', 'CRITICAL'],
    ],
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"                => { name => 'hostname', default => 'status.github.com' },
        "port:s"                    => { name => 'port', default => '443'},
        "proto:s"                   => { name => 'proto', default => 'https' },
        "urlpath:s"                 => { name => 'url_path', default => '/api/last-message.json' },
        "timeout:s"                 => { name => 'timeout' },
        "threshold-overload:s@"     => { name => 'threshold_overload' },
    });

    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    $self->{overload_th} = {};
    foreach my $val (@{$self->{option_results}->{threshold_overload}}) {
        if ($val !~ /^(.*?),(.*)$/) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload option '" . $val . "'.");
            $self->{output}->option_exit();
        }
        my ($section, $status, $filter) = ('status', $1, $2);
        if ($self->{output}->is_litteral_status(status => $status) == 0) {
            $self->{output}->add_option_msg(short_msg => "Wrong threshold-overload status '" . $val . "'.");
            $self->{output}->option_exit();
        }
        $self->{overload_th}->{$section} = [] if (!defined($self->{overload_th}->{$section}));
        push @{$self->{overload_th}->{$section}}, {filter => $filter, status => $status};
    }
    
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

    my $exit = $self->get_severity(section => 'status', value => $webcontent->{status});

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("%s", $webcontent->{body}));

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check GitHub's status

=over 8

=item B<--hostname>

IP Addr/FQDN of the GitHub's status website (Default: status.github.com)

=item B<--port>

Port used by GitHub's status website (Default: '443')

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--urlpath>

Set path to get GitHub's status information (Default: '/api/last-message.json')

=item B<--timeout>

Threshold for HTTP timeout (Default: 5)

=item B<--threshold-overload>

Set to overload default threshold values (syntax: status,regexp)
It used before default thresholds (order stays).
Example: --threshold-overload='CRITICAL,^(?!(good)$)'

=back

=cut
