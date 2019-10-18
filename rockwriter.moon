-- Write rockspecs easily!
-- By daelvn
fs     or= require "filekit"
si       = require "sirocco"
argparse = require "argparse"

local args
with argparse!
  \name        "rockwriter"
  \description "A tool to help you create rockspecs easily!"
  \epilog      "Homepage - https://github.com/daelvn/rockwriter"

  -- Update flag (only change version)
  with \flag "-u --update", "Will just update the version"
    \target "update"
    \count  "?"

  -- Optional path to the rockspec.
  with \argument "path", "Path to the rockspec"
    \args "?"

  -- Will ask for rockspec format.
  with \flag "--rockspec-format", "Explicitly asks for rockspec format"
    \target "rf"

  -- Will ask for issue URL
  with \flag "--issue-url", "Explicitly asks for issue URL"
    \target "iurl"

  -- Will ask for maintainer
  with \flag "--maintainer", "Explicitly asks for maintainer info"
    \target "mt"

  -- Will ask for labels
  \flag "--labels", "Explicitly asks for labels"

  -- Will ask for supported platforms
  with \flag "--supported-platforms", "Explicitly asks for supported platforms"
    \target "platforms"

  -- Will ask for build dependencies
  with \flag "--build-deps", "Explicitly asks for build dependencies"
    \target "bdeps"

  -- Will ask for an md5 sum for the source archive.
  with \flag "--md5", "Explicitly asks for a MD5 sum for the source archive."
    \target "md5"

  -- Will ask for a name for the archive
  with \flag "--file", "Explicitly asks for a name for the archive"
    \target "file"

  -- Will ask for a dir name for the archive to be extracted
  with \flag "--dir", "Explicitly asks for a dir name for the archive to be extracted"
    \target "dir"

  -- Will ask for a tag (CVS)
  with \flag "--tag", "Explicitly asks for a CVS tag"
    \target "tag"

  -- Will ask for a branch (CVS)
  with \flag "--branch", "Explicitly asks for a CVS branch"
    \target "branch"

  -- Will ask for a module (CVS)
  with \flag "--module", "Explicitly asks for a CVS module"
    \target "mod"

  args = \parse!

args.path or= do
  for _, node in pairs fs.list fs.currentDir!
    if file = node\match ".+%.rockspec"
      return file
  error "No .rockspec file in current directory!"

ask      = (f)       -> f\ask!
pick1    = (t)       -> t[1]
sanitize = (pattern) -> pattern\gsub "[%(%)%.%%%+%-%*%?%[%]%^%$]", "%%%0" if pattern
pass     = (s)       -> s and s\len! > 0
ap       = (t)       -> ask si.prompt t
passT    = (t)       ->
  count  = 0
  for k, v in pairs t
    count += 1
  count > 0

spacesToArray = (str) ->
  start = "{ "
  for word in str\gmatch "%S+"
    start ..= "\"#{word}\", "
  start .. " }"

serializeTable = (t) ->
  start = "{ "
  for k, v in pairs t
    start ..= "[\"#{k}\"] = \"#{v}\", "
  start .. "}"

if args.update
  error "#{args.path} does not exist!" unless fs.exists args.path
  newv = ap
    required: true
    prompt:   "New version -> "
  doTagv = pick1 ask si.confirm prompt: "Want to change the tag version?"
  local tagv
  if doTagv
    tagv = ap
      required: true
      prompt:   "New tag     -> "
  local oldv
  with fs.safeOpen args.path, "r+"
    error "#{.error}" if .error
    contents = \read "*a"
    oldv     = contents\match [[version = "(.-)"]]
    \seek "set"
    newc = contents\gsub [[version = ".-"]], "version = \"#{newv}\""
    newc = newc\gsub     [[tag = ".-"]],     "tag = \"#{tagv}\"" if doTagv
    print "New file contents:\n#{newc}"
    \write newc
    \close!
  print "Moving #{args.path} (#{oldv}) to #{args.path\gsub (sanitize oldv), newv} (#{newv})"
  fs.move args.path, args.path\gsub (sanitize oldv), newv
