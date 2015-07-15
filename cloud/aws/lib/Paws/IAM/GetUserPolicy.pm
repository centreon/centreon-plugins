
package Paws::IAM::GetUserPolicy {
  use Moose;
  has PolicyName => (is => 'ro', isa => 'Str', required => 1);
  has UserName => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetUserPolicy');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::GetUserPolicyResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetUserPolicyResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetUserPolicy - Arguments for method GetUserPolicy on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetUserPolicy on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method GetUserPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetUserPolicy.

As an example:

  $service_obj->GetUserPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> PolicyName => Str

  

The name of the policy document to get.










=head2 B<REQUIRED> UserName => Str

  

The name of the user who the policy is associated with.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetUserPolicy in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

