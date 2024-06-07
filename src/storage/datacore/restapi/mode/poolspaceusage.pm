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
package storage::datacore::restapi::mode::poolspaceusage;
use strict;
use warnings;

use base qw(centreon::plugins::templates::counter);
use JSON::XS;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        # BytesAllocatedPercentage is the disk usage of the pool
        # in datacore you can make thin provisionning, where you give to each partition more than what you really have.
        # oversubscribed is the number of Bytes allocated minus the number of bytes present in the system.
        { name => 'BytesAllocatedPercentage', type => 0 },
        { name => 'oversubscribed', type => 0 },
    ];
    $self->{maps_counters}->{BytesAllocatedPercentage} = [

        {
            label  => 'bytesallocatedpercentage',
            nlabel => 'datacore.pool.bytesallocated.percentage',
            set    => {
                key_values      => [ { name => 'bytesallocatedpercentage' } ],
                output_template => 'Bytes Allocated : %s %%',
                perfdatas       => [
                    { template => '%d', unit => '%', min => 0, max => 100 }
                ]
            }
        } ];
    $self->{maps_counters}->{oversubscribed} = [ {
        label  => 'oversubscribed',
        nlabel => 'datacore.pool.oversubscribed.bytes',
        set    => {
            key_values      => [ { name => 'oversubscribed' } ],
            output_template => 'Over subscribed bytes : %s',
            perfdatas       => [
                { template => '%d', unit => 'bytes', min => 0 }
            ]
        }
    } ];
}

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
    if (centreon::plugins::misc::is_empty($self->{option_results}->{pool_id})) {
        $self->{output}->add_option_msg(short_msg => 'Please set pool-id option');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $data = $options{custom}->request_api(
        url_path => '/RestService/rest.svc/1.0/performance/' . $self->{option_results}->{pool_id},
    );
    if (defined($data->[1])) {
        $self->{output}->add_option_msg(short_msg => 'multiples pools found in api response, only one is expected. Please check pool_id and datacore versions.');
        $self->{output}->option_exit();
    }
    $self->{BytesAllocatedPercentage}->{bytesallocatedpercentage} = $data->[0]->{"BytesAllocatedPercentage"};
    $self->{oversubscribed}->{oversubscribed} = $data->[0]->{"BytesOverSubscribed"};

}
1;

__END__

=head1 MODE

Check Datacore pool space and over subscribed usage exposed through the Rest API.

=over 8

=item B<--pool-id>

Id of the pool to check. See list-pool auto discovery mode to list pools id (required).

=item B<--warning-oversubscribed> B<--critical-oversubscribed>

Warning and critical threshold on the number of Bytes subscribed over the real space of the pool.

=item B<--warning-bytesallocatedpercentage> B<--critical-bytesallocatedpercentage>

Warning and critical threshold on the percentage of bytes allocated in the pool.

=back


