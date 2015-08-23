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

unless String::trim then String::trim = -> @replace /^\s+|\s+$/g, ""

getYear = (d) ->
  return d.getFullYear()

getMonth = (d) ->
  mm = parseInt(d.getMonth()) + 1
  if mm < 10
    mm = "0" + "#{mm}"
  return mm

getDay = (d) ->
  dd = d.getDate()
  if dd < 10
    dd = "0" + "#{dd}"  
  return dd

formatDateString = (d) ->
  return getYear(d) + "-" + getMonth(d) + "-" + getDay(d)

formatBambooDate = (d) ->
  pattern = ///
    ^([\d]{4})- # Capture the year
    ([\d]{2})-  # Capture the month
    ([\d]{2})   # Capture the day
  ///

  year = 0
  month = 0
  day = 0

  [year, month, day] = d.match(pattern)[1..3]

  dateStr = ""

  if date_format && date_format.toLowerCase() == "us"
    dateStr = month + "/" + day + "/" + year
  else
    dateStr = day + "/" + month + "/" + year

  return dateStr

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

            if employee.fields.jobTitle
              result = "*Job Title:* #{employee.fields.jobTitle}\n"
            
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

  robot.respond /whos(out|off)(\stoday|\stomorrow|\sthis\sweek|\sthis\smonth|\snext\sweek|\snext\smonth)?$/i, (msg) ->

    bambooapi = new (require 'node-bamboohr')({apikey: "#{bamboohr_apikey}", subdomain: "#{bamboohr_domain}"})

    timePeriod = msg.match[2];

    if !timePeriod
      timePeriod = "today"
    else
      timePeriod = timePeriod.trim()

    #console.log "timePeriod is #{timePeriod}"

    #set the dates
    startDate = new Date()
    endDate = new Date()

    switch timePeriod
      when "tomorrow"
        startDate = new Date(1900+startDate.getYear(), startDate.getMonth(), startDate.getDate() + 1)
        endDate = new Date(1900+startDate.getYear(), startDate.getMonth(), startDate.getDate())
      
      when "this week"
        endDate = new Date(1900+startDate.getYear(), startDate.getMonth(), startDate.getDate() + 6 - startDate.getDay() )
      
      when "this month"
        endDate = new Date(1900+startDate.getYear(), startDate.getMonth()+1, 0)
      
      when "next week"
        offset = 7-startDate.getDay()
        
        startDate = new Date(1900+startDate.getYear(), startDate.getMonth(), startDate.getDate() + offset)

        endDate = new Date(1900+startDate.getYear(), startDate.getMonth(), startDate.getDate() + 6 - startDate.getDay() )

      when "next month"
        startDate = new Date(1900+startDate.getYear(), startDate.getMonth()+1, 1)
        endDate = new Date(1900+startDate.getYear(), startDate.getMonth()+1, 0)
      
    #startdate
    startDateStr = formatDateString(startDate);
    endDateStr = formatDateString(endDate);

    #console.log "startDate is #{startDate}"
    #console.log "endDate is #{endDateStr}"

    peopleOnLeave = false

    bambooapi.whosOut startDateStr, endDateStr, (err, obj) ->
      
      from = getDay(startDate) + "/" + getMonth(startDate) + "/" + getYear(startDate)
      to = getDay(endDate) + "/" + getMonth(endDate) + "/" + getYear(endDate)

      if date_format && date_format.toLowerCase() == "us"
        from = getMonth(startDate) + "/" + getDay(startDate) + "/" + getYear(startDate)
        to = getMonth(endDate) + "/" + getDay(endDate) + "/" + getYear(endDate)

      response = "*People on leave (#{from} - #{to})*\n\n"

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
