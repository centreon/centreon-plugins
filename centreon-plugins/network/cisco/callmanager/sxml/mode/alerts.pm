#
# Copyright 2020 Centreon (http://www.centreon.com/)
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

package network::cisco::callmanager::sxml::mode::alerts;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;
use centreon::plugins::statefile;
use DateTime;
use Digest::MD5 qw(md5_hex);

my $map_severity = {
    0 => 'emergency',
    1 => 'alert',
    2 => 'critical',
    3 => 'error',
    4 => 'warning',
    5 => 'notice',
    6 => 'informational',
    7 => 'debugging'
};

sub prefix_output_global {
    my ($self, %options) = @_;

    return 'Alerts ';
}

sub set_counters {
    my ($self, %options) = @_;

    $self->{maps_counters_type} = [
        { name => 'global', type => 0, cb_prefix_output => 'prefix_output_global' }
    ];

    $self->{maps_counters}->{global} = [
        { label => 'total', nlabel => 'alerts.total.count', set => {
                key_values => [ { name => 'total' } ],
                output_template => 'total: %d',
                perfdatas => [
                    { template => '%d', min => 0 }
                ]
            }
        }
    ];

    foreach (values %$map_severity) {
       push @{$self->{maps_counters}->{global}}, {
           label => 'severity-' . $_, nlabel => 'alerts.severity.' . $_ . '.count', set => {
                key_values => [ { name => $_ }, { name => 'total' } ],
                output_template => $_ . ': %d',
                perfdatas => [
                    { template => '%d', min => 0, max => 'total' }
                ]
            }
        };
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'filter-alert-name:s' => { name => 'filter_alert_name' },
        'display-alerts'      => { name => 'display_alerts' }
    });

    $self->{statefile_cache} = centreon::plugins::statefile->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    $self->{statefile_cache}->check_options(%options);
}

sub init_seekfile {
    my ($self, %options) = @_;

    $self->{seek_infos} = $self->{statefile_cache}->get(name => 'seek_infos');
    if (!defined($self->{seek_infos})) {
        $self->{seek_infos} = { last_timestamp => time(), files => {} };
    }    
}

sub get_list_files {
    my ($self, %options) = @_;

    my $list_files = [];
    my $current_timestamp = time();
    my $last_timestamp = $self->{seek_infos}->{last_timestamp} - 86400;

    # format: AlertLog_MM_DD_YYYY_hh_mm.csv
    for (; $last_timestamp <= ($current_timestamp + 86400); $last_timestamp += 86400) {
        my $dt = DateTime->from_epoch(epoch => $last_timestamp);
        push @$list_files, sprintf('/var/log/active/cm/log/amc/AlertLog/AlertLog_%02d_%02d_%d_00_0', $dt->month(), $dt->day(), $dt->year());
    }
    
    $self->{seek_infos}->{last_timestamp} = $current_timestamp;
    return $list_files;
}

sub get_file {
    my ($self, %options) = @_;

    if (defined($options{suffix})) {
        my $content = $options{custom}->get_one_file(
            filename => $options{filename} . $options{suffix}
        );
        if (defined($content)) {
            return ($options{suffix}, $content);
        }

        return undef;
    }

    # AlertLog file can finish by _00.csv or _01.csv
    foreach (('0.csv', '1.csv')) {
        my $content = $options{custom}->get_one_file(
            filename => $options{filename} . $_
        );
        if (defined($content)) {
            return ($_, $content);
        }
    }

    return undef;
}

sub manage_selection {
    my ($self, %options) = @_;

    $self->{global} = { total => 0 };
    foreach (values %$map_severity) {
        $self->{global}->{$_} = 0;
    }

    $self->{statefile_cache}->read(
        statefile => 'cisco_cucm_' . $self->{mode} . '_' . $options{custom}->get_hostname() . '_' .
            (defined($self->{option_results}->{filter_alert_name}) ? md5_hex($self->{option_results}->{filter_alert_name}) : md5_hex('all'))
    );

    $self->init_seekfile();
    my $list_files = $self->get_list_files();
    for (my $i = 0; defined($list_files->[$i]); $i++) {
        next if (defined($self->{seek_infos}->{files}->{ $list_files->[$i] }) &&
            defined($list_files->[$i + 1]) && defined($self->{seek_infos}->{files}->{ $list_files->[$i + 1] }));

        my ($suffix, $content) = $self->get_file(
            custom => $options{custom},
            filename => $list_files->[$i],
            suffix => defined($self->{seek_infos}->{files}->{ $list_files->[$i] }) ? $self->{seek_infos}->{files}->{ $list_files->[$i] }->{suffix} : undef,
        );
        next if (!defined($suffix));

        $self->{seek_infos}->{files}->{ $list_files->[$i] } = { line => 1 } 
            if (!defined($self->{seek_infos}->{files}->{ $list_files->[$i] }));
        $self->{seek_infos}->{files}->{ $list_files->[$i] }->{suffix} = $suffix;

        my $j = 0;
        foreach my $line (split /\n/, $content) {
            $j++;
            next if ($j <=  $self->{seek_infos}->{files}->{ $list_files->[$i] }->{line});

            # Time Stamp,Alert Type,Alert Name,Alert Message,Monitored Object Name,Severity,PollValue,Action,Node ID,Group ID 
            my @fields = split(/,/, $line);

            next if (defined($self->{option_results}->{filter_alert_name}) && $self->{option_results}->{filter_alert_name} ne '' 
                && $fields[2] !~ /$self->{option_results}->{filter_alert_name}/);

            $self->{global}->{ $map_severity->{ $fields[5] } }++;
            $self->{global}->{total}++;

            if (defined($self->{option_results}->{display_alerts})) {
                $self->{output}->output_add(
                    long_msg => sprintf(
                        'alert [name: %s] [severity: %s] [date: %s]: %s',
                        $fields[2],
                        $map_severity->{ $fields[5] },
                        scalar(localtime($fields[0] / 1000)),
                        $fields[3]
                    )
                );
            }
        }

        $self->{seek_infos}->{files}->{ $list_files->[$i] }->{line} = $j;
    }

    $self->{statefile_cache}->write(data => { seek_infos => $self->{seek_infos} });
}

1;

__END__

=head1 MODE

Check alerts.

=over 8

=item B<--filter-alert-name>

Filter alerts by name (Can use regexp).

=item B<--display-alerts>

Display alerts in verbose output.

=item B<--warning-*> B<--critical-*> 

Thresholds.
Can be: 'total',
'severity-informational', 'severity-error', 'severity-debugging', 'severity-critical', 
'severity-alert', 'severity-warning', 'severity-emergency', 'severity-notice'.

=back

=cut
