# Description:
#   A script that allows users to make redisred links through hubot
#
# Configuration:
#   HUBOT_REDISRED_URL - The base URL for redirects, not including the API path.
#   HUBOT_REDISRED_TOKEN - The API token to be used for the requests.
#   HUBOT_REDISRED_PREFIX - (requires restart) The prefix to auto-expand links. "" to disable.
#
# Commands:
#   hubot redisred list - list all redirects
#   hubot redisred list <regex> - list all redirects whose key matches regex
#   hubot redisred info <key> - get info for redirect whose key is exactly key
#   hubot redisred create <key> <url> - create redirect from key and url
#   hubot redisred delete <key> - delete a redirect
#
# Author:
#   Detry322

filter = (arr, func) ->
  filtered = []
  for item in arr
    if func item
      filtered.push item
  filtered

module.exports = (robot) ->
  config = require('hubot-conf')('redisred', robot)

  cache = {}

  formatRedirect = (redirect) ->
    "(#{redirect.clicks} clicks) #{redirect.url}"

  formatRedirects = (redirects) ->
    message = "*Redirects:*"
    for redirect in redirects
      message += "\n" + formatRedirect(redirect)
    message

  formatShortlinks = (redirects) ->
    message = ""
    for redirect in redirects
      message += config('prefix').toUpperCase() + " link: #{config('url')}/#{redirect.key}\n"
    message.trim()

  modifyRedirects = (action, data, callback) ->
    postData = JSON.stringify(data)
    robot.http(config('url') + "/admin/api/" + action)
        .header('Content-Type', 'application/json')
        .header('Accept', 'application/json')
        .header('x-access-token', config("token"))
        .post(postData) (err, httpResponse, body) ->
          if not err and httpResponse.statusCode is 200
            try
              redirect = JSON.parse body
              callback(false, redirect)
            catch error
              callback(error)
          else
            callback(err || httpResponse)

  fetchRedirects = (callback) ->
    robot.http(config('url') + "/admin/api/")
        .header('Accept', 'application/json')
        .header('x-access-token', config("token"))
        .get() (err, httpResponse, body) ->
          if not err and httpResponse.statusCode is 200
            try
              redirects = JSON.parse body
              for redirect in redirects
                cache[redirect.key] = redirect
              callback(false, redirects)
            catch error
              callback(error)
          else
            callback(err || httpResponse)

  createRedirect = (res, key, url) ->
    data = {key: key, url: url}
    modifyRedirects 'create', data, (err, redirect) ->
      if (err)
        res.send "Error creating redirect."
      else
        cache[redirect.key] = redirect
        res.send "*Redirect Created:*\n" + formatRedirect(redirect)

  deleteRedirect = (res, key) ->
    data = {key: key}
    modifyRedirects 'delete', data, (err, redirect) ->
      if (err)
        res.send "Error deleting redirect."
      else
        delete cache[key]
        res.send "Deleted redirect: #{key}"

  listRedirects = (res, search) ->
    fetchRedirects (err, redirects) ->
      if (err)
        res.send "Error fetching redirects."
      else
        filtered = filter redirects, (redirect) ->
          redirect.key.match search
        res.send formatRedirects(filtered)

  fetchInfo = (res, key) ->
    fetchRedirects (err, redirects) ->
      if (err)
        res.send "Error fetching redirect."
      else
        filtered = filter redirects, (redirect) ->
          redirect.key == key
        res.send formatRedirect(filtered[0])

  if config('prefix')
    robot.hear ///#{config('prefix')}/([^\s+])///i, (res) ->
      redirects = []
      for key, value of cache
        if ///#{config('prefix')}/#{key}(\s|$)///i.test res.message.text
          redirects.push value
      if redirects.length != 0
        res.send formatShortlinks(redirects)

    fetchRedirects () ->
      # Fetch redirects so they start working immediately.

  robot.respond /redisred list$/i, (res) ->
    listRedirects(res, "")

  robot.respond /redisred list (.+)$/i, (res) ->
    search = res.match[1]
    listRedirects(res, search)

  robot.respond /redisred info ([^ \n]+)$/i, (res) ->
    key = res.match[1]
    fetchInfo(res, key)

  robot.respond /redisred create ([^ \n]+) (.+)$/i, (res) ->
    key = res.match[1]
    url = res.match[2]
    createRedirect(res, key, url)

  robot.respond /redisred delete ([^ \n]+)/i, (res) ->
    key = res.match[1]
    deleteRedirect(res, key)
