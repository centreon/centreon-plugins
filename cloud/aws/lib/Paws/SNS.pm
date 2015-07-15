package Paws::SNS {
  use Moose;
  sub service { 'sns' }
  sub version { '2010-03-31' }
  sub flattened_arrays { 0 }

  with 'Paws::API::Caller', 'Paws::API::RegionalEndpointCaller', 'Paws::Net::V4Signature', 'Paws::Net::QueryCaller', 'Paws::Net::XMLResponse';

  
  sub AddPermission {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::AddPermission', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ConfirmSubscription {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ConfirmSubscription', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePlatformApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::CreatePlatformApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreatePlatformEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::CreatePlatformEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateTopic {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::CreateTopic', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::DeleteEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeletePlatformApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::DeletePlatformApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteTopic {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::DeleteTopic', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetEndpointAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::GetEndpointAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetPlatformApplicationAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::GetPlatformApplicationAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetSubscriptionAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::GetSubscriptionAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub GetTopicAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::GetTopicAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListEndpointsByPlatformApplication {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ListEndpointsByPlatformApplication', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListPlatformApplications {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ListPlatformApplications', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSubscriptions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ListSubscriptions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListSubscriptionsByTopic {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ListSubscriptionsByTopic', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTopics {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::ListTopics', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Publish {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::Publish', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RemovePermission {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::RemovePermission', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetEndpointAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::SetEndpointAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetPlatformApplicationAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::SetPlatformApplicationAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetSubscriptionAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::SetSubscriptionAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SetTopicAttributes {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::SetTopicAttributes', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Subscribe {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::Subscribe', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub Unsubscribe {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::SNS::Unsubscribe', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS - Perl Interface to AWS Amazon Simple Notification Service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('SNS')->new;
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



Amazon Simple Notification Service

Amazon Simple Notification Service (Amazon SNS) is a web service that
enables you to build distributed web-enabled applications. Applications
can use Amazon SNS to easily push real-time notification messages to
interested subscribers over multiple delivery protocols. For more
information about this product see http://aws.amazon.com/sns. For
detailed information about Amazon SNS features and their associated API
calls, see the Amazon SNS Developer Guide.

We also provide SDKs that enable you to access Amazon SNS from your
preferred programming language. The SDKs contain functionality that
automatically takes care of tasks such as: cryptographically signing
your service requests, retrying requests, and handling error responses.
For a list of available SDKs, go to Tools for Amazon Web Services.










=head1 METHODS

=head2 AddPermission(ActionName => ArrayRef[Str], AWSAccountId => ArrayRef[Str], Label => Str, TopicArn => Str)

Each argument is described in detail in: L<Paws::SNS::AddPermission>

Returns: nothing

  

Adds a statement to a topic's access control policy, granting access
for the specified AWS accounts to the specified actions.











=head2 ConfirmSubscription(Token => Str, TopicArn => Str, [AuthenticateOnUnsubscribe => Str])

Each argument is described in detail in: L<Paws::SNS::ConfirmSubscription>

Returns: a L<Paws::SNS::ConfirmSubscriptionResponse> instance

  

Verifies an endpoint owner's intent to receive messages by validating
the token sent to the endpoint by an earlier C<Subscribe> action. If
the token is valid, the action creates a new subscription and returns
its Amazon Resource Name (ARN). This call requires an AWS signature
only when the C<AuthenticateOnUnsubscribe> flag is set to "true".











=head2 CreatePlatformApplication(Attributes => Paws::SNS::MapStringToString, Name => Str, Platform => Str)

Each argument is described in detail in: L<Paws::SNS::CreatePlatformApplication>

Returns: a L<Paws::SNS::CreatePlatformApplicationResponse> instance

  

Creates a platform application object for one of the supported push
notification services, such as APNS and GCM, to which devices and
mobile apps may register. You must specify PlatformPrincipal and
PlatformCredential attributes when using the
C<CreatePlatformApplication> action. The PlatformPrincipal is received
from the notification service. For APNS/APNS_SANDBOX, PlatformPrincipal
is "SSL certificate". For GCM, PlatformPrincipal is not applicable. For
ADM, PlatformPrincipal is "client id". The PlatformCredential is also
received from the notification service. For APNS/APNS_SANDBOX,
PlatformCredential is "private key". For GCM, PlatformCredential is
"API key". For ADM, PlatformCredential is "client secret". The
PlatformApplicationArn that is returned when using
C<CreatePlatformApplication> is then used as an attribute for the
C<CreatePlatformEndpoint> action. For more information, see Using
Amazon SNS Mobile Push Notifications.











=head2 CreatePlatformEndpoint(PlatformApplicationArn => Str, Token => Str, [Attributes => Paws::SNS::MapStringToString, CustomUserData => Str])

Each argument is described in detail in: L<Paws::SNS::CreatePlatformEndpoint>

Returns: a L<Paws::SNS::CreateEndpointResponse> instance

  

Creates an endpoint for a device and mobile app on one of the supported
push notification services, such as GCM and APNS.
C<CreatePlatformEndpoint> requires the PlatformApplicationArn that is
returned from C<CreatePlatformApplication>. The EndpointArn that is
returned when using C<CreatePlatformEndpoint> can then be used by the
C<Publish> action to send a message to a mobile app or by the
C<Subscribe> action for subscription to a topic. The
C<CreatePlatformEndpoint> action is idempotent, so if the requester
already owns an endpoint with the same device token and attributes,
that endpoint's ARN is returned without creating a new endpoint. For
more information, see Using Amazon SNS Mobile Push Notifications.

When using C<CreatePlatformEndpoint> with Baidu, two attributes must be
provided: ChannelId and UserId. The token field must also contain the
ChannelId. For more information, see Creating an Amazon SNS Endpoint
for Baidu.











=head2 CreateTopic(Name => Str)

Each argument is described in detail in: L<Paws::SNS::CreateTopic>

Returns: a L<Paws::SNS::CreateTopicResponse> instance

  

Creates a topic to which notifications can be published. Users can
create at most 3000 topics. For more information, see
http://aws.amazon.com/sns. This action is idempotent, so if the
requester already owns a topic with the specified name, that topic's
ARN is returned without creating a new topic.











=head2 DeleteEndpoint(EndpointArn => Str)

Each argument is described in detail in: L<Paws::SNS::DeleteEndpoint>

Returns: nothing

  

Deletes the endpoint from Amazon SNS. This action is idempotent. For
more information, see Using Amazon SNS Mobile Push Notifications.











=head2 DeletePlatformApplication(PlatformApplicationArn => Str)

Each argument is described in detail in: L<Paws::SNS::DeletePlatformApplication>

Returns: nothing

  

Deletes a platform application object for one of the supported push
notification services, such as APNS and GCM. For more information, see
Using Amazon SNS Mobile Push Notifications.











=head2 DeleteTopic(TopicArn => Str)

Each argument is described in detail in: L<Paws::SNS::DeleteTopic>

Returns: nothing

  

Deletes a topic and all its subscriptions. Deleting a topic might
prevent some messages previously sent to the topic from being delivered
to subscribers. This action is idempotent, so deleting a topic that
does not exist does not result in an error.











=head2 GetEndpointAttributes(EndpointArn => Str)

Each argument is described in detail in: L<Paws::SNS::GetEndpointAttributes>

Returns: a L<Paws::SNS::GetEndpointAttributesResponse> instance

  

Retrieves the endpoint attributes for a device on one of the supported
push notification services, such as GCM and APNS. For more information,
see Using Amazon SNS Mobile Push Notifications.











=head2 GetPlatformApplicationAttributes(PlatformApplicationArn => Str)

Each argument is described in detail in: L<Paws::SNS::GetPlatformApplicationAttributes>

Returns: a L<Paws::SNS::GetPlatformApplicationAttributesResponse> instance

  

Retrieves the attributes of the platform application object for the
supported push notification services, such as APNS and GCM. For more
information, see Using Amazon SNS Mobile Push Notifications.











=head2 GetSubscriptionAttributes(SubscriptionArn => Str)

Each argument is described in detail in: L<Paws::SNS::GetSubscriptionAttributes>

Returns: a L<Paws::SNS::GetSubscriptionAttributesResponse> instance

  

Returns all of the properties of a subscription.











=head2 GetTopicAttributes(TopicArn => Str)

Each argument is described in detail in: L<Paws::SNS::GetTopicAttributes>

Returns: a L<Paws::SNS::GetTopicAttributesResponse> instance

  

Returns all of the properties of a topic. Topic properties returned
might differ based on the authorization of the user.











=head2 ListEndpointsByPlatformApplication(PlatformApplicationArn => Str, [NextToken => Str])

Each argument is described in detail in: L<Paws::SNS::ListEndpointsByPlatformApplication>

Returns: a L<Paws::SNS::ListEndpointsByPlatformApplicationResponse> instance

  

Lists the endpoints and endpoint attributes for devices in a supported
push notification service, such as GCM and APNS. The results for
C<ListEndpointsByPlatformApplication> are paginated and return a
limited list of endpoints, up to 100. If additional records are
available after the first page results, then a NextToken string will be
returned. To receive the next page, you call
C<ListEndpointsByPlatformApplication> again using the NextToken string
received from the previous call. When there are no more records to
return, NextToken will be null. For more information, see Using Amazon
SNS Mobile Push Notifications.











=head2 ListPlatformApplications([NextToken => Str])

Each argument is described in detail in: L<Paws::SNS::ListPlatformApplications>

Returns: a L<Paws::SNS::ListPlatformApplicationsResponse> instance

  

Lists the platform application objects for the supported push
notification services, such as APNS and GCM. The results for
C<ListPlatformApplications> are paginated and return a limited list of
applications, up to 100. If additional records are available after the
first page results, then a NextToken string will be returned. To
receive the next page, you call C<ListPlatformApplications> using the
NextToken string received from the previous call. When there are no
more records to return, NextToken will be null. For more information,
see Using Amazon SNS Mobile Push Notifications.











=head2 ListSubscriptions([NextToken => Str])

Each argument is described in detail in: L<Paws::SNS::ListSubscriptions>

Returns: a L<Paws::SNS::ListSubscriptionsResponse> instance

  

Returns a list of the requester's subscriptions. Each call returns a
limited list of subscriptions, up to 100. If there are more
subscriptions, a C<NextToken> is also returned. Use the C<NextToken>
parameter in a new C<ListSubscriptions> call to get further results.











=head2 ListSubscriptionsByTopic(TopicArn => Str, [NextToken => Str])

Each argument is described in detail in: L<Paws::SNS::ListSubscriptionsByTopic>

Returns: a L<Paws::SNS::ListSubscriptionsByTopicResponse> instance

  

Returns a list of the subscriptions to a specific topic. Each call
returns a limited list of subscriptions, up to 100. If there are more
subscriptions, a C<NextToken> is also returned. Use the C<NextToken>
parameter in a new C<ListSubscriptionsByTopic> call to get further
results.











=head2 ListTopics([NextToken => Str])

Each argument is described in detail in: L<Paws::SNS::ListTopics>

Returns: a L<Paws::SNS::ListTopicsResponse> instance

  

Returns a list of the requester's topics. Each call returns a limited
list of topics, up to 100. If there are more topics, a C<NextToken> is
also returned. Use the C<NextToken> parameter in a new C<ListTopics>
call to get further results.











=head2 Publish(Message => Str, [MessageAttributes => Paws::SNS::MessageAttributeMap, MessageStructure => Str, Subject => Str, TargetArn => Str, TopicArn => Str])

Each argument is described in detail in: L<Paws::SNS::Publish>

Returns: a L<Paws::SNS::PublishResponse> instance

  

Sends a message to all of a topic's subscribed endpoints. When a
C<messageId> is returned, the message has been saved and Amazon SNS
will attempt to deliver it to the topic's subscribers shortly. The
format of the outgoing message to each subscribed endpoint depends on
the notification protocol selected.

To use the C<Publish> action for sending a message to a mobile
endpoint, such as an app on a Kindle device or mobile phone, you must
specify the EndpointArn. The EndpointArn is returned when making a call
with the C<CreatePlatformEndpoint> action. The second example below
shows a request and response for publishing to a mobile endpoint.











=head2 RemovePermission(Label => Str, TopicArn => Str)

Each argument is described in detail in: L<Paws::SNS::RemovePermission>

Returns: nothing

  

Removes a statement from a topic's access control policy.











=head2 SetEndpointAttributes(Attributes => Paws::SNS::MapStringToString, EndpointArn => Str)

Each argument is described in detail in: L<Paws::SNS::SetEndpointAttributes>

Returns: nothing

  

Sets the attributes for an endpoint for a device on one of the
supported push notification services, such as GCM and APNS. For more
information, see Using Amazon SNS Mobile Push Notifications.











=head2 SetPlatformApplicationAttributes(Attributes => Paws::SNS::MapStringToString, PlatformApplicationArn => Str)

Each argument is described in detail in: L<Paws::SNS::SetPlatformApplicationAttributes>

Returns: nothing

  

Sets the attributes of the platform application object for the
supported push notification services, such as APNS and GCM. For more
information, see Using Amazon SNS Mobile Push Notifications.











=head2 SetSubscriptionAttributes(AttributeName => Str, SubscriptionArn => Str, [AttributeValue => Str])

Each argument is described in detail in: L<Paws::SNS::SetSubscriptionAttributes>

Returns: nothing

  

Allows a subscription owner to set an attribute of the topic to a new
value.











=head2 SetTopicAttributes(AttributeName => Str, TopicArn => Str, [AttributeValue => Str])

Each argument is described in detail in: L<Paws::SNS::SetTopicAttributes>

Returns: nothing

  

Allows a topic owner to set an attribute of the topic to a new value.











=head2 Subscribe(Protocol => Str, TopicArn => Str, [Endpoint => Str])

Each argument is described in detail in: L<Paws::SNS::Subscribe>

Returns: a L<Paws::SNS::SubscribeResponse> instance

  

Prepares to subscribe an endpoint by sending the endpoint a
confirmation message. To actually create a subscription, the endpoint
owner must call the C<ConfirmSubscription> action with the token from
the confirmation message. Confirmation tokens are valid for three days.











=head2 Unsubscribe(SubscriptionArn => Str)

Each argument is described in detail in: L<Paws::SNS::Unsubscribe>

Returns: nothing

  

Deletes a subscription. If the subscription requires authentication for
deletion, only the owner of the subscription or the topic's owner can
unsubscribe, and an AWS signature is required. If the C<Unsubscribe>
call does not require authentication and the requester is not the
subscription owner, a final cancellation message is delivered to the
endpoint, so that the endpoint owner can easily resubscribe to the
topic if the C<Unsubscribe> request was unintended.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

