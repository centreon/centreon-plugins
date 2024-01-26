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

package apps::protocols::whois::mode::domain;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use DateTime;
use Time::HiRes qw(gettimeofday tv_interval);
use centreon::plugins::templates::catalog_functions qw(catalog_status_threshold_ng);
use centreon::plugins::misc;
use POSIX;

my $unitdiv = { s => 1, w => 604800, d => 86400, h => 3600, m => 60 };
my $unitdiv_long = { s => 'seconds', w => 'weeks', d => 'days', h => 'hours', m => 'minutes' };

sub custom_expires_perfdata {
    my ($self, %options) = @_;

    $self->{output}->perfdata_add(
        nlabel => $self->{nlabel} . '.' . $unitdiv_long->{ $self->{instance_mode}->{option_results}->{unit} },
        unit => $self->{instance_mode}->{option_results}->{unit},
        instances => $self->{result_values}->{domain},
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning-' . $self->{thlabel}),
        critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical-' . $self->{thlabel}),
        min => 0
    );
}

sub custom_expires_threshold {
    my ($self, %options) = @_;

    return $self->{perfdata}->threshold_check(
        value => floor($self->{result_values}->{expires_seconds} / $unitdiv->{ $self->{instance_mode}->{option_results}->{unit} }),
        threshold => [
            { label => 'critical-' . $self->{thlabel}, exit_litteral => 'critical' },
            { label => 'warning-'. $self->{thlabel}, exit_litteral => 'warning' },
            { label => 'unknown-'. $self->{thlabel}, exit_litteral => 'unknown' }
        ]
    );
}

sub custom_status_output {
    my ($self, %options) = @_;

    return 'status: ' . $self->{result_values}->{status};
}

sub domain_long_output {
    my ($self, %options) = @_;

    return "checking domain '" . $options{instance} . "'";
}

