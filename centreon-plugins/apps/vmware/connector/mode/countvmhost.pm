#
# Copyright 2017 Centreon (http://www.centreon.com/)
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

package apps::vmware::connector::mode::countvmhost;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "esx-hostname:s"          => { name => 'esx_hostname' },
                                  "filter"                  => { name => 'filter' },
                                  "scope-datacenter:s"      => { name => 'scope_datacenter' },
                                  "scope-cluster:s"         => { name => 'scope_cluster' },
                                  "disconnect-status:s"     => { name => 'disconnect_status', default => 'unknown' },
                                  "warning-on:s"            => { name => 'warning_on' },
                                  "critical-on:s"           => { name => 'critical_on' },
                                  "warning-off:s"           => { name => 'warning_off' },
                                  "critical-off:s"          => { name => 'critical_off' },
                                  "warning-suspended:s"     => { name => 'warning_suspended' },
                                  "critical-suspended:s"    => { name => 'critical_suspended' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $label (('warning_on', 'critical_on', 'warning_off', 'critical_off', 'warning_suspended', 'critical_suspended')) {
        if (($self->{perfdata}->threshold_validate(label => $label, value => $self->{option_results}->{$label})) == 0) {
            my ($label_opt) = $label;
            $label_opt =~ tr/_/-/;
            $self->{output}->add_option_msg(short_msg => "Wrong " . $label_opt . " threshold '" . $self->{option_results}->{$label} . "'.");
            $self->{output}->option_exit();
        }
    }

    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{disconnect_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong disconnect-status status option '" . $self->{option_results}->{disconnect_status} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{connector}->add_params(params => $self->{option_results},
                                   command => 'countvmhost');
    $self->{connector}->run();
}

1;

__END__

=head1 MODE

Check number of vm running/off on ESX hosts.

=over 8

=item B<--esx-hostname>

ESX hostname to check.
If not set, we check all ESX.

=item B<--filter>

ESX hostname is a regexp.

=item B<--scope-datacenter>

Search in following datacenter(s) (can be a regexp).

=item B<--scope-cluster>

Search in following cluster(s) (can be a regexp).

=item B<--disconnect-status>

Status if ESX host disconnected (default: 'unknown').

=item B<--warning-on>

Threshold warning for 'poweredOn' vms.

=item B<--critical-on>

Threshold critical for 'poweredOn' vms.

=item B<--warning-off>

Threshold warning for 'poweredOff' vms.

=item B<--critical-off>

Threshold critical for 'poweredOff' vms.

=item B<--warning-suspended>

Threshold warning for 'suspended' vms.

=item B<--critical-suspended>

Threshold critical for 'suspended' vms.

=back

=cut
