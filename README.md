# CoreOS Docker Java App

# Usage

Put application configuration in a shared volume, eg. /tmp/application1.service.

        docker run -t -i -v /tmp/application1.service:/opt/application/config shift/coreos-ubuntu-java run -w username:password -n "http://repo1.maven.org/maven2" -i 'org.elasticsearch:elasticsearch:1.2.2' -p jar -s 'java -jar /opt/application/artifact/artifact.jar'

Done.

## Notes

 * Only been tested with some grizzly fatjars.
 * Tomcat containers will follow.
