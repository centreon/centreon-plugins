
package Paws::ElasticBeanstalk::EnvironmentDescription {
  use Moose;
  has AbortableOperationInProgress => (is => 'ro', isa => 'Bool');
  has ApplicationName => (is => 'ro', isa => 'Str');
  has CNAME => (is => 'ro', isa => 'Str');
  has DateCreated => (is => 'ro', isa => 'Str');
  has DateUpdated => (is => 'ro', isa => 'Str');
  has Description => (is => 'ro', isa => 'Str');
  has EndpointURL => (is => 'ro', isa => 'Str');
  has EnvironmentId => (is => 'ro', isa => 'Str');
  has EnvironmentName => (is => 'ro', isa => 'Str');
  has Health => (is => 'ro', isa => 'Str');
  has Resources => (is => 'ro', isa => 'Paws::ElasticBeanstalk::EnvironmentResourcesDescription');
  has SolutionStackName => (is => 'ro', isa => 'Str');
  has Status => (is => 'ro', isa => 'Str');
  has TemplateName => (is => 'ro', isa => 'Str');
  has Tier => (is => 'ro', isa => 'Paws::ElasticBeanstalk::EnvironmentTier');
  has VersionLabel => (is => 'ro', isa => 'Str');

}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ElasticBeanstalk::EnvironmentDescription

=head1 ATTRIBUTES

=head2 AbortableOperationInProgress => Bool

  

Indicates if there is an in-progress environment configuration update
or application version deployment that you can cancel.

C<true:> There is an update in progress.

C<false:> There are no updates currently in progress.









=head2 ApplicationName => Str

  

The name of the application associated with this environment.









=head2 CNAME => Str

  

The URL to the CNAME for this environment.









=head2 DateCreated => Str

  

The creation date for this environment.









=head2 DateUpdated => Str

  

The last modified date for this environment.









=head2 Description => Str

  

Describes this environment.









=head2 EndpointURL => Str

  

For load-balanced, autoscaling environments, the URL to the
LoadBalancer. For single-instance environments, the IP address of the
instance.









=head2 EnvironmentId => Str

  

The ID of this environment.









=head2 EnvironmentName => Str

  

The name of this environment.









=head2 Health => Str

  

Describes the health status of the environment. AWS Elastic Beanstalk
indicates the failure levels for a running environment:

C<Red> : Indicates the environment is not working.

C<Yellow>: Indicates that something is wrong, the application might not
be available, but the instances appear running.

C<Green>: Indicates the environment is healthy and fully functional.

=over

=item * C<Red>: Indicates the environment is not responsive. Occurs
when three or more consecutive failures occur for an environment.

=item * C<Yellow>: Indicates that something is wrong. Occurs when two
consecutive failures occur for an environment.

=item * C<Green>: Indicates the environment is healthy and fully
functional.

=item * C<Grey>: Default health for a new environment. The environment
is not fully launched and health checks have not started or health
checks are suspended during an C<UpdateEnvironment> or
C<RestartEnvironement> request.

=back

Default: C<Grey>









=head2 Resources => Paws::ElasticBeanstalk::EnvironmentResourcesDescription

  

The description of the AWS resources used by this environment.









=head2 SolutionStackName => Str

  

The name of the C<SolutionStack> deployed with this environment.









=head2 Status => Str

  

The current operational status of the environment:

=over

=item * C<Launching>: Environment is in the process of initial
deployment.

=item * C<Updating>: Environment is in the process of updating its
configuration settings or application version.

=item * C<Ready>: Environment is available to have an action performed
on it, such as update or terminate.

=item * C<Terminating>: Environment is in the shut-down process.

=item * C<Terminated>: Environment is not running.

=back









=head2 TemplateName => Str

  

The name of the configuration template used to originally launch this
environment.









=head2 Tier => Paws::ElasticBeanstalk::EnvironmentTier

  

Describes the current tier of this environment.









=head2 VersionLabel => Str

  

The application version deployed in this environment.











=cut

