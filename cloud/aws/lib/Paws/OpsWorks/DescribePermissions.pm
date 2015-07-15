
package Paws::OpsWorks::DescribePermissions {
  use Moose;
  has IamUserArn => (is => 'ro', isa => 'Str');
  has StackId => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'DescribePermissions');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::OpsWorks::DescribePermissionsResult');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::OpsWorks::DescribePermissions - Arguments for method DescribePermissions on Paws::OpsWorks

=head1 DESCRIPTION

This class represents the parameters used for calling the method DescribePermissions on the 
AWS OpsWorks service. Use the attributes of this class
as arguments to method DescribePermissions.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to DescribePermissions.

As an example:

  $service_obj->DescribePermissions(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 IamUserArn => Str

  

The user's IAM ARN. For more information about IAM ARNs, see Using
Identifiers.










=head2 StackId => Str

  

The stack ID.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method DescribePermissions in L<Paws::OpsWorks>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

