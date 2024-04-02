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

package apps::etcd::exporter::mode::databasesize;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::common::monitoring::openmetrics::scrape;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0,
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'size',
            nlabel => 'database.size.bytes',
            set => {
                key_values => [
                    { name => 'size' }
                ],
                output_template => 'Database size: %s %s',
                output_change_bytes => 1,
                perfdatas => [
                    {
                        template => '%s',
                        unit => 'B',
                        min => 0
                    }
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

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);
}

sub manage_selection {
    my ($self, %options) = @_;
    
    my $raw_metrics = centreon::common::monitoring::openmetrics::scrape::parse(
        filter_metrics => 'etcd_mvcc_db_total_size_in_bytes',
        %options
    );

    # etcd_mvcc_db_total_size_in_bytes 1.1362304e+07
    
    $self->{global}->{size} = int($raw_metrics->{etcd_mvcc_db_total_size_in_bytes}->{data}[0]->{value});
}

1;

__END__

=head1 MODE

Check database size.

=over 8

=item B<--warning-size> B<--critical-size>

Thresholds on database size (in bytes).

=back

=cut