sub prefix_domain_output {
    my ($self, %options) = @_;

    return "Domain '" . $options{instance} . "' ";
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'domains', type => 3, cb_prefix_output => 'prefix_domain_output', cb_long_output => 'domain_long_output', indent_long_output => '    ', message_multiple => 'All domains are ok',
            group => [
                { name => 'response', type => 0, skipped_code => { -10 => 1 } },
                { name => 'status', type => 0, skipped_code => { -10 => 1 } },
                { name => 'expires', type => 0, cb_prefix_output => 'prefix_fb_output', skipped_code => { -10 => 1 } }
            ]
        }
    ];

    $self->{maps_counters}->{response} = [
        { label => 'response-time', nlabel => 'whois.response.time.milliseconds', set => {
                key_values => [ { name => 'time' } ],
                output_template => 'whois response time: %d ms',
                perfdatas => [
                    { template => '%d', unit => 'ms', min => 0, label_extra_instance => 1 }
                ]
            }
        }
    ];

    $self->{maps_counters}->{status} = [
        {
            label => 'status',
            type => 2,
            unknown_default => '%{status} =~ /checkError/i',
            set => {
                key_values => [ { name => 'status' }, { name => 'domain' } ],
                closure_custom_output => $self->can('custom_status_output'),
                closure_custom_perfdata => sub { return 0; },
                closure_custom_threshold_check => \&catalog_status_threshold_ng
            }
        }
    ];

    $self->{maps_counters}->{expires} = [
        { label => 'expires', nlabel => 'domain.expires', set => {
                key_values      => [ { name => 'expires_seconds' }, { name => 'expires_human' }, { name => 'domain' } ],
                output_template => 'expires in %s',
                output_use => 'expires_human',
                closure_custom_perfdata => $self->can('custom_expires_perfdata'),
                closure_custom_threshold_check => $self->can('custom_expires_threshold')
            }
        }
    ];
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'domain:s@'            => { name => 'domain' },
        'whois-server:s'       => { name => 'whois_server' },
        'expiration-date:s'    => { name => 'expiration_date' },
        'expiration-date-tz:s' => { name => 'expiration_date_tz' },
        'unit:s'               => { name => 'unit', default => 's' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if ($self->{option_results}->{unit} eq '' || !defined($unitdiv->{$self->{option_results}->{unit}})) {
        $self->{option_results}->{unit} = 's';
    }

    $self->{doms} = [];
    if (defined($self->{option_results}->{domain})) {
        foreach my $domain (@{$self->{option_results}->{domain}}) {
            push @{$self->{doms}}, $domain if ($domain ne '');
        }
    }
    if (scalar(@{$self->{doms}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'Need to specify --domain option.');
        $self->{output}->option_exit();
    }
}

sub get_status {
    my ($self, %options) = @_;

    $self->{domains}->{ $options{domain} }->{status}->{status} = 'noStatus';

    my @errors = (
        'Unable to connect to remote host',
        'Invalid input',
        'quota exceeded',
        'Unable to connect',
        "Can't access",
        'Network is unreachable',
        'Error for',
        '^query_status: (?:250|520)'
    );
    foreach (@errors) {
        if ($options{output} =~ /$_/msi) {
            $self->{domains}->{ $options{domain} }->{status}->{status} = 'checkError';
            return ;
        }
    }

    my @unregistered = (
        'NOT FOUND',
        #% nothing found
        'nothing found',
        '^No Found',
        'No Data Found',
        #No matching
        #No match!!
        #No match for
        'No match', 
        'no entries found',
        '^Status:\s+NOT\s+AVAILABLE',
        '^Status:\s+AVAILABLE',
        '^Status:\s+free',
        '^NO OBJECT FOUND',
        'Object_Not_Found',
        '^Domain\s+Status:\s+No\s+Object\s+Found',
        'query_status: 220 Available',
        'The domain has not been registered',
        'no\s+se\s+encuentra\s+registrado',
        #xxxxx is free
        '^' . $options{domain} . '\s+is\s+free$'
    );
    foreach (@unregistered) {
        if ($options{output} =~ /$_/msi) {
            $self->{domains}->{ $options{domain} }->{status}->{status} = 'notRegistered';
            return ;
        }
    }

    my @statusre = (
        '^status:\s*(.+?)\s*$',
        #[Status]                        Active
        '\[Status\]\s+(.+?)\s*$',
        #status.............: Registered
        '^status\.+?:\s*([^\s]+?)(\s+|$)',
        #Domain status.......: Active
        '^domain\s+status\.+:\s*([^\s]+?)(\s+|$)',
        #state:            active
        '^state:\s*([^\s]+?)',
        #query_status: 200 Active
        '^query_status:\s+200\s+(.+?)\s*$',
        #EPP Status:                   clientTransferProhibited, clientUpdateProhibited, clientDeleteProhibited
        '^EPP Status:\s+(.*?)\s+$',
    );
    my @statuses = ();
    foreach (@statusre) {
        push @statuses, $1 while ($options{output} =~ /$_/msig);
    }

    #   Domain Status: clientUpdateProhibited,clientTransferProhibited,clientDeleteProhibited
    #Domain Status: clientTransferProhibited https://icann.org/epp#clientTransferProhibited
    #Domain Status:		CLIENT UPDATE PROHIBITED
    #Domain Status: clientDeleteProhibited
    while ($options{output} =~ /Domain Status:\s+(.*?)$/msig) {
        my @values = split(/\s+/, $1);
        my $value = '';
        my $append = '';
        foreach (@values) {
            next if (/https:\/\//);
            $value .= $append . $_;
            $append = ' ';
        }
        push @statuses, $value;
    }

    $self->{domains}->{ $options{domain} }->{status}->{status} = join(',', @statuses) if (scalar(@statuses) > 0);
}

sub get_expiration_date {
    my ($self, %options) = @_;

    my %months = (
        jan => 1, feb => 2, mar => 3,
        apr => 4, may => 5, jun => 6,
        jul => 7, aug => 8, sep => 9,
        oct => 10, nov => 11, dec => 12
    );
    my ($year, $month, $day, $tz);
    my ($hour, $min, $sec) = (0, 0, 0);

    if (defined($self->{option_results}->{expiration_date}) && $self->{option_results}->{expiration_date} ne '' &&
        $self->{option_results}->{expiration_date} =~ /^(\d{4})-(\d{2})-(\d{2})/) {
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*(?:Expiry\s+Date|Registry\s+Expiry\s+Date|Registrar\s+Registration\s+Expiration\s+Date):\s+(\d+)-(\d+)-(\d+)T(\d+):(\d+):(\d+)/msi) {
        #Registrar Registration Expiration Date: 2022-09-20T22:00:00
        #Registry Expiry Date: 2023-04-18T23:59:59Z
        #Registry Expiry Date: 2023-03-24T00:00:00.000Z
        #Expiry Date: 2022-06-20T14:54:52Z
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    }elsif ($options{output} =~ /^\s*Record expires on (\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+) \((.*?)\)/msi) {
        #Record expires on 2022-10-31 12:47:54 (UTC+8)
        ($year, $month, $day, $hour, $min, $sec, $tz) = ($1, $2, $3, $4, $5, $6, $7);
    } elsif ($options{output} =~ /^\s*(?:Expiry\s+date|Exp\s+date):\s*(\d+)[-\s]([a-zA-Z]+)[-\s](\d+)/msi) {
        #Exp date:                   16 Jul 2022
        #Expiry date:  02-Jul-2030
        ($year, $month, $day) = ($3, $months{ lc($2) }, $1);
    } elsif ($options{output} =~ /^\s*Expiry\s+date:\s*(\d+)-(\d+)-(\d+)/msi) {
         #Expiry Date: 31-03-2023
        ($year, $month, $day) = ($3, $2, $1);
    } elsif ($options{output} =~ /^\s*(?:Expire|Expiration)\s+Date:\s*(\d+)-(\d+)-(\d+)/msi) {
        #Expiration Date:   2023-05-11
        #Expire Date:        2022-08-02
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*Expiration\s+Time:\s*(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #Expiration Time: 2023-03-17 12:48:36
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    } elsif ($options{output} =~ /^\s*\[Expires\s+on\]\s+(\d+)\/(\d+)\/(\d+)/msi) {
        #[Expires on]                    2023/05/31
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*expire:\s+(\d+)\.(\d+).(\d+)/msi) {
        #expire:       22.07.2022
        ($year, $month, $day) = ($3, $2, $1);
    } elsif ($options{output} =~ /^\s*expires:\s+(\d+)-(\d+)-(\d+)/msi) {
        #expires:          2022-10-20
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*expire:\s+(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #expire:		2022-11-01 00:00:00
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    } elsif ($options{output} =~ /^\s*expires\.+:\s+(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #expires............: 4.7.2023 10:15:55
        ($year, $month, $day, $hour, $min, $sec) = ($3, $2, $1, $4, $5, $6);
    } elsif ($options{output} =~ /^\s*Expiration\s+date:\s*(\d+)-(\d+)-(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #Expiration date: 2022-11-20 14:48:02 CLST
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    } elsif ($options{output} =~ /^\s*Expiration\s+date:\s*(\d+)-([a-zA-Z]+)-(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #Expiration Date:		03-Jan-2023 00:00:00
        ($year, $month, $day, $hour, $min, $sec) = ($3, $months{ lc($2) }, $1, $4, $5, $6);
    }elsif ($options{output} =~ /^\s*renewal\s+date:\s*(\d+)\.(\d+)\.(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #renewal date:          2022.09.18 14:00:00
        ($year, $month, $day, $hour, $min, $sec) = ($1, $2, $3, $4, $5, $6);
    } elsif ($options{output} =~ /^\s*free-date:\s*(\d+)-(\d+)-(\d+)/msi) {
        #free-date:     2023-04-05
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*Valid Until:\s*(\d+)-(\d+)-(\d+)/msi) {
        #Valid Until:                  2022-07-24
        ($year, $month, $day) = ($1, $2, $3);
    } elsif ($options{output} =~ /^\s*Expiration\s+Date:\s*(\d+)\/(\d+)\/(\d+)\s+(\d+):(\d+):(\d+)/msi) {
        #Expiration Date: 28/02/2023 23:59:00
        ($year, $month, $day, $hour, $min, $sec) = ($3, $2, $1, $4, $5, $6);
    }

    return if (!defined($year)); # noExpirationDate

    $tz = defined($tz) ? $tz : 'UTC';
    if (defined($self->{option_results}->{expiration_date_tz}) && $self->{option_results}->{expiration_date_tz} ne '') {
        $tz = $self->{option_results}->{expiration_date_tz};
    }
    $tz = centreon::plugins::misc::set_timezone(name => $tz);
    my $dt = DateTime->new(
        year       => $year,
        month      => $month,
        day        => $day,
        hour       => $hour,
        minute     => $min,
        second     => $sec,
        %$tz
    );

    $self->{domains}->{ $options{domain} }->{expires}->{expires_seconds} = $dt->epoch() - time();
    $self->{domains}->{ $options{domain} }->{expires}->{expires_human} = centreon::plugins::misc::change_seconds(
        value => $self->{domains}->{ $options{domain} }->{expires}->{expires_seconds}
    );
}

sub check_domain {
    my ($self, %options) = @_;

    my $tld;
    $tld = $1 if ($options{domain} =~ /\.(.*)$/);
    if ($tld eq 'ph') {
        $self->{output}->add_option_msg(short_msg => '.ph domain lookups are not available to the public');
        $self->{output}->option_exit();
    }
    if ($tld =~ /^(?:es|gr|ph|pk|py|vn)$/) {
        $self->{output}->add_option_msg(short_msg => '.' . $tld . ' tld domain lookups are not available at this time');
        $self->{output}->option_exit();
    }

    my $whois_server = defined($self->{option_results}->{whois_server}) && $self->{option_results}->{whois_server} ne '' ? $self->{option_results}->{whois_server} : '';
    if ($whois_server eq '') {
        $whois_server = "whois.nic.$tld" if ($tld =~ /^(?:asia|bo|fm|me|ms|nf|tel)$/);
    }

    my $command_options = ($whois_server ne '' ? "-h $whois_server" : '') . ' ' . $options{domain};

    my $timing0 = [gettimeofday];
    my ($output) = $options{custom}->execute_command(
        command => 'whois',
        command_options => $command_options,
        no_quit => 1
    );

    $self->{domains}->{ $options{domain} } = {
        response => { time => tv_interval($timing0, [gettimeofday]) * 1000 },
        status => { domain => $options{domain} },
        expires => { domain => $options{domain} }
    };

    $self->get_status(domain => $options{domain}, output => $output);
    $self->get_expiration_date(domain => $options{domain}, output => $output)
        if ($self->{domains}->{ $options{domain} }->{status}->{status} ne 'notRegistered');
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{domains} = {};
    foreach my $domain (@{$self->{doms}}) {
        $self->check_domain(domain => $domain, custom => $options{custom});
    }
}

1;

__END__

=head1 MODE

Check domain status and expiration. 

Command used: whois [-h $whois_server] $domain

=over 8

=item B<--domain>

Domain to check.

=item B<--whois-server>

Query this specific whois server host.

=item B<--expiration-date>

Set your domain expiration date manually (Format: YYYY-MM-DD).

=item B<--expiration-date-tz>

Set your domain expiration date timezone (default: 'UTC').

=item B<--unknown-status>

Define the conditions to match for the status to be CRITICAL (default: '%{status} =~ /checkError/i').
You can use the following variables: %{status}, %{domain}

=item B<--warning-status>

Define the conditions to match for the status to be WARNING.
You can use the following variables: %{status}, %{domain}

=item B<--critical-status>

Define the conditions to match for the status to be CRITICAL.
You can use the following variables: %{status}, %{domain}

=item B<--unit>

Select the time unit for the expiration thresholds. May be 's' for seconds, 'm' for minutes, 'h' for hours, 'd' for days, 'w' for weeks. Default is seconds.

=item B<--warning-*> B<--critical-*>

Thresholds.
Can be: 'response-time', 'expires'.

=back

=cut
