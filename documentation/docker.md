## Docker
The essdaq build can be tested/verified in Docker containers for Ubuntu and CentOS
installations. The purpose is to test the essdaq install scripts
on clean OS installations to make the install more robust.

### Instructions
To run the build scripts for CentOS/Ubuntu

    > cd docker
    > ./buildcentos  (or buildubuntu)
    > ./run.sh master interactive
    > cd essdaq
    > ./install.sh

### Limitations

Grafana/Graphite installation fails as they already run in a Docker
container and this causes problems.

There is currently no validation so the user must follow the progress
and perform his/her own tests along the way.
