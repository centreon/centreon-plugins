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
package storage::datacore::restapi::mode::monitorstatus;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use JSON::XS;
use Digest::MD5 qw(md5_hex);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc qw(empty);

my %monitor_state = (1 => "Undefined", 2 => "Healthy", 4 => "Attention", 8 => "Warning", 16 => "Critical");

sub custom_status_output {
    my ($self, %options) = @_;
    my $res = sprintf(
        "'%s' status : '%s', message is '%s'",
        $self->{result_values}->{extendedcaption},
        $self->{result_values}->{state},
        $self->{result_values}->{messagetext}
    );
    return $res;
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 1, message_multiple => 'All memory usages are ok', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label              => 'state',
            type             => 2,
            warning_default  => '%{state} =~ /Warning/i',
            critical_default => '%{state} =~ /Critical/i',
            set              => {
                key_values                     => [ { name => 'state' }, { name => 'extendedcaption' }, { name => 'messagetext' } ],
                closure_custom_output          => $self->can('custom_status_output'),
                closure_custom_perfdata        => sub {return 0;},
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

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

sub manage_selection {
    my ($self, %options) = @_;

    if ($self->{cache}->read('statefile' => 'datacore_api_monitors' . md5_hex($self->{option_results}->{hostname} . $self->{option_results}->{username}))
        and $self->{cache}->get(name => 'expires_on') > time() + 1) {

        return $self->{cache}->get(name => 'monitor_data');
    }

    my $monitor_data = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/monitors');

    my $datas = { last_timestamp => time(), monitor_data => $monitor_data, expires_on => time() + 60 };
    $self->{cache}->write(data => $datas);

    my $monitored_count = 0;
    for my $object (@$monitor_data) {

        if (!centreon::plugins::misc::is_empty($self->{option_results}->{filter_caption})
            and $object->{ExtendedCaption} !~ $self->{option_results}->{filter_caption}) {
            next;
        }
        $self->{global}->{$monitored_count} = {
            state           => $monitor_state{$object->{State}},
            messagetext     => $object->{MessageText},
            extendedcaption => $object->{ExtendedCaption}
        };
        $monitored_count++;
    }
    # for now if no data is given to the counter, output is OK: with status ok, instead of unknown.
    # We manage this case in each plugin for now.
    if ($monitored_count == 0) {
        $self->{output}->add_option_msg(short_msg => 'No monitors where checked, please check filter_caption parameter and api response.');
        $self->{output}->option_exit();
    }
}

# as --filter-caption allow to filter element to check and this api don't allow parameter filtering, we should cache
# the output in case a client make multiples check a minute.

1;

__END__

=head1 MODE

Check Datacore monitor status exposed through the rest api.

=over 8

=item B<--filter-caption>

Define which element should be monitored based on the extended caption. This option will be treated as a regular expression.
By default all elements will be checked.

=item B<--warning-state> B<--critical-state>

define which output from the api should be considered warning or critical.

warning_default  = '%{state} =~ /Warning/i',

critical_default = '%{state} =~ /Critical/i',

possible value for state : Undefined, Healthy, Attention, Warning, Critical.

=back

