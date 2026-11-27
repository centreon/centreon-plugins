#
# Copyright 2026-Present Centreon (http://www.centreon.com/)
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

package storage::emc::datadomain::snmp::lib::functions;

sub get_version {
    my (%options) = @_;
    
    return $1 if (defined($options{value}) && $options{value} =~ /(\d+\.\d+\.\d+)/);
    return undef;
}

# The Active Tier perfdata keep the plain filesystem name weither other tier are present
# Other tiers (Cloud Tier, Total) get the tier appended to the name.
sub get_fs_display_name {
    my (%options) = @_;

    return $options{name} if (!defined($options{tier}) || $options{tier} =~ /^\s*(active\s+tier)?\s*$/i);
    return $options{name} . '~' . $options{tier};
}

1;
    