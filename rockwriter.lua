local fs = fs or require("filekit")
local si = require("sirocco")
local argparse = require("argparse")
local args
do
  local _with_0 = argparse()
  _with_0:name("rockwriter")
  _with_0:description("A tool to help you create rockspecs easily!")
  _with_0:epilog("Homepage - https://github.com/daelvn/rockwriter")
  do
    local _with_1 = _with_0:flag("-u --update", "Will just update the version")
    _with_1:target("update")
    _with_1:count("?")
  end
  do
    local _with_1 = _with_0:argument("path", "Path to the rockspec")
    _with_1:args("?")
  end
  do
    local _with_1 = _with_0:flag("--rockspec-format", "Explicitly asks for rockspec format")
    _with_1:target("rf")
  end
  do
    local _with_1 = _with_0:flag("--issue-url", "Explicitly asks for issue URL")
    _with_1:target("iurl")
  end
  do
    local _with_1 = _with_0:flag("--maintainer", "Explicitly asks for maintainer info")
    _with_1:target("mt")
  end
  _with_0:flag("--labels", "Explicitly asks for labels")
  do
    local _with_1 = _with_0:flag("--supported-platforms", "Explicitly asks for supported platforms")
    _with_1:target("platforms")
  end
  do
    local _with_1 = _with_0:flag("--build-deps", "Explicitly asks for build dependencies")
    _with_1:target("bdeps")
  end
  do
    local _with_1 = _with_0:flag("--md5", "Explicitly asks for a MD5 sum for the source archive.")
    _with_1:target("md5")
  end
  do
    local _with_1 = _with_0:flag("--file", "Explicitly asks for a name for the archive")
    _with_1:target("file")
  end
  do
    local _with_1 = _with_0:flag("--dir", "Explicitly asks for a dir name for the archive to be extracted")
    _with_1:target("dir")
  end
  do
    local _with_1 = _with_0:flag("--tag", "Explicitly asks for a CVS tag")
    _with_1:target("tag")
  end
  do
    local _with_1 = _with_0:flag("--branch", "Explicitly asks for a CVS branch")
    _with_1:target("branch")
  end
  do
    local _with_1 = _with_0:flag("--module", "Explicitly asks for a CVS module")
    _with_1:target("mod")
  end
  args = _with_0:parse()
end
args.path = args.path or (function()
  for _, node in pairs(fs.list(fs.currentDir())) do
    do
      local file = node:match(".+%.rockspec")
      if file then
        return file
      end
    end
  end
  return error("No .rockspec file in current directory!")
end)()
local ask
ask = function(f)
  return f:ask()
end
local pick1
pick1 = function(t)
  return t[1]
end
local sanitize
sanitize = function(pattern)
  if pattern then
    return pattern:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0")
  end
end
local pass
pass = function(s)
  return s and s:len() > 0
end
local ap
ap = function(t)
  return ask(si.prompt(t))
end
local passT
passT = function(t)
  local count = 0
  for k, v in pairs(t) do
    count = count + 1
  end
  return count > 0
end
local spacesToArray
spacesToArray = function(str)
  local start = "{ "
  for word in str:gmatch("%S+") do
    start = start .. "\"" .. tostring(word) .. "\", "
  end
  return start .. " }"
end
local serializeTable
serializeTable = function(t)
  local start = "{ "
  for k, v in pairs(t) do
    start = start .. "[\"" .. tostring(k) .. "\"] = \"" .. tostring(v) .. "\", "
  end
  return start .. "}"
end
if args.update then
  if not (fs.exists(args.path)) then
    error(tostring(args.path) .. " does not exist!")
  end
  local newv = ap({
    required = true,
    prompt = "New version -> "
  })
  local doTagv = pick1(ask(si.confirm({
    prompt = "Want to change the tag version?"
  })))
  local tagv
  if doTagv then
    tagv = ap({
      required = true,
      prompt = "New tag     -> "
    })
  end
  local oldv
  do
    local _with_0 = fs.safeOpen(args.path, "r+")
    if _with_0.error then
      error(tostring(_with_0.error))
    end
    local contents = _with_0:read("*a")
    oldv = contents:match([[version = "(.-)"]])
    _with_0:seek("set")
    local newc = contents:gsub([[version = ".-"]], "version = \"" .. tostring(newv) .. "\"")
    if doTagv then
      newc = newc:gsub([[tag = ".-"]], "tag = \"" .. tostring(tagv) .. "\"")
    end
    print("New file contents:\n" .. tostring(newc))
    _with_0:write(newc)
    _with_0:close()
  end
  print("Moving " .. tostring(args.path) .. " (" .. tostring(oldv) .. ") to " .. tostring(args.path:gsub((sanitize(oldv)), newv)) .. " (" .. tostring(newv) .. ")")
  return fs.move(args.path, args.path:gsub((sanitize(oldv)), newv))
