-- On paper (the Typst output), the CV's classes become the template's own
-- functions, so the PDF keeps the site's structure: a section's name in the
-- margin, a date in the margin beside its entry, the thing itself set
-- semibold. In every other format this filter does nothing.

if not quarto.doc.is_format("typst") then return {} end

local function inlines_to_typst(inlines)
  return (pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), "typst"):gsub("%s+$", ""))
end

local function blocks_to_typst(blocks)
  return pandoc.write(pandoc.Pandoc(blocks), "typst")
end

local function is_entry(block)
  return block ~= nil and block.t == "Div" and block.classes:includes("cv-entry")
end

return {
  {
    Span = function(s)
      if s.classes:includes("cv-when") then
        return pandoc.RawInline("typst", "#when[" .. inlines_to_typst(s.content) .. "]")
      end
      if s.classes:includes("cv-what") then
        return pandoc.RawInline("typst", "#what[" .. inlines_to_typst(s.content) .. "]")
      end
    end,

    Div = function(d)
      if d.classes:includes("cv-entry") then
        return pandoc.RawBlock("typst", "#entry[\n" .. blocks_to_typst(d.content) .. "]")
      end
    end,
  },
  {
    -- Headings, seen with what follows them: a section whose first thing is a
    -- dated entry starts its content a line lower, so the margin reads name,
    -- then dates — as the site does.
    Blocks = function(blocks)
      local out = pandoc.Blocks({})
      for i, b in ipairs(blocks) do
        if b.t == "Header" and b.level == 2 then
          local nxt = blocks[i + 1]
          local dated = (nxt ~= nil and nxt.t == "RawBlock" and nxt.text:match("^#entry%[")) and "true" or "false"
          out:insert(pandoc.RawBlock("typst",
            "#section(dated: " .. dated .. ")[" .. inlines_to_typst(b.content) .. "]"))
        elseif b.t == "Header" and b.level == 3 then
          out:insert(pandoc.RawBlock("typst", "#sub[" .. inlines_to_typst(b.content) .. "]"))
        else
          out:insert(b)
        end
      end
      return out
    end,
  },
}
