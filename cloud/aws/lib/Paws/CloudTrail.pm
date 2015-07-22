package Paws::CloudTrail {
  use Moose;
  sub service { 'cloudtrail' }
  sub version { '2013-11-01' }
  sub target_prefix { 'com.amazonaws.cloudtrail.v20131101.CloudTrail_20131101' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateTrail {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::CreateTrail', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTrail {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::DeleteTrail', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTrails {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::DescribeTrails', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetTrailStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::GetTrailStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub LookupEvents {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::LookupEvents', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartLogging {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::StartLogging', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopLogging {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::StopLogging', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateTrail {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::CloudTrail::UpdateTrail', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudTrail - Perl Interface to AWS AWS CloudTrail

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('CloudTrail')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



AWS CloudTrail

This is the CloudTrail API Reference. It provides descriptions of
actions, data types, common parameters, and common errors for
CloudTrail.

CloudTrail is a web service that records AWS API calls for your AWS
account and delivers log files to an Amazon S3 bucket. The recorded
information includes the identity of the user, the start time of the
AWS API call, the source IP address, the request parameters, and the
response elements returned by the service.

As an alternative to using the API, you can use one of the AWS SDKs,
which consist of libraries and sample code for various programming
languages and platforms (Java, Ruby, .NET, iOS, Android, etc.). The
SDKs provide a convenient way to create programmatic access to
AWSCloudTrail. For example, the SDKs take care of cryptographically
signing requests, managing errors, and retrying requests automatically.
For information about the AWS SDKs, including how to download and
install them, see the Tools for Amazon Web Services page.

See the CloudTrail User Guide for information about the data that is
included with each AWS API call listed in the log files.










=head1 METHODS

=head2 CreateTrail(Name => Str, S3BucketName => Str, [CloudWatchLogsLogGroupArn => Str, CloudWatchLogsRoleArn => Str, IncludeGlobalServiceEvents => Bool, S3KeyPrefix => Str, SnsTopicName => Str])

Each argument is described in detail in: L<Paws::CloudTrail::CreateTrail>

Returns: a L<Paws::CloudTrail::CreateTrailResponse> instance

  

From the command line, use C<create-subscription>.

Creates a trail that specifies the settings for delivery of log data to
an Amazon S3 bucket.











=head2 DeleteTrail(Name => Str)

Each argument is described in detail in: L<Paws::CloudTrail::DeleteTrail>

Returns: a L<Paws::CloudTrail::DeleteTrailResponse> instance

  

Deletes a trail.











=head2 DescribeTrails([trailNameList => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::CloudTrail::DescribeTrails>

Returns: a L<Paws::CloudTrail::DescribeTrailsResponse> instance

  

Retrieves settings for the trail associated with the current region for
your account.











=head2 GetTrailStatus(Name => Str)

Each argument is described in detail in: L<Paws::CloudTrail::GetTrailStatus>

Returns: a L<Paws::CloudTrail::GetTrailStatusResponse> instance

  

Returns a JSON-formatted list of information about the specified trail.
Fields include information on delivery errors, Amazon SNS and Amazon S3
errors, and start and stop logging times for each trail.











=head2 LookupEvents([EndTime => Str, LookupAttributes => ArrayRef[Paws::CloudTrail::LookupAttribute], MaxResults => Int, NextToken => Str, StartTime => Str])

Each argument is described in detail in: L<Paws::CloudTrail::LookupEvents>

Returns: a L<Paws::CloudTrail::LookupEventsResponse> instance

  

Looks up API activity events captured by CloudTrail that create,
update, or delete resources in your account. Events for a region can be
looked up for the times in which you had CloudTrail turned on in that
region during the last seven days. Lookup supports five different
attributes: time range (defined by a start time and end time), user
name, event name, resource type, and resource name. All attributes are
optional. The maximum number of attributes that can be specified in any
one lookup request are time range and one other attribute. The default
number of results returned is 10, with a maximum of 50 possible. The
response includes a token that you can use to get the next page of
results. The rate of lookup requests is limited to one per second per
account.

Events that occurred during the selected time range will not be
available for lookup if CloudTrail logging was not enabled when the
events occurred.











=head2 StartLogging(Name => Str)

Each argument is described in detail in: L<Paws::CloudTrail::StartLogging>

Returns: a L<Paws::CloudTrail::StartLoggingResponse> instance

  

Starts the recording of AWS API calls and log file delivery for a
trail.











=head2 StopLogging(Name => Str)

Each argument is described in detail in: L<Paws::CloudTrail::StopLogging>

Returns: a L<Paws::CloudTrail::StopLoggingResponse> instance

  

Suspends the recording of AWS API calls and log file delivery for the
specified trail. Under most circumstances, there is no need to use this
action. You can update a trail without stopping it first. This action
is the only way to stop recording.











=head2 UpdateTrail(Name => Str, [CloudWatchLogsLogGroupArn => Str, CloudWatchLogsRoleArn => Str, IncludeGlobalServiceEvents => Bool, S3BucketName => Str, S3KeyPrefix => Str, SnsTopicName => Str])

Each argument is described in detail in: L<Paws::CloudTrail::UpdateTrail>

Returns: a L<Paws::CloudTrail::UpdateTrailResponse> instance

  

From the command line, use C<update-subscription>.

Updates the settings that specify delivery of log files. Changes to a
trail do not require stopping the CloudTrail service. Use this action
to designate an existing bucket for log delivery. If the existing
bucket has previously been a target for CloudTrail log files, an IAM
policy exists for the bucket.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

