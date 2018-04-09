#
# Copyright 2018 Centreon (http://www.centreon.com/)
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

package cloud::aws::ec2::mode::instancestypes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %spot_types = (
    'general' => ['t2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 'm4.large',
                'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm5.large', 'm5.xlarge',
                'm5.2xlarge', 'm5.4xlarge', 'm5.12xlarge', 'm5.24xlarge'],
    'compute' => ['c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'c5.large',
                'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.18xlarge'],
    'memory' => ['r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge',
                'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge',
                'x1e.32xlarge'],
    'storage' => ['r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge',
                'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge',
                'x1e.32xlarge'],
    'accelerated' => ['f1.2xlarge', 'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'p2.xlarge',
                'p2.8xlarge', 'p2.16xlarge', 'p3.2xlarge', 'p3.8xlarge', 'p3.16xlarge'],
);

sub prefix_general_output {
    my ($self, %options) = @_;

    return "Spot family 'General purpose' instance types count ";
}

sub prefix_compute_output {
    my ($self, %options) = @_;

    return "Spot family 'Compute optimized' instance types count ";
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Spot family 'Memory optimized' instance types count ";
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Spot family 'Storage optimized' instance types count ";
}

sub prefix_accelerated_output {
    my ($self, %options) = @_;

    return "Spot family 'Accelerated computing' instance types count ";
}

sub set_counters {
    my ($self, %options) = @_;

    foreach my $family (keys %spot_types) {
        my $counter = { name => $family, type => 0, cb_prefix_output => 'prefix_' . $family . '_output', skipped_code => { -10 => 1 } };
        
        push @{$self->{maps_counters_type}}, $counter;

        $self->{maps_counters}->{$family} = [];
        
        foreach my $type (@{$spot_types{$family}}) {
            my $entry = { label => $type, set => {
                            key_values => [ { name => $type }  ],
                            output_template => $type . ": %s",
                            perfdatas => [
                            { label => $type, value => $type . '_absolute', template => '%d', min => 0 },
                            ],
                        }
                    };
            push @{$self->{maps_counters}->{$family}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                    "region:s"          => { name => 'region' },
                                    "filter-family:s"   => { name => 'filter_family' },
                                    "filter-type:s"     => { name => 'filter_type' },
                                    "running"           => { name => 'running' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::check_options(%options);

    if (!defined($self->{option_results}->{region}) || $self->{option_results}->{region} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --region option.");
        $self->{output}->option_exit();
    }
}

sub manage_selection {
    my ($self, %options) = @_;
    
    foreach my $family (keys %spot_types) {
        if (defined($self->{option_results}->{filter_family}) && $self->{option_results}->{filter_family} ne '' &&
            $family !~ /$self->{option_results}->{filter_family}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping family '%s'", $family), debug => 1);
            $self->{maps_counters}->{$family} = undef;
        } else {
            foreach my $type (@{$spot_types{$family}}) {
                if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                    $type !~ /$self->{option_results}->{filter_type}/) {
                    next;
                }
                $self->{$family}->{$type} = 0;
            }
        }
    }

    $self->{instances} = $options{custom}->ec2_list_resources(region => $self->{option_results}->{region});

    foreach my $instance (@{$self->{instances}}) {
        next if ($instance->{Type} !~ /instance/ || (defined($self->{option_results}->{running}) && $instance->{State} !~ /running/));
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $instance->{InstanceType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping type '%s'", $instance->{InstanceType}), debug => 1);
            next;
        }
        
        foreach my $family (keys %spot_types) {
            $self->{$family}->{$instance->{InstanceType}}++ if (defined($self->{maps_counters}->{$family}) && map(/$instance->{InstanceType}/, @{$spot_types{$family}}));
        }
    }

    if (scalar(keys %{$self->{general}}) <= 0 && scalar(keys %{$self->{compute}}) <= 0 && scalar(keys %{$self->{memory}}) <= 0 &&
        scalar(keys %{$self->{storage}}) <= 0 && scalar(keys %{$self->{accelerated}}) <= 0) {
        $self->{output}->add_option_msg(short_msg => "No result matched with applied filters.");
        $self->{output}->option_exit();
    }
}

1;

__END__

=head1 MODE

Check EC2 instances types count.

Example: 
perl centreon_plugins.pl --plugin=cloud::aws::ec2::plugin --custommode=paws --mode=instances-types --region='eu-west-1'
--filter-family='general' --filter-type='medium' --critical-t2.medium='10' --verbose

See 'https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/instance-types.html' for more informations.

=over 8

=item B<--filter-family>

Filter by instance family (regexp)
(Can be: 'general', 'compute', 'memory', 'storage', 'accelerated')

=item B<--filter-type>

Filter by instance type (regexp)

=item B<--warning-*>

Threshold warning.
Can be: 't2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 'm4.large',
'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm5.large', 'm5.xlarge', 'm5.2xlarge',
'm5.4xlarge', 'm5.12xlarge', 'm5.24xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 
'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.18xlarge', 'r4.large', 'r4.xlarge',
'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge', 'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge',
'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge', 'x1e.32xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge',
'r4.8xlarge', 'r4.16xlarge', 'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge',
'x1e.16xlarge', 'x1e.32xlarge', 'f1.2xlarge', 'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'p2.xlarge',
'p2.8xlarge', 'p2.16xlarge', 'p3.2xlarge', 'p3.8xlarge', 'p3.16xlarge'.

=item B<--critical-*>

Threshold critical.
Can be: 't2.nano', 't2.micro', 't2.small', 't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 'm4.large',
'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm5.large', 'm5.xlarge', 'm5.2xlarge',
'm5.4xlarge', 'm5.12xlarge', 'm5.24xlarge', 'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 
'c5.large', 'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.18xlarge', 'r4.large', 'r4.xlarge',
'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge', 'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge',
'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge', 'x1e.32xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge',
'r4.8xlarge', 'r4.16xlarge', 'x1.16xlarge', 'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge',
'x1e.16xlarge', 'x1e.32xlarge', 'f1.2xlarge', 'f1.16xlarge', 'g3.4xlarge', 'g3.8xlarge', 'g3.16xlarge', 'p2.xlarge',
'p2.8xlarge', 'p2.16xlarge', 'p3.2xlarge', 'p3.8xlarge', 'p3.16xlarge'.

=item B<--running>

Only check running instances.

=back

=cut
