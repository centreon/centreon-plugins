
package Paws::AutoScaling::CreateAutoScalingGroup {
  use Moose;
  has AutoScalingGroupName => (is => 'ro', isa => 'Str', required => 1);
  has AvailabilityZones => (is => 'ro', isa => 'ArrayRef[Str]');
  has DefaultCooldown => (is => 'ro', isa => 'Int');
  has DesiredCapacity => (is => 'ro', isa => 'Int');
  has HealthCheckGracePeriod => (is => 'ro', isa => 'Int');
  has HealthCheckType => (is => 'ro', isa => 'Str');
  has InstanceId => (is => 'ro', isa => 'Str');
  has LaunchConfigurationName => (is => 'ro', isa => 'Str');
  has LoadBalancerNames => (is => 'ro', isa => 'ArrayRef[Str]');
  has MaxSize => (is => 'ro', isa => 'Int', required => 1);
  has MinSize => (is => 'ro', isa => 'Int', required => 1);
  has PlacementGroup => (is => 'ro', isa => 'Str');
  has Tags => (is => 'ro', isa => 'ArrayRef[Paws::AutoScaling::Tag]');
  has TerminationPolicies => (is => 'ro', isa => 'ArrayRef[Str]');
  has VPCZoneIdentifier => (is => 'ro', isa => 'Str');

  use MooseX::ClassAttribute;

  class_has _api_call => (isa => 'Str', is => 'ro', default => 'CreateAutoScalingGroup');
  class_has _returns => (isa => 'Str', is => 'ro');
  class_has _result_key => (isa => 'Str', is => 'ro');
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::AutoScaling::CreateAutoScalingGroup - Arguments for method CreateAutoScalingGroup on Paws::AutoScaling

=head1 DESCRIPTION

This class represents the parameters used for calling the method CreateAutoScalingGroup on the 
Auto Scaling service. Use the attributes of this class
as arguments to method CreateAutoScalingGroup.

You shouln't make instances of this class. Each attribute should be used as a named argument in the call to CreateAutoScalingGroup.

As an example:

  $service_obj->CreateAutoScalingGroup(Att1 => $value1, Att2 => $value2, ...);

Values for attributes that are native types (Int, String, Float, etc) can passed as-is (scalar values). Values for complex Types (objects) can be passed as a HashRef. The keys and values of the hashref will be used to instance the underlying object.

=head1 ATTRIBUTES

=head2 B<REQUIRED> AutoScalingGroupName => Str

  

The name of the group. This name must be unique within the scope of
your AWS account.










=head2 AvailabilityZones => ArrayRef[Str]

  

One or more Availability Zones for the group. This parameter is
optional if you specify subnets using the C<VPCZoneIdentifier>
parameter.










=head2 DefaultCooldown => Int

  

The amount of time, in seconds, after a scaling activity completes
before another scaling activity can start.

If C<DefaultCooldown> is not specified, the default value is 300. For
more information, see Understanding Auto Scaling Cooldowns in the
I<Auto Scaling Developer Guide>.










=head2 DesiredCapacity => Int

  

The number of EC2 instances that should be running in the group. This
value must be greater than or equal to the minimum size of the group
and less than or equal to the maximum size of the group.










=head2 HealthCheckGracePeriod => Int

  

The amount of time, in seconds, after an EC2 instance comes into
service that Auto Scaling starts checking its health. During this time,
any health check failures for the instance are ignored.

This parameter is required if you are adding an C<ELB> health check.
Frequently, new instances need to warm up, briefly, before they can
pass a health check. To provide ample warm-up time, set the health
check grace period of the group to match the expected startup period of
your application.

For more information, see Add an Elastic Load Balancing Health Check to
Your Auto Scaling Group in the I<Auto Scaling Developer Guide>.










=head2 HealthCheckType => Str

  

The service to use for the health checks. The valid values are C<EC2>
and C<ELB>.

By default, health checks use Amazon EC2 instance status checks to
determine the health of an instance. For more information, see Health
Checks.










=head2 InstanceId => Str

  

The ID of the EC2 instance used to create a launch configuration for
the group. Alternatively, use the C<LaunchConfigurationName> parameter
to specify a launch configuration instead of an EC2 instance.

When you specify an ID of an instance, Auto Scaling creates a new
launch configuration and associates it with the group. This launch
configuration derives its attributes from the specified instance, with
the exception of the block device mapping.

For more information, see Create an Auto Scaling Group from an EC2
Instance in the I<Auto Scaling Developer Guide>.










=head2 LaunchConfigurationName => Str

  

The name of the launch configuration. Alternatively, use the
C<InstanceId> parameter to specify an EC2 instance instead of a launch
configuration.










=head2 LoadBalancerNames => ArrayRef[Str]

  

One or more load balancers.

For more information, see Load Balance Your Auto Scaling Group in the
I<Auto Scaling Developer Guide>.










=head2 B<REQUIRED> MaxSize => Int

  

The maximum size of the group.










=head2 B<REQUIRED> MinSize => Int

  

The minimum size of the group.










=head2 PlacementGroup => Str

  

The name of the placement group into which you'll launch your
instances, if any. For more information, see Placement Groups in the
I<Amazon Elastic Compute Cloud User Guide>.










=head2 Tags => ArrayRef[Paws::AutoScaling::Tag]

  

The tag to be created or updated. Each tag should be defined by its
resource type, resource ID, key, value, and a propagate flag. Valid
values: key=I<value>, value=I<value>, propagate=I<true> or I<false>.
Value and propagate are optional parameters.

For more information, see Tagging Auto Scaling Groups and Instances in
the I<Auto Scaling Developer Guide>.










=head2 TerminationPolicies => ArrayRef[Str]

  

One or more termination policies used to select the instance to
terminate. These policies are executed in the order that they are
listed.

For more information, see Choosing a Termination Policy for Your Auto
Scaling Group in the I<Auto Scaling Developer Guide>.










=head2 VPCZoneIdentifier => Str

  

A comma-separated list of subnet identifiers for your virtual private
cloud (VPC).

If you specify subnets and Availability Zones with this call, ensure
that the subnets' Availability Zones match the Availability Zones
specified.

For more information, see Auto Scaling and Amazon Virtual Private Cloud
in the I<Auto Scaling Developer Guide>.












=head1 SEE ALSO

This class forms part of L<Paws>, documenting arguments for method CreateAutoScalingGroup in L<Paws::AutoScaling>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

