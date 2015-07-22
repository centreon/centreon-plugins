
package Paws::SES::SetIdentityNotificationTopic {
  use Moose;
  has Identity => (is => 'ro', isa => 'Str', required => 1);
  has NotificationType => (is => 'ro', isa => 'Str', required => 1);
  has SnsTopic => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetIdentityNotificationTopic');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::SES::SetIdentityNotificationTopicResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'SetIdentityNotificationTopicResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SES::SetIdentityNotificationTopic - Arguments for method SetIdentityNotificationTopic on Paws::SES

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetIdentityNotificationTopic on the 
Amazon Simple Email Service service. Use the attributes of this class
as arguments to method SetIdentityNotificationTopic.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetIdentityNotificationTopic.

As an example:

  $service_obj->SetIdentityNotificationTopic(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Identity => Str

  

The identity for which the Amazon SNS topic will be set. You can
specify an identity by using its name or by using its Amazon Resource
Name (ARN). Examples: C<user@example.com>, C<example.com>,
C<arn:aws:ses:us-east-1:123456789012:identity/example.com>.










=head2 B<REQUIRED> NotificationType => Str

  

The type of notifications that will be published to the specified
Amazon SNS topic.










=head2 SnsTopic => Str

  

The Amazon Resource Name (ARN) of the Amazon SNS topic. If the
parameter is omitted from the request or a null value is passed,
C<SnsTopic> is cleared and publishing is disabled.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetIdentityNotificationTopic in L<Paws::SES>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