else
  local pkg = {
    d = { },
    dep = { },
    s = { },
    b = { },
    i = { },
    t = { }
  }
  if not (args.rf) then
    pkg.rf = nil
  else
    pkg.rf = ap({
      prompt = "Rockspec format          -> ",
      possibleValues = {
        "1.0"
      }
    })
  end
  pkg.name = ap({
    required = true,
    prompt = "Package name             -> ",
    validator = function(text)
      return (text:match("[a-zA-Z0-9.-]*")), "Invalid name for package."
    end
  })
  pkg.version = ap({
    required = true,
    prompt = "Package version          -> "
  })
  pkg.d.summary = ap({
    prompt = "Summary                  -> "
  })
  pkg.d.detailed = ap({
    prompt = "Detailed description     -> "
  })
  pkg.d.homepage = ap({
    prompt = "Homepage                 -> "
  })
  pkg.d.license = ap({
    prompt = "License                  -> "
  })
  if not (args.iu) then
    pkg.d.iu = nil
  else
    pkg.d.iu = ap({
      prompt = "Issues URL               -> "
    })
  end
  if not (args.mt) then
    pkg.d.mt = nil
  else
    pkg.d.mt = ap({
      prompt = "Maintainer               -> "
    })
  end
  if not (args.labels) then
    pkg.d.labels = nil
  else
    pkg.d.labels = ap({
      prompt = "Labels (space-sep)       -> "
    })
  end
  if not (args.platforms) then
    pkg.dep.platforms = nil
  else
    pkg.dep.platforms = ap({
      prompt = "Platforms (space-sep)    -> "
    })
  end
  pkg.dep.deps = ap({
    prompt = "Dependencies (space-sep) -> "
  })
  if not (args.bdeps) then
    pkg.dep.buildeps = nil
  else
    pkg.dep.buildeps = ap({
      prompt = "Build deps (space-sep)   -> "
    })
  end
  pkg.s.url = ap({
    required = true,
    prompt = "Source URL               -> "
  })
  if not (args.file) then
    pkg.s.file = nil
  else
    pkg.s.file = ap({
      prompt = "Archive name             -> "
    })
  end
  if not (args.md5) then
    pkg.s.md5 = nil
  else
    pkg.s.md5 = ap({
      prompt = "MD5                      -> "
    })
  end
  if not (args.dir) then
    pkg.s.dir = nil
  else
    pkg.s.dir = ap({
      prompt = "Directory to extract to  -> "
    })
  end
  if not (args.tag) then
    pkg.s.tag = nil
  else
    pkg.s.tag = ap({
      prompt = "Tag                      -> "
    })
  end
  if not (args.branch) then
    pkg.s.branch = nil
  else
    pkg.s.branch = ap({
      prompt = "Branch                   -> "
    })
  end
  if not (args.mod) then
    pkg.s.mod = nil
  else
    pkg.s.mod = ap({
      prompt = "Module                   -> "
    })
  end
  pkg.b.copydir = ap({
    prompt = "Copy dirs (space-sep)    -> "
  })
  pkg.b.type = ap({
    required = true,
    prompt = "Build type               -> "
  })
  local _exp_0 = pkg.b.type
  if "command" == _exp_0 then
    pkg.b.buildcom = ap({
      prompt = "Build command            -> "
    })
    pkg.b.inscom = ap({
      prompt = "Install command          -> "
    })
  elseif "cmake" == _exp_0 then
    pkg.b.cmake = ap({
      prompt = "CMake contents           -> "
    })
    pkg.b.cmvars = ap({
      prompt = "CMake additional vars    -> "
    })
  elseif "make" == _exp_0 then
    pkg.b.mkfile = ap({
      prompt = "Makefile path            -> "
    })
    pkg.b.mkbp = pick1(ask(si.confirm({
      prompt = "Perform Makefile build target?"
    })))
    if pkg.b.mkbp then
      pkg.b.mkbt = ap({
        prompt = "Makefile build target    -> "
      })
    end
    pkg.b.mkip = pick1(ask(si.confirm({
      prompt = "Perform Makefile install target?"
    })))
    if pkg.b.mkip then
      pkg.b.mkit = ap({
        prompt = "Makefile install target  -> "
      })
    end
    pkg.b.mkbv = ap({
      prompt = "Makefile build vars      -> "
    })
    pkg.b.mkiv = ap({
      prompt = "Makefile install vars    -> "
    })
    pkg.b.mkv = ap({
      prompt = "Makefile variables       -> "
    })
  elseif "builtin" == _exp_0 then
    pkg.b.builtin = { }
    print("Entering modules. Simply leave a field empty to stop.")
    while true do
      local mod = ap({
        prompt = "   Module name           -> "
      })
      if not (pass(mod)) then
        break
      end
      local path = ap({
        prompt = "   Path                  -> "
      })
      pkg.b.builtin[mod] = path
    end
  end
  pkg.i["do"] = pick1(ask(si.confirm({
    prompt = "Want to add install details?"
  })))
  pkg.i.doLua, pkg.i.doLib, pkg.i.doConf, pkg.i.doBin = false, false, false, false
  if pkg.i["do"] then
    pkg.i.doLua = pick1(ask(si.confirm({
      prompt = "Want to install Lua modules?"
    })))
    pkg.i.doLib = pick1(ask(si.confirm({
      prompt = "Want to install libraries?"
    })))
    pkg.i.doConf = pick1(ask(si.confirm({
      prompt = "Want to install config files?"
    })))
    pkg.i.doBin = pick1(ask(si.confirm({
      prompt = "Want to install Lua command-line scripts?"
    })))
  end
  pkg.i.lua = { }
  if pkg.i.doLua then
    print("Entering Lua modules. Simply leave a field empty to stop.")
    while true do
      local mod = ap({
        prompt = "   Module name           -> "
      })
      if not (pass(mod)) then
        break
      end
      local path = ap({
        prompt = "   Path                  -> "
      })
      pkg.i.lua[mod] = path
    end
  end
  pkg.i.lib = { }
  if pkg.i.doLib then
    print("Entering libraries. Simply leave a field empty to stop.")
    while true do
      local mod = ap({
        prompt = "   Module name           -> "
      })
      if not (pass(mod)) then
        break
      end
      local path = ap({
        prompt = "   Path                  -> "
      })
      pkg.i.lib[mod] = path
    end
  end
  pkg.i.conf = { }
  if pkg.i.doConf then
    print("Entering configuration files. Simply leave a field empty to stop.")
    while true do
      local name = ap({
        prompt = "   Name                  -> "
      })
      if not (pass(name)) then
        break
      end
      local path = ap({
        prompt = "   Path                  -> "
      })
      pkg.i.conf[name] = path
    end
  end
  pkg.i.bin = { }
  if pkg.i.doBin then
    print("Entering Lua command-line scripts. Simply leave a field empty to stop.")
    while true do
      local name = ap({
        prompt = "   Name                  -> "
      })
      if not (pass(name)) then
        break
      end
      local path = ap({
        prompt = "   Path                  -> "
      })
      pkg.i.bin[name] = path
    end
  end
  do
    local _with_0 = fs.safeOpen(args.path, "w")
    if _with_0.error then
      error(tostring(_with_0.error))
    end
    if pass(pkg.rf) then
      _with_0:write("rockspec_format = \"" .. tostring(pkg.rf) .. "\"\n")
    end
    if pass(pkg.name) then
      _with_0:write("package = \"" .. tostring(pkg.name) .. "\"\n")
    end
    if pass(pkg.version) then
      _with_0:write("version = \"" .. tostring(pkg.version) .. "\"\n")
    end
    _with_0:write("description = {\n")
    if pass(pkg.d.summary) then
      _with_0:write("  summary = \"" .. tostring(pkg.d.summary) .. "\",\n")
    end
    if pass(pkg.d.detailed) then
      _with_0:write("  detailed = [[" .. tostring(pkg.d.detailed) .. "]],\n")
    end
    if pass(pkg.d.license) then
      _with_0:write("  license = \"" .. tostring(pkg.d.license) .. "\",\n")
    end
    if pass(pkg.d.homepage) then
      _with_0:write("  homepage = \"" .. tostring(pkg.d.homepage) .. "\",\n")
    end
    if pass(pkg.d.iu) then
      _with_0:write("  issues_url = \"" .. tostring(pkg.d.iu) .. "\",\n")
    end
    if pass(pkg.d.mt) then
      _with_0:write("  maintainer = \"" .. tostring(pkg.d.mt) .. "\",\n")
    end
    if pass(pkg.d.labels) then
      _with_0:write("  labels = " .. tostring(spacesToArray(pkg.d.labels)) .. ",\n")
    end
    _with_0:write("}\n")
    if pass(pkg.dep.deps) then
      _with_0:write("dependencies = " .. tostring(spacesToArray(pkg.dep.deps)) .. "\n")
    end
    if pass(pkg.dep.platforms) then
      _with_0:write("supported_platforms = " .. tostring(spacesToArray(pkg.dep.platforms)) .. "\n")
    end
    if pass(pkg.dep.buildeps) then
      _with_0:write("build_dependencies = " .. tostring(spacesToArray(pkg.dep.buildeps)) .. "\n")
    end
    _with_0:write("source = {\n")
    if pass(pkg.s.url) then
      _with_0:write("  url = \"" .. tostring(pkg.s.url) .. "\",\n")
    end
    if pass(pkg.s.md5) then
      _with_0:write("  md5 = \"" .. tostring(pkg.s.md5) .. "\",\n")
    end
    if pass(pkg.s.file) then
      _with_0:write("  file = \"" .. tostring(pkg.s.file) .. "\",\n")
    end
    if pass(pkg.s.dir) then
      _with_0:write("  dir = \"" .. tostring(pkg.s.dir) .. "\",\n")
    end
    if pass(pkg.s.tag) then
      _with_0:write("  tag = \"" .. tostring(pkg.s.tag) .. "\",\n")
    end
    if pass(pkg.s.branch) then
      _with_0:write("  branch = \"" .. tostring(pkg.s.branch) .. "\",\n")
    end
    if pass(pkg.s.mod) then
      _with_0:write("  module = \"" .. tostring(pkg.s.mod) .. "\",\n")
    end
    _with_0:write("}\n")
    _with_0:write("build = {\n")
    if pass(pkg.b.type) then
      _with_0:write("  type = \"" .. tostring(pkg.b.type) .. "\",\n")
    end
    if pass(pkg.b.copydir) then
      _with_0:write("  copy_directories = " .. tostring(spacesToArray(pkg.b.copydir)) .. ",\n")
    end
    local _exp_1 = pkg.b.type
    if "command" == _exp_1 then
      if pass(pkg.b.buildcom) then
        _with_0:write("  build_command = [[" .. tostring(pkg.b.buildcom) .. "]],\n")
      end
      if pass(pkg.b.inscom) then
        _with_0:write("  install_command = [[" .. tostring(pkg.b.inscom) .. "]],\n")
      end
    elseif "cmake" == _exp_1 then
      if pass(pkg.b.cmake) then
        _with_0:write("  cmake = [[" .. tostring(pkg.b.cmake) .. "]],\n")
      end
      if pass(pkg.b.cmvars) then
        _with_0:write("  variables = " .. tostring(spacesToArray(pkg.b.cmvars)) .. ",\n")
      end
    elseif "make" == _exp_1 then
      if pass(pkg.b.mkfile) then
        _with_0:write("  makefile = \"" .. tostring(pkg.b.mkfile) .. "\",\n")
      end
      if pkg.b.mkbp then
        _with_0:write("  build_pass = " .. tostring(pkg.b.mkbp) .. ",\n")
      end
      if pass(pkg.b.mkbp and pkg.b.mkbt) then
        _with_0:write("  build_target = \"" .. tostring(pkg.b.mkbt) .. "\",\n")
      end
      if pkg.b.mkip then
        _with_0:write("  install_pass = " .. tostring(pkg.b.mkip) .. ",\n")
      end
      if pass(pkg.b.mkip and pkg.b.mkit) then
        _with_0:write("  install_target = \"" .. tostring(pkg.b.mkit) .. "\",\n")
      end
      if pass(pkg.b.mkbv) then
        _with_0:write("  build_variables = " .. tostring(spacesToArray(pkg.b.mkbv)) .. ",\n")
      end
      if pass(pkg.b.mkiv) then
        _with_0:write("  install_variables = " .. tostring(spacesToArray(pkg.b.mkiv)) .. ",\n")
      end
      if pass(pkg.b.mkv) then
        _with_0:write("  variables = " .. tostring(spacesToArray(pkg.b.mkv)) .. ",\n")
      end
    elseif "builtin" == _exp_1 then
      if passT(pkg.b.builtin) then
        _with_0:write("  modules = " .. tostring(serializeTable(pkg.b.builtin)) .. ",\n")
      end
    end
    if pkg.i["do"] then
      _with_0:write("  install = {\n")
    end
    if pkg.i.doLua then
      _with_0:write("    lua = " .. tostring(serializeTable(pkg.i.lua)) .. ",\n")
    end
    if pkg.i.doLib then
      _with_0:write("    lib = " .. tostring(serializeTable(pkg.i.lib)) .. ",\n")
    end
    if pkg.i.doConf then
      _with_0:write("    conf = " .. tostring(serializeTable(pkg.i.conf)) .. ",\n")
    end
    if pkg.i.doBin then
      _with_0:write("    bin = " .. tostring(serializeTable(pkg.i.bin)) .. ",\n")
    end
    if pkg.i["do"] then
      _with_0:write("  }\n")
    end
    _with_0:write("}\n")
    _with_0:close()
    return _with_0
  end
end
