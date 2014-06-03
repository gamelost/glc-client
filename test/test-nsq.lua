require "library/nsq"

queue = ...

n = NsqHttp:new()

print("testing nsq")
print("creating topic: " .. n:createTopic("testing").status_txt)
print("publishing to topic: " .. n:publish("testing", "{}"))
print("deleting topic: " .. n:deleteTopic("testing").status_txt)
