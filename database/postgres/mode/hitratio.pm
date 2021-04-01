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

package database::postgres::mode::hitratio;

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
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "lookback"                => { name => 'lookback', },
                                  "exclude:s"               => { name => 'exclude', },
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
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }

    $self->{statefile_cache}->check_options(%options);
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();
    
    $self->{sql}->query(query => q{
SELECT sd.blks_hit, sd.blks_read, d.datname
FROM pg_stat_database sd, pg_database d
WHERE d.oid=sd.datid
    });

    $self->{statefile_cache}->read(statefile => 'postgres_' . $self->{mode} . '_' . $self->{sql}->get_unique_id4save());
    my $old_timestamp = $self->{statefile_cache}->get(name => 'last_timestamp');
    
    my $database_check = 0;
    my $new_datas = {};
    $new_datas->{last_timestamp} = time();
    my $result = $self->{sql}->fetchall_arrayref();
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => "All databases hitratio are ok.");

    
    foreach my $row (@{$result}) {
        $new_datas->{$$row[2] . '_blks_hit'} = $$row[0];
        $new_datas->{$$row[2] . '_blks_read'} = $$row[1];
        
        if (defined($self->{option_results}->{exclude}) && $$row[2] !~ /$self->{option_results}->{exclude}/) {
            $self->{output}->output_add(long_msg => "Skipping database '" . $$row[2] . '"');
            next;
        }

        my $old_blks_hit = $self->{statefile_cache}->get(name => $$row[2] . '_blks_hit');
        my $old_blks_read = $self->{statefile_cache}->get(name => $$row[2] . '_blks_read');
        
        next if (!defined($old_blks_hit) || !defined($old_blks_read));
        $old_blks_hit = 0 if ($$row[0] <= $old_blks_hit);
        $old_blks_read = 0 if ($$row[1] <= $old_blks_read);
        
        $database_check++;
        my %prcts = ();
        my $total_read_requests = $new_datas->{$$row[2] . '_blks_hit'} - $old_blks_hit;
        my $total_read_disk = $new_datas->{$$row[2] . '_blks_read'} - $old_blks_read;
        $prcts{hitratio_now} = (($total_read_requests + $total_read_disk) == 0) ? 100 : $total_read_requests * 100 / ($total_read_requests + $total_read_disk);
        $prcts{hitratio} = (($new_datas->{$$row[2] . '_blks_hit'} + + $new_datas->{$$row[2] . '_blks_read'}) == 0) ? 100 : $new_datas->{$$row[2] . '_blks_hit'} * 100 / ($new_datas->{$$row[2] . '_blks_hit'} + $new_datas->{$$row[2] . '_blks_read'});
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $prcts{'hitratio' . ((defined($self->{option_results}->{lookback})) ? '' : '_now' )}, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("Database '%s' hitratio at %.2f%%", 
                                                    $$row[2], $prcts{'hitratio' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')})
                                    );
        
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1)) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Database '%s' hitratio at %.2f%%", 
                                                    $$row[2], $prcts{'hitratio' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')})
                                        );
        }
        $self->{output}->perfdata_add(label => $$row[2] . '_hitratio' . ((defined($self->{option_results}->{lookback})) ? '' : '_now'), unit => '%',
                                      value => sprintf("%.2f", $prcts{'hitratio' . ((defined($self->{option_results}->{lookback})) ? '' : '_now')}),
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0, max => 100);
        $self->{output}->perfdata_add(label => $$row[2] . '_hitratio' . ((defined($self->{option_results}->{lookback})) ? '_now' : ''), unit => '%',
                                      value => sprintf("%.2f", $prcts{'hitratio' . ((defined($self->{option_results}->{lookback})) ? '_now' : '')}),
                                      min => 0, max => 100);
    }
    
    $self->{statefile_cache}->write(data => $new_datas); 
    if (!defined($old_timestamp)) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => "Buffer creation...");
    }
    if (defined($old_timestamp) && $database_check == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => 'No database checked. (permission or a wrong exclude filter)');
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check hitratio (in buffer cache) for databases.

=over 8

=item B<--warning>

Threshold warning.

=item B<--critical>

Threshold critical.

=item B<--lookback>

Threshold isn't on the percent calculated from the difference ('xxx_hitratio_now').

=item B<--exclude>

Filter databases.

=back

=cut
