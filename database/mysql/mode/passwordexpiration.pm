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

package database::mysql::mode::passwordexpiration;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "[user: %s] [password updated: %s] [expired: %s] expire in: %s",
        $self->{result_values}->{user},
        scalar(localtime($self->{result_values}->{password_last_changed})),
        $self->{result_values}->{expire} eq 'never' ? $self->{result_values}->{expire} : $self->{result_values}->{expire} . ' days',
        centreon::plugins::misc::change_seconds(value => $self->{result_values}->{expire_time})
    );
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'users', type => 2, format_output => '%s user(s) detected', display_counter_problem => { label => 'users', min => 0 },
          group => [ { name => 'user', skipped_code => { -11 => 1 } } ] 
        }
    ];

    $self->{maps_counters}->{user} = [
        { label => 'status', type => 2, critical_default => '%{expire} ne "never" and %{expire_time} == 0', set => {
                key_values => [
                    { name => 'user' }, { name => 'expire' },
                    { name => 'expire_time' }, { name => 'password_last_changed' }
                ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
    });

    return $self;
}

sub get_database_timezone {
    my ($self, %options) = @_;

    $options{sql}->query(
        query => q{SELECT @@GLOBAL.time_zone, @@system_time_zone}
    );
    my @row = $options{sql}->fetchrow_array();
    my $timezone = $row[0]; 
    if ($row[0] eq 'SYSTEM') {
        $timezone = $row[1];
    }
    return $timezone;
}

sub get_expire_time {
    my ($self, %options) = @_;

    my $current_time = time();
    my $dt = DateTime->from_epoch(epoch => $options{epoch}, time_zone => $options{timezone});
    $dt->add(days => $options{days});
    my $expire_in = $dt->epoch() - time();
    $expire_in = 0 if ($expire_in < 0);
    return $expire_in;
}

sub get_password_mariadb {
    my ($self, %options) = @_;

    my $timezone = $self->get_database_timezone(sql => $options{sql});
    $options{sql}->query(
        query => q{show variables like 'default_password_lifetime'}
    );
    my ($name, $default_password_lifetime) = $options{sql}->fetchrow_array();

    my $query = q{
        SELECT Host, User,
            JSON_EXTRACT(Priv, '$.password_last_changed') as password_last_changed,
            JSON_EXTRACT(Priv, '$.password_lifetime') as password_lifetime 
        FROM mysql.global_priv
    };
    $options{sql}->query(query => $query);
    my $i = 1;
    while ((my @row = $options{sql}->fetchrow_array())) {
        my $expire = 'never';
        if ((!defined($row[3]) || $row[3] == -1) && $default_password_lifetime > 0) {
            $expire = $default_password_lifetime;
        } elsif (defined($row[3]) && $row[3] > 0) {
            $expire = $row[3];
        }
        my $expire_time = 0;
        if ($expire ne 'never') {
            $expire_time = $self->get_expire_time(
                epoch => $row[2],
                days => $expire,
                timezone => $timezone
            );
        }
        $self->{users}->{global}->{user}->{$i} = {
            user => $row[0] . '@' . $row[1],
            password_last_changed => $row[2],
            expire => $expire,
            expire_time => $expire_time
        };
        $i++;
    }
}

sub get_password_mysql {
    my ($self, %options) = @_;

    my $timezone = $self->get_database_timezone(sql => $options{sql});
    $options{sql}->query(
        query => q{show variables like 'default_password_lifetime'}
    );
    my ($name, $default_password_lifetime) = $options{sql}->fetchrow_array();

    my $query = q{
        SELECT User, Host, UNIX_TIMESTAMP(password_last_changed), password_lifetime
        FROM mysql.user 
    };
    $options{sql}->query(query => $query);
    my $i = 1;
    while ((my @row = $options{sql}->fetchrow_array())) {
        my $expire = 'never';
        if (!defined($row[3]) && $default_password_lifetime > 0) {
            $expire = $default_password_lifetime;
        } elsif (defined($row[3]) && $row[3] > 0) {
            $expire = $row[3];
        }
        my $expire_time = 0;
        if ($expire ne 'never') {
            $expire_time = $self->get_expire_time(
                epoch => $row[2],
                days => $expire,
                timezone => $timezone
            );
        }
        $self->{users}->{global}->{user}->{$i} = {
            user => $row[0] . '@' . $row[1],
            password_last_changed => $row[2],
            expire => $expire,
            expire_time => $expire_time
        };
        $i++;
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{users}->{global} = { user => {} };

    $options{sql}->connect();
    if ($options{sql}->is_mariadb() && $options{sql}->is_version_minimum(version => '10.4.3')) {
         $self->get_password_mariadb(sql => $options{sql});
    } elsif (!$options{sql}->is_mariadb() && $options{sql}->is_version_minimum(version => '5.7.4')) {
        $self->get_password_mysql(sql => $options{sql});
    } else {
        $self->{output}->add_option_msg(short_msg => 'unsupported password policy.');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check user password expiration.

=over 8

=item B<--warning-status>

Set warning threshold for status.
Can used special variables like: %{user}, %{expire}, %{expire_time}

=item B<--critical-status>

Set critical threshold for status (Default: '%{expire} ne "never" and %{expire_time} == 0').
Can used special variables like: %{user}, %{expire}, %{expire_time}

=back

=cut
