#!/usr/bin/perl
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

use strict;
use warnings;

# Paws loads most of its modules at runtime, so installing the package does not
# prove its dependencies are there: load and run the code paths used by the
# cloud::aws plugins, without any network access.
# Every check is run even if a previous one failed, to report all missing
# dependencies at once.

# Fake credentials, picked up by Paws::Credential::Environment
$ENV{AWS_ACCESS_KEY_ID} = 'AKIAIOSFODNN7EXAMPLE';
$ENV{AWS_SECRET_ACCESS_KEY} = 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY';
delete $ENV{AWS_SESSION_TOKEN};

my @errors;

# Modules loaded on demand by Paws or by src/cloud/aws/custom/paws.pm
my @modules = (
    'Paws',
    'Paws::Credential::ProviderChain',
    'Paws::Credential::File',
    'Paws::Credential::AssumeRole',
    'Paws::Net::Caller',
    'Paws::Net::LWPCaller',
    'Paws::Net::XMLResponse',
    'Paws::Net::JsonResponse',
    'String::CRC32',
    'IO::Socket::SSL'
);
foreach my $module (@modules) {
    if (eval "require $module; 1") {
        print "Module $module loaded\n";
    } else {
        push @errors, "Cannot load module $module: $@";
    }
}

if (eval { require HTTP::Tiny; 1 }) {
    my ($ssl_ok, $ssl_reason) = HTTP::Tiny->can_ssl();
    if ($ssl_ok) {
        print "HTTPS support available\n";
    } else {
        push @errors, "HTTP::Tiny cannot use SSL: $ssl_reason";
    }
} else {
    push @errors, "Cannot load module HTTP::Tiny: $@";
}

# Caller that signs the request but answers with a canned CloudWatch response
my $fake_caller = <<'EOF';
package FakeCaller;
use Moose;
extends 'Paws::Net::Caller';

sub send_request {
    my ($self, $service, $call_object) = @_;

    my $request = $service->prepare_request_for_call($call_object);
    die "Request is not signed\n" unless ($request->header('Authorization') // '') =~ /^AWS4-HMAC-SHA256 /;

    return Paws::Net::APIResponse->new(
        status => 200,
        headers => { 'content-type' => 'text/xml' },
        content => <<'XML'
<ListMetricsResponse xmlns="http://monitoring.amazonaws.com/doc/2010-08-01/">
  <ListMetricsResult>
    <Metrics>
      <member>
        <Namespace>AWS/EC2</Namespace>
        <MetricName>CPUUtilization</MetricName>
        <Dimensions>
          <member>
            <Name>InstanceId</Name>
            <Value>i-0123456789abcdef0</Value>
          </member>
        </Dimensions>
      </member>
    </Metrics>
  </ListMetricsResult>
  <ResponseMetadata>
    <RequestId>11111111-2222-3333-4444-555555555555</RequestId>
  </ResponseMetadata>
</ListMetricsResponse>
XML
    );
}
1;
EOF

# Default credentials provider chain, as used by the plugins without --aws-role-arn
eval {
    eval $fake_caller or die $@;
    my $paws = Paws->new(config => { caller => FakeCaller->new() });
    my $cw = $paws->service('CloudWatch', region => 'eu-west-1');
    my $result = $cw->ListMetrics(Namespace => 'AWS/EC2');

    my $metric = $result->Metrics->[0];
    die "Unexpected CloudWatch response\n"
        unless defined($metric) && $metric->MetricName eq 'CPUUtilization'
        && $metric->Dimensions->[0]->Value eq 'i-0123456789abcdef0';
    print "CloudWatch ListMetrics response parsed: " . $metric->Namespace . ' ' . $metric->MetricName . "\n";
    1;
} or push @errors, "CloudWatch ListMetrics call failed: $@";

if (@errors) {
    print STDERR "$_\n" foreach (@errors);
    die scalar(@errors) . " check(s) failed\n";
}

print "Test succeeded\n";
