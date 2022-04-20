
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
    timeout(time: 10, unit: 'MINUTES') {
      def qualityGate = waitForQualityGate()
      if (qualityGate.status != 'OK') {
        currentBuild.result = 'FAIL'
      }
    }
  }
}

stage('RPM Packaging') {
  parallel 'package rpms': {
    node {
      sh 'setup_centreon_build.sh'
      sh './centreon-build/jobs/plugins/plugins-package.sh'
      archiveArtifacts artifacts: 'rpms-centos7.tar.gz'
      archiveArtifacts artifacts: 'rpms-alma8.tar.gz'
      stash name: "rpms-centos7", includes: 'output-centos7/noarch/*.rpm'
      stash name: "rpms-alma8", includes: 'output-alma8/noarch/*.rpm'
      sh 'rm -rf output'
    },
    'package debian bullseye': {
      node {
        sh 'setup_centreon_build.sh'
        sh './centreon-build/jobs/plugins/plugins-package-deb.sh'
        archiveArtifacts artifacts: '*.deb'
        stash name: "Debian11", includes: '*.deb'
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
      unstash 'rpms-alma8'
      sh './centreon-build/jobs/plugins/plugins-delivery.sh'
    }
  }
  if ((currentBuild.result ?: 'SUCCESS') != 'SUCCESS') {
    error('Package stage failure.');
  }
}

