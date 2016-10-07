# Cadavres Exquis "Swarm edition"

## Warm-up

If you plan on attending this workshop, you need:

* A laptop + power cord
* Install Docker 1.12:
  * With [Docker for Mac](https://download.docker.com/mac/beta/Docker.dmg) or [Docker for Windows](https://download.docker.com/win/beta/InstallDocker.msi)
  * On Windows older than Windows 10 Pro, install [Docker Toolbox](https://github.com/docker/toolbox/releases/download/v1.12.0/DockerToolbox-1.12.0.exe) instead
  * On Linux, grab [docker-compose v1.8.1](https://github.com/docker/compose/releases/download/1.8.1/docker-compose-Linux-x86_64) and put it in your path somewhere.
* Test that your docker installation works fine:
  * `docker version` should show version `1.12` on both Client and Server side.
  * Run `docker run hello-world` and check you see the welcome message.
* Get the source of the lab by `git clone git@github.com:CodeStory/lab-docker.git`
* During the workshop, we'll distribute USB keys with the docker images we need for the lab:
  * `cd lab-docker`
  * `docker load -i images.tar` will load all the images you need.
* As an alternate solution, you can load the images directly from the hub:
  * `docker pull dockerdemos/lab-web`
  * `docker pull dockerdemos/lab-words-dispatcher`
  * `docker pull dockerdemos/lab-words-java`
  * `docker pull mongo-express:0.31.0`
  * `docker pull mongo:3.3.15`

## 1 - Look Ma', micro-services on my laptop

Our first version of the application is composed of four micro-services:

  - A `web` service that uses `nginx` running on port `80` to serve an HTML5/Js
    application written in angularJs.
  - A `words-java` service that runs a `java` web server on a random port. This
    server connects to the database and exposes a Rest Api to the `web`.
  - A `db` service that runs a `mongoDb` database on a random port.
  - A `db-ui` service that runs a web UI on port `8081` to edit the content of
    the database

## Let's run the application

1. Point Docker CLI to the Docker daemon:

  - If you have `Docker for Mac` or `Docker for Windows`, there's nothing to be
    done. Run `docker info` to check that everything is up and running.

  - If you have `Docker Toolbox`, either open the `Quick Start` terminal or run
    `docker-machine env` to show the command you have to **run** to point to the
    Docker daemon running on the VirtualBox VM. On OSX, it's typically:

    ```
    eval $(docker-machine env default)
    ```

2. Configure *Docker Compose* to use the first configuration file:

  ```
  cd lab-docker
  cp docker-compose-v1.yml docker-compose.yml
  ```

3. Build and start the application:

  ```
  docker-compose up -d
  ```

4. Take a look at the logs, to see if there's any error:

  ```
  docker-compose logs
  ```

5. List the running containers:

  ```
  docker-compose ps

    Name                       Command               State              Ports
  ---------------------------------------------------------------------------------------------
  labdocker_db-ui_1        tini -- node app                 Up      0.0.0.0:8081->8081/tcp
  labdocker_db_1           /entrypoint.sh mongod            Up      27017/tcp
  labdocker_web_1          nginx -g daemon off;             Up      443/tcp, 0.0.0.0:80->80/tcp
  labdocker_words-java_1   java -DPROD_MODE=true -Xmx ...   Up      8080/tcp
  ```

## Let's use the application

With Docker for Mac and Docker for Windows, you can open a browser on "http://localhost".
With Docker Toolbox, get the ip address of the VM with `docker-machine ip default` and open a browser on "http://[THE_IP]".

You should see a random composed of 5 random words: a noun, an adjective,
a verb, a noun and an adjective. That's a "Cadavre Exquis"! You did it!

However, you'll notice that it's always the same sentence that's displayed.
We have to fix that! And will do it without touching the code...

## How does it work?

The angularJs application served by the `nginx` based `web` service sends 5
http `GET` queries to the `nginx` that proxies the `words` REST service.

That was easy because with docker, each service can be reached on the network
via it's name.

On each query, the `words` service loads all the words from the `mongo` database,
chooses a random one and memoizes it so that future queries are served from the
memory and not from the database.

## What to explore in this step

1. The `db-ui` web UI can be used to configure the list of words in the database.
  * Use this command to find the url for the UI: `docker-compose port db-ui 8081`
  * Add some nouns, adjectives and verbs, use non-plural and male noun and adjectives, or the grammar will not be correct.
  * **Careful**, all words added to the database at this stage will be lost for the next stages.

2. You can improve the web UI:
  * Change something in `web/static/index.html`
  * Then `docker-compose stop web; docker-compose rm -f web; docker-compose build web; docker up -d web`, see how this updates a single micro service.

3. Things to check in this step:
  * Notice the db connexion string in `words-java/src/main/java/Main.java`
  * Notice the nginx configuration in `web/default.conf` on `location /words/` and check the corresponding code in `web/static/app.js`
  * Notice in the `docker-compose-v1.yml` file some services have `build` and `image` instructions while others have only `image`
  * Notice the `ports` vs `expose` instructions, try to find a way to call the `/verb` instruction on the `words-java`, without changing the `yml` file.

# 2 - Run the application with a dispatcher

We are going to change the micro-service based architecture of our application
without changing its code. That's neat!

Our idea is to introduce an additional micro-service between the `web` and the
`java` rest api. This new component is a Go based web server that will later
help dispatch word queries to multiple java REST backends.

## Let's use the application

1. Stop the application currently running:

  ```
  cd lab-docker
  docker-compose stop
  docker-compose rm -f
  ```

2. Configure *Docker Compose* to use the second configuration file:

  ```
  cp docker-compose-v2.yml docker-compose.yml
  ```

3. Build and start the application:

  ```
  docker-compose up -d
  docker-compose logs
  ```

As a user, you should see no difference compared to the original application.
That's the whole point!

## How is that possible?

The `web`'s expectation is that a `words` host exists on the network and that
it responds on port `8080`. What we did it renamed the `words` service to
`words-java` and introduced a new `go` based service under the name of `words`.

> Step 1, we had: web:80 -> words:8080 (java)
> Now, we have: web:80 -> words:8080 (go) -> words-java:8080 (java)

Thanks to Docker networking and the `expose` configuration, we can have two
services running on port `8080` without a conflict. An automatic translation
will be done by the network. We don't have to change our code. How cool is that?

## What to explore in this step

1. Check the logs and see the dispatcher in action
  * Run `docker-compose logs -f` and refresh your page at will, check the dispatcher work described in the logs.

2. Check the dispatcher code
  * Especially the `forward` function in the `words-dispatcher/dispatcher.go` source.
  * **careful** this code is not really efficient but it serves well the purpose of this workshop

# 3 - Run the application on a shared Swarm with Docker 1.12 services

We are going to the Cloud! Your containers will be send to a shared Swarm
composed of multiple nodes. We have already setup the Swarm for you before the talk.
You just need to point your Docker CLI to the Swarm rather than to your local
Docker daemon.
This is done through environment variables. And because our Swarm has TLS enabled,
you need a copy of our certificates. We'll pass along a couple of USB keys with
the certificates on them. Then follow the instructions below:

1. Stop the application currently running:

  ```
  cd lab-docker
  docker-compose stop
  docker-compose rm -f
  ```

2. Copy the provided `certificates` from the USB key.

3. Point your docker client to the proper machine:

If you are on the Google Cloud Swarm cluster:

  ```
  export DOCKER_TLS_VERIFY="1"
  export DOCKER_HOST="tcp://104.155.53.144:2376"
  export DOCKER_CERT_PATH="$(pwd)/certificates"
  ```

4. Confirm that `docker node ls` shows multiple nodes.

5. Configure *Docker Compose* to use the third configuration file:

  ```
  cd lab-docker
  cp docker-compose-v3.yml docker-compose.yml
  ```

5. Create a bundle file:

  ```
  docker-compose bundle -o MY-UNIQUE-TEAM-NAME.dab
  docker deploy MY-UNIQUE-TEAM-NAME
  docker service ls
  ```

6. Get the port of the `web` service.

  ```
  docker service inspect --pretty MY-UNIQUE-TEAM-NAME_web | tail -n1
  ```

7. Open the browser on `http://104.155.53.144:PORT`

The same application that ran on you machine now runs in the Cloud on a shared Swarm.

## How is that possible?

If you compare [docker-compose-v2.yml](docker-compose-v2.yml) and [docker-compose-v3.yml](docker-compose-v3.yml)
you'll see that all the services now use a private network now. This network is
created by *Docker Compose*. Its name is `private`, prefixed by the name of your
project (ie your team name). It's a network available to your containers only.

Thanks to this private network, multiple similar applications can coexist on a
Swarm.

All the services with the same name or alias on a shared network
will be reachable on the same DNS name. A client can get all the IPs for
the DNS name and start load balancing between the nodes. Nothing complicated
to setup!

That's exactly what the `words-dispatcher` does. To bypass the DNS cache, it
searches for all the IPs for the `works-java` services and uses a random one
each time. This effectively load balances queries among all the teams.

## What to explore in this step

1. You can increase the numbers of `words-java` nodes and see how the dispatcher react.
  * Add more `words-java` node with `docker service scale MY-UNIQUE-TEAM-NAME_words-java=4`.
  * You have now 4 `words-java` containers. Check their numbers with `docker service ls`

2. You can kill containers and see them respawned

# Docker Features demonstrated

* Multi-host Networking - *Docker 1.9*
* New compose file - *Docker 1.10*
* Use links in networks - *Docker 1.10*
* Network-wide container aliases - *Docker 1.10*
* DNS discovery - *Docker 1.11*
* Build in docker-compose up - *Docker-Compose 1.7*
* Bundles and Services - *Docker 1.12*

# About 'Cadavres Exquis'

Cadavres Exquis is a French word game, you'll find more on
[wikipedia page](https://fr.wikipedia.org/wiki/Cadavre_exquis_(jeu)) (in French)

# How did we create the Swarm?

The Swarm has been created on Google Cloud with the [init_swarm_google.sh](init_swarm_google.sh) script. Take a look to what we do there but you'll need an account and this may cost you money.
You can also try it on your own laptop by running the [init_swarm_virtualbox.sh](init_swarm_virtualbox.sh), you'll need virtualbox and `docker-machine`
