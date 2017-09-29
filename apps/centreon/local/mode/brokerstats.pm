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

package apps::centreon::local::mode::brokerstats;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use JSON;
use File::Basename;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                 "broker-stats-file:s@"     => { name => 'broker_stats_file' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
 
    if (!defined($self->{option_results}->{broker_stats_file}) || scalar(@{$self->{option_results}->{broker_stats_file}}) == 0) {
        $self->{output}->add_option_msg(short_msg => "Please set broker-stats-file option.");
        $self->{output}->option_exit();
    }
}

sub read_stats {
    my ($self, %options) = @_;
    
    my $content = do {
        local $/ = undef;
        if (!open my $fh, "<", $options{file}) {
            $self->{output}->add_option_msg(short_msg => "Could not open file $options{file} : $!");
            $self->{output}->option_exit();
        }
        <$fh>;
    };
    eval {
        $self->{json_stats} = decode_json($content);
    };
}

sub run {
    my ($self, %options) = @_;
    
    $self->{output}->output_add(severity => 'OK',
                                short_msg => 'Broker statistics are ok');
    
    my $total_size = 0;
    foreach my $config (@{$self->{option_results}->{broker_stats_file}}) {
        $self->{output}->output_add(long_msg => "Checking stats file '$config'");
        
        eval {
            $self->read_stats(file => $config);
        };
        if ($@) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => "'$config': cannot parse file");
            next;
        }

        foreach my $entry (sort keys $self->{json_stats}) {
            if ($entry =~ m/^endpoint/) {
                my $endpoint = $entry;
                $endpoint =~ s/endpoint //;
                if (!defined($self->{json_stats}->{$entry}->{status})) {
                    $self->{output}->output_add(long_msg => "Checking '$endpoint' input endpoint :");
                    $self->{output}->output_add(long_msg => "state: $self->{json_stats}->{$entry}->{state}");
                } else {
                    $self->{output}->output_add(long_msg => "Checking '$endpoint' output endpoint :");
                    $self->{output}->output_add(long_msg => "state: $self->{json_stats}->{$entry}->{state}");
                    $self->{output}->output_add(long_msg => "status: $self->{json_stats}->{$entry}->{status}");
                    $self->{output}->output_add(long_msg => "event processing speed: $self->{json_stats}->{$entry}->{event_processing_speed}");
                    $self->{output}->perfdata_add(label => $endpoint."_speed", unit => "events/s", 
                                value => $self->{json_stats}->{$entry}->{event_processing_speed},
                                min => 0);
                    $self->{output}->output_add(long_msg => "queued events: $self->{json_stats}->{$entry}->{queued_events}");
                    $self->{output}->perfdata_add(label => $endpoint."_queued_events", unit => "events",
                                value => $self->{json_stats}->{$entry}->{queued_events},
                                min => 0);
                    if (defined($self->{json_stats}->{$entry}->{bbdo_unacknowledged_events})) {
                        $self->{output}->output_add(long_msg => "unacknowledged events: $self->{json_stats}->{$entry}->{bbdo_unacknowledged_events}");
                        $self->{output}->perfdata_add(label => $endpoint."_uack_events", unit => "events",
                                    value => $self->{json_stats}->{$entry}->{bbdo_unacknowledged_events},
                                    min => 0);
                    }
                    $self->{output}->output_add(long_msg => "queue file enabled: $self->{json_stats}->{$entry}->{queue_file_enabled}");

                    if ($self->{json_stats}->{$entry}->{state} ne "connected") {
                        $self->{output}->output_add(severity => 'WARNING',
                                                    short_msg => "Some endpoints are not connected");
                    }

                    if ($self->{json_stats}->{$entry}->{queue_file_enabled} eq "yes") {
                        $self->{output}->output_add(severity => 'CRITICAL',
                                                    short_msg => "Some endpoints are queueing data");
                        $self->{output}->output_add(long_msg => "queue file path: $self->{json_stats}->{$entry}->{queue_file_path}");
                    }
                }        
            }
        }
    }

    $self->{output}->display();
    $self->{output}->exit();
    
}

1;

__END__

=head1 MODE

Check Centreon Broker statistics files.

=over 8

=item B<--broker-stats-file>

Specify the centreon-broker json stats file (Required). Can be multiple.

=back

=cut
