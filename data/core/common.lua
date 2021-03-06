local config = require "core.config"


config.dprint("common.lua -> loaded")


local common = {}


function common.truncate_text(font, text, sx, dx)
  local text_w = font:get_width(text)
  if text_w+sx > dx then
    while text_w+sx > dx do
      text = text:sub(1,-2)
      text_w = font:get_width(text)
    end
    text = text:sub(1,-6)
    text = text .. " …"
  end
  return text
end

-- rootview, node
function common.copy_position_and_size(dst, src)
  dst.position.x, dst.position.y = src.position.x, src.position.y
  dst.size.x, dst.size.y = src.size.x, src.size.y
end

function common.sort_positions(line1, col1, line2, col2)
  if line1 > line2
  or line1 == line2 and col1 > col2 then
    return line2, col2, line1, col1, true
  end
  return line1, col1, line2, col2, false
end

function common.is_utf8_cont(char)
  local byte = char:byte()
  return byte >= 0x80 and byte < 0xc0
end


function common.utf8_chars(text)
  return text:gmatch("[\0-\x7f\xc2-\xf4][\x80-\xbf]*")
end


function common.clamp(n, lo, hi)
  return math.max(math.min(n, hi), lo)
end


function common.round(n)
  return n >= 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
end


function common.lerp(a, b, t)
  if type(a) ~= "table" then
    return a + (b - a) * t
  end
  local res = {}
  for k, v in pairs(b) do
    res[k] = common.lerp(a[k], v, t)
  end
  return res
end


function common.color(str)
  local r, g, b, a = str:match("#(%x%x)(%x%x)(%x%x)")
  if r then
    r = tonumber(r, 16)
    g = tonumber(g, 16)
    b = tonumber(b, 16)
    a = 1
  elseif str:match("rgba?%s*%([%d%s%.,]+%)") then
    local f = str:gmatch("[%d.]+")
    r = (f() or 0)
    g = (f() or 0)
    b = (f() or 0)
    a = f() or 1
  else
    error(string.format("bad color string '%s'", str))
  end
  return r, g, b, a * 0xff
end


local function compare_score(a, b)
  return a.score > b.score
end

local function fuzzy_match_items(items, needle)
  local res = {}
  for _, item in ipairs(items) do
    local score = system.fuzzy_match(tostring(item), needle)
    if score then
      table.insert(res, { text = item, score = score })
    end
  end
  table.sort(res, compare_score)
  for i, item in ipairs(res) do
    res[i] = item.text
  end
  return res
end


function common.fuzzy_match(haystack, needle)
  if type(haystack) == "table" then
    return fuzzy_match_items(haystack, needle)
  end
  return system.fuzzy_match(haystack, needle)
end


local function list_dir(text, only)
  local path, _ = text:match("^(.-)([^/\\]*)$")
  local files = system.list_dir(path == "" and "." or path) or {}
  local res = {}
  for _, file in ipairs(files) do
    file = path .. file
    local info = system.get_file_info(file)
    local is_valid = file:lower():find(text:lower(), nil, true) == 1
    if info then
      if info.type == "dir" then
        file = file .. PATHSEP
      end
      if only == info.type and is_valid then
        table.insert(res, file)
      else
        if only == nil and is_valid then
          table.insert(res, file)
        end
      end
    end
  end
  return res
end

function common.path_suggest_only_dirs(text)
  return list_dir(text, "dir")
end


function common.path_suggest_only_files(text)
  return list_dir(text, "file")
end


function common.path_suggest(text)
  return list_dir(text)
end


function common.matches_ext(filename, patterns)
  for _, ptn in ipairs(patterns) do
    if filename:find(ptn) then return true end
  end
  return nil
end


function common.match_pattern(text, pattern, ...)
  if type(pattern) == "string" then
    return text:find(pattern, ...)
  end
  for _, p in ipairs(pattern) do
    local s, e = common.match_pattern(text, p, ...)
    if s then return s, e end
  end
  return false
end


function common.draw_text(font, color, text, align, x,y,w,h)
  local tw, th = font:get_width(text), font:get_height(text)
  if align == "center" then
    x = x + (w - tw) / 2
  elseif align == "right" then
    x = x + (w - tw)
  end
  y = common.round(y + (h - th) / 2)
  return renderer.draw_text(font, text, x, y, color), y + th
end


function common.draw_doc(font, color, text, align, x,y,w,h)
  local tw, th = font:get_width(text), font:get_height(text)
  if align == "center" then
    x = x + (w - tw) / 2
  elseif align == "right" then
    x = x + (w - tw)
  end
  y = y + 10
  return renderer.draw_text(font, text, x, y, color), y + th
end


function common.bench(name, fn, ...)
  local start = system.get_time()
  local res = fn(...)
  local t = system.get_time() - start
  local ms = t * 1000
  local per = (t / (1 / 60)) * 100
  print(string.format("*** %-16s : %8.3fms %6.2f%%", name, ms, per))
  return res
end


return common
