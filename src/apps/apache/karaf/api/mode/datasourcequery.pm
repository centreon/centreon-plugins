#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::apache::karaf::api::mode::datasourcequery;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "Datasource query status is '%s'",
        $self->{result_values}->{status},
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        {
            name => 'global',
            type => 0
        }
    ];

    $self->{maps_counters}->{global} = [
        {
            label => 'status',
            type => 2,
            critical_default => '%{status} != 200',
            set => {
                key_values => [
                    { name => 'status' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
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
        'instance:s'   => { name => 'instance' },
        'datasource:s' => { name => 'datasource' },
        'query:s'      => { name => 'query' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{instance}) || $self->{option_results}->{instance} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --instance option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{datasource}) || $self->{option_results}->{datasource} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --datasource option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{option_results}->{query}) || $self->{option_results}->{query} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --query option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    my $datasource = $self->{option_results}->{datasource};
    $datasource  = 'jdbc/' . $datasource if ($datasource !~ /^jdbc\//);

    my $result = $options{custom}->request_api(
        method => 'POST',
        endpoint => '/jolokia/exec',
        payload => {
            type => 'exec',
            mbean => 'org.apache.karaf:type=jdbc,name=' . $self->{option_results}->{instance},
            operation => 'query(java.lang.String,java.lang.String)',
            arguments => [
                $datasource,
                $self->{option_results}->{query}
            ]
        }
    );

    $self->{global} = {
        status => $result->{status}
    };
}

1;

=head1 MODE

Check a datasource query execution status.

=over 8

=item B<--instance>

Set the Karaf instance where the datasource resides.

=item B<--datasource>

Set the datasource on which the query should be executed (Eg.: --datasource='as400ds'
or --datasource='jdbc/as400ds').

=item B<--query>

Set the SQL query to execute.

=item B<--warning-status>

Set warning threshold for status.
Can use special variables like: %{status}.

=item B<--critical-status>

Set critical threshold for status (Default: '%{status} != 200').
Can use special variables like: %{status}.

=back

=cut