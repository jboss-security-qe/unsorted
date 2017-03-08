# Files which don't fit elsewhere

## prepareLadybird.sh

Script to fetch and build WildFly Ladybird branch (Elytron integration).

Just run the [scripts/prepareLadybird.sh](scripts/prepareLadybird.sh).

It downloads all and builds all necessary projects. The SNAPSHOT versions 
are then provided in the subsequent build steps (depending projects).

```bash
mkdir ladybird-dev
cd ladybird-dev
wget https://rawgit.com/jboss-security-qe/unsorted/master/scripts/prepareLadybird.sh
chmod +x prepareLadybird.sh
./prepareLadybird.sh
```
