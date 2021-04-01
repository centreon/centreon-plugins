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

package apps::centreon::sql::mode::countproblems;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => { 
        'warning:s'                   => { name => 'warning' },
        'critical:s'                  => { name => 'critical' },
        'centreon-storage-database:s' => { name => 'centreon_storage_database', default => 'centreon_storage' },
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
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
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical}. "'.");
        $self->{output}->option_exit();
    }
    
    $self->{statefile_cache}->check_options(%options);
}

sub execute {
    my ($self, %options) = @_;

    $self->{sql}->connect();
    $self->{sql}->query(query => "SELECT name, msg_type, status, count(NULLIF(log_id, 0)) as num FROM " . $self->{option_results}->{centreon_storage_database} . ".instances LEFT JOIN " . $self->{option_results}->{centreon_storage_database} . ".logs ON logs.ctime > " . $options{time} . " AND logs.msg_type IN ('0', '1') AND type = '1' AND status NOT IN ('0') AND logs.instance_name = instances.name WHERE deleted = '0' GROUP BY name, msg_type, status");

    my $total_problems = { total => 0, hosts => 0, services => 0 };
    my $total_problems_by_poller = {};
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (!defined($total_problems_by_poller->{$row->{name}})) {
            $total_problems_by_poller->{$row->{name}} = {
                '0_1' => { label_perf => 'host_down', label => 'host down', num => 0 },
                '1_1' => { label_perf => 'service_warning', label => 'service warning', num => 0 },
                '1_2' => { label_perf => 'service_critical', label => 'service critical', num => 0 },
                '1_3' => { label_perf => 'service_unknown', label => 'service unknown', num => 0 }
            };
        }

        if ($row->{num} != 0 && defined($total_problems_by_poller->{$row->{name}}->{$row->{msg_type} . '_' . $row->{status}})) {
            $total_problems_by_poller->{$row->{name}}->{$row->{msg_type} . '_' . $row->{status}}->{num} = $row->{num};
            if ($row->{msg_type} == 0) {
                $total_problems->{hosts} += $row->{num};
            } else {
                $total_problems->{services} += $row->{num};
            }
            $total_problems->{total} += $row->{num};
        }        
    }

    $self->{output}->output_add(long_msg => sprintf("%d total hosts problems", $total_problems->{services}));
    $self->{output}->output_add(long_msg => sprintf("%d total services problems", $total_problems->{services}));
    foreach my $poller (sort keys %{$total_problems_by_poller}) {
        foreach my $id (sort keys %{$total_problems_by_poller->{$poller}}) {
            $self->{output}->output_add(
                long_msg => sprintf(
                    "%d %s problems on %s", 
                    $total_problems_by_poller->{$poller}->{$id}->{num},
                    $total_problems_by_poller->{$poller}->{$id}->{label},
                    $poller
                )
            );
            $self->{output}->perfdata_add(
                label => $total_problems_by_poller->{$poller}->{$id}->{label_perf} . "_" . $poller,
                value => $total_problems_by_poller->{$poller}->{$id}->{num},
                min => 0
            );
        }
    }

    my $exit_code = $self->{perfdata}->threshold_check(value => $total_problems->{total}, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%d total problems", $total_problems->{total}));
    $self->{output}->perfdata_add(
        label => 'total',
        value => $total_problems->{total},
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
        min => 0
    );
    $self->{output}->perfdata_add(
        label => 'total_hosts',
        value => $total_problems->{hosts},
        min => 0);
    $self->{output}->perfdata_add(
        label => 'total_services',
        value => $total_problems->{services},
        min => 0
    );
}

sub run {
    my ($self, %options) = @_;
    $self->{sql} = $options{sql};

    $self->{statefile_cache}->read(statefile => 'sql_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    my $new_datas = { last_timestamp => time() };
    $self->{statefile_cache}->write(data => $new_datas);
    
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");   
    } else {
        $self->execute(time => $old_timestamp);
    }

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check the number of problems (works only with centreon-broker).
The mode should be used with mysql plugin and dyn-mode option.

=over 8

=item B<--centreon-storage-database>

Centreon storage database name (default: 'centreon_storage').

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=back

=cut
