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

package cloud::docker::mode::cpu;

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
            "port:s"      => { name => 'port' },
            "name:s"      => { name => 'name' },
            "id:s"        => { name => 'id' },
            "warning:s"   => { name => 'warning' },
            "critical:s"  => { name => 'critical' },
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

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }

    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    $self->{http}->set_options(%{$self->{option_results}});
    $self->{statefile_value}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;

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

    my $cpu_totalusage = $webcontent->{cpu_stats}->{cpu_usage}->{total_usage};
    my $cpu_systemusage = $webcontent->{cpu_stats}->{system_cpu_usage};
    my @cpu_number = @{$webcontent->{cpu_stats}->{cpu_usage}->{percpu_usage}};
    my $cpu_throttledtime = $webcontent->{cpu_stats}->{throttling_data}->{throttled_time};

    my $new_datas = {};
    $new_datas->{cpu_totalusage} = $cpu_totalusage;
    $new_datas->{cpu_systemusage} = $cpu_systemusage;
    $new_datas->{cpu_throttledtime} = $cpu_throttledtime;
    my $old_cpu_totalusage = $self->{statefile_value}->get(name => 'cpu_totalusage');
    my $old_cpu_systemusage = $self->{statefile_value}->get(name => 'cpu_systemusage');
    my $old_cpu_throttledtime = $self->{statefile_value}->get(name => 'cpu_throttledtime');

    if ((!defined($old_cpu_totalusage)) || (!defined($old_cpu_systemusage)) || (!defined($old_cpu_throttledtime))) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
        $self->{statefile_value}->write(data => $new_datas);
        $self->{output}->display();
        $self->{output}->exit();
    }

    if ($new_datas->{cpu_totalusage} < $old_cpu_totalusage) {
        # We set 0. Has reboot.
        $old_cpu_totalusage = 0;
    }
    if ($new_datas->{cpu_systemusage} < $old_cpu_systemusage) {
        # We set 0. Has reboot.
        $old_cpu_systemusage = 0;
    }

	if ($new_datas->{cpu_throttledtime} < $old_cpu_throttledtime) {
        # We set 0. Has reboot.
        $old_cpu_throttledtime = 0;
    }

    my $delta_totalusage = $cpu_totalusage - $old_cpu_totalusage;
    my $delta_systemusage = $cpu_systemusage - $old_cpu_systemusage;
	my $delta_throttledtime = $cpu_throttledtime - $old_cpu_throttledtime;
	# Nano second to second
	my $throttledtime = $delta_throttledtime / 10 ** 9;
    my $prct_cpu = (($delta_totalusage / $delta_systemusage) * scalar(@cpu_number)) * 100;

    my $exit = $self->{perfdata}->threshold_check(value => $prct_cpu, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);

    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("CPU Usage is %.2f%% (Throttled Time: %.3fs)", $prct_cpu, $throttledtime));

    $self->{output}->perfdata_add(label => "cpu", unit => '%',
                                    value => $prct_cpu,
                                    warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                    critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                    min => 0,
                                    max => 100,
                                    );
    $self->{output}->perfdata_add(label => "throttled", unit => 's',
                                    value => $throttledtime,
                                    min => 0,
                                    );


    $self->{statefile_value}->write(data => $new_datas);

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check Container's CPU usage

=head2 DOCKER OPTIONS

=item B<--port>

Port used by Docker

=item B<--id>

Specify one container's id

=item B<--name>

Specify one container's name

=head2 MODE OPTIONS

=item B<--warning>

Threshold warning in percent.

=item B<--critical>

Threshold critical in percent.

=back

=cut
