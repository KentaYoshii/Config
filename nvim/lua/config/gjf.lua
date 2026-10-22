-- config/gjf.lua — google-java-format on save, driven by the repo's Linterator
-- config. The nearest .lintrc.yaml above the file decides everything: its
-- google-java-format `flags`, and its `include`/`exclude` globs (relative to
-- the .lintrc.yaml directory). Files outside `include` are left alone, since
-- reformatting a not-yet-clean path would bury the real change in a PR. Repos
-- without a google-java-format check are never formatted.
--
-- :Gjf formats the current buffer regardless of `include`; :GjfToggle turns
-- format-on-save off and on for the session.

local M = {}

-- Pinned to match wingman's CONTRIBUTING.md; download with:
--   curl -fsSLo ~/.local/share/gjf/google-java-format-1.36.1-all-deps.jar \
--     https://repo1.maven.org/maven2/com/google/googlejavaformat/google-java-format/1.36.1/google-java-format-1.36.1-all-deps.jar
local JAR = vim.fn.expand('~/.local/share/gjf/google-java-format-1.36.1-all-deps.jar')
local TIMEOUT_MS = 10000

local enabled = true
local cache = {}  -- lintrc path -> { mtime, config }

local function unquote(s)
  return (s:gsub('^%s*["\']', ''):gsub('["\']%s*$', ''))
end

-- Minimal reader for the google-java-format check of a .lintrc.yaml: list
-- items under `include:`/`exclude:` and an inline `flags: [...]`. Returns nil
-- when the file has no google-java-format check.
local function parse_lintrc(path)
  local cfg, list = { flags = {}, include = {}, exclude = {} }, nil
  local has_gjf = false
  for line in io.lines(path) do
    line = line:gsub('%s+#.*$', '')
    if line:match('name:%s*google%-java%-format') then
      has_gjf = true
    end
    local key = line:match('^%s*(%w+):%s*$')
    if key then
      list = (key == 'include' or key == 'exclude') and key or nil
    end
    local item = line:match('^%s*%-%s*(.+)$')
    if list and item and not item:match(':%s') then
      local glob = unquote(item)
      table.insert(cfg[list], vim.glob.to_lpeg(glob))
    end
    local flags = line:match('^%s*flags:%s*%[(.*)%]')
    if flags then
      for f in flags:gmatch('[^,]+') do
        table.insert(cfg.flags, unquote(f))
      end
    end
  end
  return has_gjf and cfg or nil
end

-- (config, lintrc dir) for `file`, or nil when no google-java-format check applies.
local function config_for(file)
  local lintrc = vim.fs.find('.lintrc.yaml', { path = vim.fs.dirname(file), upward = true })[1]
  if not lintrc then
    return nil
  end
  local mtime = vim.uv.fs_stat(lintrc).mtime.sec
  local hit = cache[lintrc]
  if not hit or hit.mtime ~= mtime then
    hit = { mtime = mtime, config = parse_lintrc(lintrc) }
    cache[lintrc] = hit
  end
  return hit.config, vim.fs.dirname(lintrc)
end

local function matches_any(patterns, rel)
  for _, p in ipairs(patterns) do
    if p:match(rel) then
      return true
    end
  end
  return false
end

-- Replace the buffer with gjf's output for `flags`. Leaves the buffer as is
-- (and says why) if the jar is missing or the source does not parse.
local function format(bufnr, flags)
  if vim.fn.filereadable(JAR) == 0 then
    vim.notify('gjf: ' .. JAR .. ' not found (see lua/config/gjf.lua)', vim.log.levels.WARN)
    return
  end
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local cmd = vim.list_extend({ 'java', '-jar', JAR }, flags)
  table.insert(cmd, '-')
  local res = vim.system(cmd, { stdin = table.concat(lines, '\n') .. '\n', text = true })
    :wait(TIMEOUT_MS)
  if res.code ~= 0 then
    local msg = (res.stderr ~= '' and res.stderr) or ('exit ' .. tostring(res.code))
    vim.notify('gjf: not formatted\n' .. vim.trim(msg), vim.log.levels.WARN)
    return
  end
  local out = vim.split(res.stdout:gsub('\n$', ''), '\n', { plain = true })
  if vim.deep_equal(out, lines) then
    return
  end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, out)
  vim.fn.winrestview(view)
end

local function on_save(bufnr)
  if not enabled then
    return
  end
  local file = vim.api.nvim_buf_get_name(bufnr)
  local cfg, root = config_for(file)
  if not cfg then
    return
  end
  local rel = file:sub(#root + 2)
  if matches_any(cfg.include, rel) and not matches_any(cfg.exclude, rel) then
    format(bufnr, cfg.flags)
  end
end

-- Per-buffer setup from ftplugin/java.lua.
function M.attach(bufnr)
  if not bufnr or bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  local group = vim.api.nvim_create_augroup('gjf_' .. bufnr, { clear = true })
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = group,
    buffer = bufnr,
    callback = function(args) on_save(args.buf) end,
  })
  vim.api.nvim_buf_create_user_command(bufnr, 'Gjf', function()
    local cfg = config_for(vim.api.nvim_buf_get_name(bufnr))
    format(bufnr, cfg and cfg.flags or { '--aosp', '--skip-sorting-imports', '--skip-reflowing-long-strings' })
  end, { desc = 'google-java-format this buffer (ignores .lintrc.yaml include)' })
end

vim.api.nvim_create_user_command('GjfToggle', function()
  enabled = not enabled
  vim.notify('gjf format-on-save ' .. (enabled and 'on' or 'off'))
end, { desc = 'Toggle google-java-format on save' })

return M
