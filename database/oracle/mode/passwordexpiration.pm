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

package database::oracle::mode::passwordexpiration;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use centreon::plugins::statefile;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold);

sub custom_status_output {
    my ($self, %options) = @_;
    
    my $msg = sprintf("[username: %s] [account status: %s] expired in : %s",
        $self->{result_values}->{username},
        $self->{result_values}->{account_status},
        $self->{result_values}->{expire_time}
    );
    return $msg;
}

sub custom_status_calc {
    my ($self, %options) = @_;
    
    $self->{result_values}->{account_status} = $options{new_datas}->{$self->{instance} . '_account_status'};
    $self->{result_values}->{username} = $options{new_datas}->{$self->{instance} . '_username'};
    $self->{result_values}->{expire} = $options{new_datas}->{$self->{instance} . '_expire'};
    $self->{result_values}->{expire_time} = $options{new_datas}->{$self->{instance} . '_expire_time'};
    return 0;
}


sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'users', type => 2, format_output => '%s user(s) detected', display_counter_problem => { label => 'users', min => 0 },
          group => [ { name => 'user', skipped_code => { -11 => 1 } } ] 
        }
    ];
    
    $self->{maps_counters}->{user} = [
        { label => 'status', threshold => 0, set => {
                key_values => [ { name => 'username' }, { name => 'account_status' }, { name => 'expire' }, { name => 'expire_time' } ],
                closure_custom_calc => $self->can('custom_status_calc'),
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold,
            }
        },
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $options{options}->add_options(arguments => {
        "warning-status:s"    => { name => 'warning_status', default => '' },
        "critical-status:s"   => { name => 'critical_status', default => '' },
        "timezone:s"          => { name => 'timezone' },
    });
    
    centreon::plugins::misc::mymodule_load(output => $self->{output}, module => 'DateTime',
                                           error_msg => "Cannot load module 'DateTime'.");
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->change_macros(macros => ['warning_status', 'critical_status']);
}

sub manage_selection {
    my ($self, %options) = @_;
    $options{sql}->connect();

    $self->{users}->{global} = { user => {} };
    
    my $query = q{
        SELECT username, account_status, ((expiry_date - date '1970-01-01')*24*60*60) 
        FROM dba_users 
        WHERE expiry_date is not null AND account_status NOT LIKE '%EXPIRED%'
    };
    $options{sql}->query(query => $query);

    my $tz = centreon::plugins::misc::set_timezone(name => $self->{option_results}->{timezone});
    my $i = 1;
    while ((my @row = $options{sql}->fetchrow_array())) {
        # can be: 1541985283,999999999999999999999999999996
        $row[2] =~ s/,/./;
        my @values = localtime($row[2]);
        my $dt = DateTime->new(
            year       => $values[5] + 1900,
            month      => $values[4] + 1,
            day        => $values[3],
            hour       => $values[2],
            minute     => $values[1],
            second     => $values[0],
            %$tz
        );
 
        my $expire = abs(time() - $dt->epoch);
        $self->{users}->{global}->{user}->{$i} = {
            account_status => $row[1],
            username => $row[0],
            expire => $expire,
            expire_time => centreon::plugins::misc::change_seconds(value => $expire) 
        };
        $i++;
    }

    $options{sql}->disconnect();
}

1;

__END__

=head1 MODE

Check user password expiration.

=over 8

=item B<--warning-status>

Set warning threshold for status (Default: '')
Can used special variables like: %{username}, %{account_status}, %{expire}

=item B<--critical-status>

Set critical threshold for status (Default: '').
Can used special variables like: %{username}, %{account_status}, %{expire}

=item B<--timezone>

Timezone of oracle server (If not set, we use current server execution timezone).

=back

=cut
