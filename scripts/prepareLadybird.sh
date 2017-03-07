#!/bin/bash

set +x

fetchAndBuild () {
  local PROJECT=$1
  local GITURL=$2
  local BRANCH=$3
  shift 3

  test -d $PROJECT
  local PROJECT_EXIST=$?
  if [ $PROJECT_EXIST -ne 0 ]; then
    echo "Cloning $GITURL ..." >&2
    git clone -b $BRANCH -o upstream $GITURL $PROJECT &>>$PROJECT.log
  fi
  pushd $PROJECT >/dev/null
    if [ $PROJECT_EXIST -eq 0 ]; then
      echo "Updating $PROJECT to latest sources ($BRANCH) ..." >&2
      # update to latest
      git fetch upstream &>>$PROJECT.log
      git rebase upstream/$BRANCH &>>$PROJECT.log
    fi
    # deploy
    echo "Building $PROJECT ..." >&2
    mvn clean source:jar install -DskipTests -Dcheckstyle.skip -Denforcer.skip $* &>>../$PROJECT.log
    local PROJECT_VERSION=$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version 2>/dev/null |grep -Ev '(^\[|Download\w+:)')
    echo "Project $PROJECT version: $PROJECT_VERSION" >&2
    echo $PROJECT_VERSION
  popd >/dev/null
}

VERSION_ELY=$(fetchAndBuild wildfly-elytron git@github.com:wildfly-security/wildfly-elytron.git master)
VERSION_ELYWEB=$(fetchAndBuild elytron-web git@github.com:wildfly-security/elytron-web.git master -Dversion.org.wildfly.security.elytron=$VERSION_ELY)
VERSION_ELYTOOL=$(fetchAndBuild wildfly-elytron-tool git@github.com:wildfly-security/wildfly-elytron-tool.git master -Dversion..elytron=$VERSION_ELY)
VERSION_WFCORE=$(fetchAndBuild wildfly-core git@github.com:wildfly-security-incubator/wildfly-core.git ladybird -Dversion.org.wildfly.security.elytron=$VERSION_ELY -Dversion.org.wildfly.security.elytron.tool=$VERSION_ELYTOOL -Dversion.org.wildfly.security.elytron-web.undertow-server=$VERSION_ELYWEB)
VERSION_ELYSUBSYSTEM=$(fetchAndBuild elytron-subsystem git@github.com:wildfly-security/elytron-subsystem.git master -Dversion.elytron=$VERSION_ELY -Dversion.wildfly.core=$VERSION_WFCORE)
VERSION_WFLY=$(fetchAndBuild wildfly git@github.com:wildfly-security-incubator/wildfly.git ladybird -Dversion.org.wildfly.security.elytron-subsystem=$VERSION_ELYSUBSYSTEM -Dversion.org.wildfly.core=$VERSION_WFCORE -Dversion.org.wildfly.security.elytron-web.undertow-server=$VERSION_ELYWEB)

echo "To rebuild the wildfly (ladybird) use:"
echo "  mvn clean install -DskipTests -Dcheckstyle.skip -Denforcer.skip -Dversion.org.wildfly.security.elytron-subsystem=$VERSION_ELYSUBSYSTEM -Dversion.org.wildfly.core=$VERSION_WFCORE -Dversion.org.wildfly.security.elytron-web.undertow-server=$VERSION_ELYWEB"
echo
