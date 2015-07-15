
package Paws::IAM::GetPolicyVersion {
  use Moose;
  has PolicyArn => (is => 'ro', isa => 'Str', required => 1);
  has VersionId => (is => 'ro', isa => 'Str', required => 1);

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetPolicyVersion');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::IAM::GetPolicyVersionResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetPolicyVersionResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::IAM::GetPolicyVersion - Arguments for method GetPolicyVersion on Paws::IAM

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetPolicyVersion on the 
AWS Identity and Access Management service. Use the attributes of this class
as arguments to method GetPolicyVersion.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetPolicyVersion.

As an example:

  $service_obj->GetPolicyVersion(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> PolicyArn => Str

  

=head2 B<REQUIRED> VersionId => Str

  

Identifies the policy version to retrieve.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetPolicyVersion in L<Paws::IAM>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

