
package Paws::CodeDeploy::ListDeployments {
  use Moose;
  has applicationName => (is => 'ro', isa => 'Str');
  has createTimeRange => (is => 'ro', isa => 'Paws::CodeDeploy::TimeRange');
  has deploymentGroupName => (is => 'ro', isa => 'Str');
  has includeOnlyStatuses => (is => 'ro', isa => 'ArrayRef[Str]');
  has nextToken => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'ListDeployments');
  class_has _returns => (isa => 'Str', is => 'ro', default => 'Paws::CodeDeploy::ListDeploymentsOutput');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::CodeDeploy::ListDeployments - Arguments for method ListDeployments on Paws::CodeDeploy

=head1 DESCRIPTION

This class represents the parameters used for calling the method ListDeployments on the 
AWS CodeDeploy service. Use the attributes of this class
as arguments to method ListDeployments.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to ListDeployments.

As an example:

  $service_obj->ListDeployments(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 applicationName => Str

  

The name of an existing AWS CodeDeploy application associated with the
applicable IAM user or AWS account.










=head2 createTimeRange => Paws::CodeDeploy::TimeRange

  

A deployment creation start- and end-time range for returning a subset
of the list of deployments.










=head2 deploymentGroupName => Str

  

The name of an existing deployment group for the specified application.










=head2 includeOnlyStatuses => ArrayRef[Str]

  

A subset of deployments to list, by status:

=over

=item * Created: Include in the resulting list created deployments.

=item * Queued: Include in the resulting list queued deployments.

=item * In Progress: Include in the resulting list in-progress
deployments.

=item * Succeeded: Include in the resulting list succeeded deployments.

=item * Failed: Include in the resulting list failed deployments.

=item * Aborted: Include in the resulting list aborted deployments.

=back










=head2 nextToken => Str

  

An identifier that was returned from the previous list deployments
call, which can be used to return the next set of deployments in the
list.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method ListDeployments in L<Paws::CodeDeploy>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

