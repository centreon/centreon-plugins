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
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oracleksqltemptable;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datasource', type => 1, cb_prefix_output => 'prefix_datasource_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{datasource} = [
        { label => 'table-ksqltemp', nlabel => 'datasource.table.ksqltemp.count', set => {
                key_values => [ { name => 'ksqltemp_count' } ],
                output_template => 'ksqltemp table: %s',
                perfdatas => [
                    { value => 'ksqltemp_count', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        }
    ];
}

sub prefix_datasource_output {
    my ($self, %options) = @_;

    return "Datasource '" . $options{instance_value}->{display} . "' ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s'    => { name => 'url_path', default => "/easportal/tools/nagios/checkoraclevt.jsp" },
        'datasource:s' => { name => 'datasource' },
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{datasource}) || $self->{option_results}->{datasource} eq "") {
        $self->{output}->add_option_msg(short_msg => "Missing datasource name.");
        $self->{output}->option_exit();
    }
    $self->{option_results}->{url_path} .= "?ds=" . $self->{option_results}->{datasource};
}

sub manage_selection {
    my ($self, %options) = @_;

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});
    if ($webcontent !~ /^COUNT.*?=\d+/i) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find ksql temptable status.');
        $self->{output}->option_exit();
    }

    $self->{datasource}->{$self->{option_results}->{datasource}} = { display => $self->{option_results}->{datasource} };
    $self->{datasource}->{$self->{option_results}->{datasource}}->{ksqltemp_count} = $1 if ($webcontent =~ /^COUNT.*?=(\d+)/i);
}

1;

__END__

=head1 MODE

Check ksql temp table count for specify datasource.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoraclevt.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'table-ksqltemp'.

=back

=cut
