
package Paws::IAM::CreatePolicyVersion {
  use Moose;
  has PolicyArn => (is => 'ro', isa => 'Str', required => 1);
  has PolicyDocument => (is => 'ro', isa => 'Str', required => 1);
  has SetAsDefault => (is => 'ro', isa => 'Bool');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreatePolicyVersion');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::CreatePolicyVersionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'CreatePolicyVersionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::CreatePolicyVersion - Arguments for method CreatePolicyVersion on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreatePolicyVersion on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method CreatePolicyVersion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreatePolicyVersion.

As an example:

  $service_obj->CreatePolicyVersion(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> PolicyArn => Str

  

=head2 B<REQUIRED> PolicyDocument => Str

  

The policy document.










=head2 SetAsDefault => Bool

  

Specifies whether to set this version as the policy's default version.

When this parameter is C<true>, the new policy version becomes the
operative version; that is, the version that is in effect for the IAM
users, groups, and roles that the policy is attached to.

For more information about managed policy versions, see Versioning for
Managed Policies in the I<Using IAM> guide.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreatePolicyVersion in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

