
---@alias Path userdata

---@type table
local log = require("log")

---@class PluginLoaderCache
---@field plugins PluginData[]
local cache

if _G.__plugin_loader_cache then
  cache = _G.__plugin_loader_cache
else
  cache = {}
  _G.__plugin_loader_cache = cache

  ---@type table
  local config = require("config")
  ---@type table
  local fs = require("bee.filesystem")
  ---@type table
  local workspace = require("workspace")
  ---@type table
  local fsu = require("fs-utility")

  ---@type Path
  local plugin_path = fs.path(workspace.getAbsolutePath(config.get('Lua.runtime.plugin')))

  ---@type Path
  local plugin_dir_path = plugin_path:parent_path()

  ---@type string
  local new_path = (plugin_dir_path / "?.lua"):string()
  if not package.path:find(new_path, 1, true) then
    package.path = package.path..";"..new_path
  end

  ---@type PluginData[]
  local plugins = {}
  cache.plugins = plugins
  ---@type Path
  for sub_path in plugin_dir_path:list_directory() do
    if fs.is_directory(sub_path) then
      local sub_plugin_path = sub_path / "plugin.lua"
      -- seems to savely check for existance first
      if fs.is_regular_file(sub_plugin_path) then
        ---@type string
        local plugin_package_path = (sub_path / "?.lua"):string()
        package.path = package.path..";"..plugin_package_path
        ---@class PluginData
        local plugin_data = {
          path = sub_plugin_path,
          package_path = plugin_package_path,
          env = {},
        }
        ---@type string|nil
        local plugin_lua = fsu.loadFile(sub_plugin_path)
        if not plugin_lua then
          goto continue
        end
        local env = setmetatable(plugin_data.env, { __index = _G })
        local f, err = load(plugin_lua, '@'..sub_plugin_path:string(), "t", env)
        if not f then
          log.error(err)
          goto continue
        end
        if xpcall(f, log.error, f) then
          plugins[#plugins+1] = plugin_data
        end
      end
    end
    ::continue::
  end
end

---@class Diff
---@field start integer @ The number of bytes at the beginning of the replacement
---@field finish integer @ The number of bytes at the end of the replacement
---@field text string @ What to replace

---@param  uri string @ The uri of file
---@param  text string @ The content of file
---@return nil|string|Diff[]
function OnSetText(uri, text)
  ---@type Diff[]
  local diffs = {}
  ---@type PluginData
  for _, plugin_data in ipairs(cache.plugins) do
    if plugin_data.env.OnSetText then
      -- TODO: somehow support strings as results
      -- i think it's doable, but tbh i also don't really
      -- care because using strings is bad for intelisense anyway
      -- though i've never tried it, i must add
      ---@type Diff[]|nil
      local plugin_diffs = plugin_data.env.OnSetText(uri, text)
      if plugin_diffs then
        for _, diff in ipairs(plugin_diffs) do
          diffs[#diffs+1] = diff
        end
      end
    end
  end
  return #diffs ~= 0 and diffs
end
