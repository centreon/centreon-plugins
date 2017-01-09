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

package apps::vmware::connector::mode::nethost;

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
                                  "nic-name:s"              => { name => 'nic_name' },
                                  "filter"                  => { name => 'filter' },
                                  "scope-datacenter:s"      => { name => 'scope_datacenter' },
                                  "scope-cluster:s"         => { name => 'scope_cluster' },
                                  "filter-nic"              => { name => 'filter_nic' },
                                  "disconnect-status:s"     => { name => 'disconnect_status', default => 'unknown' },
                                  "warning-in:s"            => { name => 'warning_in', },
                                  "critical-in:s"           => { name => 'critical_in', },
                                  "warning-out:s"           => { name => 'warning_out', },
                                  "critical-out:s"          => { name => 'critical_out', },
                                  "link-down-status:s"      => { name => 'link_down_status', default => 'critical' },
                                  "no-proxyswitch"          => { name => 'no_proxyswitch' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $label (('warning_in', 'critical_in', 'warning_out', 'critical_out')) {
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
    if ($self->{output}->is_litteral_status(status => $self->{option_results}->{link_down_status}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong link down status option '" . $self->{option_results}->{link_down_status} . "'.");
        $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{connector}->add_params(params => $self->{option_results},
                                   command => 'nethost');
    $self->{connector}->run();
}

1;

__END__

=head1 MODE

Check ESX net usage.

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

=item B<--nic-name>

ESX nic to check.
If not set, we check all nics.

=item B<--filter-nic>

Nic name is a regexp.

=item B<--disconnect-status>

Status if ESX host disconnected (default: 'unknown').

=item B<--link-down-status>

Status if some links are down (default: 'critical').

=item B<--warning-in>

Threshold warning traffic in (percent).

=item B<--critical-in>

Threshold critical traffic in (percent).

=item B<--warning-out>

Threshold warning traffic out (percent).

=item B<--critical-out>

Threshold critical traffic out (percent).

=item B<--no-proxyswitch>

Use the following option if you are checking an ESX 3.x version (it's mandatory).

=back

=cut
