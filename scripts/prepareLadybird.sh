#!/bin/bash

set +x -e

BUILD_LOG=`pwd`/ladybird-build.log

fetchAndBuild () {
  local PROJECT=$1
  local GITUSER=$2
  local BRANCH=$3
  shift 3

  echo "Project $PROJECT is to be processed."  2>&1 | tee -a $BUILD_LOG >&2
  test -d $PROJECT
  local PROJECT_EXIST=$?
  if [ $PROJECT_EXIST -ne 0 ]; then
    echo "Cloning $GITURL ..."  2>&1 | tee -a $BUILD_LOG >&2
    git clone -b $BRANCH -o upstream git@github.com:$GITUSER/$PROJECT.git 2>&1 | tee -a $BUILD_LOG >&2
  fi
  pushd $PROJECT >/dev/null
    if [ $PROJECT_EXIST -eq 0 ]; then
      echo "Updating $PROJECT to latest sources ($BRANCH) ..."  2>&1 | tee -a $BUILD_LOG >&2
      # update to latest
      git fetch upstream 2>&1 | tee -a $BUILD_LOG >&2
      git rebase upstream/$BRANCH  2>&1 | tee -a $BUILD_LOG  2>&1 | tee -a $BUILD_LOG >&2
    fi
    # updating versions
    for SETVERSION in "$@"; do
      IFS== read PROPERTY NEWVERSION <<< $SETVERSION
      mvn versions:update-property -DallowSnapshots=true -DnewVersion=$NEWVERSION -Dproperty=$PROPERTY  2>&1 | tee -a $BUILD_LOG >&2
    done
    # deploy
    echo "Building $PROJECT ..."  | tee -a $BUILD_LOG >&2
    mvn clean source:jar install -DskipTests -Dcheckstyle.skip -Denforcer.skip  2>&1 | tee -a $BUILD_LOG >&2
    local PROJECT_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version 2>/dev/null |grep -Ev '(^\[|Download\w+:)')
    echo "Project $PROJECT version: $PROJECT_VERSION"  2>&1 | tee -a $BUILD_LOG >&2
    echo $PROJECT_VERSION
  popd >/dev/null
}

VERSION_ELY=$(fetchAndBuild wildfly-elytron wildfly-security master)
VERSION_ELYWEB=$(fetchAndBuild elytron-web wildfly-security master version.org.wildfly.security.elytron=$VERSION_ELY)
VERSION_ELYTOOL=$(fetchAndBuild wildfly-elytron-tool wildfly-security master version.elytron=$VERSION_ELY)
VERSION_WFCORE=$(fetchAndBuild wildfly-core wildfly-security-incubator ladybird version.org.wildfly.security.elytron=$VERSION_ELY version.org.wildfly.security.elytron.tool=$VERSION_ELYTOOL version.org.wildfly.security.elytron-web.undertow-server=$VERSION_ELYWEB)
VERSION_WFLY=$(fetchAndBuild wildfly wildfly-security-incubator ladybird version.org.wildfly.core=$VERSION_WFCORE)

echo "To rebuild the wildfly (ladybird) use:"
echo "  mvn clean install -DskipTests -Dcheckstyle.skip -Denforcer.skip -Dversion.org.wildfly.core=$VERSION_WFCORE"
echo
