irc_buzz_bot
============

To run as a container: docker run -d --name buzz -p 4000:4000 --link ircd:ircd --link redis:redis elmundio87/irc-buzz-bot

Requires an active IRC container: docker run -d --name ircd -p 6667:6667 elmundio87/irc
Requires an active Redis container: docker run -d --name redis -p 6379:6379 redis

It will listen to requests on port 4000 from the Jenkins Notification plugin

