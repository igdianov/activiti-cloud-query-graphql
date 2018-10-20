CHART_REPO := @CHART_REPO@
CURRENT=$(pwd)
NAME := @project.artifactId@
OS := $(shell uname)
RELEASE_VERSION := $(shell cat ../../../VERSION)

init:
	helm init --client-only

build: clean init
	rm -rf requirements.lock
	helm dependency build
	helm lint

package: build 
    helm repo add chart-repo @CHART_REPO@
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

release: package
	curl --fail -u $(CHARTMUSEUM_CREDS_USR):$(CHARTMUSEUM_CREDS_PSW) --data-binary "@$(NAME)-$(shell sed -n 's/^version: //p' Chart.yaml).tgz" $(CHART_REPO)/api/charts
	rm -rf ${NAME}*.tgz%
