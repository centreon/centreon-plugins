import groovy.json.JsonSlurper

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
    // Run sonarQube analysis
    withSonarQubeEnv('SonarQubeDev') {
      sh './centreon-build/jobs/plugins/plugins-analysis.sh'
    }
  }
}

try {
  stage('Quality gate') {
    node {
      def reportFilePath = "target/sonar/report-task.txt"
      def reportTaskFileExists = fileExists "${reportFilePath}"
      if (reportTaskFileExists) {
        echo "Found report task file"
        def taskProps = readProperties file: "${reportFilePath}"
        echo "taskId[${taskProps['ceTaskId']}]"
        timeout(time: 10, unit: 'MINUTES') {
          while (true) {
            sleep 10
            def taskStatusResult    =
            sh(returnStdout: true, script: "curl -s -X GET -u ${authString} \'${sonarProps['sonar.host.url']}/api/ce/task?id=${taskProps['ceTaskId']}\'")
            echo "taskStatusResult[${taskStatusResult}]"
            def taskStatus  = new JsonSlurper().parseText(taskStatusResult).task.status
            echo "taskStatus[${taskStatus}]"
            // Status can be SUCCESS, ERROR, PENDING, or IN_PROGRESS. The last two indicate it's
            // not done yet.
            if (taskStatus != "IN_PROGRESS" && taskStatus != "PENDING") {
              break;
            }
            def qualityGate = waitForQualityGate()
            if (qualityGate.status != 'OK') {
              currentBuild.result = 'FAIL'
            }
          }
        }
      }
      if ((currentBuild.result ?: 'SUCCESS') != 'SUCCESS') {
        error("Quality gate failure: ${qualityGate.status}.");
      }
    }
  }

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
