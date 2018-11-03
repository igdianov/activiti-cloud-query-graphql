CHART_REPOSITORY := $(or $(CHART_REPOSITORY),http://jenkins-x-chartmuseum:8080)
CURRENT=$(pwd)
NAME := @project.artifactId@
OS := $(shell uname)
RELEASE_VERSION := @project.version@

GITHUB_CHARTS_BRANCH := $(or $(GITHUB_CHARTS_BRANCH),gh-pages)
GITHUB_CHARTS_REPO := $(or $(GITHUB_CHARTS_REPO),@GITHUB_CHARTS_REPO@)
GITHUB_CHARTS_DIR := $(or $(GITHUB_CHARTS_DIR),$(shell basename $(GITHUB_CHARTS_REPO)))

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
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(RELEASE_VERSION).tgz" $(CHART_REPOSITORY)/api/charts
	rm -rf ${NAME}*.tgz%
	
$(NAME)-$(RELEASE_VERSION).tgz: package
	
publish: 
	git clone -b "$(GITHUB_CHARTS_BRANCH)" "$(GITHUB_CHARTS_REPO).git" $(GITHUB_CHARTS_DIR)
	cp "$(NAME)-$(RELEASE_VERSION).tgz" $(GITHUB_CHARTS_DIR)
	cd $(GITHUB_CHARTS_DIR) && \
	   helm repo index . && \
	   git add . && \
	   git status && \
	   git commit -m "fix: (version) add $(NAME)-$(RELEASE_VERSION) chart" && \
	   git push origin "$(GITHUB_CHARTS_BRANCH)"
	   rm -rf $(GITHUB_CHARTS_DIR)
	   
release:
	jx step helm release
	
build:
	jx step helm build	
	
promote:
	jx promote -b --all-auto --timeout 1h --version $(RELEASE_VERSION)	