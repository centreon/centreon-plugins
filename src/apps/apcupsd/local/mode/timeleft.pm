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

package apps::apcupsd::local::mode::timeleft;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'apchost:s'       => { name => 'apchost', default => 'localhost' },
        'apcport:s'       => { name => 'apcport', default => '3551' },
        'searchpattern:s' => { name => 'searchpattern', default => 'TIMELEFT' },
        'warning:s'       => { name => 'warning' },
        'critical:s'      => { name => 'critical' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{apchost})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify an APC Host.");
        $self->{output}->option_exit(); 
    }
    if (!defined($self->{option_results}->{apcport})) {
        $self->{output}->add_option_msg(short_msg => "Need to specify an APC Port.");
        $self->{output}->option_exit(); 
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }

    $self->{option_results}->{apchost} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{apchost});
    $self->{option_results}->{apcport} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{apcport});
}

sub run {
    my ($self, %options) = @_;

    my $result = $options{custom}->execute_command(
        command_path => '/sbin',
        command => 'apcaccess',
        command_options => 'status ' . $self->{option_results}->{apchost} . ':' . $self->{option_results}->{apcport} . ' 2>&1',
        searchpattern => $self->{option_results}->{searchpattern}
    );

    my $exit = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf($self->{option_results}->{searchpattern} . ": %f", $result)
    );

    $self->{output}->perfdata_add(
        label => $self->{option_results}->{searchpattern},
        value => $result,
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check battery time left

Command used: /sbin/apcaccess status %(apchost):%(apcport) 2>&1

=over 8

=item B<--apchost>

IP used by apcupsd

=item B<--apcport>

Port used by apcupsd

=item B<--warning>

Warning Threshold

=item B<--critical>

Critical Threshold

=back

=cut
