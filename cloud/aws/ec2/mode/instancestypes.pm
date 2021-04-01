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

package cloud::aws::ec2::mode::instancestypes;

use base qw(centreon::plugins::templates::counter);

use strict;
use warnings;

my %family_mapping = (
    'general' => {
        'prefix_output' => 'prefix_general_output',
        'types' => [
            'a1.medium', 'a1.large', 'a1.xlarge', 'a1.2xlarge', 'a1.4xlarge', 'm4.large',
            'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm5.large',
            'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge',
            'm5.24xlarge', 'm5.metal', 'm5a.large', 'm5a.xlarge', 'm5a.2xlarge', 'm5a.4xlarge',
            'm5a.8xlarge', 'm5a.12xlarge', 'm5a.16xlarge', 'm5a.24xlarge', 'm5ad.large',
            'm5ad.xlarge', 'm5ad.2xlarge', 'm5ad.4xlarge', 'm5ad.12xlarge', 'm5ad.24xlarge',
            'm5d.large', 'm5d.xlarge', 'm5d.2xlarge', 'm5d.4xlarge', 'm5d.8xlarge', 'm5d.12xlarge',
            'm5d.16xlarge', 'm5d.24xlarge', 'm5d.metal', 't2.nano', 't2.micro', 't2.small',
            't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 't3.nano', 't3.micro', 't3.small',
            't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge', 't3a.nano', 't3a.micro', 't3a.small',
            't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge'
        ],
    },
    'compute' => {
        'prefix_output' => 'prefix_compute_output',
        'types' => [
            'c4.large', 'c4.xlarge', 'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'c5.large',
            'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge',
            'c5.24xlarge', 'c5.metal', 'c5d.large', 'c5d.xlarge', 'c5d.2xlarge', 'c5d.4xlarge',
            'c5d.9xlarge', 'c5d.18xlarge', 'c5n.large', 'c5n.xlarge', 'c5n.2xlarge', 'c5n.4xlarge',
            'c5n.9xlarge', 'c5n.18xlarge'
        ],
    },
    'memory' => {
        'prefix_output' => 'prefix_memory_output',
        'types' => [
            'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge',
            'r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge',
            'r5.16xlarge', 'r5.24xlarge', 'r5.metal', 'r5a.large', 'r5a.xlarge', 'r5a.2xlarge',
            'r5a.4xlarge', 'r5a.8xlarge', 'r5a.12xlarge', 'r5a.16xlarge', 'r5a.24xlarge', 'r5ad.large',
            'r5ad.xlarge', 'r5ad.2xlarge', 'r5ad.4xlarge', 'r5ad.12xlarge', 'r5ad.24xlarge', 'r5d.large',
            'r5d.xlarge', 'r5d.2xlarge', 'r5d.4xlarge', 'r5d.8xlarge', 'r5d.12xlarge', 'r5d.16xlarge',
            'r5d.24xlarge', 'r5d.metal', 'u-6tb1.metal', 'u-9tb1.metal', 'u-12tb1.metal', 'x1.16xlarge',
            'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge',
            'x1e.32xlarge', 'z1d.large', 'z1d.xlarge', 'z1d.2xlarge', 'z1d.3xlarge', 'z1d.6xlarge',
            'z1d.12xlarge', 'z1d.metal'
        ],
    },
    'storage' => {
        'prefix_output' => 'prefix_storage_output',
        'types' => [
            'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge', 'h1.2xlarge', 'h1.4xlarge',
            'h1.8xlarge', 'h1.16xlarge', 'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge',
            'i3.8xlarge', 'i3.16xlarge', 'i3.metal', 'i3en.large', 'i3en.xlarge', 'i3en.2xlarge',
            'i3en.3xlarge', 'i3en.6xlarge', 'i3en.12xlarge', 'i3en.24xlarge'
        ],
    },
    'accelerated' => {
        'prefix_output' => 'prefix_accelerated_output',
        'types' => [
            'f1.2xlarge', 'f1.4xlarge', 'f1.16xlarge', 'g3s.xlarge', 'g3.4xlarge', 'g3.8xlarge',
            'g3.16xlarge', 'p2.xlarge', 'p2.8xlarge', 'p2.16xlarge', 'p3.2xlarge', 'p3.8xlarge',
            'p3.16xlarge', 'p3dn.24xlarge'
        ],
    },
);

