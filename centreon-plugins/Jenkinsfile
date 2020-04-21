properties([buildDiscarder(logRotator(numToKeepStr: '50'))])

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
    if (env.BRANCH_NAME == 'master') {
      withSonarQubeEnv('SonarQube') {
        sh './centreon-build/jobs/plugins/plugins-analysis.sh'
      }
    }
  }
}

try {
  stage('Package') {
    parallel 'all': {
      node {
        sh 'setup_centreon_build.sh'
        sh './centreon-build/jobs/plugins/plugins-package.sh'
      }
    }
    if ((currentBuild.result ?: 'SUCCESS') != 'SUCCESS') {
      error('Package stage failure.');
    }
  }
} catch(e) {
  if (env.BRANCH_NAME == 'master') {
    slackSend channel: "#monitoring-metrology", color: "#F30031", message: "*FAILURE*: `CENTREON PLUGINS` <${env.BUILD_URL}|build #${env.BUILD_NUMBER}> on branch ${env.BRANCH_NAME}\n*COMMIT*: <https://github.com/centreon/centreon-plugins/commit/${source.COMMIT}|here> by ${source.COMMITTER}\n*INFO*: ${e}"
  }
}
