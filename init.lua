-- Copyright 2007-2022 Mitchell. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- The YAML module for Textadept.
-- It provides utilities for editing YAML documents.
--
-- ### Compiling
--
-- Releases include binaries, so building this modules should not be necessary. If you want to
-- build manually, run `make deps` followed by `make`. This assumes the module is installed
-- in Textadept's *modules/* directory. If it is not (e.g. it is in your `_USERHOME`), run
-- `make ta=/path/to/textadept`.
--
-- ### Key Bindings
--
-- + `Ctrl+&` (`⌘&` | `M-&`)
--   Jump to the anchor for the alias under the caret.
module('_M.yaml')]]

local lyaml = require('yaml.lyaml')

-- Always use spaces.
events.connect(events.LEXER_LOADED, function(name)
  if name ~= 'yaml' then return end
  buffer.use_tabs = false
  buffer.word_chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890-*'
end)

-- Commands.

-- Verify syntax.
events.connect(events.FILE_AFTER_SAVE, function()
  if buffer:get_lexer() ~= 'yaml' or not lyaml then return end
  buffer:annotation_clear_all()
  local ok, errmsg = pcall(lyaml.load, buffer:get_text())
  if ok then return end
  local line, col, msg = errmsg:match('^(%d+):(%d+): (.+)$')
  if not line or not col then line, col, msg = 1, 1, errmsg end
  buffer.annotation_text[line] = msg
  local GETNAMEDSTYLE = _SCINTILLA.properties.named_styles[1]
  local style = buffer:private_lexer_call(GETNAMEDSTYLE, 'error')
  buffer.annotation_style[line] = style
  buffer:goto_pos(buffer:find_column(line, col))
end)

---
-- Jumps to the anchor for the alias underneath the caret.
-- @name goto_anchor
function M.goto_anchor()
  local s = buffer:word_start_position(buffer.current_pos, true)
  local e = buffer:word_end_position(buffer.current_pos)
  local anchor = buffer:text_range(s, e):match('^%*(.+)$')
  if anchor then
    buffer:target_whole_document()
    buffer.search_flags = buffer.FIND_WHOLEWORD
    if buffer:search_in_target('&' .. anchor) ~= -1 then buffer:goto_pos(buffer.target_start) end
  end
end

keys.yaml[CURSES and 'meta+&' or OSX and 'cmd+&' or 'ctrl+&'] = M.goto_anchor

return M
