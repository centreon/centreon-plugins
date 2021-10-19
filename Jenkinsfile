
env.REF_BRANCH = 'master'
if ((env.BRANCH_NAME == env.REF_BRANCH)) {
  env.BUILD = 'REFERENCE'
} else {
  env.BUILD = 'CI'
}

stage('Source') {
  node {
    sh 'setup_centreon_build.sh'
    dir('centreon-plugins') {
      checkout scm
    }
    sh './centreon-build/jobs/plugins/plugins-source.sh'
    source = readProperties file: 'source.properties'
    env.VERSION = "${source.VERSION}"
    env.RELEASE = "${source.RELEASE}"
    // Run sonarQube analysis
    withSonarQubeEnv('SonarQubeDev') {
      sh './centreon-build/jobs/plugins/plugins-analysis.sh'
    }
    def qualityGate = waitForQualityGate()
    if (qualityGate.status != 'OK') {
      currentBuild.result = 'FAIL'
    }
  }
}

stage('RPM Packaging') {
  parallel 'all': {
    node {
      sh 'setup_centreon_build.sh'
      sh './centreon-build/jobs/plugins/plugins-package.sh'
      archiveArtifacts artifacts: 'rpms-centos7.tar.gz'
      archiveArtifacts artifacts: 'rpms-centos8.tar.gz'
      stash name: "rpms-centos7", includes: 'output-centos7/noarch/*.rpm'
      stash name: "rpms-centos8", includes: 'output-centos8/noarch/*.rpm'
      sh 'rm -rf output'
    }
  }
  if ((currentBuild.result ?: 'SUCCESS') != 'SUCCESS') {
    error('Package stage failure.');
  }
}

stage('RPM Delivery') {
  parallel 'all': {
    node {
      sh 'setup_centreon_build.sh'
      unstash 'rpms-centos7'
      unstash 'rpms-centos8'
      sh './centreon-build/jobs/plugins/plugins-delivery.sh'
    }
  }
  if ((currentBuild.result ?: 'SUCCESS') != 'SUCCESS') {
    error('Package stage failure.');
  }
}

