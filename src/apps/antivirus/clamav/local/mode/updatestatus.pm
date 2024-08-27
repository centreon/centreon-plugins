#
# Copyright 2024 Centreon (http://www.centreon.com/)
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

package apps::antivirus::clamav::local::mode::updatestatus;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::misc;
use Net::DNS;
use DateTime;
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);

sub custom_engine_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "clamav engine version '%s/%s'", 
        $self->{result_values}->{current_engine_version},
        $self->{result_values}->{last_engine_version}
    );
}

sub custom_maindb_status_output {
    my ($self, %options) = @_;
    
    return sprintf(
        "main.cvd version '%s/%s', last update %s", 
        $self->{result_values}->{current_maindb_version}, 
        $self->{result_values}->{last_maindb_version}, 
        centreon::plugins::misc::change_seconds(
            value => $self->{result_values}->{current_maindb_timediff}
        )
    );
}

sub custom_dailydb_status_output {
    my ($self, %options) = @_;

    return sprintf(
        "daily.cvd version '%s/%s', last update %s",
        $self->{result_values}->{current_dailydb_version},
        $self->{result_values}->{last_dailydb_version},
        centreon::plugins::misc::change_seconds(
            value => $self->{result_values}->{current_dailydb_timediff}
        )
    );
}

sub set_counters {
    my ($self, %options) = @_;
    
    $self->{maps_counters_type} = [
        { name => 'update', type => 0, message_separator => ' - ' }
    ];
    
    $self->{maps_counters}->{update} = [
        { label => 'engine-status', type => 2, critical_default => '%{last_engine_version} ne %{current_engine_version}', set => {
                key_values => [ { name => 'last_engine_version' }, { name => 'current_engine_version' } ],
                closure_custom_output => $self->can('custom_engine_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'maindb-status', type => 2, critical_default => '%{last_maindb_version} ne %{current_maindb_version}', set => {
                key_values => [ { name => 'last_maindb_version' }, { name => 'current_maindb_version' }, { name => 'current_maindb_timediff' } ],
                closure_custom_output => $self->can('custom_maindb_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        },
        { label => 'dailydb-status', type => 2, critical_default => '%{last_dailydb_version} ne %{current_dailydb_version} || %{current_dailydb_timediff} > 432000', set => {
                key_values => [ { name => 'last_dailydb_version' }, { name => 'current_dailydb_version' }, { name => 'current_dailydb_timediff' } ],
                closure_custom_output => $self->can('custom_dailydb_status_output'),
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
        'nameservers:s@'    => { name => 'nameservers' },
        'maindb-file:s'     => { name => 'maindb_file', default => '/var/lib/clamav/main.cvd' },
        'dailydb-file:s'    => { name => 'dailydb_file', default => '/var/lib/clamav/daily.cvd' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{option_results}->{maindb_file} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{maindb_file});
    $self->{option_results}->{dailydb_file} = centreon::plugins::misc::sanitize_command_param(value => $self->{option_results}->{dailydb_file});
}

sub get_clamav_last_update {
    my ($self, %options) = @_;

    #0.99.2:57:23114:1487851834:1:63:45614:290
    # field 2 = main.cvd version number
    # field 3 = daily.cvd version number
    my %dns_options = ();
    if (defined($self->{option_results}->{nameservers})) {
        foreach my $dns (@{$self->{option_results}->{nameservers}}) {
            next if ($dns !~ /[a-zA-Z0-9]/);
            $dns_options{nameservers} = [] if (!defined($dns_options{nameservers}));
            push @{$dns_options{nameservers}}, $dns;
        }
    }
    my $handle = Net::DNS::Resolver->new(%dns_options);
    my $txt_query = $handle->query("current.cvd.clamav.net", "TXT");
    if (!$txt_query) {
        $self->{output}->add_option_msg(short_msg => "Unable to get TXT Record : " . $handle->errorstring . ".");
        $self->{output}->option_exit();
    }

    my @fields = split /:/, ($txt_query->answer)[0]->txtdata;
    ($self->{last_engine_version}, $self->{last_maindb_version}, $self->{last_dailydb_version}) = 
        ($fields[0], $fields[1], $fields[2]);
}

sub get_clamav_current_signature_info {
    my ($self, %options) = @_;

    if ($options{content} !~ /====\s+$options{label}.*?Build\s+time:\s+(.*?)\n.*?Version:\s+(\d+)/msi) {
        return ;
    }

    $self->{'current_' . $options{label} . 'db_version'} = $2;
    #13 Jun 2016 09:53 -0400
    my $time = $1;
    if ($time =~ /^\s*(\d+)\s+(\S+)\s+(\d+)\s+(\d+):(\d+)\s+(\S+)/) {
        my %months = ("Jan" => 1, "Feb" => 2, "Mar" => 3, "Apr" => 4, "May" => 5, "Jun" => 6, "Jul" => 7, "Aug" => 8, "Sep" => 9, "Oct" => 10, "Nov" => 11, "Dec" => 12);
        my $dt = DateTime->new(
            year       => $3,
            month      => $months{$2},
            day        => $1,
            hour       => $4,
            minute     => $5,
            second     => 0,
            time_zone  => $6,
        );
        $self->{'current_' . $options{label} . 'db_timediff'}  = time() - $dt->epoch();
    }
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->get_clamav_last_update();

    my ($stdout) = $options{custom}->execute_command(
        command => 'echo "==== CLAMD ===" ; clamd -V ; echo "==== DAILY ===="; sigtool --info ' . $self->{option_results}->{dailydb_file} . '; echo "==== MAIN ====" ; sigtool --info ' . $self->{option_results}->{maindb_file}
    );

    #==== CLAMD ===
    #ClamAV 0.99.2/21723/Mon Jun 13 14:53:00 2016
    #==== DAILY ====
    #File: /var/lib/clamav/daily.cvd
    #Build time: 13 Jun 2016 09:53 -0400
    #Version: 21723
    #Signatures: 276682
    #Functionality level: 63
    #Builder: neo
    #MD5: 280928f25d175359e6e6a0270d9d4fb2
    #Digital signature: yLfcgb9dbgKO2rWpXGa238252jqH7VDsAjnqQsHc+9cbIwiM9wnz3fqyl33G15S4YsMbRR6CYbSTxccKXBJvvxRhgZQJmpCYiThslUKBPo5QhIFcI1QBMfoHKCpf8riB2/xAgI401UkZVJip+6eWFpUJ9aeaFai+Mvinif5BRzi
    #LibClamAV Warning: **************************************************
    #LibClamAV Warning: ***  The virus database is older than 7 days!  ***
    #LibClamAV Warning: ***   Please update it as soon as possible.    ***
    #LibClamAV Warning: **************************************************
    #Verification OK.
    #==== MAIN ====
    #File: /var/lib/clamav/main.cvd
    #Build time: 16 Mar 2016 23:17 +0000
    #Version: 57
    #Signatures: 4218790
    #Functionality level: 60
    #Builder: amishhammer
    #MD5: 06386f34a16ebeea2733ab037f0536be
    #Digital signature: AIzk/LYbX8K9OEbR5GMyJ6LWTqSu9ffa5bONcA0FN3+onMlZ2BMRzuyvVURBvAZvOaGPdtMBcgDJSl7fGxDfcxRWhIrQ98f8FPdAQaFPgWu3EX46ufw+IRZnM4irKKYuh1GdCIbsGs6jejWo9iNErsbDqkFSobVBkUJYxBgvqfd
    #Verification OK.

    $self->get_clamav_current_signature_info(label => 'daily', content => $stdout);
    $self->get_clamav_current_signature_info(label => 'main', content => $stdout);    
    if ($stdout =~ /==== CLAMD.*?ClamAV (.*?)\//msi) {
        $self->{current_engine_version} = $1;
    }

    $self->{update} = { 
        last_engine_version => $self->{last_engine_version}, last_maindb_version => $self->{last_maindb_version}, last_dailydb_version => $self->{last_dailydb_version},
        current_engine_version => $self->{current_engine_version},
        current_maindb_version => $self->{current_maindb_version}, current_maindb_timediff => $self->{current_maindb_timediff},
        current_dailydb_version => $self->{current_dailydb_version}, current_dailydb_timediff => $self->{current_dailydb_timediff},
    };
}

1;

__END__

=head1 MODE

Check antivirus update status.

Command used: 'clamd -V ; sigtool --info %(dailydb-file) ; sigtool --info %(maindb-file)'

=over 8

=item B<--nameservers>

Set nameserver to query (can be multiple).
The system configuration is used by default.

=item B<--maindb-file>

Antivirus main.cvd file (default: '/var/lib/clamav/main.cvd').

=item B<--dailydb-file>

Antivirus daily.cvd file (default: '/var/lib/clamav/daily.cvd').

=item B<--warning-engine-status>

Define the conditions to match for the status to be WARNING (default: '')
You can use the following variables: %{last_engine_version}, %{current_engine_version}

=item B<--critical-engine-status>

Define the conditions to match for the status to be CRITICAL (default: '%{last_engine_version} ne %{current_engine_version}').
You can use the following variables: %{last_engine_version}, %{current_engine_version}

=item B<--warning-maindb-status>

Define the conditions to match for the status to be WARNING (default: '')
You can use the following variables: %{last_maindb_version}, %{current_maindb_version}, %{current_maindb_timediff}

=item B<--critical-maindb-status>

Define the conditions to match for the status to be CRITICAL (default: '%{last_maindb_version} ne %{current_maindb_version}').
You can use the following variables: %{last_maindb_version}, %{current_maindb_version}, %{current_maindb_timediff}

=item B<--warning-dailydb-status>

Define the conditions to match for the status to be WARNING (default: '')
You can use the following variables: %{last_dailydb_version}, %{current_dailydb_version}, %{current_dailydb_timediff}

=item B<--critical-dailydb-status>

Define the conditions to match for the status to be CRITICAL (default: '%{last_dailydb_version} ne %{current_dailydb_version} || %{current_dailydb_timediff} > 432000').
You can use the following variables: %{last_dailydb_version}, %{current_dailydb_version}, %{current_dailydb_timediff}

=back

=cut
