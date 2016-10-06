#
# Copyright 2016 Centreon (http://www.centreon.com/)
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

package cloud::aws::mode::metrics::ec2instancenetwork;

use strict;
use warnings;
use Data::Dumper;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(&cloudwatchCheck);

my @Param;

$Param[0] = {
    'NameSpace'  => 'AWS/EC2',
    'MetricName' => 'NetworkIn',
    'ObjectName' => 'InstanceId',
    'Unit'       => 'Bytes',
    'Labels'     => {
        'ShortOutput' => "Traffic In %s Bytes",
        'LongOutput'  => "Traffic In %s Bytes",
        'PerfData'    => 'traffic_in',
        'Unit'        => 'B',
        'Value'       => "%.2f",
    }
};

$Param[1] = {
    'NameSpace'  => 'AWS/EC2',
    'MetricName' => 'NetworkOut',
    'ObjectName' => 'InstanceId',
    'Unit'       => 'Bytes',
    'Labels'     => {
        'ShortOutput' => "Traffic Out %s Bytes",
        'LongOutput'  => "Traffic Out %s Bytes",
        'PerfData'    => 'traffic_out',
        'Unit'        => 'B',
        'Value'       => "%.2f",
    }
};

sub cloudwatchCheck {
    my ($self) = @_;

    @{ $self->{metric} } = @Param;
}

1;
