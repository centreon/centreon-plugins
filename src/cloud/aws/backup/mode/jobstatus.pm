
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
package cloud::aws::backup::mode::jobstatus;

use base qw(cloud::aws::custom::mode);

use strict;
use warnings;

sub get_metrics_mapping {
    my ($self, %options) = @_;
    my $metrics_mapping = {
        extra_params => {
            message_multiple => 'All backup jobs are OK.'
        },
        metrics => {
            'NumberOfBackupJobsCompleted' => {
                'output'    => 'Number of backup jobs completed',
                'label'     => 'number-backup-jobs-completed',
                'nlabel'    => {
                    'absolute'      => 'backup.jobs.completed.count',
                },
                'unit'      => '',
                'min'       => 0
            },
            'NumberOfBackupJobsFailed' => {
                'output'    => 'Number of backup jobs failed',
                'label'     => 'number-backup-jobs-failed',
                'nlabel'    => {
                    'absolute'      => 'backup.jobs.failed.count',
                },
                'unit'      => '',
                'min'       => 0
            },
            'NumberOfBackupJobsExpired' => {
                'output'    => 'Number of backup jobs expired',
                'label'     => 'number-backup-jobs-expired',
                'nlabel'    => {
                    'absolute'      => 'backup.jobs.expired.count',
                },
                'unit'      => '',
                'min'       => 0
            },
            'NumberOfCopyJobsCompleted' => {
                'output'    => 'Number of copy jobs completed',
                'label'     => 'number-copy-jobs-completed',
                'nlabel'    => {
                    'absolute'      => 'copy.jobs.completed.count',
                },
                'unit'      => '',
                'min'       => 0
            },
            'NumberOfCopyJobsFailed' => {
                'output'    => 'Number of copy jobs failed',
                'label'     => 'number-copy-jobs-failed',
                'nlabel'    => {
                    'absolute'      => 'copy.jobs.failed.count',
                },
                'unit'      => '',
                'min'       => 0                
            },
            'NumberOfRecoveryPointsExpired' => {
                'output'    => 'Number of recovery jobs expired',
                'label'     => 'number-recovery-jobs-expired',
                'nlabel'    => {
                    'absolute'      => 'recovery.jobs.expired.count',
                },
                'unit'      => '',
                'min'       => 0
            }
        }
    };

    return $metrics_mapping;
}

sub long_output {
    my ($self, %options) = @_;
    return "AWS Backup Vault Name'" . $options{instance_value}->{display} . "' ";

}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        'backup-vault-name:s@' => { name => 'backup_vault' }
    });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{backup_vault}) || $self->{option_results}->{backup_vault} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --backup-vault-name option.");
        $self->{output}->option_exit();
    };

    foreach my $instance (@{$self->{option_results}->{backup_vault}}) {
        if ($instance ne '') {
            push @{$self->{aws_instance}}, $instance;
        };
    }

    $self->{aws_timeframe} = defined($self->{option_results}->{timeframe}) ? $self->{option_results}->{timeframe} : 86400;
    $self->{aws_period} = defined($self->{option_results}->{period}) ? $self->{option_results}->{period} : 3600;
    $self->{aws_statistics} = ['Sum'];

}
sub manage_selection {
    my ($self, %options) = @_;

    my %metric_results;
    foreach my $instance (@{$self->{aws_instance}}) {
        $metric_results{$instance} = $options{custom}->cloudwatch_get_metrics(
            namespace   => 'AWS/Backup',
            dimensions  => [ { Name => 'BackupVaultName', Value => $instance } ],
            metrics     => $self->{aws_metrics},
            statistics  => $self->{aws_statistics},
            timeframe   => $self->{aws_timeframe},
            period      => $self->{aws_period}
        );

        foreach my $metric (@{$self->{aws_metrics}}) {
            foreach my $statistic (@{$self->{aws_statistics}}) {
                next if (!defined($metric_results{$instance}->{$metric}->{lc($statistic)}) &&
                    !defined($self->{option_results}->{zeroed}));
                $self->{metrics}->{$instance}->{display} = $instance;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{display} = $statistic;
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{timeframe} = $self->{aws_timeframe};
                $self->{metrics}->{$instance}->{statistics}->{lc($statistic)}->{$metric} =
                    defined($metric_results{$instance}->{$metric}->{lc($statistic)}) ?
                    $metric_results{$instance}->{$metric}->{lc($statistic)} : 0;
            }
        }
    }

    if (scalar(keys %{$self->{metrics}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => 'No metrics. Check your options or use --zeroed option to set 0 on undefined values');
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check AWS backup jobs. 
Check number of : 
- backup jobs completed, failed and expired. 
- copy jobs completed and failed.
- recovery points expired. 

=over 8

=item B<--backup-vault-name>

Name of the backup vault.

=item B<--filter-metric>

Filter on a specific metric. 

Can be: NumberOfBackupJobsCompleted, NumberOfBackupJobsFailed, NumberOfBackupJobsExpired, NumberOfCopyJobsCompleted, NumberOfCopyJobsFailed, NumberOfRecoveryPointsExpired

Can be regex, for example : --filter-metric="NumberOf(Backup|Copy).*Failed"

=item B<--warning-*>

Warning thresholds. Not mandatory, but if you don't specify critical or warning thresholds you will always get OK status.

Can be : --warning-number-backup-jobs-completed, --warning-number-backup-jobs-failed, --warning-umber-backup-jobs-expired,
--warning-number-copy-jobs-completed, --warning-number-copy-jobs-failed, --warning-number-recovery-jobs-expired

=item B<--critical-*>

Critical thresholds. Not mandatory, but if you don't specify critical or warning thresholds you will always get OK status.

Can be : --critical-number-backup-jobs-completed, --critical-number-backup-jobs-failed, --critical-number-backup-jobs-expired,
--critical-number-copy-jobs-completed, --critical-number-copy-jobs-failed, --critical-number-recovery-jobs-expired

=back

=cut
