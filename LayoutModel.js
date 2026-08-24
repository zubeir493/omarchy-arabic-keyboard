function quoted(value) {
  return String(value || "").replace(/^'|'$/g, "")
}

function layoutCatalog(text) {
  var catalog = {}
  var current = null

  String(text || "").split("\n").forEach(function(line) {
    var layout = line.match(/^- layout: '([^']*)'/)
    if (layout) {
      current = { layout: layout[1], variant: "", brief: "", description: "" }
      return
    }
    if (!current) return

    var variant = line.match(/^  variant: '([^']*)'/)
    if (variant) {
      current.variant = variant[1]
      return
    }

    var brief = line.match(/^  brief: '([^']*)'/)
    if (brief) {
      current.brief = brief[1]
      return
    }

    var description = line.match(/^  description: (.*)$/)
    if (description) {
      current.description = quoted(description[1])
      catalog[current.layout + "|" + current.variant] = {
        brief: current.brief,
        description: current.description
      }
    }
  })

  return catalog
}

function parts(value) {
  var text = String(value || "")
  return text === "" ? [] : text.split(",")
}

function layoutInfo(layout, variant, index, activeIndex, activeKeymap, catalog) {
  var key = layout + "|" + variant
  var known = (catalog || {})[key]
  var custom = {
    hameem: { brief: "ar", description: "Hameem Arabic" }
  }[layout]

  var fallback = known || custom || {
    brief: layout.substring(0, 2),
    description: layout.toUpperCase() + (variant ? " (" + variant + ")" : "")
  }

  // A full custom kb_file reports its group name for the active group even
  // though the layout is not registered in xkeyboard-config's catalogue.
  if (!known && index === activeIndex && activeKeymap)
    fallback = { brief: fallback.brief, description: activeKeymap }

  return {
    index: index,
    layout: layout,
    variant: variant,
    brief: String(fallback.brief || layout.substring(0, 2)).split("-")[0].toUpperCase().substring(0, 3),
    description: String(fallback.description || layout.toUpperCase()),
    active: index === activeIndex
  }
}

function enabledLayouts(layoutValue, variantValue, activeIndex, activeKeymap, catalog) {
  var layouts = parts(layoutValue)
  var variants = parts(variantValue)
  if (layouts.length === 0) return activeKeymap ? [{
    index: 0,
    layout: "",
    variant: "",
    brief: "",
    description: activeKeymap,
    active: true
  }] : []

  return layouts.map(function(layout, index) {
    return layoutInfo(
      layout,
      variants[index] || "",
      index,
      activeIndex,
      activeKeymap,
      catalog
    )
  })
}

var UNTYPED_KEYBOARDS = /^(hl-virtual-keyboard|power-button|sleep-button|lid-switch|video-bus)/

function isTypedKeyboard(name) {
  return !UNTYPED_KEYBOARDS.test(String(name || ""))
}

function eventKeyboardName(event) {
  var parts = null
  try {
    if (event && event.parse) parts = event.parse(2)
  } catch (error) {
  }
  if (!parts) parts = String(event && event.data ? event.data : "").split(",")
  var name = String(parts[0] || "")
  return name.indexOf("hl-virtual-keyboard") === 0 ? "" : name
}

function layoutIndex(keyboard) {
  return (keyboard && keyboard.active_layout_index) || 0
}

function selectKeyboard(keyboards, namedByEvent) {
  var typed = keyboards || []
  return typed.find(function(keyboard) {
    return keyboard.name === namedByEvent
  }) || typed.reduce(function(furthest, keyboard) {
    return layoutIndex(keyboard) > layoutIndex(furthest) ? keyboard : furthest
  }, typed[0])
}

if (typeof module !== "undefined") {
  module.exports = {
    enabledLayouts: enabledLayouts,
    eventKeyboardName: eventKeyboardName,
    isTypedKeyboard: isTypedKeyboard,
    layoutCatalog: layoutCatalog,
    selectKeyboard: selectKeyboard
  }
}
