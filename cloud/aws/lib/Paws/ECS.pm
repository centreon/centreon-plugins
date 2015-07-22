package Paws::ECS {
  use Moose;
  sub service { 'ecs' }
  sub version { '2014-11-13' }
  sub target_prefix { 'AmazonEC2ContainerServiceV20141113' }
  sub json_version { "1.1" }

  with 'Paws::API::Caller', 'Paws::API::EndpointResolver', 'Paws::Net::V4Signature', 'Paws::Net::JsonCaller', 'Paws::Net::JsonResponse';

  
  sub CreateCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::CreateCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub CreateService {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::CreateService', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteCluster {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DeleteCluster', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeleteService {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DeleteService', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterContainerInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DeregisterContainerInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DeregisterTaskDefinition {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DeregisterTaskDefinition', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeClusters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DescribeClusters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeContainerInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DescribeContainerInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeServices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DescribeServices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTaskDefinition {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DescribeTaskDefinition', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DescribeTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DescribeTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub DiscoverPollEndpoint {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::DiscoverPollEndpoint', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListClusters {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListClusters', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListContainerInstances {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListContainerInstances', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListServices {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListServices', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTaskDefinitionFamilies {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListTaskDefinitionFamilies', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTaskDefinitions {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListTaskDefinitions', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub ListTasks {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::ListTasks', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterContainerInstance {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::RegisterContainerInstance', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RegisterTaskDefinition {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::RegisterTaskDefinition', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub RunTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::RunTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StartTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::StartTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub StopTask {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::StopTask', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SubmitContainerStateChange {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::SubmitContainerStateChange', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub SubmitTaskStateChange {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::SubmitTaskStateChange', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateContainerAgent {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::UpdateContainerAgent', @_);
    return $self->caller->do_call($self, $call_object);
  }
  sub UpdateService {
    my $self = shift;
    my $call_object = $self->new_with_coercions('Paws::ECS::UpdateService', @_);
    return $self->caller->do_call($self, $call_object);
  }
}
1;

### main pod documentation begin ###

=head1 NAME

Paws::ECS - Perl Interface to AWS Amazon EC2 Container Service

=head1 SYNOPSIS

  use Paws;

  my $obj = Paws->service('ECS')->new;
  my $res = $obj->Method(
    Arg1 => $val1,
    Arg2 => [ 'V1', 'V2' ],
    # if Arg3 is an object, the HashRef will be used as arguments to the constructor
    # of the arguments type
    Arg3 => { Att1 => 'Val1' },
    # if Arg4 is an array of objects, the HashRefs will be passed as arguments to
    # the constructor of the arguments type
    Arg4 => [ { Att1 => 'Val1'  }, { Att1 => 'Val2' } ],
  );

=head1 DESCRIPTION



Amazon EC2 Container Service (Amazon ECS) is a highly scalable, fast,
container management service that makes it easy to run, stop, and
manage Docker containers on a cluster of Amazon EC2 instances. Amazon
ECS lets you launch and stop container-enabled applications with simple
API calls, allows you to get the state of your cluster from a
centralized service, and gives you access to many familiar Amazon EC2
features like security groups, Amazon EBS volumes, and IAM roles.

You can use Amazon ECS to schedule the placement of containers across
your cluster based on your resource needs, isolation policies, and
availability requirements. Amazon EC2 Container Service eliminates the
need for you to operate your own cluster management and configuration
management systems or worry about scaling your management
infrastructure.










=head1 METHODS

=head2 CreateCluster([clusterName => Str])

Each argument is described in detail in: L<Paws::ECS::CreateCluster>

Returns: a L<Paws::ECS::CreateClusterResponse> instance

  

Creates a new Amazon ECS cluster. By default, your account will receive
a C<default> cluster when you launch your first container instance.
However, you can create your own cluster with a unique name with the
C<CreateCluster> action.











=head2 CreateService(desiredCount => Int, serviceName => Str, taskDefinition => Str, [clientToken => Str, cluster => Str, loadBalancers => ArrayRef[Paws::ECS::LoadBalancer], role => Str])

Each argument is described in detail in: L<Paws::ECS::CreateService>

Returns: a L<Paws::ECS::CreateServiceResponse> instance

  

Runs and maintains a desired number of tasks from a specified task
definition. If the number of tasks running in a service drops below
C<desiredCount>, Amazon ECS will spawn another instantiation of the
task in the specified cluster.











=head2 DeleteCluster(cluster => Str)

Each argument is described in detail in: L<Paws::ECS::DeleteCluster>

Returns: a L<Paws::ECS::DeleteClusterResponse> instance

  

Deletes the specified cluster. You must deregister all container
instances from this cluster before you may delete it. You can list the
container instances in a cluster with ListContainerInstances and
deregister them with DeregisterContainerInstance.











=head2 DeleteService(service => Str, [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::DeleteService>

Returns: a L<Paws::ECS::DeleteServiceResponse> instance

  

Deletes a specified service within a cluster.











=head2 DeregisterContainerInstance(containerInstance => Str, [cluster => Str, force => Bool])

Each argument is described in detail in: L<Paws::ECS::DeregisterContainerInstance>

Returns: a L<Paws::ECS::DeregisterContainerInstanceResponse> instance

  

Deregisters an Amazon ECS container instance from the specified
cluster. This instance will no longer be available to run tasks.

If you intend to use the container instance for some other purpose
after deregistration, you should stop all of the tasks running on the
container instance before deregistration to avoid any orphaned tasks
from consuming resources.

Deregistering a container instance removes the instance from a cluster,
but it does not terminate the EC2 instance; if you are finished using
the instance, be sure to terminate it in the Amazon EC2 console to stop
billing.

When you terminate a container instance, it is automatically
deregistered from your cluster.











=head2 DeregisterTaskDefinition(taskDefinition => Str)

Each argument is described in detail in: L<Paws::ECS::DeregisterTaskDefinition>

Returns: a L<Paws::ECS::DeregisterTaskDefinitionResponse> instance

  

Deregisters the specified task definition by family and revision. Upon
deregistration, the task definition is marked as C<INACTIVE>. Existing
tasks and services that reference an C<INACTIVE> task definition
continue to run without disruption. Existing services that reference an
C<INACTIVE> task definition can still scale up or down by modifying the
service's desired count.

You cannot use an C<INACTIVE> task definition to run new tasks or
create new services, and you cannot update an existing service to
reference an C<INACTIVE> task definition (although there may be up to a
10 minute window following deregistration where these restrictions have
not yet taken effect).











=head2 DescribeClusters([clusters => ArrayRef[Str]])

Each argument is described in detail in: L<Paws::ECS::DescribeClusters>

Returns: a L<Paws::ECS::DescribeClustersResponse> instance

  

Describes one or more of your clusters.











=head2 DescribeContainerInstances(containerInstances => ArrayRef[Str], [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::DescribeContainerInstances>

Returns: a L<Paws::ECS::DescribeContainerInstancesResponse> instance

  

Describes Amazon EC2 Container Service container instances. Returns
metadata about registered and remaining resources on each container
instance requested.











=head2 DescribeServices(services => ArrayRef[Str], [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::DescribeServices>

Returns: a L<Paws::ECS::DescribeServicesResponse> instance

  

Describes the specified services running in your cluster.











=head2 DescribeTaskDefinition(taskDefinition => Str)

Each argument is described in detail in: L<Paws::ECS::DescribeTaskDefinition>

Returns: a L<Paws::ECS::DescribeTaskDefinitionResponse> instance

  

Describes a task definition. You can specify a C<family> and
C<revision> to find information on a specific task definition, or you
can simply specify the family to find the latest C<ACTIVE> revision in
that family.

You can only describe C<INACTIVE> task definitions while an active task
or service references them.











=head2 DescribeTasks(tasks => ArrayRef[Str], [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::DescribeTasks>

Returns: a L<Paws::ECS::DescribeTasksResponse> instance

  

Describes a specified task or tasks.











=head2 DiscoverPollEndpoint([cluster => Str, containerInstance => Str])

Each argument is described in detail in: L<Paws::ECS::DiscoverPollEndpoint>

Returns: a L<Paws::ECS::DiscoverPollEndpointResponse> instance

  

This action is only used by the Amazon EC2 Container Service agent, and
it is not intended for use outside of the agent.

Returns an endpoint for the Amazon EC2 Container Service agent to poll
for updates.











=head2 ListClusters([maxResults => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::ECS::ListClusters>

Returns: a L<Paws::ECS::ListClustersResponse> instance

  

Returns a list of existing clusters.











=head2 ListContainerInstances([cluster => Str, maxResults => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::ECS::ListContainerInstances>

Returns: a L<Paws::ECS::ListContainerInstancesResponse> instance

  

Returns a list of container instances in a specified cluster.











=head2 ListServices([cluster => Str, maxResults => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::ECS::ListServices>

Returns: a L<Paws::ECS::ListServicesResponse> instance

  

Lists the services that are running in a specified cluster.











=head2 ListTaskDefinitionFamilies([familyPrefix => Str, maxResults => Int, nextToken => Str])

Each argument is described in detail in: L<Paws::ECS::ListTaskDefinitionFamilies>

Returns: a L<Paws::ECS::ListTaskDefinitionFamiliesResponse> instance

  

Returns a list of task definition families that are registered to your
account (which may include task definition families that no longer have
any C<ACTIVE> task definitions). You can filter the results with the
C<familyPrefix> parameter.











=head2 ListTaskDefinitions([familyPrefix => Str, maxResults => Int, nextToken => Str, sort => Str, status => Str])

Each argument is described in detail in: L<Paws::ECS::ListTaskDefinitions>

Returns: a L<Paws::ECS::ListTaskDefinitionsResponse> instance

  

Returns a list of task definitions that are registered to your account.
You can filter the results by family name with the C<familyPrefix>
parameter or by status with the C<status> parameter.











=head2 ListTasks([cluster => Str, containerInstance => Str, desiredStatus => Str, family => Str, maxResults => Int, nextToken => Str, serviceName => Str, startedBy => Str])

Each argument is described in detail in: L<Paws::ECS::ListTasks>

Returns: a L<Paws::ECS::ListTasksResponse> instance

  

Returns a list of tasks for a specified cluster. You can filter the
results by family name, by a particular container instance, or by the
desired status of the task with the C<family>, C<containerInstance>,
and C<desiredStatus> parameters.











=head2 RegisterContainerInstance([cluster => Str, containerInstanceArn => Str, instanceIdentityDocument => Str, instanceIdentityDocumentSignature => Str, totalResources => ArrayRef[Paws::ECS::Resource], versionInfo => Paws::ECS::VersionInfo])

Each argument is described in detail in: L<Paws::ECS::RegisterContainerInstance>

Returns: a L<Paws::ECS::RegisterContainerInstanceResponse> instance

  

This action is only used by the Amazon EC2 Container Service agent, and
it is not intended for use outside of the agent.

Registers an Amazon EC2 instance into the specified cluster. This
instance will become available to place containers on.











=head2 RegisterTaskDefinition(containerDefinitions => ArrayRef[Paws::ECS::ContainerDefinition], family => Str, [volumes => ArrayRef[Paws::ECS::Volume]])

Each argument is described in detail in: L<Paws::ECS::RegisterTaskDefinition>

Returns: a L<Paws::ECS::RegisterTaskDefinitionResponse> instance

  

Registers a new task definition from the supplied C<family> and
C<containerDefinitions>. Optionally, you can add data volumes to your
containers with the C<volumes> parameter. For more information on task
definition parameters and defaults, see Amazon ECS Task Definitions in
the I<Amazon EC2 Container Service Developer Guide>.











=head2 RunTask(taskDefinition => Str, [cluster => Str, count => Int, overrides => Paws::ECS::TaskOverride, startedBy => Str])

Each argument is described in detail in: L<Paws::ECS::RunTask>

Returns: a L<Paws::ECS::RunTaskResponse> instance

  

Start a task using random placement and the default Amazon ECS
scheduler. If you want to use your own scheduler or place a task on a
specific container instance, use C<StartTask> instead.

The C<count> parameter is limited to 10 tasks per call.











=head2 StartTask(containerInstances => ArrayRef[Str], taskDefinition => Str, [cluster => Str, overrides => Paws::ECS::TaskOverride, startedBy => Str])

Each argument is described in detail in: L<Paws::ECS::StartTask>

Returns: a L<Paws::ECS::StartTaskResponse> instance

  

Starts a new task from the specified task definition on the specified
container instance or instances. If you want to use the default Amazon
ECS scheduler to place your task, use C<RunTask> instead.

The list of container instances to start tasks on is limited to 10.











=head2 StopTask(task => Str, [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::StopTask>

Returns: a L<Paws::ECS::StopTaskResponse> instance

  

Stops a running task.











=head2 SubmitContainerStateChange([cluster => Str, containerName => Str, exitCode => Int, networkBindings => ArrayRef[Paws::ECS::NetworkBinding], reason => Str, status => Str, task => Str])

Each argument is described in detail in: L<Paws::ECS::SubmitContainerStateChange>

Returns: a L<Paws::ECS::SubmitContainerStateChangeResponse> instance

  

This action is only used by the Amazon EC2 Container Service agent, and
it is not intended for use outside of the agent.

Sent to acknowledge that a container changed states.











=head2 SubmitTaskStateChange([cluster => Str, reason => Str, status => Str, task => Str])

Each argument is described in detail in: L<Paws::ECS::SubmitTaskStateChange>

Returns: a L<Paws::ECS::SubmitTaskStateChangeResponse> instance

  

This action is only used by the Amazon EC2 Container Service agent, and
it is not intended for use outside of the agent.

Sent to acknowledge that a task changed states.











=head2 UpdateContainerAgent(containerInstance => Str, [cluster => Str])

Each argument is described in detail in: L<Paws::ECS::UpdateContainerAgent>

Returns: a L<Paws::ECS::UpdateContainerAgentResponse> instance

  

Updates the Amazon ECS container agent on a specified container
instance. Updating the Amazon ECS container agent does not interrupt
running tasks or services on the container instance. The process for
updating the agent differs depending on whether your container instance
was launched with the Amazon ECS-optimized AMI or another operating
system.

C<UpdateContainerAgent> requires the Amazon ECS-optimized AMI or Amazon
Linux with the C<ecs-init> service installed and running. For help
updating the Amazon ECS container agent on other operating systems, see
Manually Updating the Amazon ECS Container Agent in the I<Amazon EC2
Container Service Developer Guide>.











=head2 UpdateService(service => Str, [cluster => Str, desiredCount => Int, taskDefinition => Str])

Each argument is described in detail in: L<Paws::ECS::UpdateService>

Returns: a L<Paws::ECS::UpdateServiceResponse> instance

  

Modify the desired count or task definition used in a service.

You can add to or subtract from the number of instantiations of a task
definition in a service by specifying the cluster that the service is
running in and a new C<desiredCount> parameter.

You can use C<UpdateService> to modify your task definition and deploy
a new version of your service, one task at a time. If you modify the
task definition with C<UpdateService>, Amazon ECS spawns a task with
the new version of the task definition and then stops an old task after
the new version is running. Because C<UpdateService> starts a new
version of the task before stopping an old version, your cluster must
have capacity to support one more instantiation of the task when
C<UpdateService> is run. If your cluster cannot support another
instantiation of the task used in your service, you can reduce the
desired count of your service by one before modifying the task
definition.











=head1 SEE ALSO

This service class forms part of L<Paws>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: https://github.com/pplu/aws-sdk-perl

Please report bugs to: https://github.com/pplu/aws-sdk-perl/issues

=cut

