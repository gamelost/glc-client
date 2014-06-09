require "library/http"
require "library/json"
require "conf"

NsqHttp = Http:new{url_prefix=settings.nsq_http_api}

function NsqHttp:checkStatus()
  return function(status, response)
    if status ~= 200 then
      error("invalid status " .. status)
    end
    if response:lower() ~= "ok" then
      error("invalid response " .. response)
    end
    return "OK"
  end
end

function NsqHttp:decodeJson()
  return function(status, response)
    if status ~= 200 then
      error("invalid status " .. status)
    end
    return json.decode(response)
  end
end

function NsqHttp:publish(topic, message)
  return self:post("/pub", {topic=topic}, message, self.checkStatus())
end

function NsqHttp:multi_publish(topic, messages)
  -- NB. not tested. probably does not work.
  -- if anyone wants to work on this, he or she should implement the 'binary' flag.
  print("Warning: NsqHttp:multi_publish is not fully implemented.\n")
  return self:post("/mpub", {topic=topic}, table.join(message, "\n"), self.checkStatus())
end

function NsqHttp:createTopic(topic)
  return self:get("/create_topic", {topic=topic}, self.decodeJson())
end

function NsqHttp:emptyTopic(topic)
  return self:get("/empty_topic", {topic=topic}, self.decodeJson())
end

function NsqHttp:deleteTopic(topic)
  return self:get("/delete_topic", {topic=topic}, self.decodeJson())
end

function NsqHttp:pauseTopic(topic)
  return self:get("/pause_topic", {topic=topic}, self.decodeJson())
end

function NsqHttp:unpauseTopic(topic)
  return self:get("/unpause_topic", {topic=topic}, self.decodeJson())
end

function NsqHttp:createChannel(topic, channel)
  return self:get("/create_channel", {topic=topic, channel=channel}, self.decodeJson())
end

function NsqHttp:emptyChannel(topic, channel)
  return self:get("/empty_channel", {topic=topic, channel=channel}, self.decodeJson())
end

function NsqHttp:deleteChannel(topic, channel)
  return self:get("/delete_channel", {topic=topic, channel=channel}, self.decodeJson())
end

function NsqHttp:pauseChannel(topic, channel)
  return self:get("/pause_channel", {topic=topic, channel=channel}, self.decodeJson())
end

function NsqHttp:unpauseChannel(topic, channel)
  return self:get("/unpause_channel", {topic=topic, channel=channel}, self.decodeJson())
end

function NsqHttp:stats()
  return self:get("/stats", {format="json"}, self.decodeJson())
end

function NsqHttp:ping()
  return self:get("/ping", {}, self:checkStatus())
end

function NsqHttp:info()
  return self:get("/info", {}, self:decodeJson())
end
