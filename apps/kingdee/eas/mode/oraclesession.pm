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

package apps::kingdee::eas::mode::oraclesession;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'datasource', type => 1, cb_prefix_output => 'prefix_datasource_output', skipped_code => { -10 => 1 } },
    ];

    $self->{maps_counters}->{datasource} = [
        { label => 'oracle-sessions-active', nlabel => 'datasource.oracle.sessions.active.count', set => {
                key_values => [ { name => 'active' } ],
                output_template => 'sessions active: %s',
                perfdatas => [
                    { value => 'active', template => '%s', min => 0, max => 'total', label_extra_instance => 1 },
                ],
            }
        },
        { label => 'oracle-sessions-inactive', nlabel => 'datasource.oracle.sessions.inactive.count', set => {
                key_values => [ { name => 'inactive' } ],
                output_template => 'sessions inactive: %s',
                perfdatas => [
                    { value => 'inactive', template => '%s', min => 0, max => 'total', label_extra_instance => 1 },
                ],
            }
        },
    ];

    foreach (
        ('other', 'queueing', 'network', 'administrative', 'configuration',
         'commit', 'application', 'concurrency',
         'scheduler', 'idle', 'userio', 'systemio')
    ) {
        push @{$self->{maps_counters}->{datasource}},
        { label => 'oracle-waitclass-' . $_, nlabel => 'datasource.oracle.waitclass.' . $_ . '.count', display_ok => 0, set => {
                key_values => [ { name => $_ } ],
                output_template => 'wait class ' . $_ . ': %s',
                perfdatas => [
                    { value => $_ , template => '%s', min => 0, label_extra_instance => 1 },
                ],
            }
        };
    }
}

sub prefix_datasource_output {
    my ($self, %options) = @_;

    return "Datasource '" . $options{instance_value}->{display} . "' oracle ";
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'urlpath:s'    => { name => 'url_path', default => "/easportal/tools/nagios/checkoraclesession.jsp" },
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

    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path} . '&groupby=status');
	if ($webcontent !~ /^STATUS=ACTIVE/mi) {
		$self->{output}->add_option_msg(short_msg => 'Cannot find oracle session info.');
		$self->{output}->option_exit();
	}

    $self->{datasource}->{$self->{option_results}->{datasource}} = { display => $self->{option_results}->{datasource} };
    $self->{datasource}->{$self->{option_results}->{datasource}}->{active} = $1 if ($webcontent =~ /^STATUS=ACTIVE\sCOUNT=(\d+)/mi);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{inactive} = $1 if ($webcontent =~ /^STATUS=INACTIVE\sCOUNT=(\d+)/mi);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{total} =
        $self->{datasource}->{$self->{option_results}->{datasource}}->{active} + $self->{datasource}->{$self->{option_results}->{datasource}}->{inactive};

    $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path} . '&groupby=wait_class&status=ACTIVE');
	if ($webcontent !~ /^WAIT_CLASS=.*?COUNT=\d+/mi) {
		$self->{output}->add_option_msg(short_msg => 'Cannot find oracle session info.');
		$self->{output}->option_exit();
	} 
	
    foreach (
        ('other', 'queueing', 'network', 'administrative', 'configuration',
         'commit', 'application', 'concurrency',
         'scheduler', 'idle')
    ) {
        $self->{datasource}->{$self->{option_results}->{datasource}}->{$_} = $1 if ($webcontent =~ /^WAIT_CLASS=$_\sCOUNT=(\d+)/mi);
    }
    
    $self->{datasource}->{$self->{option_results}->{datasource}}->{systemio} = $1 if ($webcontent =~ /^WAIT_CLASS='System\s+I\/O'\sCOUNT=(\d+)/mi);
    $self->{datasource}->{$self->{option_results}->{datasource}}->{userio} = $1 if ($webcontent =~ /^WAIT_CLASS='User\s+I\/O'\sCOUNT=(\d+)/mi);
}

1;

__END__

=head1 MODE

Check oracle database session status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkoraclesession.jsp')

=item B<--datasource>

Specify the datasource name.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'oracle-sessions-active', 'oracle-sessions-inactive', 'oracle-waitclass-other',
'oracle-waitclass-queueing', 'oracle-waitclass-network', 'oracle-waitclass-administrative',
'oracle-waitclass-configuration', 'oracle-waitclass-commit', 'oracle-waitclass-application',
'oracle-waitclass-concurrency', 'oracle-waitclass-scheduler', 'oracle-waitclass-idle',
'oracle-waitclass-userio', 'oracle-waitclass-systemio'.

=back

=cut
