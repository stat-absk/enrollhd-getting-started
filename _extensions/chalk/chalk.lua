-- The site's marks as shortcodes.
--
--   {{< tally 15 >}}   a count in gates of five; the number is there as text,
--                      the strokes are hidden from assistive technology.
--   {{< rule >}}       one chalk rule, the next stroke from the set of eight,
--                      so neighbouring rules never match.
--
-- The strokes are written inline (the paths are those of marks/chalk.svg), so
-- a mark needs no other file: the same shortcode works on the site and in a
-- self-contained deck. On the site the chalk roughening is the page's #chalk
-- filter, applied by _marks.scss. In any format that is not HTML (the
-- CV's PDF, for one) a tally is simply its number and a rule is nothing.

local rule_n = 0

local STROKE = "M6.4 2.5 C5.7 12, 6.3 24, 5.5 37.5"   -- one upright, in a 12 x 40 box
local STRIKE = "M3 31 C18 24.5, 40 14, 57 7"         -- the fifth, across a 60 x 40 gate

local function stroke(x)
  return string.format('<path transform="translate(%d 0)" d="%s"/>', x, STROKE)
end

-- One gate: up to four uprights and, at five, the strike through them.
local function gate(k)
  local parts = {}
  for i = 1, math.min(k, 4) do parts[#parts + 1] = stroke(2 + (i - 1) * 13) end
  if k == 5 then parts[#parts + 1] = string.format('<path d="%s"/>', STRIKE) end
  local width = (k >= 4) and 60 or (2 + k * 13)
  return string.format('<svg viewBox="0 0 %d 40" aria-hidden="true" focusable="false">%s</svg>', width, table.concat(parts))
end

return {
  ["tally"] = function(args, kwargs, meta)
    local n = tonumber(pandoc.utils.stringify(args[1] or "")) or 0
    if quarto.doc.is_format("typst") then return pandoc.RawInline("typst", "#tally(" .. n .. ")") end
    if not quarto.doc.is_format("html") then return pandoc.Str(tostring(n)) end
    local gates, left = {}, n
    while left > 0 do
      local k = math.min(left, 5)
      gates[#gates + 1] = gate(k)
      left = left - k
    end
    local html = string.format(
      '<span class="tally" role="img" aria-label="%d"><span class="visually-hidden">%d</span>%s</span>',
      n, n, table.concat(gates))
    return pandoc.RawInline("html", html)
  end,

  ["rule"] = function(args, kwargs, meta)
    if not quarto.doc.is_format("html") then return pandoc.Null() end
    rule_n = rule_n % 8 + 1
    return pandoc.RawBlock("html",
      string.format('<div class="chalk-rule" data-rule="%d" aria-hidden="true"></div>', rule_n))
  end,
}
