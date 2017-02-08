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

package cloud::aws::mode::metrics::s3bucketsize;

use strict;
use warnings;
use POSIX;
use Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(&cloudwatchCheck);

my @Param;

$Param[0] = {
    'NameSpace'       => 'AWS/S3',
    'MetricName'      => 'BucketSizeBytes',
    'ObjectName'      => 'BucketName',
    'Unit'            => 'Bytes',
    'ExtraDimensions' => {
        'Name' => 'StorageType',
        'Value'=> 'StandardStorage'
    },
    'Labels'          => {
        'ShortOutput' => "Bucket size is %s Bytes",
        'LongOutput'  => "Bucket size is %s Bytes",
        'PerfData'    => 'size',
        'Unit'        => 'Bytes',
        'Value'       => "%s",
    }
};
$Param[1] = {
    'NameSpace'       => 'AWS/S3',
    'MetricName'      => 'NumberOfObjects',
    'ObjectName'      => 'BucketName',
    'Unit'            => 'Count',
    'ExtraDimensions' => {
        'Name' => 'StorageType',
        'Value'=> 'AllStorageTypes'
    },
    'Labels'          => {
        'ShortOutput' => "Number of objects is %s",
        'LongOutput'  => "Number of objects is %s",
        'PerfData'    => 'number',
        'Unit'        => '',
        'Value'       => "%s",
    }
};

sub cloudwatchCheck {
    my ($self) = @_;

    @{ $self->{metric} } = @Param;
    $self->{option_results}->{starttime} = strftime( "%FT%H:%M:%S.000Z", gmtime( $self->{option_results}->{def_endtime} - 86400 ) );
}

1;
