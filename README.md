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
- HUBOT_BAMBOOHR_DATEFORMAT - Either us or uk date format (default: uk)

Once your environment variables are set, the following commands are available:

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
user1>> hubot whosoff
hubot>> People currently on leave (07/08/2015):*

*John Smith*
05/08/2015 - 07/08/2015

*Jane Smith*
07/08/2015 - 07/08/2015

*Sally Stevens*
07/08/2015 - 07/08/2015
```

The `whosoff` function also takes an optional time period:

- today
- tomorrow
- this week
- next week
- this month
- next month

## Change Log

V1.0.6
- Fixed a bug when there was no one on leave it threw an error
