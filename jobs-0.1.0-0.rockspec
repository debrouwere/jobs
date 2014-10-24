package = "Jobs"
version = "0.1.0-0"
source = {
   url = "..." -- We don't have one yet
}
description = {
   summary = "A next-generation cron.",
   homepage = "http://...", -- We don't have one yet
   license = "MIT" -- or whatever you like
}
dependencies = {
   "lua ~> 5.1", 
   "moonscript ~> 0.2.6", 
   "luasocket ~> 3", 
   "redis-lua ~> 2", 
   "luafilesystem ~> 1.6"
}
build = {
   type = "make"
}