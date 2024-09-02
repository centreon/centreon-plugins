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

package apps::ipfabric::mode::discovery;

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

    my $disco_raw_form_post = {
        "columns" => [
            "id",
            "hostname",
            "siteName",
            "loginIp",
            "vendor",
            "family",
            "platform"
        ],
        "filters" => {},
        "pagination" => {
            "limit" => undef,
            "start" => 0
        },
        "reports" => "/inventory/devices"
    };

    my $disco_api_results = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/inventory/devices',
        query_form_post => $disco_raw_form_post
    );

    foreach my $host (@{$disco_api_results->{data}}) {
        my %device;
        $device{id} = $host->{id};
        $device{hostname} = $host->{hostname};
        $device{loginIp} = $host->{loginIp};
        $device{siteName} = $host->{siteName};
        $device{vendor} = $host->{vendor};
        $device{family} = $host->{family};
        $device{platform} = $host->{platform};
        $device{snmp_community} = undef;
        push @disco_data, \%device;
    }

    my $snmp_req_data_raw = {
        columns => [
            'id',
            'hostname',
            'name'
        ],
        filters => {},
        pagination => {
            limit => undef,
            start => 0
        }
    }; 

    my $snmp_community_api_results = $options{custom}->request_api(
        endpoint => '/management/snmp/communities',
        query_form_post => $snmp_req_data_raw
    );

    foreach my $snmp_device (@{$snmp_community_api_results->{data}}) {
        for my $index (0 .. $#disco_data){
            next if (!defined($disco_data[$index]->{hostname}));
            if ($snmp_device->{hostname} eq $disco_data[$index]->{hostname}){
                $disco_data[$index]->{snmp_community} = $snmp_device->{name};
            }
        }
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

IP Fabric devices discovery.

=over 8

=back

=cut
