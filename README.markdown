Nuntium
=======

[![Build Status](https://github.com/instedd/nuntium/actions/workflows/ci.yml/badge.svg)](https://github.com/instedd/nuntium/actions/workflows/ci.yml)

Nuntium is an open source and free platform -developed by [InSTEDD](http://www.instedd.org)- that allows applications to send and receive all type of messages. Examples of messages are sms, emails and twitter direct messages.

Read about some of the [new features in the last release](http://ndt.instedd.org/2010/08/make-your-sms-apps-scale.html).

Let's start with an example
---------------------------

Suppose you have a website that lets users browse and geolocate sms sent by users. Once a message is geolocated you want to send this information to a particular number. Also suppose you have an sms number by which you can receive and send sms. You want your website to focus on the geolocation task and leave the sending and receiving of sms to Nuntium. Here's how you do it:

*  You get an account in Nuntium.
*  You create an Application in Nuntium that will represent your application. You then select an Interface for it, for example HTTP callback. An Interface is something that lets Nuntium communicate with your application.
*  You create a Channel that will communicate with the cellphone company. A Channel is something that lets Nuntium communicate with the world.

Your website gets messages from Nuntium using the configured Interface (in this case via an HTTP callback containing the messages.) Once a message is geolocated your website sends it to Nuntium (it performs an HTTP POST to Nuntium). And that's it!

What are the benefits of using Nuntium?
---------------------------------------

*  Your application deals with a simple protocol (HTTP, might be another one) instead of communicating directly with the cellphone company.
*  Nuntium will do its best to deliver messages.
*  You have a complete trace of what happened to each message.
*  You can specify custom routing logic.
*  You can change the routing logic without touching a single line in your application's source code.

This way you don't have to repeat this logic in every application that needs to send and receive messages.

Installing
----------
[Installation docs](https://github.com/instedd/nuntium/wiki/Installing)

API
---

[API documentation](https://github.com/instedd/nuntium/wiki/API)

Docker development
------------------

`docker-compose.yml` file build a development environment mounting the current folder and running rails in development environment.

Run the following commands to have a stable development environment.

```
$ docker-compose run --rm --no-deps web bundle install
$ docker-compose run --rm web bash -c 'rake db:setup db:seed'
$ docker-compose up
```

Intercom
--------

Nuntium supports Intercom as its CRM platform. To load the Intercom chat widget, simply start Nuntium with the env variable `INTERCOM_APP_ID` set to your Intercom app id (https://www.intercom.com/help/faqs-and-troubleshooting/getting-set-up/where-can-i-find-my-workspace-id-app-id).

Nuntium will forward any conversation with a logged user identifying them through their email address. Anonymous, unlogged users will also be able to communicate.

If you don't want to use Intercom, you can simply omit `INTERCOM_APP_ID` or set it to `''`.

To test the feature in development, add the `INTERCOM_APP_ID` variable and its value to the `environment` object inside the `web` service in `docker-compose.yml`.
