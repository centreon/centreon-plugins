package Paws::Config {
  use Moose;
  sub service { 'config' }
  sub version { '2014-11-12' }
  sub target_prefix { 'StarlingDoveService' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub DeleteDeliveryChannel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DeleteDeliveryChannel', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeliverConfigSnapshot {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DeliverConfigSnapshot', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConfigurationRecorders {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DescribeConfigurationRecorders', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeConfigurationRecorderStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DescribeConfigurationRecorderStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDeliveryChannels {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DescribeDeliveryChannels', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeDeliveryChannelStatus {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::DescribeDeliveryChannelStatus', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetResourceConfigHistory {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::GetResourceConfigHistory', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutConfigurationRecorder {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::PutConfigurationRecorder', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub PutDeliveryChannel {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::PutDeliveryChannel', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartConfigurationRecorder {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::StartConfigurationRecorder', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopConfigurationRecorder {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::Config::StopConfigurationRecorder', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Config - Perl Interface to AWS AWS Config

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('Config')->new;
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



AWS Config

AWS Config provides a way to keep track of the configurations of all
the AWS resources associated with your AWS account. You can use AWS
Config to get the current and historical configurations of each AWS
resource and also to get information about the relationship between the
resources. An AWS resource can be an Amazon Compute Cloud (Amazon EC2)
instance, an Elastic Block Store (EBS) volume, an Elastic network
Interface (ENI), or a security group. For a complete list of resources
currently supported by AWS Config, see Supported AWS Resources.

You can access and manage AWS Config through the AWS Management
Console, the AWS Command Line Interface (AWS CLI), the AWS Config API,
or the AWS SDKs for AWS Config

This reference guide contains documentation for the AWS Config API and
the AWS CLI commands that you can use to manage AWS Config.

The AWS Config API uses the Signature Version 4 protocol for signing
requests. For more information about how to sign a request with this
protocol, see Signature Version 4 Signing Process.

For detailed information about AWS Config features and their associated
actions or commands, as well as how to work with AWS Management
Console, see What Is AWS Config? in the I<AWS Config Developer Guide>.










=head1 METHODS

=head2 DeleteDeliveryChannel(DeliveryChannelName => Str)

Each argument is described in detail in: L<Paws::Config::DeleteDeliveryChannel>

Returns: nothing

  

Deletes the specified delivery channel.

The delivery channel cannot be deleted if it is the only delivery
channel and the configuration recorder is still running. To delete the
delivery channel, stop the running configuration recorder using the
StopConfigurationRecorder action.











=head2 DeliverConfigSnapshot(deliveryChannelName => Str)

Each argument is described in detail in: L<Paws::Config::DeliverConfigSnapshot>

Returns: a L<Paws::Config::DeliverConfigSnapshotResponse> instance

  

Schedules delivery of a configuration snapshot to the Amazon S3 bucket
in the specified delivery channel. After the delivery has started, AWS
Config sends following notifications using an Amazon SNS topic that you
have specified.

=over

=item * Notification of starting the delivery.

=item * Notification of delivery completed, if the delivery was
successfully completed.

=item * Notification of delivery failure, if the delivery failed to
complete.

=back











=head2 DescribeConfigurationRecorders([ConfigurationRecorderNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Config::DescribeConfigurationRecorders>

Returns: a L<Paws::Config::DescribeConfigurationRecordersResponse> instance

  

Returns the name of one or more specified configuration recorders. If
the recorder name is not specified, this action returns the names of
all the configuration recorders associated with the account.

Currently, you can specify only one configuration recorder per account.











=head2 DescribeConfigurationRecorderStatus([ConfigurationRecorderNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Config::DescribeConfigurationRecorderStatus>

Returns: a L<Paws::Config::DescribeConfigurationRecorderStatusResponse> instance

  

Returns the current status of the specified configuration recorder. If
a configuration recorder is not specified, this action returns the
status of all configuration recorder associated with the account.

Currently, you can specify only one configuration recorder per account.











=head2 DescribeDeliveryChannels([DeliveryChannelNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Config::DescribeDeliveryChannels>

Returns: a L<Paws::Config::DescribeDeliveryChannelsResponse> instance

  

Returns details about the specified delivery channel. If a delivery
channel is not specified, this action returns the details of all
delivery channels associated with the account.

Currently, you can specify only one delivery channel per account.











=head2 DescribeDeliveryChannelStatus([DeliveryChannelNames => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::Config::DescribeDeliveryChannelStatus>

Returns: a L<Paws::Config::DescribeDeliveryChannelStatusResponse> instance

  

Returns the current status of the specified delivery channel. If a
delivery channel is not specified, this action returns the current
status of all delivery channels associated with the account.

Currently, you can specify only one delivery channel per account.











=head2 GetResourceConfigHistory(resourceId => Str, resourceType => Str, [chronologicalOrder => Str, earlierTime => Str, laterTime => Str, limit => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::Config::GetResourceConfigHistory>

Returns: a L<Paws::Config::GetResourceConfigHistoryResponse> instance

  

Returns a list of configuration items for the specified resource. The
list contains details about each state of the resource during the
specified time interval. You can specify a C<limit> on the number of
results returned on the page. If a limit is specified, a C<nextToken>
is returned as part of the result that you can use to continue this
request.

Each call to the API is limited to span a duration of seven days. It is
likely that the number of records returned is smaller than the
specified C<limit>. In such cases, you can make another call, using the
C<nextToken> .











=head2 PutConfigurationRecorder(ConfigurationRecorder => Paws::Config::ConfigurationRecorder)

Each argument is described in detail in: L<Paws::Config::PutConfigurationRecorder>

Returns: nothing

  

Creates a new configuration recorder to record the selected resource
configurations.

You can use this action to change the role C<roleARN> and/or the
C<recordingGroup> of an existing recorder. To change the role, call the
action on the existing configuration recorder and specify a role.

Currently, you can specify only one configuration recorder per account.

If C<ConfigurationRecorder> does not have the B<recordingGroup>
parameter specified, the default is to record all supported resource
types.











=head2 PutDeliveryChannel(DeliveryChannel => Paws::Config::DeliveryChannel)

Each argument is described in detail in: L<Paws::Config::PutDeliveryChannel>

Returns: nothing

  

Creates a new delivery channel object to deliver the configuration
information to an Amazon S3 bucket, and to an Amazon SNS topic.

You can use this action to change the Amazon S3 bucket or an Amazon SNS
topic of the existing delivery channel. To change the Amazon S3 bucket
or an Amazon SNS topic, call this action and specify the changed values
for the S3 bucket and the SNS topic. If you specify a different value
for either the S3 bucket or the SNS topic, this action will keep the
existing value for the parameter that is not changed.

Currently, you can specify only one delivery channel per account.











=head2 StartConfigurationRecorder(ConfigurationRecorderName => Str)

Each argument is described in detail in: L<Paws::Config::StartConfigurationRecorder>

Returns: nothing

  

Starts recording configurations of the AWS resources you have selected
to record in your AWS account.

You must have created at least one delivery channel to successfully
start the configuration recorder.











=head2 StopConfigurationRecorder(ConfigurationRecorderName => Str)

Each argument is described in detail in: L<Paws::Config::StopConfigurationRecorder>

Returns: nothing

  

Stops recording configurations of the AWS resources you have selected
to record in your AWS account.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

