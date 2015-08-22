# Description:
#   BambooHR Plugin for Hubot
#
# Dependencies:
#   node-bamboohr
#
# Configuration:
#   HUBOT_BAMBOOHR_APIKEY
#   HUBOT_BAMBOOHR_DOMAIN
#
# Commands:
#   hubot bamboo <employee name> - returns the details for the employee from bamboohr
#   hubot whos(off|out) - returns the list of employees that are on leave today
#
# Author:
#   Jordan Walsh <jordanwalsh23@gmail.com>

bamboohr_apikey = process.env.HUBOT_BAMBOOHR_APIKEY
bamboohr_domain = process.env.HUBOT_BAMBOOHR_DOMAIN
date_format = process.env.HUBOT_BAMBOOHR_DATEFORMAT
default_timezone = process.env.HUBOT_BAMBOOHR_TIMEZONE

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

  robot.respond /whos(out|off)(\stoday|\sthis\sweek|\sthis\smonth)?$/i, (msg) ->

    bambooapi = new (require 'node-bamboohr')({apikey: "#{bamboohr_apikey}", subdomain: "#{bamboohr_domain}"})

    timePeriod = msg.match[2];

    if !timePeriod
      timePeriod = "today"
    else
      timePeriod = timePeriod.trim()

    console.log "timePeriod is #{timePeriod}"

    #set the dates
    startDate = new Date()
    endDate = new Date()

    if timePeriod == "this month"
      endDate = new Date(1900+startDate.getYear(), startDate.getMonth()+1, 0)
    
    if timePeriod == "this week"
      endDate = new Date(1900+startDate.getYear(), startDate.getMonth()+1, 0)

    #startdate
    startDateStr = formatDateString(startDate);
    endDateStr = formatDateString(endDate);

    console.log "startDate is #{startDate}"
    console.log "endDate is #{endDateStr}"

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
          response += "#{timeoff.start[0]} - #{timeoff.end[0]}\n\n"
          peopleOnLeave = true
      
      if peopleOnLeave
        msg.send response
      else
        msg.send "Seems everyone is hard at work. No leave booked on #{dd}/#{mm}/#{yyyy}"
