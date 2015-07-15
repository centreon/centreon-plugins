
package Paws::Lambda::RemovePermission {
  use Moose;
  has FunctionName => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'FunctionName' , required => 1);
  has StatementId => (is => 'ro', isa => 'Str', traits => ['ParamInURI'], uri_name => 'StatementId' , required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'RemovePermission');
  class_has _api_uri  => (isa => 'Str', is => 'ro', default => '/2015-03-31/functions/{FunctionName}/versions/HEAD/policy/{StatementId}');
  class_has _api_method  => (isa => 'Str', is => 'ro', default => 'DELETE');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::Lambda::RemovePermission - Arguments for method RemovePermission on Paws::Lambda

=head1 DESCRIPTION

This class represents the parameters used for calling the method RemovePermission on the 
AWS Lambda service. Use the attributes of this class
as arguments to method RemovePermission.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to RemovePermission.

As an example:

  $service_obj->RemovePermission(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> FunctionName => Str

  

Lambda function whose access policy you want to remove a permission
from.

You can specify an unqualified function name (for example, "Thumbnail")
or you can specify Amazon Resource Name (ARN) of the function (for
example, "arn:aws:lambda:us-west-2:account-id:function:ThumbNail"). AWS
Lambda also allows you to specify only the account ID qualifier (for
example, "account-id:Thumbnail"). Note that the length constraint
applies only to the ARN. If you specify only the function name, it is
limited to 64 character in length.










=head2 B<REQUIRED> StatementId => Str

  

Statement ID of the permission to remove.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method RemovePermission in L<Paws::Lambda>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

