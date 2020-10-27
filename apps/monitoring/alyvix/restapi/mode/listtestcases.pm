#
## Copyright 2020 Centreon (http://www.centreon.com/)
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

package apps::monitoring::alyvix::restapi::mode::listtestcases;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-testcase:s'   => { name => 'filter_testcase' },
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
	my $result = $options{custom}->request_api(endpoint => 'testcases');
	return $result->{testcases};
}

sub run {
	my ($self, %options) = @_;
	my $testcases = $self->manage_selection(%options);
	foreach my $testcase (values $testcases) {
        next if (defined($self->{option_results}->{filter_testcase})
            && $self->{option_results}->{filter_testcase} ne ''
            && $testcase->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/ );

		$self->{output}->output_add(long_msg =>
            sprintf(
                '[name = %s]',$testcase->{testcase_alias} 
 			)
        );
    }

    $self->{output}->output_add(
        severity => 'OK',
        short_msg => 'List test cases:'
    );

    $self->{output}->display(nolabel => 1, force_ignore_perfdata => 1, force_long_output => 1);
    $self->{output}->exit();
}

sub disco_format {
    my ($self, %options) = @_;
    
    $self->{output}->add_disco_format(elements => ['name']);
}

sub disco_show {
    my ($self, %options) = @_;

    my $testcases = $self->manage_selection(%options);
    foreach my $testcase (values  $testcases) {
        next if (defined($self->{option_results}->{filter_case})
            && $self->{option_results}->{filter_case} ne ''
            && $testcase->{scenario} !~ /$self->{option_results}->{filter_case}/ );
        $self->{output}->add_disco_entry(name => $testcases->{testcase_alias});
    }
}

1;

__END__

=head1 MODE

Check Graylog system notifications using Graylog API

Example:
perl centreon_plugins.pl --plugin=apps::monitoring::alyvix::restapi::plugin
--mode=notifications --hostname=10.0.0.1 --username='username' --password='password' --credentials

More information on https://docs.graylog.org/en/<version>/pages/configuration/rest_api.html

=over 8

=item B<--filter-severity>

Filter on specific notification severity.
Can be 'normal' or 'urgent'.
(Default: both severities shown).

=item B<--filter-node>

Filter notifications by node ID.
(Default: all notifications shown).

=item B<--warning-notifications-*>

Set warning threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=item B<--critical-notifications-*>

Set critical threshold for notifications count (Default: '') where '*' can be 'total', 'normal'  or 'urgent'.

=back

=cut
