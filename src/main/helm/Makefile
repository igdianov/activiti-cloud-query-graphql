CHART_REPO := $(or $(CHART_REPOSITORY),@CHART_REPO@)
CURRENT=$(pwd)
NAME := @project.artifactId@
OS := $(shell uname)
RELEASE_VERSION := @project.version@
GITHUB_PAGES_BRANCH := gh-pages
GITHUB_PAGES_REPO := https://github.com/igdianov/activiti-cloud-query-graphql-charts
GITHIB_PAGES_DIR := $(shell basename $(GITHUB_PAGES_REPO))

init:
	helm init --client-only
	helm repo add chart-repo $(CHART_REPO)

lint: clean init
	rm -rf requirements.lock
	helm dependency build
	helm lint

package: build 
	helm package .

install: clean build
	helm install . --name ${NAME}

upgrade: clean build
	helm upgrade ${NAME} .

delete:
	helm delete --purge ${NAME}

clean:
	rm -rf charts
	rm -rf ${NAME}*.tgz

deploy: package
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(RELEASE_VERSION).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz%
	
publish: 
	git clone -b "$(GITHUB_PAGES_BRANCH)" "$(GITHUB_PAGES_REPO).git" $(GITHIB_PAGES_DIR)
	cp "$(NAME)-$(RELEASE_VERSION).tgz" $(GITHIB_PAGES_DIR)
	cd $(GITHIB_PAGES_DIR) && \
	   helm repo index . && \
	   git add . && \
	   git status && \
	   git commit -m "fix: (version) add $(NAME)-$(RELEASE_VERSION) chart" && \
	   git push origin "$(GITHUB_PAGES_BRANCH)"
	   
release:
	jx step helm release
	
build:
	jx step helm build	
	
promote:
	jx promote -b --all-auto --timeout 1h --version $(RELEASE_VERSION)	