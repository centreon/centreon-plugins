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

package apps::centreon::sql::mode::countnotifications;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::statefile;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"                   => { name => 'warning' },
                                  "critical:s"                  => { name => 'critical' },
                                  "centreon-storage-database:s" => { name => 'centreon_storage_database', default => 'centreon_storage' },
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
    $self->{sql}->query(query => "SELECT name, count(NULLIF(log_id, 0)) as num FROM " . $self->{option_results}->{centreon_storage_database} . ".instances LEFT JOIN " . $self->{option_results}->{centreon_storage_database} . ".logs ON logs.ctime > " . $options{time} . " AND logs.msg_type IN ('2', '3') AND logs.instance_name = instances.name WHERE deleted = '0' GROUP BY name");
    my $total_notifications = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        $self->{output}->output_add(long_msg => sprintf("%d sent notifications from %s", $row->{num}, $row->{name}));
        $total_notifications += $row->{num};
        $self->{output}->perfdata_add(label => 'notifications_' . $row->{name},
                                      value => $row->{num},
                                      min => 0);
    }

    my $exit_code = $self->{perfdata}->threshold_check(value => $total_notifications, threshold => [ { label => 'critical', exit_litteral => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    $self->{output}->output_add(severity => $exit_code,
                                short_msg => sprintf("%d total sent notifications", $total_notifications));
    $self->{output}->perfdata_add(label => 'total',
                                  value => $total_notifications,
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  min => 0);
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
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

Check the number of notifications (works only with centreon-broker).
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
