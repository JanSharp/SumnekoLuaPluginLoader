
# Introduction

This happy little plugin allows you to load multiple plugins for the [sumneko.lua](https://github.com/sumneko/lua-language-server) extension.

# Usage

The plugin loads all `plugin.lua` files located 1 sub folder deep relative to this `plugin.lua` file, very similar to how the extension loads plugins. It also adds each sub plugin path to `package.path`, specifically `<full sub folder path>/?.lua`.

# Limitations

These limitations might change, potentially.

- There is no way to specify different entry points for the sub plugins. It only looks for `plugin.lua`.
- It does not support `string` return values from `OnSetText` by the sub plugins.
