package Paws::Net::Regions {
  use Moose;
  use JSON;
  use autodie;
  use URI::Template;
  use Paws::RegionInfo;

  has config => (is => 'ro', isa => 'HashRef', default => sub {
    return Paws::RegionInfo::get();
  },
  traits => [ 'Hash' ],
  handles => {
    get_rules_for_service => 'get'
  });

  has default_scheme => ( is => 'ro', isa => 'Str', default => 'https' );

  sub construct_endpoint {
    my ($self, $service, $region, $args) = @_;

    $args->{ service } = $service;
    $args->{ region  } = $region;
    $args->{ scheme  } = $self->default_scheme if (not defined $args->{scheme});

    my $service_rules = $self->get_rules_for_service($service);
    my $endpoint_info = $self->_match_rules($service_rules, $region, $args);
    if (not defined $endpoint_info) {
      $service_rules = $self->get_rules_for_service('_default');
      $endpoint_info = $self->_match_rules($service_rules, $region, $args);
    }

    if ( not defined $endpoint_info ) {
      die "NoRegionError()";
    } else {
      my $template = URI::Template->new($endpoint_info->{uri});
      my $url = $template->process($args);
      $endpoint_info->{ url } = $url;
    }

    return $endpoint_info;
  }

  sub _match_rules {
    my ( $self, $service_rules, $region, $args ) = @_;

    return undef if (not defined $service_rules);
    return undef if scalar(@$service_rules) == 0;

    for my $rule ( @$service_rules ) {
      if ( $self->_matches_rule($rule, $region, $args) ) {
        return { uri => $rule->{ uri }, (defined $rule->{ properties }) ? %{ $rule->{ properties } } : () };
      }
    }
    return undef;
  }

  sub _matches_rule {
    my( $self, $rule, $region, $args ) = @_;

    return 1 if (not defined $rule->{ constraints });

    my @constraints = @{ $rule->{ constraints } };
    for my $constraint (@constraints) {
      return 1 if ( $self->_matches_constraint($region, $constraint, $args) );
    }
    return 0;
  }

  has constraints => (
    is => 'ro',
    init_arg => undef,
    default => sub {
      {
      startsWith => sub {
        my ( $a, $v ) = @_;
        return 0 if (not defined $a and defined $v);
        return 0 if (defined $a and not defined $v);
        return $a =~ /^$v.*/i;
      },
      notStartsWith => sub {
        my ( $a, $v ) = @_;
        return 0 if (not defined $a);
        return $a !~ /^$v.*/i;
      },
      equals => sub {
        my ( $a, $v ) = @_;
        return $a eq $v;
      },
      notEquals => sub {
        # in the sample json, notEqual region's is always null
        # this needs review
        my ( $a, $v ) = @_;
        return 1 if (defined $a and not defined $v);
        return 1 if (not defined $a and defined $v);
        return 0 if (not defined $a and not defined $v);
        return $a ne $v;
      },
      oneOf => sub {
        my ( $a, $v ) = @_;
        for my $b (@$v) {
          return not defined($a) if (not defined($b));
          return not defined($b) if (not defined($a));
          return 1 if $a eq $b;
        }
        return 0;
      }
      };
    }
  );

  sub _matches_constraint {
    my ($self, $region, $constraint, $args ) = @_;
    my $property = $constraint->[0];
    die "We only know how to apply constraints to region" if ($property ne 'region');
    my $func  = $constraint->[1];
    my $value = $constraint->[2];
    return $self->constraints->{$func}->($region,$value);
  }
}

1;

