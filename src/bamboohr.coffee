# Description:
#   BambooHR Plugin for Hubot
#
# Dependencies:
#   node-bamboohr
#
# Configuration:
#   HUBOT_BAMBOOHR_APIKEY
#   HUBOT_BAMBOOHR_DOMAIN
#   HUBOT_BAMBOOHR_DATEFORMAT
#   HUBOT_SLACK_USER_TZ_LOOKUP
#
# Commands:
#   hubot bamboo <employee name> - returns the details for the employee from bamboohr
#   hubot whos(off|out) (when) - returns the list of employees that are on leave during the duration specified e.g. today, tomorrow, this week, next month
#
# Author:
#   Jordan Walsh <jordanwalsh23@gmail.com>

bamboohr_apikey = process.env.HUBOT_BAMBOOHR_APIKEY
bamboohr_domain = process.env.HUBOT_BAMBOOHR_DOMAIN
date_format = process.env.HUBOT_BAMBOOHR_DATEFORMAT
user_tz_lookup = process.env.HUBOT_SLACK_USER_TZ_LOOKUP

unless String::trim then String::trim = -> @replace /^\s+|\s+$/g, ""

formatBambooDate = (d) ->

  pattern = ///
    ^([\d]{4})- # Capture the year
    ([\d]{2})-  # Capture the month
    ([\d]{2})   # Capture the day
  ///

  [year, month, day] = d.match(pattern)[1..3]

  days = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

  year = parseInt year
  month = parseInt month
  day = parseInt day

  date = new Date(year, month-1, day)

  #console.log "date is " + date

  dateStr = ""

  if date_format && date_format.toLowerCase() == "us"
    dateStr = month + "/" + day + "/" + year
  else
    dateStr = day + "/" + month + "/" + year

  return dateStr

calculateDateStrings = (tz, timePeriod) ->

  if !timePeriod
    timePeriod = "today"
  else
    timePeriod = timePeriod.trim()

  moment = require('moment-timezone');

  #set the dates
  startDate = moment().tz(tz)
  endDate = moment().tz(tz)

  switch timePeriod
    when "tomorrow"
      startDate = startDate.add(1, 'day')
      endDate = startDate

    when "this week"

      dayOfMonth = parseInt(startDate.format('D'))
      dayOfWeek = parseInt(startDate.format('d'))

      newDayOfMonth = dayOfMonth + 6 - dayOfWeek

      endDate = endDate.add(newDayOfMonth-dayOfMonth, 'days')

    when "this month"
      dayOfMonth = parseInt(startDate.format('D'))

      endDate = endDate.add(1, 'months').subtract(dayOfMonth, 'days')

    when "next week"
      offset = 7 - parseInt(startDate.format('d'))

      startDate.add(offset, 'days')
      endDate.add(6 + offset, 'days')

    when "next month"
      dayOfMonth = parseInt(startDate.format('D'))

      startDate.add(1, 'months').subtract(dayOfMonth-1, 'days')
      endDate.add(2, 'months').subtract(dayOfMonth, 'days')

  response =
    startDate: startDate
    endDate: endDate
    startDateString: startDate.format("YYYY-MM-DD")
    endDateString: endDate.format("YYYY-MM-DD")

  return response

printDates = (msg, dates) ->
  #Create the BambooAPI object
  bambooapi = new (require 'node-bamboohr')({apikey: "#{bamboohr_apikey}", subdomain: "#{bamboohr_domain}"})

  bambooapi.whosOut dates.startDateString, dates.endDateString, (err, obj) ->

    startDate = dates.startDate
    endDate = dates.endDate
    peopleOnLeave = false

    #from = getDay(startDate) + "/" + getMonth(startDate) + "/" + getYear(startDate)
    from = startDate.format("DD/MM/YYYY")
    #to = getDay(endDate) + "/" + getMonth(endDate) + "/" + getYear(endDate)
    to = endDate.format("DD/MM/YYYY")

    if date_format && date_format.toLowerCase() == "us"
      #from = getMonth(startDate) + "/" + getDay(startDate) + "/" + getYear(startDate)
      from = startDate.format("MM/DD/YYYY")
      #to = getMonth(endDate) + "/" + getDay(endDate) + "/" + getYear(endDate)
      to = endDate.format("MM/DD/YYYY")

    response = "*People on leave (#{from} - #{to})*\n\n"

    if obj && obj.calendar != ''
      for timeoff in obj.calendar.item

        if timeoff.employee && timeoff.employee.length > 0
          response += "*#{timeoff.employee[0]._}*\n"

          timeOffStart = formatBambooDate timeoff.start[0];
          timeOffEnd = formatBambooDate timeoff.end[0];

          response += "#{timeOffStart} - #{timeOffEnd}\n\n"
          peopleOnLeave = true

    if peopleOnLeave
      msg.send response
    else
      msg.send "Seems everyone is hard at work. No leave found."


# Configures the plugin
module.exports = (robot) ->

  robot.respond /bamboo\s([\w\s]+)$/i, (msg) ->

    if msg.match[1].length < 3
      msg.send "*Minimim 3 letters required for bamboo search*"
    else
      bambooapi = new (require 'node-bamboohr')({apikey: "#{bamboohr_apikey}", subdomain: "#{bamboohr_domain}"})

      bambooapi.employees (err, employees) ->

        matched = false

        for employee in employees

          name = employee.fields.displayName.toLowerCase()
          search = msg.match[1].toLowerCase()

          if name != "" && name.indexOf("#{search}") >= 0
            msg.send "Found *#{employee.fields.displayName}*\n"

            if employee.fields.photoUrl
              msg.send employee.fields.photoUrl

            result = ''

            if employee.fields.jobTitle
              result += "*Job Title:* #{employee.fields.jobTitle}\n"

            if employee.fields.workPhone
              result += "*Work Phone:* #{employee.fields.workPhone}\n"

            if employee.fields.mobilePhone
              result += "*Mobile Phone:* #{employee.fields.mobilePhone}\n"

            if employee.fields.workEmail
              result += "*Email Address:* #{employee.fields.workEmail}"

            msg.send result

            matched = true

        if !matched
          msg.send "No match found for #{msg.match[1]}"


  # WHOS OFF Function
  # - Shows when people have approved leave in bamboohr

  robot.respond /whos(out|off)(\stoday|\stomorrow|\sthis\sweek|\sthis\smonth|\snext\sweek|\snext\smonth)?$/i, (msg) ->

    timePeriod = msg.match[2];

    if user_tz_lookup == "true"
      #Need to lookup the user's timezone info from slack
      params =
        user : msg.envelope.user.id

      msg.robot.slack.users.info params, (err, res) ->
        if res
          tz = res.user.tz
          msg.send "Detected timezone for #{res.user.real_name} as #{tz}. Querying BambooHR now."
        else
          tz = "Australia\/Melbourne"
          msg.send "Querying BambooHR based on #{tz} time"

        dates = calculateDateStrings(tz,timePeriod)
        printDates(msg, dates, )
    else
      #Assume the default system timezone
      msg.send "Querying BambooHR based on Australia\/Melbourne time"
      dates = calculateDateStrings("Australia\/Melbourne",timePeriod)
      printDates(msg, dates)
