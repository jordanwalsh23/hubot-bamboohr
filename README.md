# hubot-bamboohr

Access information from BambooHR like employee details and whos on leave

See [`src/bamboohr.coffee`](src/bamboohr.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-bamboohr --save`

Then add **hubot-bamboohr** to your `external-scripts.json`:

```json
["hubot-bamboohr"]
```
Two environment variables are required:

- HUBOT_BAMBOOHR_APIKEY - Your BambooHR API key (see your BambooHR admin)
- HUBOT_BAMBOOHR_DOMAIN - Your BambooHR subdomain

Once your environment variables are sent, the following commands are available:

## Get Employee Data

```
user1>> hubot bamboo John Smith
hubot>> Found *John Smith*
hubot>> https://<domain>.bamboohr.com/images/photo_placeholder.gif (1KB)
hubot>> *Job Title:* Consultant
*Mobile Phone:* 61400000000
*Email Address:* jsmith@example.com
```

## Get Who's on leave

```
user1>> hubot whosout
hubot>> People currently on leave (07/08/2015):*

*John Smith*
2015-08-05 - 2015-08-14

*Jane Smith*
2015-08-07 - 2015-08-07

*Sally Stevens*
2015-08-07 - 2015-08-07
```
