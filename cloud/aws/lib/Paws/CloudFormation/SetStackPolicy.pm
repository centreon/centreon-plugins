
package Paws::CloudFormation::SetStackPolicy {
  use Moose;
  has StackName => (is => 'ro', isa => 'Str', required => 1);
  has StackPolicyBody => (is => 'ro', isa => 'Str');
  has StackPolicyURL => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'SetStackPolicy');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CloudFormation::SetStackPolicy - Arguments for method SetStackPolicy on Paws::CloudFormation

=head1 DESCRIPTION

This class represents the parameters used for calling the method SetStackPolicy on the 
AWS CloudFormation service. Use the attributes of this class
as arguments to method SetStackPolicy.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to SetStackPolicy.

As an example:

  $service_obj->SetStackPolicy(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> StackName => Str

  

The name or unique stack ID that you want to associate a policy with.










=head2 StackPolicyBody => Str

  

Structure containing the stack policy body. For more information, go to
Prevent Updates to Stack Resources in the AWS CloudFormation User
Guide. You can specify either the C<StackPolicyBody> or the
C<StackPolicyURL> parameter, but not both.










=head2 StackPolicyURL => Str

  

Location of a file containing the stack policy. The URL must point to a
policy (max size: 16KB) located in an S3 bucket in the same region as
the stack. You can specify either the C<StackPolicyBody> or the
C<StackPolicyURL> parameter, but not both.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method SetStackPolicy in L<Paws::CloudFormation>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

