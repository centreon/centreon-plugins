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

package cloud::docker::mode::traffic;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.1';
    $options{options}->add_options(arguments =>
        {
            "port:s"          => { name => 'port' },
            "name:s"          => { name => 'name' },
            "id:s"            => { name => 'id' },
            "warning-in:s"    => { name => 'warning_in' },
            "critical-in:s"   => { name => 'critical_in' },
            "warning-out:s"   => { name => 'warning_out' },
            "critical-out:s"  => { name => 'critical_out' },
        });

    $self->{statefile_value} = centreon::plugins::statefile->new(%options);
    $self->{http} = centreon::plugins::http->new(output => $self->{output});

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if ((defined($self->{option_results}->{name})) && (defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }
    if ((!defined($self->{option_results}->{name})) && (!defined($self->{option_results}->{id}))) {
        $self->{output}->add_option_msg(short_msg => "Please set the name or id option");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-in', value => $self->{option_results}->{warning_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'in' threshold '" . $self->{option_results}->{warning_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-in', value => $self->{option_results}->{critical_in})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'in' threshold '" . $self->{option_results}->{critical_in} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'warning-out', value => $self->{option_results}->{warning_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning 'out' threshold '" . $self->{option_results}->{warning_out} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical-out', value => $self->{option_results}->{critical_out})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical 'out' threshold '" . $self->{option_results}->{critical_out} . "'.");
        $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

    my $new_datas = {};

    if (defined($self->{option_results}->{id})) {
        $self->{statefile_value}->read(statefile => 'docker_' . $self->{option_results}->{id}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    } elsif (defined($self->{option_results}->{name})) {
        $self->{statefile_value}->read(statefile => 'docker_' . $self->{option_results}->{name}  . '_' . $self->{http}->get_port() . '_' . $self->{mode});
    }

    my $urlpath;
    if (defined($self->{option_results}->{id})) {
        $urlpath = "/containers/".$self->{option_results}->{id}."/stats";
    } elsif (defined($self->{option_results}->{name})) {
        $urlpath = "/containers/".$self->{option_results}->{name}."/stats";
    }
    my $port = $self->{option_results}->{port};
    my $containerapi = $options{custom};

    my $webcontent = $containerapi->api_request(urlpath => $urlpath,
                                                port => $port);

    my $rx_bytes = $webcontent->{network}->{rx_bytes};
    my $tx_bytes = $webcontent->{network}->{tx_bytes};
    $new_datas->{rx_bytes} = $rx_bytes;
    $new_datas->{tx_bytes} = $tx_bytes;
    $new_datas->{last_timestamp} = time();
    my $old_timestamp = $self->{statefile_value}->get(name => 'last_timestamp');

    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{statefile_value}->write(data => $new_datas);
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $time_delta = $new_datas->{last_timestamp} - $old_timestamp;
        if ($time_delta <= 0) {
            # At least one second. two fast calls ;)
            $time_delta = 1;
    }

    my $old_rx_bytes = $self->{statefile_value}->get(name => 'rx_bytes');
    my $old_tx_bytes = $self->{statefile_value}->get(name => 'tx_bytes');

    if ($new_datas->{rx_bytes} < $old_rx_bytes) {
        # We set 0. Has reboot.
        $old_rx_bytes = 0;
    }
    if ($new_datas->{tx_bytes} < $old_tx_bytes) {
        # We set 0. Has reboot.
        $old_tx_bytes = 0;
    }

    my $delta_rx_bits = ($rx_bytes - $old_rx_bytes) * 8;
    my $delta_tx_bits = ($tx_bytes - $old_tx_bytes) * 8;
    my $rx_absolute_per_sec = $delta_rx_bits / $time_delta;
    my $tx_absolute_per_sec = $delta_tx_bits / $time_delta;

    my $exit1 = $self->{perfdata}->threshold_check(value => $rx_absolute_per_sec, threshold => [ { label => 'critical-in', 'exit_litteral' => 'critical' }, { label => 'warning-in', exit_litteral => 'warning' } ]);
    my $exit2 = $self->{perfdata}->threshold_check(value => $tx_absolute_per_sec, threshold => [ { label => 'critical-out', 'exit_litteral' => 'critical' }, { label => 'warning-out', exit_litteral => 'warning' } ]);

    my ($rx_value, $rx_unit) = $self->{perfdata}->change_bytes(value => $rx_absolute_per_sec, network => 1);
    my ($tx_value, $tx_unit) = $self->{perfdata}->change_bytes(value => $tx_absolute_per_sec, network => 1);
    my $exit = $self->{output}->get_most_critical(status => [ $exit1, $exit2 ]);
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Traffic In : %s/s, Out : %s/s",
                                    $rx_value . $rx_unit,
                                    $tx_value . $tx_unit));

    $self->{output}->perfdata_add(label => 'traffic_in', unit => 'b/s',
                                      value => sprintf("%.2f", $rx_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-in'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-in'),
                                      min => 0);
    $self->{output}->perfdata_add(label => 'traffic_out', unit => 'b/s',
                                      value => sprintf("%.2f", $tx_absolute_per_sec),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-out'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-out'),
                                      min => 0);

    $self->{statefile_value}->write(data => $new_datas);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's Network traffic usage

=head2 DOCKER OPTIONS

=item B<--port>

Port used by Docker

=item B<--id>

Specify one container's id

=item B<--name>

Specify one container's name

=head2 MODE OPTIONS

=item B<--warning-in>

Threshold warning in b/s for 'in' traffic.

=item B<--critical-in>

Threshold critical in b/s for 'in' traffic.

=item B<--warning-out>

Threshold warning in b/s for 'out' traffic.

=item B<--critical-out>

Threshold critical in b/s for 'out' traffic.

=back

=cut
