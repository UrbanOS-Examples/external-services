library(
    identifier: 'pipeline-lib@4.3.6',
    retriever: modernSCM([$class: 'GitSCMSource',
                          remote: 'https://github.com/SmartColumbusOS/pipeline-lib',
                          credentialsId: 'jenkins-github-user'])
)

properties([
    pipelineTriggers([scos.dailyBuildTrigger()]),
])

def image
def doStageIf = scos.&doStageIf
def doStageIfRelease = doStageIf.curry(scos.changeset.isRelease)
def doStageUnlessRelease = doStageIf.curry(!scos.changeset.isRelease)
def doStageIfPromoted = doStageIf.curry(scos.changeset.isMaster)

node ('infrastructure') {
    ansiColor('xterm') {
        scos.doCheckoutStage()

        doStageUnlessRelease('Deploy to Dev') {
            deployProxiesTo(environment: 'dev')
        }

        doStageIfPromoted('Deploy to Staging')  {
            def environment = 'staging'

            deployProxiesTo(environment: environment)

            scos.applyAndPushGitHubTag(environment)

        }

        doStageIfRelease('Deploy to Production') {
            def releaseTag = env.BRANCH_NAME
            def promotionTag = 'prod'

            deployProxiesTo(environment: 'prod', internal: false)

            scos.applyAndPushGitHubTag(promotionTag)

        }
    }
}

def deployProxiesTo(params = [:]) {
    def environment = params.get('environment')
    if (environment == null) throw new IllegalArgumentException("environment must be specified")

    def terraform = scos.terraform(environment)
    sh "terraform init && terraform workspace new ${environment}"
    terraform.plan(terraform.defaultVarFile)
    terraform.apply()
}
