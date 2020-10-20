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

package apps::exchange::2010::local::mode::resources::types;

use strict;
use warnings;
use Exporter;

our $queue_status;
our $queue_delivery_type;
our $copystatus_contentindexstate;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    $queue_status $queue_delivery_type
    $copystatus_contentindexstate
);

$queue_status = {
    0 => 'None',
    1 => 'Active',
    2 => 'Ready', 
    3 => 'Retry',
    4 => 'Suspended',
    5 => 'Connecting',
    6 => 'Throttled'
};

$queue_delivery_type = {
    0 => 'Undefined',
    1 => 'DnsConnectorDelivery',
    2 => 'MapiDelivery',
    3 => 'NonSmtpGatewayDelivery',
    4 => 'SmartHostConnectorDelivery',
    5 => 'SmtpRelayToRemoteAdSite',
    6 => 'SmtpRelayToTiRg',
    7 => 'SmtpRelayWithinAdSite',
    8 => 'SmtpRelayWithinAdSiteToEdge',
    9 => 'Unreachable',
    10 => 'ShadowRedundancy',
    11 => 'Heartbeat',
    12 => 'DeliveryAgent',
    13 => 'SmtpDeliveryToMailbox',
    14 => 'SmtpRelayToDag',
    15 => 'SmtpRelayToMailboxDeliveryGroup',
    16 => 'SmtpRelayToConnectorSourceServers',
    17 => 'SmtpRelayToServers',
    18 => 'SmtpRelayToRemoteForest',
    19 => 'SmtpDeliveryToExo',
    20 => 'HttpDeliveryToMailbox',
    21 => 'HttpDeliveryToExo',
    22 => 'Delay',
    23 => 'SmtpSubmissionToEop',
    24 => 'SmtpSubmissionToExo',
    25 => 'HttpDeliveryToApp'
};

$copystatus_contentindexstate = {
    0 => 'Unknown',
    1 => 'Healthy',
    2 => 'Crawling',
    3 => 'Failed',
    4 => 'Seeding',
    5 => 'FailedAndSuspended',
    6 => 'Suspended',
    7 => 'Disabled',
    8 => 'AutoSuspended',
    9 => 'HealthyAndUpgrading',
    10 => 'DiskUnavailable'
};

1;
