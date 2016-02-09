path = require('path')
getLibDir = (filepath) ->
  home =
    if process.platform.startsWith 'win'
    then process.env.HOMEPATH else process.env.HOME
  projpaths = ["#{home}/github/Test-Lab"]
  curpath = path.dirname filepath
  while curpath != path.dirname(curpath)
    console.log curpath
    return false if curpath in projpaths
    return false if curpath is home
    return "-I#{curpath}" if path.basename(curpath) is 'lib'
    curpath = path.dirname curpath
  return false

console.log getLibDir process.argv[2]
