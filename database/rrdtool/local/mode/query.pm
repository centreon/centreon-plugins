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

package database::rrdtool::local::mode::query;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub prefix_global_output {
    my ($self, %options) = @_;
    
    return "datasource '" . $options{instance_value}->{ds_name} . "': ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_global_output', skipped_code => { -10 => 1 } }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'value-minimum', nlabel => 'datasource.value.minimum.count', set => {
                key_values => [ { name => 'min' }, { name => 'ds_name' } ],
                output_template => '%s (min)',
                perfdatas => [
                    { template => '%s', label_extra_instance => 1, instance_use => 'ds_name' }
                ]
            }
        },
        { label => 'value-average', nlabel => 'datasource.value.average.count', set => {
                key_values => [ { name => 'avg' }, { name => 'ds_name' } ],
                output_template => '%s (avg)',
                perfdatas => [
                    { template => '%s', label_extra_instance => 1, instance_use => 'ds_name' }
                ]
            }
        },
        { label => 'value-maximum', nlabel => 'datasource.value.maximum.count', set => {
                key_values => [ { name => 'max'}, { name => 'ds_name' } ],
                output_template => '%s (max)',
                perfdatas => [
                    { template => '%s', label_extra_instance => 1, instance_use => 'ds_name' }
                ]
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'rrd-file:s'  => { name => 'rrd_file' },
        'ds-name:s'   => { name => 'ds_name', default => 'value' },
        'timeframe:s' => { name => 'timeframe', default => 3600 }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{rrd_file}) || $self->{option_results}->{rrd_file} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --rrd-file option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{timeframe}) || $self->{option_results}->{timeframe} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --timeframe option.');
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{ds_name}) || $self->{option_results}->{ds_name} eq '') {
        $self->{output}->add_option_msg(short_msg => 'Please set --ds-name option.');
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->query(
        rrd_file => $self->{option_results}->{rrd_file},
        ds_name => $self->{option_results}->{ds_name},
        start => time() - $self->{option_results}->{timeframe},
        end => time()
    );

    $self->{global} = {
        ds_name => $self->{option_results}->{ds_name},
        %$result
    };
}

1;

__END__

=head1 MODE

Query DS min/max/average on a timeframe.

=over 8

=item B<--rrd-file>

Set rrd file to query.

=item B<--ds-name>

Set DS name to query (default: 'value').

=item B<--timeframe>

Set timeframe in seconds (E.g '3600' to check last 60 minutes).

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'value-minimum', 'value-average', 'value-maximum'.

=back

=cut
