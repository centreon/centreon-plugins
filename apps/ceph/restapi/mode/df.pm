#
# Copyright 2022 Centreon (http://www.centreon.com/)
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

package apps::ceph::restapi::mode::df;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub custom_rawusage_output {
    my ($self, %options) = @_;

    return sprintf(
        'Raw Usage is %.2f%%',
        $self->{result_values}->{raw_usage_prcnt}
    );
}

sub prefix_global_output {
    my ($self, %options) = @_;

    return 'Cluster df stats ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'raw-usage-prcnt', nlabel => 'df.stats.usage.raw.percentage', display_ok => 0, set => {
                key_values => [ { name => 'raw_usage_prcnt' }, { name => 'total_used_raw_ratio' }, { name => 'total_used_raw_bytes' }, { name => 'total_bytes' } ],
                closure_custom_output => $self->can('custom_rawusage_output'),
                perfdatas => [
                    { template => '%.2f', min => 0, max => 100, unit => '%' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {});

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;

    my $health = $options{custom}->request_api(endpoint => '/api/health/full');
    # We'll just set the entire stats array so it's all available for future features. 
    $self->{global} = $health->{df}->{stats};
    # Set a var so we have an actual percentage value based off the raw_ratio
    $self->{global}->{raw_usage_prcnt} = $health->{df}->{stats}->{total_used_raw_ratio} * 100 ;

}

1;

__END__

=head1 MODE

Check object storage daemons.

=over 8

=item B<--warning-raw-usage-prcnt> B<--critical-raw-usage-prcnt>

Thresholds.

=back

=cut