sub prefix_general_output {
    my ($self, %options) = @_;

    return "Spot family 'General purpose' instances count ";
}

sub prefix_compute_output {
    my ($self, %options) = @_;

    return "Spot family 'Compute optimized' instances count ";
}

sub prefix_memory_output {
    my ($self, %options) = @_;

    return "Spot family 'Memory optimized' instances count ";
}

sub prefix_storage_output {
    my ($self, %options) = @_;

    return "Spot family 'Storage optimized' instances count ";
}

sub prefix_accelerated_output {
    my ($self, %options) = @_;

    return "Spot family 'Accelerated computing' instances count ";
}

sub set_counters {
    my ($self, %options) = @_;

    foreach my $family (keys %family_mapping) {
        my $counter = { 
            name => $family,
            type => 0,
            cb_prefix_output => $family_mapping{$family}->{prefix_output},
            skipped_code => { -10 => 1 } };
        
        push @{$self->{maps_counters_type}}, $counter;

        $self->{maps_counters}->{$family} = [];
        
        foreach my $type (@{$family_mapping{$family}->{types}}) {
            my $entry = {
                label => $type, nlabel => 'ec2.instances.type.' . $family . '.' . $type . '.count', set => {
                    key_values => [ { name => $type }  ],
                    output_template => $type . ": %s",
                    perfdatas => [
                        { value => $type , template => '%d', min => 0 },
                    ],
                }
            };
            push @{$self->{maps_counters}->{$family}}, $entry;
        }
    }
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1);
    bless $self, $class;

    $options{options}->add_options(arguments =>  {
        "filter-family:s"   => { name => 'filter_family' },
        "filter-type:s"     => { name => 'filter_type' },
        "running"           => { name => 'running' }
    });

    return $self;
}

