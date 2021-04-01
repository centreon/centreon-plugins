#
# Copyright 2021 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure      application monitoring for
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
# See the License for the specific language governing permissions     
# limitations under the License.
#
# Author : CHEN JUN , aladdin.china@gmail.com

package apps::kingdee::eas::mode::oracleredolog;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datasource', type => 1, cb_prefix_output => 'prefix_datasource_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{datasource} = [
        { label => 'oracle-redolog-inactive', nlabel => 'datasource.oracle.redolog.inactive.count', set => {
                key_values => [ { name => 'inactive' } ],
                output_template => 'inactive: %s',
                perfdatas => [
                    { value => 'inactive', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'oracle-redolog-active', nlabel => 'datasource.oracle.redolog.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'active: %s',
                perfdatas => [
                    { value => 'active', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
        { label => 'oracle-redolog-current', nlabel => 'datasource.oracle.redolog.current.count', set => {
                key_values => [ { name => 'current' } ],
                output_template => 'current: %s',
                perfdatas => [
                    { value => 'current', template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        },
    ];
}

sub prefix_datasource_output {
    my ($self, %options) = @_;

    return "Datasource '" . $options{instance_value}->{display} . "' oracle redolog ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s'    => { name => 'url_path', default => "/easportal/tools/nagios/checkoracleredolog.jsp" },
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
	if ($webcontent !~ /^STATUS=CURRENT/mi) {
        $self->{output}->add_option_msg(short_msg => 'Cannot find oracle redolog status.');
		$self->{output}->option_exit();
	}

    $self->{datasource}->{$self->{option_results}->{datasource}} = { display => $self->{option_results}->{datasource} };
    $self->{datasource}->{$self->{option_results}->{datasource}}->{active} = $1 if ($webcontent =~ /^STATUS=ACTIVE\sCOUNT=(\d+)/mi);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{inactive} = $1 if ($webcontent =~ /^STATUS=INACTIVE\sCOUNT=(\d+)/mi);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{current} = $1 if ($webcontent =~ /^STATUS=CURRENT\sCOUNT=(\d+)/mi);
}

1;

__END__

=head1 MODE

Check oracle redolog status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoracleredolog.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'oracle-redolog-inactive', 'oracle-redolog-'active', 'oracle-redolog-current'.

=back

=cut
