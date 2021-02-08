#
## Copyright 2021 Centreon (http://www.centreon.com/)
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

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-testcase:s' => { name => 'filter_testcase' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
}

sub manage_selection {
    my ($self, %options) = @_;

    my $result = $options{custom}->request_api(endpoint => 'testcases');
    return $result->{testcases};
}

sub run {
    my ($self, %options) = @_;

    my $testcases = $self->manage_selection(%options);
    foreach my $testcase (@$testcases) {
        next if (defined($self->{option_results}->{filter_testcase})
            && $self->{option_results}->{filter_testcase} ne ''
            && $testcase->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/);

        $self->{output}->output_add(long_msg =>
            sprintf(
                '[name = %s]', $testcase->{testcase_alias}
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
    foreach my $testcase (@$testcases) {
        next if (defined($self->{option_results}->{filter_testcase})
            && $self->{option_results}->{filter_testcase} ne ''
            && $testcase->{testcase_alias} !~ /$self->{option_results}->{filter_testcase}/ );

        $self->{output}->add_disco_entry(name => $testcase->{testcase_alias});
    }
}

1;

__END__

=head1 MODE

List Alyvix Server test cases.

=over 8

=item B<--filter-testcase>

Filter on specific test case.

=back

=cut
