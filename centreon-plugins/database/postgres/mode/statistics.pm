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

package database::postgres::mode::statistics;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;
use centreon::plugins::statefile;
use Digest::MD5 qw(md5_hex);

my $maps_counters = {
    database => { 
        '000_commit'   => { set => {
                        key_values => [ { name => 'commit', diff => 1 }, { name => 'name' }, ],
                        output_template => 'Commit : %s',
                        perfdatas => [
                            { label => 'commit', value => 'commit_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                        ],
                    }
               },
        '001_rollback'   => { set => {
                        key_values => [ { name => 'rollback', diff => 1 }, { name => 'name' }, ],
                        output_template => 'Rollback : %s',
                        perfdatas => [
                            { label => 'rollback', value => 'rollback_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                        ],
                    }
               },
        '002_insert'   => { set => {
                        key_values => [ { name => 'insert', diff => 1 }, { name => 'name' }, ],
                        output_template => 'Insert : %s',
                        perfdatas => [
                            { label => 'insert', value => 'insert_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                        ],
                    }
               },
        '003_update'   => { set => {
                        key_values => [ { name => 'update', diff => 1 }, { name => 'name' }, ],
                        output_template => 'Update : %s',
                        perfdatas => [
                            { label => 'update', value => 'update_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                        ],
                    }
               },
        '004_delete'   => { set => {
                        key_values => [ { name => 'delete', diff => 1 }, { name => 'name' }, ],
                        output_template => 'Delete : %s',
                        perfdatas => [
                            { label => 'delete', value => 'delete_absolute', template => '%s',
                              min => 0, label_extra_instance => 1, instance_use => 'name_absolute' },
                        ],
                    }
               },
        },
    total => {
        '000_total-commit'   => { set => {
                        key_values => [ { name => 'commit', diff => 1 } ],
                        output_template => 'Commit : %s',
                        perfdatas => [
                            { label => 'commit', value => 'commit_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '001_total-rollback'   => { set => {
                        key_values => [ { name => 'rollback', diff => 1 } ],
                        output_template => 'Rollback : %s',
                        perfdatas => [
                            { label => 'rollback', value => 'rollback_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '002_total-insert'   => { set => {
                        key_values => [ { name => 'insert', diff => 1 } ],
                        output_template => 'Insert : %s',
                        perfdatas => [
                            { label => 'insert', value => 'insert_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '003_total-update'   => { set => {
                        key_values => [ { name => 'update', diff => 1 } ],
                        output_template => 'Update : %s',
                        perfdatas => [
                            { label => 'update', value => 'update_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
        '004_total-delete'   => { set => {
                        key_values => [ { name => 'delete', diff => 1 } ],
                        output_template => 'Delete : %s',
                        perfdatas => [
                            { label => 'delete', value => 'delete_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    }
};

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "filter-database:s"     => { name => 'filter_database' },
                                });                         
    $self->{statefile_value} = centreon::plugins::statefile->new(%options);

    foreach my $key (('database', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            my ($id, $name) = split /_/;
            if (!defined($maps_counters->{$key}->{$_}->{threshold}) || $maps_counters->{$key}->{$_}->{threshold} != 0) {
                $options{options}->add_options(arguments => {
                                                            'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                            'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                               });
            }
            $maps_counters->{$key}->{$_}->{obj} = centreon::plugins::values->new(statefile => $self->{statefile_value},
                                                      output => $self->{output}, perfdata => $self->{perfdata},
                                                      label => $name);
            $maps_counters->{$key}->{$_}->{obj}->set(%{$maps_counters->{$key}->{$_}->{set}});
        }
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach my $key (('database', 'total')) {
        foreach (keys %{$maps_counters->{$key}}) {
            $maps_counters->{$key}->{$_}->{obj}->init(option_results => $self->{option_results});
        }
    }
    
    $self->{statefile_value}->check_options(%options);
}

sub check_total {
    my ($self, %options) = @_;
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits = ();
    foreach (sort keys %{$maps_counters->{total}}) {
        my $obj = $maps_counters->{total}->{$_}->{obj};
        $obj->set(instance => 'global');
    
        my ($value_check) = $obj->execute(values => $self->{global},
                                          new_datas => $self->{new_datas});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $obj->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $obj->threshold_check();
        push @exits, $exit2;

        my $output = $obj->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $obj->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Total $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Total $long_msg");
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};
    
    $self->manage_selection();
    
    $self->{new_datas} = {};
    $self->{statefile_value}->read(statefile => "postgres_" . $self->{mode} . '_' . $self->{sql}->get_unique_id4save() . '_' . (defined($self->{option_results}->{filter_database}) ? md5_hex($self->{option_results}->{filter_database}) : md5_hex('.*')));
    $self->{new_datas}->{last_timestamp} = time();
    
    my $multiple = 1;
    if (scalar(keys %{$self->{db_selected}}) == 1) {
        $multiple = 0;
    }

    if ($multiple == 1) {
        $self->check_total();
    }
    
    ####
    # By database 
    if ($multiple == 1) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All database statistics are ok');
    }
    
    foreach my $id (sort keys %{$self->{db_selected}}) {     
        my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
        my @exits = ();
        foreach (sort keys %{$maps_counters->{database}}) {
            my $obj = $maps_counters->{database}->{$_}->{obj};
            $obj->set(instance => $id);
        
            my ($value_check) = $obj->execute(values => $self->{db_selected}->{$id},
                                              new_datas => $self->{new_datas});

            if ($value_check != 0) {
                $long_msg .= $long_msg_append . $obj->output_error();
                $long_msg_append = ', ';
                next;
            }
            my $exit2 = $obj->threshold_check();
            push @exits, $exit2;

            my $output = $obj->output();
            $long_msg .= $long_msg_append . $output;
            $long_msg_append = ', ';
            
            if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
                $short_msg .= $short_msg_append . $output;
                $short_msg_append = ', ';
            }
            
            $maps_counters->{database}->{$_}->{obj}->perfdata(extra_instance => $multiple);
        }

        $self->{output}->output_add(long_msg => "Database '" . $self->{db_selected}->{$id}->{name} . "' $long_msg");
        my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => "Database '" . $self->{db_selected}->{$id}->{name} . "' $short_msg"
                                        );
        }
        
        if ($multiple == 0) {
            $self->{output}->output_add(short_msg => "Database '" . $self->{db_selected}->{$id}->{name} . "' $long_msg");
        }
    }
     
    $self->{statefile_value}->write(data => $self->{new_datas});
    $self->{output}->display();
    $self->{output}->exit();
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{db_selected} = {};
    $self->{global} = { commit => 0, rollback => 0, insert => 0, update => 0, delete => 0 };
    my $query = q{
SELECT d.datname as name, pg_stat_get_db_xact_commit(d.oid) as commit, 
                  pg_stat_get_db_xact_rollback(d.oid) as rollback, 
                  pg_stat_get_tuples_inserted(d.oid) as insert, 
                  pg_stat_get_tuples_updated(d.oid) as update, pg_stat_get_tuples_updated(d.oid) as delete 
       FROM pg_database d;
};
    $self->{sql}->connect();
    $self->{sql}->query(query => $query);
    
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        if (defined($self->{option_results}->{filter_database}) && $self->{option_results}->{filter_database} ne '' &&
            $row->{name} !~ /$self->{option_results}->{filter_database}/) {
            $self->{output}->output_add(long_msg => "Skipping  '" . $row->{name} . "': no matching filter.");
            next;
        }
        
        $self->{db_selected}->{$row->{name}} = {%$row};
        foreach (keys %{$self->{global}}) {
            $self->{global}->{$_} += $row->{$_};
        }
    }
    
    if (scalar(keys %{$self->{db_selected}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No database found.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check database statistics: commit, rollback, insert, delete, update.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'total-*', 'total-*', '*', The '*' can be: 'commit', 'rollback', 'insert', 'delete', 'update'.
Examples: --warning-total-commit='', --warning-delete='', --warning-total-rollback=''

=item B<--critical-*>

Threshold critical.
Can be: 'total-*', 'total-*', '*', The '*' can be: 'commit', 'rollback', 'insert', 'delete', 'update'.
Examples: --warning-total-commit='', --warning-delete='', --warning-total-rollback=''

=item B<--filter-database>

Filter database (can be a regexp).

=back

=cut
