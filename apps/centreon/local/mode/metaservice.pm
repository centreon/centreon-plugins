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

package apps::centreon::local::mode::metaservice;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::common::db;
use centreon::common::logger;

use vars qw($centreon_config);

my %DSTYPE = ( "0" => "g", "1" => "c", "2" => "d", "3" => "a");

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => { 
        'centreon-config:s' => { name => 'centreon_config', default => '/etc/centreon/centreon-config.pm' },
        'meta-id:s'         => { name => 'meta_id' },
    });

    $self->{metric_selected} = {};
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (!defined($self->{option_results}->{meta_id}) || $self->{option_results}->{meta_id} !~ /^[0-9]+$/) {
        $self->{output}->add_option_msg(short_msg => "Need to specify meta-id (numeric value) option.");
        $self->{output}->option_exit();
    }
    require $self->{option_results}->{centreon_config};
}

sub execute_query {
    my ($self, $db, $query) = @_;

    my ($status, $stmt) = $db->query($query);
    if ($status == -1) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'SQL Query error: ' . $query
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
    return $stmt;
}

sub select_by_regexp {
    my ($self, %options) = @_;

    my $count = 0;
    my $stmt = $self->execute_query(
        $self->{centreon_db_centstorage},
        "SELECT metrics.metric_id, metrics.metric_name, metrics.current_value FROM index_data, metrics WHERE index_data.service_description LIKE " . $self->{centreon_db_centstorage}->quote($options{regexp_str}) . " AND index_data.id = metrics.index_id"
    );
    while ((my $row = $stmt->fetchrow_hashref())) {
        if ($options{metric_select} eq $row->{metric_name}) {
            $self->{metric_selected}->{$row->{metric_id}} = $row->{current_value};
            $count++;
        }
    }
    if ($count == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot find a metric.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub select_by_list {
    my ($self, %options) = @_;

    my $count = 0;
    my $metric_ids = {};
    my $stmt = $self->execute_query($self->{centreon_db_centreon}, "SELECT metric_id FROM `meta_service_relation` WHERE meta_id = '". $self->{option_results}->{meta_id} . "' AND activate = '1'");
    while ((my $row = $stmt->fetchrow_hashref())) {
        $metric_ids->{$row->{metric_id}} = 1;
        $count++;
    }
    if ($count == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot find a metric_id in table meta_service_relation.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    $count = 0;
    $stmt = $self->execute_query(
        $self->{centreon_db_centstorage}, 
        "SELECT metric_id, current_value FROM metrics WHERE metric_id IN (" . join(',', keys %{$metric_ids}) . ")"
    );
    while ((my $row = $stmt->fetchrow_hashref())) {
        $self->{metric_selected}->{$row->{metric_id}} = $row->{current_value};
        $count++;
    }
    if ($count == 0) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot find a metric_id in metrics table.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }
}

sub calculate {
    my ($self, %options) = @_;
    my $result = 0;

    if ($options{calculation} eq 'MIN') {
        my @values = sort { $a <=> $b } values(%{$self->{metric_selected}});
        if (defined($values[0])) {
            $result = $values[0];
        }
    } elsif ($options{calculation} eq 'MAX') {
        my @values = sort { $a <=> $b } values(%{$self->{metric_selected}});
        if (defined($values[0])) {
            $result = $values[scalar(@values) - 1];
        }
    } elsif ($options{calculation} eq 'SOM') {
        foreach my $value (values %{$self->{metric_selected}}) {
            $result += $value;
        }
    } elsif ($options{calculation} eq 'AVE') {
        my @values = values %{$self->{metric_selected}};
        foreach my $value (@values) {
            $result += $value;
        }
        my $total = scalar(@values);
        if ($total == 0) {
            $total = 1;
        }
        $result = $result / $total;
    }
    return $result;
}

sub run {
    my ($self, %options) = @_;

    $self->{logger} = centreon::common::logger->new();
    $self->{logger}->severity('none');
    $self->{centreon_db_centreon} = centreon::common::db->new(
        db => $centreon_config->{centreon_db},
        host => $centreon_config->{db_host},
        port => $centreon_config->{db_port},
        user => $centreon_config->{db_user},
        password => $centreon_config->{db_passwd},
        force => 0,
        logger => $self->{logger}
    );
    my $status = $self->{centreon_db_centreon}->connect();
    if ($status == -1) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'Cannot connect to Centreon Database.');
        $self->{output}->display();
        $self->{output}->exit();
    }
    $self->{centreon_db_centstorage} = centreon::common::db->new(
        db => $centreon_config->{centstorage_db},
        host => $centreon_config->{db_host},
        port => $centreon_config->{db_port},
        user => $centreon_config->{db_user},
        password => $centreon_config->{db_passwd},
        force => 0,
        logger => $self->{logger}
    );
    $status = $self->{centreon_db_centstorage}->connect();
    if ($status == -1) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot connect to Centstorage Database.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    my $stmt = $self->execute_query($self->{centreon_db_centreon}, "SELECT meta_display, calcul_type, regexp_str, warning, critical, metric, meta_select_mode, data_source_type FROM `meta_service` WHERE meta_id = '". $self->{option_results}->{meta_id} . "' LIMIT 1");
    my $row = $stmt->fetchrow_hashref();
    if (!defined($row)) {
        $self->{output}->output_add(
            severity => 'UNKNOWN',
            short_msg => 'Cannot get meta service informations.'
        );
        $self->{output}->display();
        $self->{output}->exit();
    }

    # Set threshold
    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $row->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $row->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $row->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $row->{critical} . "'.");
        $self->{output}->option_exit();
    }

    if ($row->{meta_select_mode} == 2) {
        $self->select_by_regexp(regexp_str => $row->{regexp_str}, metric_select => $row->{metric});
    } else {
        $self->select_by_list();
    } 

    my $result = $self->calculate(calculation => $row->{calcul_type});

    my $exit = $self->{perfdata}->threshold_check(value => $result, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    my $display = defined($row->{meta_display}) ? $row->{meta_display} : $row->{calcul_type} . ' - value : %f';
    $self->{output}->output_add(
        severity => $exit,
        short_msg => sprintf($display, $result)
    );
    $self->{output}->perfdata_add(
        label => (defined($DSTYPE{$row->{data_source_type}}) ? $DSTYPE{$row->{data_source_type}} : 'g') . '[' . $row->{metric} . ']', 
        value => sprintf("%02.2f", $result),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical')
    );

    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Do Centreon meta-service checks.

=over 8

=item B<--centreon-config>

Centreon Database Config File (Default: '/etc/centreon/centreon-config.pm').

=item B<--meta-id>

Meta-id to check (required).

=back

=cut
