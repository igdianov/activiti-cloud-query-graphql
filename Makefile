CURRENT=$(pwd)
NAME := $(APP_NAME)
OS := $(shell uname)

RELEASE_BRANCH := $(or $(CHANGE_TARGET),$(shell git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'),master)
RELEASE_VERSION := $(or $(shell cat VERSION), $(shell mvn help:evaluate -Dexpression=project.version -q -DforceStdout))
GROUP_ID := $(shell mvn help:evaluate -Dexpression=project.groupId -q -DforceStdout)
ARTIFACT_ID := $(shell mvn help:evaluate -Dexpression=project.artifactId -q -DforceStdout)
RELEASE_ARTIFACT := $(GROUP_ID):$(ARTIFACT_ID)
RELEASE_GREP_EXPR := '^[Rr]elease'

.PHONY: ;

# dependency on .PHONY prevents Make from 
# thinking there's `nothing to be done`
preview-version: .PHONY
	$(eval VERSION = $(shell echo $(PREVIEW_VERSION)))	

release-version: .PHONY
	$(eval VERSION = $(shell echo $(RELEASE_VERSION)))

git-rev-list: .PHONY
	$(eval REV = $(shell git rev-list --tags --max-count=1 --grep $(RELEASE_GREP_EXPR)))
	$(eval PREVIOUS_REV = $(shell git rev-list --tags --max-count=1 --skip=1 --grep $(RELEASE_GREP_EXPR)))
	$(eval REV_TAG = $(shell git describe ${PREVIOUS_REV}))
	$(eval PREVIOUS_REV_TAG = $(shell git describe ${REV}))
	@echo Found commits between $(PREVIOUS_REV_TAG) and $(REV_TAG) tags:
	git rev-list $(PREVIOUS_REV)..$(REV) --first-parent --pretty

credentials: .PHONY
	git config --global credential.helper store
	jx step git credentials

checkout: credentials
	# ensure we're not on a detached head
	git checkout $(RELEASE_BRANCH) 

skaffold/release: release-version
	@echo doing skaffold docker build with tag=$(RELEASE_VERSION)
	export VERSION=$(RELEASE_VERSION) && skaffold build -f skaffold.yaml 

skaffold/preview: preview-version
	@echo doing skaffold docker build with tag=$(PREVIEW_VERSION)
	export VERSION=$(PREVIEW_VERSION) &&  skaffold build -f skaffold.yaml 

skaffold/build: .PHONY
	@echo doing skaffold docker build with tag=$(VERSION)
	#skaffold build -f skaffold.yaml 

update-versions: updatebot/push updatebot/update-loop

updatebot/push: .PHONY
	@echo doing updatebot push $(RELEASE_VERSION)
	updatebot push --ref $(RELEASE_VERSION)

updatebot/push-version: .PHONY
	@echo doing updatebot push-version
	$(eval QUERY_VERSION := $(shell mvn help:evaluate -Dexpression=$(ARTIFACT_ID)-query.version -q -DforceStdout))
	$(eval NOTIFICATIONS_VERSION := $(shell mvn help:evaluate -Dexpression=$(ARTIFACT_ID)-notifications.version -q -DforceStdout))
	$(eval SUBSCRIPTIONS_VERSION := $(shell mvn help:evaluate -Dexpression=$(ARTIFACT_ID)-subscriptions.version -q -DforceStdout))

	@echo Push artifact versions into Helm chart requirements.yaml 
	updatebot push-version --kind helm $(RELEASE_ARTIFACT) $(RELEASE_VERSION) \
        $(ARTIFACT_ID)-query $(QUERY_VERSION) \
        $(ARTIFACT_ID)-notifications $(NOTIFICATIONS_VERSION) \
        $(ARTIFACT_ID)-subscriptions $(SUBSCRIPTIONS_VERSION)

updatebot/update: .PHONY
	@echo doing updatebot update $(RELEASE_VERSION)
	updatebot update

updatebot/update-loop: .PHONY
	@echo doing updatebot update-loop $(RELEASE_VERSION)
	updatebot update-loop --poll-time-ms 60000

preview: .PHONY
	mvn versions:set -DnewVersion=$(PREVIEW_VERSION)
	${MAKE} install

install: .PHONY
	mvn clean install

verify: .PHONY
	mvn clean verify

deploy: .PHONY
	mvn clean deploy -DskipTests

VERSION: 
	$(shell jx-release-version > VERSION)
	$(eval RELEASE_VERSION = $(shell cat VERSION))
	@echo Using next release version $(RELEASE_VERSION)

next-version: VERSION
	mvn versions:set -DnewVersion=$(RELEASE_VERSION)
	
snapshot: .PHONY
	$(eval SNAPSHOT_VERSION = $(shell mvn versions:set -DnextSnapshot -q && mvn help:evaluate -Dexpression=project.version -q -DforceStdout))
	mvn versions:commit
	git add --all
	git commit -m "Update version to $(SNAPSHOT_VERSION)" --allow-empty # if first release then no verion update is performed
	git push

changelog: git-rev-list
	@echo Creating Github changelog for release: $(RELEASE_VERSION)
	jx step changelog --version v$(RELEASE_VERSION) --generate-yaml=false --rev=$(REV) --previous-rev=$(PREVIOUS_REV)
	
commit: VERSION
	mvn versions:commit
	git add --all
	git commit -m "Release $(RELEASE_VERSION)" --allow-empty # if first release then no verion update is performed

revert: .PHONY
	mvn versions:revert

tag: commit
	git status
	git tag -fa v$(RELEASE_VERSION) -m "Release version $(RELEASE_VERSION)"
	git push origin v$(RELEASE_VERSION)
	
reset: .PHONY
	git reset --hard origin/$(RELEASE_BRANCH)
		
release: version install tag deploy changelog  

clean: revert
	mvn clean
	rm -f VERSION
