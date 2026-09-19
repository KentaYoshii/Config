-- lsp/java.lua — eclipse.jdt.ls setup, invoked per buffer from
-- ftplugin/java.lua. Started via nvim-jdtls, which manages one jdt.ls server per
-- project root and attaches all Java buffers of that project to it.

local common = require('lsp.common')

local M = {}

-- Multi-module Maven: import the whole reactor as one project so cross-module
-- navigation works and dependencies resolve once. The reactor root is the
-- topmost pom.xml at or below the enclosing git repository.
local function find_reactor_root(start)
  local git = vim.fs.find('.git', { path = start, upward = true })[1]
  local boundary = git and vim.fn.fnamemodify(git, ':h') or nil
  local dir, best = start, start
  while true do
    if vim.fn.filereadable(dir .. '/pom.xml') == 1 then best = dir end
    if boundary and dir == boundary then break end
    local parent = vim.fn.fnamemodify(dir, ':h')
    if parent == dir then break end
    dir = parent
  end
  return best
end

-- Lombok javaagent: jdt.ls must load Lombok for @Getter/@Setter/@Data etc. to
-- contribute generated methods; without it those show as "undefined". The agent
-- has to suit the server rather than the project, so prefer a jar installed to
-- ~/.local/share/lombok. A jar under ~/.m2 also works as an agent, but only as a
-- fallback: its version is whatever the project pins as a compile dependency,
-- and anything before 1.18.32 fails every handler with a NoSuchMethodError on
-- Expression.print against recent jdt.ls builds, which silently breaks
-- resolution of all Lombok-generated members.
local function lombok_version_key(path)
  local key = {}
  for n in (path:match('lombok%-(%d[%d%.]*)%.jar$') or '0'):gmatch('%d+') do
    key[#key + 1] = tonumber(n)
  end
  return key
end

local function lombok_is_newer(a, b)  -- true if version(a) > version(b)
  local ka, kb = lombok_version_key(a), lombok_version_key(b)
  for i = 1, math.max(#ka, #kb) do
    local x, y = ka[i] or 0, kb[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

-- Newest real lombok jar matching a glob (sources/javadoc jars are not agents).
local function newest_lombok(pattern)
  local best
  for _, j in ipairs(vim.fn.glob(pattern, true, true)) do
    if not j:match('%-sources%.jar$') and not j:match('%-javadoc%.jar$') then
      if not best or lombok_is_newer(j, best) then best = j end
    end
  end
  return best
end

local function find_lombok_jar()
  return newest_lombok(vim.fn.expand('~/.local/share/lombok') .. '/lombok-*.jar')
    or newest_lombok(
      vim.fn.expand('~/.m2/repository/org/projectlombok/lombok') .. '/*/lombok-*.jar')
end

-- `brew install jdtls` puts a `jdtls` wrapper on PATH. The wrapper resolves the
-- equinox launcher jar and the platform config directory itself, so it is the
-- preferred launch path; the directory installs below only matter if the
-- server was installed by hand or by mason.
local function find_wrapper()
  local on_path = vim.fn.exepath('jdtls')
  if on_path ~= '' then
    return on_path
  end
  for _, dir in ipairs({
    vim.fn.expand('~/.local/share/jdtls'),
    vim.fn.stdpath('data') .. '/mason/packages/jdtls',
  }) do
    if vim.fn.executable(dir .. '/bin/jdtls') == 1 then
      return dir .. '/bin/jdtls'
    end
  end
  return nil
end

-- A directory install to launch directly, used only when no wrapper is present.
-- Identified by the equinox launcher jar, since that is what the java command
-- below needs.
local function find_install_dir()
  for _, dir in ipairs({
    vim.fn.expand('~/.local/share/jdtls'),
    vim.fn.stdpath('data') .. '/mason/packages/jdtls',
  }) do
    if vim.fn.glob(dir .. '/plugins/org.eclipse.equinox.launcher_*.jar') ~= '' then
      return dir
    end
  end
  return nil
end

-- Build the launch command, or nil if no server is installed. The equinox
-- config directory is platform-specific: Apple Silicon ships config_mac_arm,
-- Intel config_mac.
local function build_cmd(workspace_dir, lombok_jar)
  local wrapper = find_wrapper()
  if wrapper then
    local cmd = { wrapper, '-data', workspace_dir }
    if lombok_jar then
      table.insert(cmd, '--jvm-arg=-javaagent:' .. lombok_jar)
    end
    return cmd
  end

  local install_dir = find_install_dir()
  if not install_dir then
    return nil
  end

  local config_dir
  for _, name in ipairs({ 'config_mac_arm', 'config_mac' }) do
    if vim.fn.isdirectory(install_dir .. '/' .. name) == 1 then
      config_dir = install_dir .. '/' .. name
      break
    end
  end
  if not config_dir then
    return nil
  end

  local launcher = vim.fn.glob(install_dir .. '/plugins/org.eclipse.equinox.launcher_*.jar')
  local cmd = { 'java' }
  if lombok_jar then
    table.insert(cmd, '-javaagent:' .. lombok_jar)
  end
  vim.list_extend(cmd, {
    '-Declipse.application=org.eclipse.jdt.ls.core.id1',
    '-Dosgi.bundles.defaultStartLevel=4',
    '-Declipse.product=org.eclipse.jdt.ls.core.product',
    '-Dlog.protocol=true',
    '-Dlog.level=ALL',
    '-Xmx1g',
    '--add-modules=ALL-SYSTEM',
    '--add-opens', 'java.base/java.util=ALL-UNNAMED',
    '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
    '-jar', launcher,
    '-configuration', config_dir,
    '-data', workspace_dir,
  })
  return cmd
end

-- Major version of the JDK installed at `home`, read from the `release` file
-- every JDK ships (JAVA_VERSION="21.0.8"). Returns nil when the file is absent
-- or unparseable, so the caller can skip the entry rather than register a
-- runtime jdt.ls cannot use.
local function jdk_major_version(home)
  local release = home .. '/release'
  if vim.fn.filereadable(release) == 0 then
    return nil
  end
  for _, line in ipairs(vim.fn.readfile(release)) do
    local version = line:match('^JAVA_VERSION="([^"]+)"')
    if version then
      -- Releases before 9 use the 1.N form, where N is the major version.
      local major = version:match('^1%.(%d+)') or version:match('^(%d+)')
      return major and tonumber(major) or nil
    end
  end
  return nil
end

-- Register the JDKs present on the machine so jdt.ls can compile a project
-- against the release its build file targets. macOS keeps installed JDKs under
-- /Library/Java/JavaVirtualMachines; Homebrew's openjdk lives under its own
-- prefix. The highest version found is the default. An empty list leaves jdt.ls
-- using the JVM it was launched with.
local function mac_runtimes()
  local homes = vim.fn.glob('/Library/Java/JavaVirtualMachines/*/Contents/Home', true, true)
  for _, prefix in ipairs({ '/opt/homebrew/opt', '/usr/local/opt' }) do
    vim.list_extend(homes,
      vim.fn.glob(prefix .. '/openjdk*/libexec/openjdk.jdk/Contents/Home', true, true))
  end

  -- First home wins per version: the JavaVirtualMachines entries are globbed
  -- before the Homebrew ones, which are usually symlinks to the same install.
  local by_version, highest = {}, nil
  for _, home in ipairs(homes) do
    local version = jdk_major_version(home)
    if version and not by_version[version] then
      by_version[version] = home
      if not highest or version > highest then highest = version end
    end
  end

  local runtimes = {}
  for version, home in pairs(by_version) do
    runtimes[#runtimes + 1] = {
      -- The execution environment names jdt.ls expects: JavaSE-21, but
      -- JavaSE-1.8 for releases before 9.
      name = version >= 9 and ('JavaSE-' .. version) or ('JavaSE-1.' .. version),
      path = home,
      default = version == highest,
    }
  end
  return runtimes
end

function M.start()
  local ok_jdtls, jdtls = pcall(require, 'jdtls')
  if not ok_jdtls then
    return
  end

  -- Closest project marker (used only as a starting point for reactor detection).
  local start_root = require('jdtls.setup').find_root({
    'gradlew', 'mvnw', 'pom.xml', 'build.gradle', 'settings.gradle', '.git',
  })
  if start_root == nil or start_root == '' then
    return  -- not inside a recognisable project; skip starting the server
  end

  local root_dir = find_reactor_root(start_root)

  -- One data workspace per project, kept out of the source tree.
  local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
  local workspace_dir = vim.fn.expand('~/.cache/jdtls/workspace/') .. project_name
  vim.fn.mkdir(workspace_dir, 'p')

  local cmd = build_cmd(workspace_dir, find_lombok_jar())
  if not cmd then
    -- Reported once per buffer rather than silently doing nothing, since a
    -- missing server is otherwise indistinguishable from a slow import.
    vim.notify('jdt.ls not found; install it with `brew install jdtls`',
      vim.log.levels.WARN)
    return
  end

  jdtls.start_or_attach({
    cmd = cmd,
    root_dir = root_dir,
    capabilities = common.capabilities(),
    on_attach = function(_, bufnr) common.on_attach(bufnr) end,
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = 'fernflower' },  -- decompile .class files
        configuration = {
          updateBuildConfiguration = 'automatic',
          runtimes = mac_runtimes(),
        },
        import = {
          maven = { enabled = true },
        },
        maven = {
          -- Source jars give real javadoc on hover and real source on `gd` into
          -- a library, at the cost of a slower first import per project.
          downloadSources = true,
        },
        completion = {
          importOrder = { 'java', 'javax', 'com', 'org' },
        },
        sources = {
          organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
        },
      },
    },
  })
end

-- jdt.ls keeps a per-project Eclipse workspace under ~/.cache/jdtls/workspace.
-- If two servers ever end up on one workspace (e.g. a stale/orphaned server from
-- a previous session), imports hang. Stop the running server cleanly and, when
-- `wipe` is set, delete the workspace so the next open re-imports from scratch.
-- Backs :JdtRestart and :JdtWipe.
function M.restart(wipe)
  local clients = vim.lsp.get_clients({ name = 'jdtls' })
  local root = clients[1] and clients[1].config.root_dir or nil

  common.restart_clients('jdtls', { 'java' }, {
    label = 'jdt.ls',
    force = true,
    tries = 60,
    after_stop = function()
      if wipe and root then
        local name = vim.fn.fnamemodify(root, ':p:h:t')
        local ws = vim.fn.expand('~/.cache/jdtls/workspace/') .. name
        vim.fn.delete(ws, 'rf')
        vim.notify('jdt.ls: wiped workspace ' .. ws)
      end
    end,
  })
end

return M
