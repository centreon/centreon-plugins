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
package storage::datacore::api::mode::statusmonitor;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

my %monitor_state = (1 => "Undefined", 2 => "Healthy", 4 => "Attention", 8 => "Warning", 16 => "Critical", 'toto' => 'TOTO');
sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    $options{options}->add_options(arguments => {
        'filter-caption:s' => { name => 'filter_caption' } });
    $self->{cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    $self->{cache}->check_options(option_results => $self->{option_results});
}
sub prefix_health_output {
    my ($self, %options) = @_;

    return 'prefix-output : ';
}
sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, cb_prefix_output => 'prefix_health_output' },
    ];

    $self->{maps_counters}->{global} = [
        { label => 'global', type => 2, critical_default => '%{State} =~ /16/', warning_default => '%{State} =~ /TOTO/',
            set => {
                key_values                     => [
                    { name => 'state' }, { name => 'messagetext' }, { name => 'extendedcaption' },
                ],

                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
    ];
}

sub manage_selection {
    my ($self, %options) = @_;
    my $monitor_data = $self->request_monitors(%options);
    for my $object (@$monitor_data) {
        #$self->{global} = $object->{ExtendedCaption};
        $self->{global}->{$object->{ExtendedCaption}} = {
            state           => 'toto',
            messagetext     => $object->{MessageText},
            extendedcaption => $object->{ExtendedCaption}
        };
        #print "$object->{ExtendedCaption}  $object->{State} \n";

    }
    use Data::Dumper;
    print Dumper($self);
}

sub custom_status_output {
    my ($self, %options) = @_;
    my $res = sprintf(
        "%s status : %s because : %s",
        $self->{result_values}->{extendedcaption},
        $monitor_state{$self->{result_values}->{state}},
        $self->{result_values}->{messagetext}

    );
    return $res;
}

sub request_monitors {
    my ($self, %options) = @_;

    if ($self->{cache}->read('statefile' => 'datacore_api_monitors' . md5_hex($self->{option_results}->{hostname} . $self->{option_results}->{username}))
        and $self->{cache}->get(name => 'expires_on') > time() + 1) {

        return $self->{cache}->get(name => 'monitor_data');
    }

    my $result = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/monitors');

    my $datas = { last_timestamp => time(), monitor_data => $result, expires_on => time() + 60 };
    $self->{cache}->write(data => $datas);
    return $result;

}
1;