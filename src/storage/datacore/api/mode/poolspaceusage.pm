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
package storage::datacore::api::mode::poolspaceusage;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use JSON::XS;

sub new {
    my ($class, %options) = @_;

    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    $options{options}->add_options(arguments => {
        'pool-id:s' => { name => 'pool_id' } });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
    if (centreon::plugins::misc::empty($self->{option_results}->{pool_id})) {
        $self->{output}->add_option_msg(short_msg => 'Please set pool-id option');
        $self->{output}->option_exit();
    }
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'BytesAllocatedPercentage', type => 0 },
        { name => 'oversubscribed', type => 0 },
    ];
    $self->{maps_counters}->{BytesAllocatedPercentage} = [
        # The label defines options name, a --warning-bytesallocatedpercentage and --critical-bytesallocatedpercentage will be added to the mode
        # The nlabel is the name of your performance data / metric that will show up in your graph
        {
            label  => 'bytesallocatedpercentage',
            nlabel => 'datacore.pool.bytesallocated.percentage',
            set    => {
                # Key value name is the name we will use to pass the data to this counter. You can have several ones.
                key_values      => [ { name => 'bytesallocatedpercentage' } ],
                # Output template describe how the value will display
                output_template => 'Bytes Allocated : %s %%',
                # Perfdata array allow you to define relevant metrics properties (min, max) and its sprintf template format
                perfdatas       => [
                    { template => '%d', unit => '%', min => 0, max => 100 }
                ]
            }
        } ];
    $self->{maps_counters}->{oversubscribed} = [ {
        label  => 'oversubscribed',
        nlabel => 'datacore.pool.oversubscribed.bytes',
        set    => {
            # Key value name is the name we will use to pass the data to this counter. You can have several ones.
            key_values      => [ { name => 'oversubscribed' } ],
            # Output template describe how the value will display
            output_template => 'Over subscribed bytes : %s',
            # Perfdata array allow you to define relevant metrics properties (min, max) and its sprintf template format
            perfdatas       => [
                { template => '%d', unit => 'bytes', min => 0 }
            ]
        }
    } ];

}

sub manage_selection {
    my ($self, %options) = @_;

    my $data = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/performances/' . $self->{option_results}->{pool_id},
    );

    $self->{BytesAllocatedPercentage}->{bytesallocatedpercentage} = $data->[0]->{"BytesAllocatedPercentage"};
    $self->{oversubscribed}->{oversubscribed} = $data->[0]->{"BytesOverSubscribed"};

}
1;