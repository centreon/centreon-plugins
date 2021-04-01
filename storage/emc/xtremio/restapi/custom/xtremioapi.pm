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

package storage::emc::xtremio::restapi::custom::xtremioapi;

use strict;
use warnings;
use centreon::plugins::http;
use centreon::plugins::statefile;
use JSON;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {
            'hostname:s@'         => { name => 'hostname' },
            'xtremio-username:s@' => { name => 'xtremio_username' },
            'xtremio-password:s@' => { name => 'xtremio_password' },
            'timeout:s@'          => { name => 'timeout' },
            'reload-cache-time:s' => { name => 'reload_cache_time' }
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{http} = centreon::plugins::http->new(%options);
    $self->{statefile_cache_cluster} = centreon::plugins::statefile->new(%options);

    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? shift(@{$self->{option_results}->{hostname}}) : undef;
    $self->{xtremio_username} = (defined($self->{option_results}->{xtremio_username})) ? shift(@{$self->{option_results}->{xtremio_username}}) : '';
    $self->{xtremio_password} = (defined($self->{option_results}->{xtremio_password})) ? shift(@{$self->{option_results}->{xtremio_password}}) : '';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? shift(@{$self->{option_results}->{timeout}}) : 10;
    $self->{reload_cache_time} = (defined($self->{option_results}->{reload_cache_time})) ? shift(@{$self->{option_results}->{reload_cache_time}}) : 180;
 
    if (!defined($self->{hostname})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify hostname option.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{xtremio_username}) || !defined($self->{xtremio_password})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify --xtremio-username and --xtremio-password options.");
        $self->{output}->option_exit();
    }

    if (!defined($self->{hostname}) ||
        scalar(@{$self->{option_results}->{hostname}}) == 0) {
        $self->{statefile_cache_cluster}->check_options(option_results => $self->{option_results});
        return 0;
    }
    return 1;
}


sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{xtremio_username}.':'.$self->{xtremio_password}.'@'.$self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = 443;
    $self->{option_results}->{proto} = 'https';
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->set_options(%{$self->{option_results}});
}

sub cache_clusters {
    my ($self, %options) = @_;
    
    my $has_cache_file = $self->{statefile_cache_cluster}->read(statefile => 'cache_xtremio_clusters_' . $self->{hostname});
    my $timestamp_cache = $self->{statefile_cache_cluster}->get(name => 'last_timestamp');
    my $clusters = $self->{statefile_cache_cluster}->get(name => 'clusters');
    if ($has_cache_file == 0 || !defined($timestamp_cache) || ((time() - $timestamp_cache) > (($self->{reload_cache_time}) * 60))) {
        $clusters = {};
        my $datas = { last_timestamp => time(), clusters => $clusters };
        my @items = $self->get_items(url => '/api/json/types/',
                                     obj => 'clusters');
        foreach (@items) {
            $clusters->{$_} = 1;
        }
        $self->{statefile_cache_cluster}->write(data => $datas);
    }
    
    return $clusters;
}

sub get_items {
    my ($self, %options) = @_;

    $self->settings();

    if (defined($options{obj}) && $options{obj} ne '') {
        $options{url} .= $options{obj} . '/';
    }

    my $response = $self->{http}->request(url_path => $options{url});
    my $decoded;
    eval {
        $decoded = decode_json($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
   
    my @items;
    foreach my $context (@{$decoded->{$options{obj}}}) {
        push @items, $context->{name};       
    }

    return @items;
}

sub get_details_data {
    my ($self, %options) = @_;
    
    my $response = $self->{http}->request(url_path => $options{url},
        critical_status => '', warning_status => '', unknown_status => '');
    my $decoded;
    eval {
        $decoded = decode_json($response);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
    return $decoded;
}


sub get_details_lookup_clusters {
    my ($self, %options) = @_;

    #Message if object not found:
    #{
    #   "message": "obj_not_found",
    #   "error_code": 400
    #}
    #
    if (!defined($self->{cache_clusters})) {
        $self->{cache_clusters} = $self->cache_clusters();
    }
    foreach my $cluster_name (keys %{$self->{cache_clusters}}) {
        my $url = $options{url} . $options{append} . 'cluster-name=' . $cluster_name;
        my $decoded = $self->get_details_data(url => $url);
        return $decoded if (!defined($decoded->{error_code}));
    }
    
    # object is not found.
    $self->{output}->add_option_msg(short_msg => "xtremio api issue: cannot found object details");
    $self->{output}->option_exit();
}

sub get_details {
    my ($self, %options) = @_;

    $self->settings();
    
    my $append = '?';
    if ((defined($options{obj}) && $options{obj} ne '') && (defined($options{name}) && $options{name} ne '')) {
        $options{url} .= $options{obj} . '/?name=' . $options{name};
        $append = '&';
    }

    #Message when cluster id needed:
    #{
    #   "message": "cluster_id_is_required",
    #   "error_code": 400
    #}
    #
    my $decoded = $self->get_details_data(%options);
    if (defined($decoded->{error_code}) && 
        ($decoded->{error_code} == 400 && $decoded->{message} eq 'cluster_id_is_required')) {
        $decoded = $self->get_details_lookup_clusters(%options, append => $append);
    } elsif (defined($decoded->{error_code})) {
        $self->{output}->add_option_msg(short_msg => "xtremio api issue: $decoded->{message}");
        $self->{output}->option_exit();
    }
     
    return $decoded->{content};

}

1;

__END__

=head1 NAME

XREMIO REST API

=head1 SYNOPSIS

Xtremio Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

Xtremio hostname.

=item B<--xtremio-username>

Xtremio username.

=item B<--xtremio-password>

Xtremio password.

=item B<--timeout>

Set HTTP timeout

=item B<--reload-cache-time>

Time in seconds before reloading cache file (default: 180).
The cache is used when XMS manages multiple clusters.

=back

=head1 DESCRIPTION

B<custom>.

=cut
