require "modules/hotkey"
require "modules/auto_reload"
--require "modules/statuslet"
require "modules/windows"
require "modules/screens"
require "modules/system"
require "modules/watcher"
require "modules/launch"

-- Finally, show a notification that we finished loading the config successfully
hs.notify.new({
    title='Hammerspoon',
    informativeText='Config loaded'
  }):send()

collectgarbage("setstepmul", 1000)
collectgarbage("setpause", 1)

--local wfRedshift=hs.window.filter.new({loginwindow={visible=true,allowRoles='*'}},'wf-redshift')
--hs.redshift.start(2000,'20:00','7:00','3h',false,wfRedshift)
