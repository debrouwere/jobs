package = "Jobs"
version = "0.1.0-0"
source = {
   url = "https://github.com/debrouwere/jobs/archive/master.zip"
}
description = {
   summary = "A next-generation cron.",
   homepage = "https://github.com/debrouwere/jobs/", 
   license = "ISC"
}
dependencies = {
   "lua ~> 5.1", 
   "moonscript ~> 0.2.6", 
   "luasocket ~> 3", 
   "lua-cjson ~> 2", 
   "redis-lua ~> 2", 
   "luafilesystem ~> 1.6", 
   "argparse ~> 0.3", 
   "busted ~> 2"
}
build = {
   type = "make"
}