-- TODO: once we have a stable release, stop 
-- using master for the latest releases

package = "Jobs"
version = "scm-1"
source = {
   url = "https://github.com/debrouwere/jobs/archive/master.zip", 
   branch = "master", 
   dir = "jobs-master"
}
description = {
   summary = "A next-generation cron.",
   homepage = "https://github.com/debrouwere/jobs/", 
   license = "ISC"
}
dependencies = {
   "lua >= 5.1", 
   "moonscript >= 0.2.6", 
   "luasocket ~> 3", 
   "lua-cjson ~> 2", 
   "redis-lua ~> 2", 
   "luafilesystem ~> 1.6", 
   "argparse ~> 0.3", 
   "luaposix ~> 33", 
   "busted ~> 2"
}
build = {
   type = "none", 
   copy_directories = { "bin", "lib", "test" }, 
   install = {
      bin = {
         "bin/jobs", 
         "bin/jobs-log-runner", 
         "bin/jobs-shell-runner"
      }
   }
}