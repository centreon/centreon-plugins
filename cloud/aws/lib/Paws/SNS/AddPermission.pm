
package Paws::SNS::AddPermission {
  use Moose;
  has ActionName => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has AWSAccountId => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);
  has Label => (is => 'ro', isa => 'Str', required => 1);
  has TopicArn => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'AddPermission');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::SNS::AddPermission - Arguments for method AddPermission on Paws::SNS

=head1 DESCRIPTION

This class represents the parameters used for calling the method AddPermission on the 
Amazon Simple Notification Service service. Use the attributes of this class
as arguments to method AddPermission.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to AddPermission.

As an example:

  $service_obj->AddPermission(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> ActionName => ArrayRef[Str]

  

The action you want to allow for the specified principal(s).

Valid values: any Amazon SNS action name.










=head2 B<REQUIRED> AWSAccountId => ArrayRef[Str]

  

The AWS account IDs of the users (principals) who will be given access
to the specified actions. The users must have AWS accounts, but do not
need to be signed up for this service.










=head2 B<REQUIRED> Label => Str

  

A unique identifier for the new policy statement.










=head2 B<REQUIRED> TopicArn => Str

  

The ARN of the topic whose access control policy you wish to modify.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method AddPermission in L<Paws::SNS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

