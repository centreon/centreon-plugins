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

package centreon::common::jvm::mode::fdusage;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"   => { name => 'warning' },
                                  "critical:s"  => { name => 'critical' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{request} = [
         { mbean => "java.lang:type=OperatingSystem", attributes => [ { name => 'MaxFileDescriptorCount' }, { name => 'OpenFileDescriptorCount' } ] }
    ];
    my $result = $self->{connector}->get_attributes(request => $self->{request}, nothing_quit => 1);
    my $prct_fd = $result->{"java.lang:type=OperatingSystem"}->{OpenFileDescriptorCount} / $result->{"java.lang:type=OperatingSystem"}->{MaxFileDescriptorCount} * 100;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_fd,
                                                  threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->perfdata_add(label => 'fd',
                                  value => $result->{"java.lang:type=OperatingSystem"}->{OpenFileDescriptorCount},
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $result->{"java.lang:type=OperatingSystem"}->{MaxFileDescriptorCount}, cast_int => 1),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $result->{"java.lang:type=OperatingSystem"}->{MaxFileDescriptorCount}, cast_int => 1),
                                  min => 0, max => $result->{"java.lang:type=OperatingSystem"}->{MaxFileDescriptorCount});

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("File descriptor percentage usage: %.2f%%", $prct_fd));

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check number/percentage of file descriptors

Example:
perl centreon_plugins.pl --plugin=apps::tomcat::jmx::plugin --custommode=jolokia --url=http://10.30.2.22:8080/jolokia-war --mode=fd-usage --warning 60 --critical 75

=over 8

=item B<--warning>

Threshold warning percentage concerning fd capacity

=item B<--critical>

Threshold critical percentage concerning fd capacity

=back

=cut

