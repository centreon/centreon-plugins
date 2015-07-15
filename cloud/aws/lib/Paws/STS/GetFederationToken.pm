
package Paws::STS::GetFederationToken {
  use Moose;
  has DurationSeconds => (is => 'ro', isa => 'Int');
  has Name => (is => 'ro', isa => 'Str', required => 1);
  has Policy => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'GetFederationToken');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::STS::GetFederationTokenResponse');
  class_has _result_key => (isa => 'Str', is => 'ro', default => 'GetFederationTokenResult');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::STS::GetFederationToken - Arguments for method GetFederationToken on Paws::STS

=head1 DESCRIPTION

This class represents the parameters used for calling the method GetFederationToken on the 
AWS Security Token Service service. Use the attributes of this class
as arguments to method GetFederationToken.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to GetFederationToken.

As an example:

  $service_obj->GetFederationToken(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 DurationSeconds => Int

  

The duration, in seconds, that the session should last. Acceptable
durations for federation sessions range from 900 seconds (15 minutes)
to 129600 seconds (36 hours), with 43200 seconds (12 hours) as the
default. Sessions obtained using AWS account (root) credentials are
restricted to a maximum of 3600 seconds (one hour). If the specified
duration is longer than one hour, the session obtained by using AWS
account (root) credentials defaults to one hour.










=head2 B<REQUIRED> Name => Str

  

The name of the federated user. The name is used as an identifier for
the temporary security credentials (such as C<Bob>). For example, you
can reference the federated user name in a resource-based policy, such
as in an Amazon S3 bucket policy.










=head2 Policy => Str

  

An IAM policy in JSON format that is passed with the
C<GetFederationToken> call and evaluated along with the policy or
policies that are attached to the IAM user whose credentials are used
to call C<GetFederationToken>. The passed policy is used to scope down
the permissions that are available to the IAM user, by allowing only a
subset of the permissions that are granted to the IAM user. The passed
policy cannot grant more permissions than those granted to the IAM
user. The final permissions for the federated user are the most
restrictive set based on the intersection of the passed policy and the
IAM user policy.

If you do not pass a policy, the resulting temporary security
credentials have no effective permissions. The only exception is when
the temporary security credentials are used to access a resource that
has a resource-based policy that specifically allows the federated user
to access the resource.

For more information about how permissions work, see Permissions for
GetFederationToken in I<Using Temporary Security Credentials>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method GetFederationToken in L<Paws::STS>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