else
  pkg               = { d: {}, dep: {}, s: {}, b: {}, i: {}, t: {} }
  -- general
  pkg.rf            = unless args.rf then nil else ap
    prompt:         "Rockspec format          -> "
    possibleValues: { "1.0" }
  pkg.name          = ap
    required:       true
    prompt:         "Package name             -> "
    validator:      (text) -> return (text\match "[a-zA-Z0-9.-]*"), "Invalid name for package."
  pkg.version       = ap
    required:       true
    prompt:         "Package version          -> "
  -- description
  pkg.d.summary     = ap prompt:                                     "Summary                  -> "
  pkg.d.detailed    = ap prompt:                                     "Detailed description     -> "
  pkg.d.homepage    = ap prompt:                                     "Homepage                 -> "
  pkg.d.license     = ap prompt:                                     "License                  -> "
  pkg.d.iu          = unless args.iu        then nil else ap prompt: "Issues URL               -> "
  pkg.d.mt          = unless args.mt        then nil else ap prompt: "Maintainer               -> "
  pkg.d.labels      = unless args.labels    then nil else ap prompt: "Labels (space-sep)       -> "
  -- dependencies
  pkg.dep.platforms = unless args.platforms then nil else ap prompt: "Platforms (space-sep)    -> "
  pkg.dep.deps      = ap prompt:                                     "Dependencies (space-sep) -> "
  pkg.dep.buildeps  = unless args.bdeps     then nil else ap prompt: "Build deps (space-sep)   -> "
  -- source
  pkg.s.url         = ap
    required:       true
    prompt:         "Source URL               -> "
  pkg.s.file        = unless args.file   then nil else ap prompt: "Archive name             -> "
  pkg.s.md5         = unless args.md5    then nil else ap prompt: "MD5                      -> "
  pkg.s.dir         = unless args.dir    then nil else ap prompt: "Directory to extract to  -> "
  pkg.s.tag         = unless args.tag    then nil else ap prompt: "Tag                      -> "
  pkg.s.branch      = unless args.branch then nil else ap prompt: "Branch                   -> "
  pkg.s.mod         = unless args.mod    then nil else ap prompt: "Module                   -> "
  -- build
  pkg.b.copydir     = ap prompt:                                  "Copy dirs (space-sep)    -> "
  pkg.b.type        = ap
    required:       true
    prompt:         "Build type               -> "
  switch pkg.b.type
    when "command"
      pkg.b.buildcom    = ap prompt:                   "Build command            -> "
      pkg.b.inscom      = ap prompt:                   "Install command          -> "
    when "cmake"
      pkg.b.cmake       = ap prompt:                   "CMake contents           -> "
      pkg.b.cmvars      = ap prompt:                   "CMake additional vars    -> "
    when "make"
      pkg.b.mkfile      = ap prompt:                   "Makefile path            -> "
      pkg.b.mkbp        = pick1 ask si.confirm prompt: "Perform Makefile build target?"
      if pkg.b.mkbp
        pkg.b.mkbt      = ap prompt:                   "Makefile build target    -> "
      pkg.b.mkip        = pick1 ask si.confirm prompt: "Perform Makefile install target?"
      if pkg.b.mkip
        pkg.b.mkit      = ap prompt:                   "Makefile install target  -> "
      pkg.b.mkbv        = ap prompt:                   "Makefile build vars      -> "
      pkg.b.mkiv        = ap prompt:                   "Makefile install vars    -> "
      pkg.b.mkv         = ap prompt:                   "Makefile variables       -> "
    when "builtin"
      -- only supports an array of strings
      pkg.b.builtin     = {}
      print "Entering modules. Simply leave a field empty to stop."
      while true
        mod  = ap prompt: "   Module name           -> "
        break unless pass mod
        path = ap prompt: "   Path                  -> "
        pkg.b.builtin[mod] = path
  -- install
  pkg.i.do              = pick1 ask si.confirm prompt: "Want to add install details?"
  --
  pkg.i.doLua, pkg.i.doLib, pkg.i.doConf, pkg.i.doBin = false, false, false, false
  if pkg.i.do
    pkg.i.doLua  = pick1 ask si.confirm prompt: "Want to install Lua modules?"
    pkg.i.doLib  = pick1 ask si.confirm prompt: "Want to install libraries?"
    pkg.i.doConf = pick1 ask si.confirm prompt: "Want to install config files?"
    pkg.i.doBin  = pick1 ask si.confirm prompt: "Want to install Lua command-line scripts?"
  pkg.i.lua = {}
  if pkg.i.doLua
    print "Entering Lua modules. Simply leave a field empty to stop."
    while true
      mod  = ap prompt: "   Module name           -> "
      break unless pass mod
      path = ap prompt: "   Path                  -> "
      pkg.i.lua[mod] = path
  pkg.i.lib = {}
  if pkg.i.doLib
    print "Entering libraries. Simply leave a field empty to stop."
    while true
      mod  = ap prompt: "   Module name           -> "
      break unless pass mod
      path = ap prompt: "   Path                  -> "
      pkg.i.lib[mod] = path
  pkg.i.conf = {}
  if pkg.i.doConf
    print "Entering configuration files. Simply leave a field empty to stop."
    while true
      name = ap prompt: "   Name                  -> "
      break unless pass name
      path = ap prompt: "   Path                  -> "
      pkg.i.conf[name] = path
  pkg.i.bin = {}
  if pkg.i.doBin
    print "Entering Lua command-line scripts. Simply leave a field empty to stop."
    while true
      name = ap prompt: "   Name                  -> "
      break unless pass name
      path = ap prompt: "   Path                  -> "
      pkg.i.bin[name] = path
  -- test
  --pkg.t.do = pick1 ask si.confirm prompt: "Want to add test details?"
  --if pkg.t.do
  --  pkg.rf       = "3.0"
  --  pkg.t.doDeps = pick1 ask si.confirm prompt: "Want to add test dependencies?"
  --
  with fs.safeOpen args.path, "w"
    error "#{.error}" if .error
    \write "rockspec_format = \"#{pkg.rf}\"\n"                          if pass pkg.rf
    \write "package = \"#{pkg.name}\"\n"                                if pass pkg.name
    \write "version = \"#{pkg.version}\"\n"                             if pass pkg.version
    \write "description = {\n"
    \write "  summary = \"#{pkg.d.summary}\",\n"                        if pass pkg.d.summary
    \write "  detailed = [[#{pkg.d.detailed}]],\n"                      if pass pkg.d.detailed
    \write "  license = \"#{pkg.d.license}\",\n"                        if pass pkg.d.license
    \write "  homepage = \"#{pkg.d.homepage}\",\n"                      if pass pkg.d.homepage
    \write "  issues_url = \"#{pkg.d.iu}\",\n"                          if pass pkg.d.iu
    \write "  maintainer = \"#{pkg.d.mt}\",\n"                          if pass pkg.d.mt
    \write "  labels = #{spacesToArray pkg.d.labels},\n"                if pass pkg.d.labels
    \write "}\n"
    \write "dependencies = #{spacesToArray pkg.dep.deps}\n"             if pass pkg.dep.deps
    \write "supported_platforms = #{spacesToArray pkg.dep.platforms}\n" if pass pkg.dep.platforms
    \write "build_dependencies = #{spacesToArray pkg.dep.buildeps}\n"   if pass pkg.dep.buildeps
    \write "source = {\n"
    \write "  url = \"#{pkg.s.url}\",\n"                                if pass pkg.s.url
    \write "  md5 = \"#{pkg.s.md5}\",\n"                                if pass pkg.s.md5
    \write "  file = \"#{pkg.s.file}\",\n"                              if pass pkg.s.file
    \write "  dir = \"#{pkg.s.dir}\",\n"                                if pass pkg.s.dir
    \write "  tag = \"#{pkg.s.tag}\",\n"                                if pass pkg.s.tag
    \write "  branch = \"#{pkg.s.branch}\",\n"                          if pass pkg.s.branch
    \write "  module = \"#{pkg.s.mod}\",\n"                             if pass pkg.s.mod
    \write "}\n"
    \write "build = {\n"
    \write "  type = \"#{pkg.b.type}\",\n"                              if pass pkg.b.type
    \write "  copy_directories = #{spacesToArray pkg.b.copydir},\n"     if pass pkg.b.copydir
    switch pkg.b.type
      when "command"
        \write "  build_command = [[#{pkg.b.buildcom}]],\n"             if pass pkg.b.buildcom
        \write "  install_command = [[#{pkg.b.inscom}]],\n"             if pass pkg.b.inscom
      when "cmake"
        \write "  cmake = [[#{pkg.b.cmake}]],\n"                        if pass pkg.b.cmake
        \write "  variables = #{spacesToArray pkg.b.cmvars},\n"         if pass pkg.b.cmvars
      when "make"
        \write "  makefile = \"#{pkg.b.mkfile}\",\n"                    if pass pkg.b.mkfile
        \write "  build_pass = #{pkg.b.mkbp},\n"                        if pkg.b.mkbp
        \write "  build_target = \"#{pkg.b.mkbt}\",\n"                  if pass pkg.b.mkbp and pkg.b.mkbt
        \write "  install_pass = #{pkg.b.mkip},\n"                      if pkg.b.mkip
        \write "  install_target = \"#{pkg.b.mkit}\",\n"                if pass pkg.b.mkip and pkg.b.mkit
        \write "  build_variables = #{spacesToArray pkg.b.mkbv},\n"     if pass pkg.b.mkbv
        \write "  install_variables = #{spacesToArray pkg.b.mkiv},\n"   if pass pkg.b.mkiv
        \write "  variables = #{spacesToArray pkg.b.mkv},\n"            if pass pkg.b.mkv
      when "builtin"
        \write "  modules = #{serializeTable pkg.b.builtin},\n"         if passT pkg.b.builtin
    \write "  install = {\n"                                            if pkg.i.do
    \write "    lua = #{serializeTable pkg.i.lua},\n"                   if pkg.i.doLua
    \write "    lib = #{serializeTable pkg.i.lib},\n"                   if pkg.i.doLib
    \write "    conf = #{serializeTable pkg.i.conf},\n"                 if pkg.i.doConf
    \write "    bin = #{serializeTable pkg.i.bin},\n"                   if pkg.i.doBin
    \write "  }\n"                                                      if pkg.i.do
    \write "}\n"

    \close!
