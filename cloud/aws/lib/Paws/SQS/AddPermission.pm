
package Paws::SQS::AddPermission {
  use Moose;
  has Actions => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has AWSAccountIds => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Label => (is => 'ro', isa => 'Str', required => 1);
  has QueueUrl => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddPermission');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SQS::AddPermission - Arguments for method AddPermission on Paws::SQS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddPermission on the 
Amazon Simple Queue Service service. Use the attributes of this class
as arguments to method AddPermission.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddPermission.

As an example:

  $service_obj->AddPermission(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> Actions => ArrayRef[Str]

  

The action the client wants to allow for the specified principal. The
following are valid values: C<* | SendMessage | ReceiveMessage |
DeleteMessage | ChangeMessageVisibility | GetQueueAttributes |
GetQueueUrl>. For more information about these actions, see
Understanding Permissions in the I<Amazon SQS Developer Guide>.

Specifying C<SendMessage>, C<DeleteMessage>, or
C<ChangeMessageVisibility> for the C<ActionName.n> also grants
permissions for the corresponding batch versions of those actions:
C<SendMessageBatch>, C<DeleteMessageBatch>, and
C<ChangeMessageVisibilityBatch>.










=head2 B<REQUIRED> AWSAccountIds => ArrayRef[Str]

  

The AWS account number of the principal who will be given permission.
The principal must have an AWS account, but does not need to be signed
up for Amazon SQS. For information about locating the AWS account
identification, see Your AWS Identifiers in the I<Amazon SQS Developer
Guide>.










=head2 B<REQUIRED> Label => Str

  

The unique identification of the permission you're setting (e.g.,
C<AliceSendMessage>). Constraints: Maximum 80 characters; alphanumeric
characters, hyphens (-), and underscores (_) are allowed.










=head2 B<REQUIRED> QueueUrl => Str

  

The URL of the Amazon SQS queue to take action on.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddPermission in L<Paws::SQS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

