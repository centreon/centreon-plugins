#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package apps::kingdee::eas::mode::javaruntime;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use POSIX;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments =>
            {
            "urlpath:s"         => { name => 'url_path', default => "/easportal/tools/nagios/checkjavaruntime.jsp" },
            "warning:s"         => { name => 'warning' },
            "critical:s"        => { name => 'critical' },
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
        
    my $webcontent = $options{custom}->request(path => $self->{option_results}->{url_path});

    if ($webcontent !~ /VmName=/mi) {
        $self->{output}->output_add(
            severity  => 'UNKNOWN',
            short_msg => "Cannot find java runtime status."
        );
        $self->{output}->option_exit();
    }
        
    my $vmname = $1 if $webcontent =~ /VmName=\'(.*?)\'/i;
    my $specversion = $1 if $webcontent =~ /SpecVersion=([\d\.]+)/i;
    my $vmversion = $1 if $webcontent =~ /VmVersion=(.*?)\s/i;
    my $vender = $1 if $webcontent =~ /VmVendor=\'(.*?)\'/i;
    my $uptime = $1 if $webcontent =~ /Uptime=(\d*)/i;   #unit:ms
    my $startime = $1 if $webcontent =~ /StartTime=(\d*)/i;

    my $exit = $self->{perfdata}->threshold_check(value => $uptime / 1000, threshold => [ 
                                                  { label => 'critical', 'exit_litteral' => 'critical' }, 
                                                  { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("Uptime: %s", 
                                  centreon::plugins::misc::change_seconds(value => floor($uptime / 1000), start => 'd'))
                                  );
    $self->{output}->output_add(severity => $exit, short_msg => sprintf("%s %s (build %s), %s", 
                                  $vmname ,$specversion, $vmversion,$vender)
                                  );
  
    $self->{output}->perfdata_add(label => "Uptime", unit => 's',
                                  value => sprintf("%d", floor($uptime / 1000)),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );
    $self->{output}->perfdata_add(label => "SpecVersion", unit => '',
                                  value => sprintf("%s", $specversion),
                                  );

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check EAS application java runtime status.

=over 8

=item B<--urlpath>

Set path to get status page. (Default: '/easportal/tools/nagios/checkjavaruntime.jsp')

=item B<--warning>

Warning Threshold for uptime (sec)

=item B<--critical>

Critical Threshold for uptime (sec)

=back

=cut
