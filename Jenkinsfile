pipeline {
	
    agent {
	    kubernetes {
	        // Change the name of jenkins-maven label to be able to use yaml configuration snippet
	        label "maven-jenkins"
	        // Inherit from Jx Maven pod template
	        inheritFrom "maven"
	        // Add scheduling configuration to Jenkins builder pod template
	        yaml """
spec:
  nodeSelector:
    cloud.google.com/gke-preemptible: true

  # It is necessary to add toleration to GKE preemtible pool taint to the pod in order to run it on that node pool
  tolerations:
  - key: gke-preemptible
    operator: Equal
    value: true
    effect: NoSchedule

  volumes:
  - name: gsutil-volume
    secret:
      secretName: gsutil-secret
      items:
      - key: .boto
        path: .boto

  containers:
  - name: gsutil
    image: introproventures/gsutil
    command:
    - sh -c
    args:
    - cat
    workingDir: /home/jenkins
    securityContext:
      privileged: false
    tty: true
    env:
    - name: CHART_REPOSITORY
      value: http://jenkins-x-chartmuseum:8080
    - name: CHART_BUCKET
      value: introproventures
    resources:
      requests:
        cpu: 128m
        memory: 256Mi
      limits:
    volumeMounts:
      - mountPath: /home/jenkins
        name: workspace-volume
      - name: gsutil-volume
        mountPath: /root/.boto
        subPath: .boto
"""        
        } 
    }
    
    environment {
      ORG               = "introproventures"
      APP_NAME          = "activiti-cloud-query-graphql"
      CHARTMUSEUM_CREDS = credentials("jenkins-x-chartmuseum")
    }
    stages {
      stage("CI Build and push snapshot") {
        when {
          branch "PR-*"
        }
        environment {
          PREVIEW_VERSION = "0.0.0-SNAPSHOT-$BRANCH_NAME-$BUILD_NUMBER"
          PREVIEW_NAMESPACE = "$APP_NAME-$BRANCH_NAME".toLowerCase()
          HELM_RELEASE = "$PREVIEW_NAMESPACE".toLowerCase()
        }
        steps {
          container("maven") {
            sh "make preview"
          }
        }
      }
      stage("Build Release") {
        when {
          branch "master"
        }
        steps {
          container("maven") {
            // ensure we're not on a detached head
            sh "make checkout"

            // so we can retrieve the version in later steps
            sh "make version"
            
            // Let's test first
            sh "make install"

            // Let's make tag in Git
            sh "make tag"
            
            // Let's deploy to Nexus
            sh "make deploy"
          }
          container("gsutil") {
            // update 
            sh "make chartmuseum/index.yaml"
          }
        }
      }
      stage("Promote to Environments") {
        when {
          branch "master"
        }
        steps {
            container("maven") {
              sh "make promote"
            }
        }
      }
    }
    post {
        always {
            cleanWs()
        }
/*
        failure {

		input """Pipeline failed. 
We will keep the build pod around to help you diagnose any failures. 

Select Proceed or Abort to terminate the build pod"""
        }
*/	

    }
}