sub manage_selection {
    my ($self, %options) = @_;
    
    foreach my $family (keys %family_mapping) {
        if (defined($self->{option_results}->{filter_family}) && $self->{option_results}->{filter_family} ne '' &&
            $family !~ /$self->{option_results}->{filter_family}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping family '%s'", $family), debug => 1);
            $self->{maps_counters}->{$family} = undef;
        } else {
            foreach my $type (@{$family_mapping{$family}->{types}}) {
                if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
                    $type !~ /$self->{option_results}->{filter_type}/) {
                    next;
                }
                $self->{$family}->{$type} = 0;
            }
        }
    }

    $self->{instances} = $options{custom}->ec2_list_resources();

    foreach my $instance (@{$self->{instances}}) {
        next if ($instance->{Type} !~ /instance/ || (defined($self->{option_results}->{running}) && $instance->{State} !~ /running/));
        if (defined($self->{option_results}->{filter_type}) && $self->{option_results}->{filter_type} ne '' &&
            $instance->{InstanceType} !~ /$self->{option_results}->{filter_type}/) {
            $self->{output}->output_add(long_msg => sprintf("skipping type '%s'", $instance->{InstanceType}), debug => 1);
            next;
        }
        
        foreach my $family (keys %family_mapping) {
            $self->{$family}->{$instance->{InstanceType}}++ if (defined($self->{maps_counters}->{$family}) && map(/$instance->{InstanceType}/, @{$family_mapping{$family}->{types}}));
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

=item B<--warning-*> B<--critical-*>

Threshold warning.
Can be: 'a1.medium', 'a1.large', 'a1.xlarge', 'a1.2xlarge', 'a1.4xlarge', 'm4.large',
'm4.xlarge', 'm4.2xlarge', 'm4.4xlarge', 'm4.10xlarge', 'm4.16xlarge', 'm5.large',
'm5.xlarge', 'm5.2xlarge', 'm5.4xlarge', 'm5.8xlarge', 'm5.12xlarge', 'm5.16xlarge',
'm5.24xlarge', 'm5.metal', 'm5a.large', 'm5a.xlarge', 'm5a.2xlarge', 'm5a.4xlarge',
'm5a.8xlarge', 'm5a.12xlarge', 'm5a.16xlarge', 'm5a.24xlarge', 'm5ad.large',
'm5ad.xlarge', 'm5ad.2xlarge', 'm5ad.4xlarge', 'm5ad.12xlarge', 'm5ad.24xlarge',
'm5d.large', 'm5d.xlarge', 'm5d.2xlarge', 'm5d.4xlarge', 'm5d.8xlarge', 'm5d.12xlarge',
'm5d.16xlarge', 'm5d.24xlarge', 'm5d.metal', 't2.nano', 't2.micro', 't2.small',
't2.medium', 't2.large', 't2.xlarge', 't2.2xlarge', 't3.nano', 't3.micro', 't3.small',
't3.medium', 't3.large', 't3.xlarge', 't3.2xlarge', 't3a.nano', 't3a.micro', 't3a.small',
't3a.medium', 't3a.large', 't3a.xlarge', 't3a.2xlarge', 'c4.large', 'c4.xlarge',
'c4.2xlarge', 'c4.4xlarge', 'c4.8xlarge', 'c5.large',
'c5.xlarge', 'c5.2xlarge', 'c5.4xlarge', 'c5.9xlarge', 'c5.12xlarge', 'c5.18xlarge',
'c5.24xlarge', 'c5.metal', 'c5d.large', 'c5d.xlarge', 'c5d.2xlarge', 'c5d.4xlarge',
'c5d.9xlarge', 'c5d.18xlarge', 'c5n.large', 'c5n.xlarge', 'c5n.2xlarge', 'c5n.4xlarge',
'c5n.9xlarge', 'c5n.18xlarge', 'r4.large', 'r4.xlarge', 'r4.2xlarge', 'r4.4xlarge', 'r4.8xlarge', 'r4.16xlarge',
'r5.large', 'r5.xlarge', 'r5.2xlarge', 'r5.4xlarge', 'r5.8xlarge', 'r5.12xlarge',
'r5.16xlarge', 'r5.24xlarge', 'r5.metal', 'r5a.large', 'r5a.xlarge', 'r5a.2xlarge',
'r5a.4xlarge', 'r5a.8xlarge', 'r5a.12xlarge', 'r5a.16xlarge', 'r5a.24xlarge', 'r5ad.large',
'r5ad.xlarge', 'r5ad.2xlarge', 'r5ad.4xlarge', 'r5ad.12xlarge', 'r5ad.24xlarge', 'r5d.large',
'r5d.xlarge', 'r5d.2xlarge', 'r5d.4xlarge', 'r5d.8xlarge', 'r5d.12xlarge', 'r5d.16xlarge',
'r5d.24xlarge', 'r5d.metal', 'u-6tb1.metal', 'u-9tb1.metal', 'u-12tb1.metal', 'x1.16xlarge',
'x1.32xlarge', 'x1e.xlarge', 'x1e.2xlarge', 'x1e.4xlarge', 'x1e.8xlarge', 'x1e.16xlarge',
'x1e.32xlarge', 'z1d.large', 'z1d.xlarge', 'z1d.2xlarge', 'z1d.3xlarge', 'z1d.6xlarge',
'z1d.12xlarge', 'z1d.metal', 'd2.xlarge', 'd2.2xlarge', 'd2.4xlarge', 'd2.8xlarge', 'h1.2xlarge', 'h1.4xlarge',
'h1.8xlarge', 'h1.16xlarge', 'i3.large', 'i3.xlarge', 'i3.2xlarge', 'i3.4xlarge',
'i3.8xlarge', 'i3.16xlarge', 'i3.metal', 'i3en.large', 'i3en.xlarge', 'i3en.2xlarge',
'i3en.3xlarge', 'i3en.6xlarge', 'i3en.12xlarge', 'i3en.24xlarge','f1.2xlarge',
'f1.4xlarge', 'f1.16xlarge', 'g3s.xlarge', 'g3.4xlarge', 'g3.8xlarge',
'g3.16xlarge', 'p2.xlarge', 'p2.8xlarge', 'p2.16xlarge', 'p3.2xlarge', 'p3.8xlarge',
'p3.16xlarge', 'p3dn.24xlarge'.

=item B<--running>

Only check running instances.

=back

=cut
