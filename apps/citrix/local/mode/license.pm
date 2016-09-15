#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package apps::citrix::local::mode::license;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use Win32::OLE;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"             => { name => 'warning', },
                                  "critical:s"            => { name => 'critical', },
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

    $self->{output}->output_add(severity => 'Ok',
                                short_msg => "All licenses are ok");
    
    my $wmi = Win32::OLE->GetObject('winmgmts:root\CitrixLicensing');
    if (!defined($wmi)) {
        $self->{output}->add_option_msg(short_msg => "Cant create server object:" . Win32::OLE->LastError());
        $self->{output}->option_exit();
    }

    my $count = 0;
    my $inUseCount = 0;
    my $percentUsed = 100;

    my $query = "Select InUseCount,Count from Citrix_GT_License_Pool";
    my $resultset = $wmi->ExecQuery($query);
    foreach my $obj (in $resultset) {
        $inUseCount = $obj->{InUseCount};
        $count = $obj->{Count};
        $percentUsed = ($inUseCount / $count) * 100;

        my $exit = $self->{perfdata}->threshold_check(value => $percentUsed, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(severity => $exit,
                                    short_msg => $percentUsed . "% licenses are used (" . $inUseCount . "/" . $count . ")");
        $self->{output}->perfdata_add(label => 'licenses_used',
                                      value => $inUseCount,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning', total => $count),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical', total => $count),
                                      min => 0, max => $count);
    }

    if ($count == 0) {
        $self->{output}->output_add(severity => 'Unknown',
                                    short_msg => "Can't get licenses count");
    }
 
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check Citrix licenses.

=over 8

=item B<--warning>

Threshold warning of licenses used in percent.

=item B<--critical>

Threshold critical of licenses used in percent.

=back

=cut
