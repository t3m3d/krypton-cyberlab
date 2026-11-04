#!/usr/bin/env kr
// Krypton CyberLab: native AppKit through Objective-K/OKUI. No WebView.
// State and callbacks stay together, following Cortex/Code Brain conventions.
import "k:okui"
import "curriculum.k"

let catalog = 0
let curriculum = 0
let sections = 0
let preferences = 0
let stateFile = 0
let saveFailed = 0
let win = 0
let document = 0
let sidebar = 0
let scroller = 0
let editor = 0
let editorKey = ""
let editorMode = ""
let delegate = 0
let statusLabel = 0
let responsePopup = 0
let feedbackView = 0
let caseIndex = 0
let itemIndex = 0
let decisionIndex = 0
let reportIndex = 0
let screen = "home"
let docHeight = 1000
let loadingEditor = 0
let testMode = 0
let assertions = 0
let buildingSidebar = 0
let themePopup = 0
let settingsWindow = 0
let settingsDocument = 0
let settingsButton = 0
let darkTheme = 0
let applyingTheme = 0

// Foundation objects retain persistent strings, avoiding foreign-pointer identity
// comparisons and interior-string storage hazards documented by Cortex.
func obj(object, key) { emit msg_1(object, "objectForKey:", nsString(key)) }
func str(object, key) { emit nsToStr(obj(object, key)) }
func at(array, i) { emit msg_1(array, "objectAtIndex:", i) }
func clean(value) { emit nsToStr(msg_1(nsString(value), "stringByTrimmingCharactersInSet:", msg(cls("NSCharacterSet"), "whitespaceAndNewlineCharacterSet"))) }
func currentCase() { emit at(curriculum, caseIndex) }
func evidenceAt(i) { emit at(obj(currentCase(), "evidence"), i) }
func decisionAt(i) { emit at(obj(currentCase(), "decisions"), i) }
func slot(prefix, i) { emit prefix + "." + i }
func keyName(key) { emit "v1.case." + caseIndex + "." + key }
func saved(key) {
    let value = msg_1(preferences, "objectForKey:", nsString(keyName(key)))
    if value == 0 { emit "" }
    emit nsToStr(value)
}
func store(key, value) {
    msg_2(preferences, "setObject:forKey:", nsString(value), nsString(keyName(key)))
    if key != "complete" { msg_2(preferences, "setObject:forKey:", nsString(""), nsString(keyName("complete"))) }
    emit persistProgress()
}
func persistProgress() {
    let success = msg_2(preferences, "writeToFile:atomically:", stateFile, 1)
    saveFailed = 0
    if success == 0 { saveFailed = 1 }
    if statusLabel != 0 {
        if success == 1 { doText(statusLabel, "Saved locally on this Mac") }
        else { doText(statusLabel, "SAVE FAILED · session only · export report before quitting") }
    }
    emit success
}
func token(i) { emit substring("abcdef", i, i + 1) }
func recordId(i) { emit str(evidenceAt(i), "id") }
func assessedCount() {
    let n = 0 let i = 0
    while i < 6 { if saved(slot("classification", i)) != "" { n += 1 } i += 1 }
    emit n
}
func decisionCount() {
    let n = 0 let i = 0
    while i < 3 { if saved(slot("answer", i)) != "" { n += 1 } i += 1 }
    emit n
}
func reviewedCount() {
    let n = 0 let i = 0
    while i < 6 { if saved(slot("reviewed", i)) == "yes" { n += 1 } i += 1 }
    emit n
}
func reportCount() {
    let n = 0 let i = 0
    while i < 6 { if clean(saved(slot("report", i))) != "" { n += 1 } i += 1 }
    emit n
}
func correctClassifications() {
    let n = 0 let i = 0
    while i < 6 { if saved(slot("classification", i)) == str(evidenceAt(i), "expected") { n += 1 } i += 1 }
    emit n
}
func correctDecisions() {
    let n = 0 let i = 0
    while i < 3 {
        let answer = saved(slot("answer", i))
        if answer == "0" || answer == "1" || answer == "2" {
            let option = at(obj(decisionAt(i), "options"), toInt(answer))
            if msg(obj(option, "correct"), "boolValue") == 1 { n += 1 }
        }
        i += 1
    }
    emit n
}
func progressPercent() { emit (reviewedCount() + assessedCount() + len(saved("timeline")) + decisionCount() + reportCount()) * 100 / 27 }
func reportText() {
    let b = sbNew() let i = 0
    while i < 6 { b = sbAppend(b, saved(slot("report", i)) + "\n") i += 1 }
    emit sbToString(b)
}
func citationCount() {
    let text = reportText() let n = 0 let i = 0
    while i < 6 { if contains(text, "[" + recordId(i) + "]") { n += 1 } i += 1 }
    emit n
}
func invalidCitations() {
    let text = reportText() let i = 0 let bad = 0
    while i < len(text) {
        if substring(text, i, i + 1) == "[" {
            let tail = substring(text, i + 1, len(text))
            let end = indexOf(tail, "]")
            if end > 0 && end < 8 {
                let candidate = substring(tail, 0, end)
                // Only validate bracketed evidence-style IDs, not ordinary prose.
                if len(candidate) >= 2 && charCode(substring(candidate, 0, 1)) >= 65 && charCode(substring(candidate, 0, 1)) <= 90 && charCode(substring(candidate, 1, 2)) >= 48 && charCode(substring(candidate, 1, 2)) <= 57 {
                    let found = 0 let j = 0
                    while j < 6 { if candidate == recordId(j) { found = 1 } j += 1 }
                    if found == 0 { bad += 1 }
                }
            }
        }
        i += 1
    }
    emit bad
}
func readyToComplete() {
    if reviewedCount() != 6 || assessedCount() != 6 || len(saved("timeline")) != 6 { emit 0 }
    if decisionCount() != 3 || reportCount() != 6 || citationCount() < 2 || invalidCitations() != 0 { emit 0 }
    let i = 0
    while i < 3 { if clean(saved(slot("reason", i))) == "" { emit 0 } i += 1 }
    emit 1
}
func timelineAdd(i) {
    let order = saved("timeline")
    if !contains(order, token(i)) { store("timeline", order + token(i)) }
    emit 1
}
func timelineRemove(i) {
    let order = saved("timeline") let b = sbNew() let j = 0
    while j < len(order) { let t = substring(order, j, j + 1) if t != token(i) { b = sbAppend(b, t) } j += 1 }
    store("timeline", sbToString(b)) emit 1
}
func timelineMove(i, offset) {
    let order = saved("timeline") let position = indexOf(order, token(i)) let other = position + offset
    if position < 0 || other < 0 || other >= len(order) { emit 0 }
    let b = sbNew() let j = 0
    while j < len(order) {
        if j == position { b = sbAppend(b, substring(order, other, other + 1)) }
        else { if j == other { b = sbAppend(b, token(i)) } else { b = sbAppend(b, substring(order, j, j + 1)) } }
        j += 1
    }
    store("timeline", sbToString(b)) emit 1
}
func chronologicalOrder() { if caseIndex == 0 { emit "dabcef" } if caseIndex == 1 { emit "abcdef" } emit "bacdef" }
func sortTimeline() {
    let desired = chronologicalOrder() let order = saved("timeline") let b = sbNew() let i = 0
    while i < 6 { let t = substring(desired, i, i + 1) if contains(order, t) { b = sbAppend(b, t) } i += 1 }
    store("timeline", sbToString(b)) emit 1
}
func confidenceName(value) {
    if value == "confirmed" { emit "Confirmed fact" }
    if value == "inference" { emit "Reasonable inference" }
    if value == "unresolved" { emit "Unresolved" }
    emit "Not assessed"
}
func confidenceValue(i) { if i == 0 { emit "confirmed" } if i == 1 { emit "inference" } emit "unresolved" }

// Native view construction. Coordinates below are measured from document top.
func ink() { if darkTheme == 1 { emit rgb(240, 234, 248) } emit rgb(43, 34, 56) }
func muted() { if darkTheme == 1 { emit rgb(193, 180, 207) } emit rgb(91, 73, 107) }
func purple() { if darkTheme == 1 { emit rgb(197, 162, 247) } emit rgb(92, 48, 140) }
func pageColor() { if darkTheme == 1 { emit rgb(25, 20, 33) } emit rgb(218, 209, 229) }
func cardColor() { if darkTheme == 1 { emit rgb(38, 30, 49) } emit rgb(232, 224, 239) }
func insetColor() { if darkTheme == 1 { emit rgb(31, 25, 41) } emit rgb(222, 211, 233) }
func highlightColor() { if darkTheme == 1 { emit rgb(51, 37, 67) } emit rgb(207, 191, 224) }
func titleBarColor() { if darkTheme == 1 { emit rgb(33, 23, 46) } emit pageColor() }
func themeChoice() {
    let value = nsToStr(obj(preferences, "ui.appearance"))
    if value == "light" || value == "dark" { emit value }
    emit "system"
}
// Same effectiveAppearance/name query used by the existing Brain/Stem apps.
func systemIsDark() {
    let name = msg(msg(msg(sharedApp(), "effectiveAppearance"), "name"), "UTF8String")
    emit indexOf(name, "Dark") >= 0
}
func applyTheme() {
    applyingTheme = 1
    let mode = themeChoice()
    darkTheme = systemIsDark()
    let appearance = 0
    let selected = 0
    if mode == "light" { darkTheme = 0 selected = 1 appearance = msg_1(cls("NSAppearance"), "appearanceNamed:", nsString("NSAppearanceNameAqua")) }
    if mode == "dark" { darkTheme = 1 selected = 2 appearance = msg_1(cls("NSAppearance"), "appearanceNamed:", nsString("NSAppearanceNameDarkAqua")) }
    // nil inherits  appearance; overrides affect CyberLab windows only.
    msg_1(win, "setAppearance:", appearance)
    msg_1(win, "setTitlebarAppearsTransparent:", 1)
    doWindowBackground(win, titleBarColor())
    paint(msg(win, "contentView"), pageColor())
    if settingsWindow != 0 {
        msg_1(settingsWindow, "setAppearance:", appearance)
        msg_1(settingsWindow, "setTitlebarAppearsTransparent:", 1)
        doWindowBackground(settingsWindow, titleBarColor())
        refreshSettings()
    }
    if statusLabel != 0 { msg_1(statusLabel, "setTextColor:", muted()) }
    if themePopup != 0 { msg_1(themePopup, "selectItemAtIndex:", selected) msg_1(themePopup, "setContentTintColor:", ink()) }
    applyingTheme = 0
    emit 1
}
func chooseTheme(value) {
    flushEditor()
    msg_2(preferences, "setObject:forKey:", nsString(value), nsString("ui.appearance"))
    persistProgress()
    applyTheme()
    render()
    emit 1
}
func onSystemTheme(self, command, keyPath, object, change, context) {
    if applyingTheme == 0 && themeChoice() == "system" && document != 0 {
        flushEditor() applyTheme() render()
    }
    emit 0
}
func green() { emit rgb(179, 237, 143) }
func fresh(name) { emit allocInit(name) }
func attach(view) { msg_1(document, "addSubview:", view) emit view }
func frame(view, x, y, w, h) {
    let origin = y
    if buildingSidebar == 1 { origin = docHeight - y - h }
    msg_frame(view, "setFrame:", x, origin, w, h)
    if buildingSidebar == 1 { msg_1(view, "setAutoresizingMask:", 8) }
    emit view
}
func documentIsFlipped(self, command) { emit 1 }
func identify(view, value) { msg_1(view, "setAccessibilityIdentifier:", nsString(value)) emit view }
func paint(view, shade) {
    msg_1(view, "setWantsLayer:", 1)
    msg_1(msg(view, "layer"), "setBackgroundColor:", msg(shade, "CGColor"))
    emit view
}
func panel(x, y, w, h, shade) {
    let v = fresh("NSView") frame(v, x, y, w, h) paint(v, shade)
    msg_d1(msg(v, "layer"), "setCornerRadius:", 13)
    attach(v) emit v
}
func labelAt(value, x, y, w, h, size, shade) {
    let v = fresh("NSTextField") frame(v, x, y, w, h)
    msg_1(v, "setStringValue:", nsString(value))
    msg_1(v, "setEditable:", 0) msg_1(v, "setSelectable:", 1)
    msg_1(v, "setBezeled:", 0) msg_1(v, "setBordered:", 0) msg_1(v, "setDrawsBackground:", 0)
    msg_1(v, "setUsesSingleLineMode:", 0)
    msg_1(v, "setMaximumNumberOfLines:", 0)
    msg_1(v, "setTextColor:", shade)
    let font = msg_d1(cls("NSFont"), "systemFontOfSize:", size)
    if size >= 17 { font = msg_d1(cls("NSFont"), "boldSystemFontOfSize:", size) }
    msg_1(v, "setFont:", font)
    attach(v) emit v
}
func actionAt(value, x, y, w, action, tag, primary) {
    let v = fresh("NSButton") frame(v, x, y, w, 34)
    msg_1(v, "setTitle:", nsString(value)) msg_1(v, "setBezelStyle:", 1)
    msg_1(v, "setFont:", msg_d1(cls("NSFont"), "systemFontOfSize:", 12))
    msg_1(v, "setTag:", tag)
    msg_1(v, "setContentTintColor:", ink())
    if primary == 1 { msg_1(v, "setBezelColor:", rgb(105, 63, 157)) msg_1(v, "setContentTintColor:", rgb(255, 255, 255)) }
    doClick(v, action, funcptr(onAction))
    chocSetAssocKey(v, "lab.action", nsString(action))
    identify(v, action + "." + tag)
    attach(v) emit v
}
func popupAt(array, x, y, w, selected, action) {
    let v = fresh("NSPopUpButton") frame(v, x, y, w, 32)
    msg_1(v, "setContentTintColor:", ink())
    let i = 0
    while i < msg(array, "count") { msg_1(v, "addItemWithTitle:", at(array, i)) i += 1 }
    msg_1(v, "selectItemAtIndex:", selected)
    doClick(v, action, funcptr(onAction)) chocSetAssocKey(v, "lab.action", nsString(action))
    attach(v) emit v
}
func nativeStrings(a, b, c) {
    let array = fresh("NSMutableArray") msg_1(array, "addObject:", nsString(a)) msg_1(array, "addObject:", nsString(b)) msg_1(array, "addObject:", nsString(c)) emit array
}
func textArea(value, x, y, w, h, editable, key, mode, monospaced) {
    let sv = fresh("NSScrollView") frame(sv, x, y, w, h)
    msg_1(sv, "setHasVerticalScroller:", 1) msg_1(sv, "setBorderType:", 0)
    msg_1(sv, "setWantsLayer:", 1) msg_d1(msg(sv, "layer"), "setCornerRadius:", 8)
    let tv = msg_frame(msg(cls("NSTextView"), "alloc"), "initWithFrame:", 0, 0, w, h)
    msg_1(tv, "setRichText:", 0) msg_1(tv, "setEditable:", editable)
    msg_1(tv, "setSelectable:", 1) msg_1(tv, "setVerticallyResizable:", 1)
    msg_1(tv, "setHorizontallyResizable:", 0)
    msg_d2(tv, "setTextContainerInset:", 12, 12)
    msg_1(tv, "setBackgroundColor:", insetColor()) msg_1(tv, "setTextColor:", ink())
    msg_1(tv, "setFont:", msg_d1(cls("NSFont"), "systemFontOfSize:", 13))
    if monospaced == 1 { msg_1(tv, "setFont:", mono(12)) }
    msg_1(msg(tv, "textContainer"), "setWidthTracksTextView:", 1)
    msg_1(tv, "setAutoresizingMask:", 2)
    msg_1(tv, "setString:", nsString(value))
    msg_1(sv, "setDocumentView:", tv)
    attach(sv)
    if editable == 1 {
        editor = tv editorKey = key editorMode = mode
        msg_1(tv, "setDelegate:", delegate)
        identify(tv, "analyst.editor")
    }
    emit tv
}
func flushEditor() {
    if editor != 0 && loadingEditor == 0 && editorKey != "" {
        let value = textBoxValue(editor)
        if value != saved(editorKey) {
            store(editorKey, value)
            if editorMode == "reason" { store(slot("answer", decisionIndex), "") if feedbackView != 0 { doTextBox(feedbackView, "Rationale changed. Check your decision again for updated feedback.") } }
        }
    }
    emit 1
}
func onTextChange(self, command, notification) { flushEditor() emit 0 }
func clearDocument(height) {
    flushEditor() loadingEditor = 1 editor = 0 editorKey = "" editorMode = "" responsePopup = 0 feedbackView = 0
    while msg(msg(document, "subviews"), "count") > 0 { msg(at(msg(document, "subviews"), 0), "removeFromSuperview") }
    docHeight = height msg_d2(document, "setFrameSize:", 960, height)
    msg_frame(msg(scroller, "contentView"), "scrollToPoint:", 0, 0, 0, 0)
    msg_1(scroller, "reflectScrolledClipView:", msg(scroller, "contentView"))
    loadingEditor = 0 emit 1
}
func header(kicker, title, subtitle) {
    labelAt(kicker, 32, 26, 880, 19, 10, muted())
    labelAt(title, 32, 53, 880, 44, 29, ink())
    labelAt(subtitle, 32, 104, 880, 47, 13, muted())
    emit 1
}
func caseHeader(stage) {
    header("SIMULATED CASE " + str(currentCase(), "number") + "  /  " + str(currentCase(), "org"), str(currentCase(), "title"), str(currentCase(), "category") + "   ·   All records fictional. All timestamps UTC.")
    let names = nativeStrings("1  Evidence", "2  Timeline", "3  Decisions")
    msg_1(names, "addObject:", nsString("4  Report")) msg_1(names, "addObject:", nsString("5  Review"))
    let i = 0
    while i < 5 { let primary = 0 if i == stage { primary = 1 } actionAt(nsToStr(at(names, i)), 32 + i * 178, 158, 168, "stage", i, primary) i += 1 }
    labelAt("Progress: " + progressPercent() + "%   ·   " + reviewedCount() + "/6 reviewed   ·   " + assessedCount() + "/6 assessed   ·   " + decisionCount() + "/3 decisions checked", 34, 204, 870, 25, 11, muted())
    emit 1
}
func showHome() {
    clearDocument(1150)
    header("THE KRYPTON ANALYST WORKSPACE", "Think critically. Investigate confidently.", "Apply your cybersecurity education through evidence, defensible decisions, and business impact.")
    panel(32, 165, 890, 194, rgb(48, 31, 67))
    labelAt("KNOWLEDGE MEETS INVESTIGATION", 57, 185, 760, 18, 10, rgb(205, 190, 222))
    labelAt("Your next breakthrough starts with the evidence.", 57, 215, 770, 65, 28, rgb(250, 247, 255))
    labelAt("Three complete missions. Native on your Mac. No connected security systems.", 57, 294, 770, 23, 13, rgb(205, 190, 222))
    labelAt("LOCAL PRACTICE  /  SIMULATED DATA ONLY", 57, 327, 770, 19, 10, green())
    let i = 0
    while i < 3 {
        let old = caseIndex caseIndex = i
        let top = 389 + i * 169
        panel(32, top, 890, 150, cardColor())
        labelAt("CASE " + str(currentCase(), "number") + "   ·   " + str(currentCase(), "category"), 54, top + 15, 670, 20, 10, purple())
        labelAt(str(currentCase(), "title"), 54, top + 42, 660, 32, 20, ink())
        labelAt(str(currentCase(), "summary"), 54, top + 82, 620, 48, 12, muted())
        let caption = "Open investigation"
        if saved("complete") == "yes" { caption = "Revisit case" }
        actionAt(caption, 711, top + 44, 188, "case", i, 1)
        labelAt(progressPercent() + "%  ·  " + str(currentCase(), "duration"), 715, top + 93, 180, 24, 11, muted())
        caseIndex = old i += 1
    }
    panel(32, 919, 890, 125, highlightColor())
    labelAt("Good analysts know what they don’t know.", 54, 939, 830, 28, 18, ink())
    labelAt("Classify facts, inferences, and unresolved claims. Explain technical findings and business consequences. Reports become your local evidence portfolio.", 54, 976, 830, 49, 12, muted())
    labelAt("PLANNED: network defense · risk & governance · isolated labs · secure-code review", 35, 1071, 880, 24, 11, muted())
    emit 1
}
func showEvidence() {
    clearDocument(1610) caseHeader(0)
    labelAt("Your assignment", 34, 247, 850, 24, 17, ink())
    labelAt(str(currentCase(), "brief"), 34, 281, 870, 70, 13, muted())
    labelAt(str(currentCase(), "context"), 34, 362, 870, 76, 12, muted())
    let list = fresh("NSMutableArray") let i = 0
    while i < 6 { msg_1(list, "addObject:", nsString(recordId(i) + "  ·  " + str(evidenceAt(i), "type") + "  ·  " + str(evidenceAt(i), "title"))) i += 1 }
    identify(popupAt(list, 32, 451, 890, itemIndex, "evidence-pick"), "evidence.selector")
    let e = evidenceAt(itemIndex)
    labelAt(recordId(itemIndex) + " / " + str(e, "source"), 34, 499, 875, 23, 11, purple())
    labelAt(str(e, "title"), 34, 531, 870, 35, 22, ink())
    textArea(str(e, "body"), 32, 580, 890, 315, 0, "", "", 1)
    let reviewed = "Mark reviewed"
    if saved(slot("reviewed", itemIndex)) == "yes" { reviewed = "✓ Reviewed" }
    actionAt(reviewed, 32, 910, 170, "reviewed", itemIndex, 1)
    let added = "Add to timeline"
    if contains(saved("timeline"), token(itemIndex)) { added = "✓ In timeline" }
    actionAt(added, 215, 910, 170, "add", itemIndex, 0)
    labelAt("Assess this observation", 34, 971, 870, 26, 18, ink())
    labelAt("“" + str(e, "claim") + "”", 34, 1010, 870, 62, 15, purple())
    labelAt("Classify the statement above, not whether the record itself exists.", 34, 1083, 870, 24, 11, muted())
    let selected = saved(slot("classification", itemIndex))
    let labels = nativeStrings("Confirmed fact", "Reasonable inference", "Unresolved") let j = 0
    while j < 3 { let primary = 0 if selected == confidenceValue(j) { primary = 1 } actionAt(nsToStr(at(labels, j)), 32 + j * 297, 1120, 282, "classify", j, primary) j += 1 }
    let guidance = "Choose a classification to see the authored explanation."
    if selected != "" {
        guidance = "Expected: " + confidenceName(str(e, "expected")) + ". " + str(e, "why")
        if selected == str(e, "expected") { guidance = "Well supported. " + str(e, "why") }
    }
    labelAt(guidance, 34, 1174, 870, 85, 12, muted())
    labelAt("Your analyst notes  ·  Explain support, alternatives, and collection gaps", 34, 1280, 870, 26, 13, ink())
    textArea(saved(slot("note", itemIndex)), 32, 1319, 890, 155, 1, slot("note", itemIndex), "note", 0)
    actionAt("Next: build your timeline →", 641, 1500, 282, "stage", 1, 1)
    emit 1
}
func showTimeline() {
    clearDocument(1230) caseHeader(1)
    labelAt("Put the story in order.", 34, 250, 860, 33, 23, ink())
    labelAt("Arrange events using Earlier / Later. UTC throughout. Sequence alone does not prove causation.", 34, 293, 865, 46, 13, muted())
    actionAt("Sort chronologically", 32, 350, 196, "sort", 0, 1)
    let order = saved("timeline") let i = 0
    if len(order) == 0 { labelAt("Your timeline is empty. Add records from the shelf below.", 34, 406, 870, 55, 15, muted()) }
    while i < len(order) {
        let item = indexOf("abcdef", substring(order, i, i + 1)) let e = evidenceAt(item) let y = 408 + i * 82
        panel(32, y, 890, 70, cardColor())
        let time = str(e, "time") + " UTC"
        if str(e, "date") != "" { time = "13 May · " + str(e, "time") }
        labelAt(recordId(item) + "  ·  " + time, 49, y + 12, 470, 18, 10, purple())
        labelAt(str(e, "title"), 49, y + 34, 460, 24, 14, ink())
        let up = actionAt("Earlier", 540, y + 18, 110, "earlier", item, 0)
        let down = actionAt("Later", 657, y + 18, 100, "later", item, 0)
        actionAt("Remove", 765, y + 18, 139, "remove", item, 0)
        if i == 0 { doDisable(up) } if i == len(order) - 1 { doDisable(down) }
        i += 1
    }
    let y = 480 + len(order) * 82
    labelAt("Evidence shelf", 34, y, 850, 28, 18, ink())
    let added = 0 let j = 0
    while j < 6 {
        if !contains(order, token(j)) { actionAt("+ " + recordId(j) + "  " + str(evidenceAt(j), "title"), 32, y + 43 + added * 45, 890, "add", j, 0) added += 1 }
        j += 1
    }
    if added == 0 { labelAt("All six records added. Check chronology before making response decisions.", 34, y + 44, 870, 45, 13, muted()) }
    actionAt("Next: response decisions →", 640, 1158, 282, "stage", 2, 1)
    emit 1
}
func showDecisions() {
    clearDocument(1370) caseHeader(2)
    labelAt("Make the call. Show your thinking.", 34, 249, 870, 36, 23, ink())
    labelAt("Proposed responses only. No account, mailbox, or endpoint action is executed.", 34, 297, 870, 35, 12, muted())
    let list = fresh("NSMutableArray") let i = 0
    while i < 3 { msg_1(list, "addObject:", nsString("Decision " + (i + 1) + "  ·  " + str(decisionAt(i), "title"))) i += 1 }
    identify(popupAt(list, 32, 348, 890, decisionIndex, "decision-pick"), "decision.selector")
    let d = decisionAt(decisionIndex)
    labelAt(str(d, "title"), 34, 401, 870, 36, 22, ink())
    labelAt(str(d, "prompt"), 34, 449, 870, 46, 14, muted())
    actionAt("Optional hint", 32, 503, 155, "hint", 0, 0)
    let options = obj(d, "options") let titles = fresh("NSMutableArray")
    msg_1(titles, "addObject:", nsString("Choose your response…"))
    let n = 0
    while n < 3 {
        msg_1(titles, "addObject:", nsString("Option " + (n + 1)))
        panel(32, 558 + n * 97, 890, 83, cardColor())
        labelAt("0" + (n + 1), 49, 575 + n * 97, 50, 25, 16, purple())
        labelAt(str(at(options, n), "label"), 100, 575 + n * 97, 793, 54, 13, ink())
        n += 1
    }
    let selection = 0
    let draft = saved(slot("choice", decisionIndex))
    if draft == "0" || draft == "1" || draft == "2" { selection = toInt(draft) + 1 }
    responsePopup = popupAt(titles, 32, 873, 890, selection, "response-pick")
    labelAt("Defend your decision. Cite evidence, explain risk reduction and business tradeoff.", 34, 929, 870, 40, 13, ink())
    textArea(saved(slot("reason", decisionIndex)), 32, 975, 890, 143, 1, slot("reason", decisionIndex), "reason", 0)
    actionAt("Check my decision", 32, 1140, 200, "check-decision", 0, 1)
    let answer = saved(slot("answer", decisionIndex)) let guidance = "Your explanation matters. Write a rationale, then check your response."
    if answer == "0" || answer == "1" || answer == "2" { guidance = str(at(options, toInt(answer)), "explanation") }
    feedbackView = textArea(guidance, 32, 1196, 890, 135, 0, "", "", 0)
    emit 1
}
func showReport() {
    clearDocument(1080) caseHeader(3)
    labelAt("Turn findings into a defensible report.", 34, 249, 870, 34, 23, ink())
    labelAt("Write for responders and leadership. Cite case records using [" + recordId(0) + "]. Draft saves as you type.", 34, 295, 870, 44, 13, muted())
    let list = fresh("NSMutableArray") let i = 0
    while i < 6 { msg_1(list, "addObject:", obj(at(sections, i), "label")) i += 1 }
    identify(popupAt(list, 32, 353, 890, reportIndex, "report-pick"), "report.selector")
    labelAt(str(at(sections, reportIndex), "label"), 34, 407, 870, 32, 21, ink())
    labelAt(str(at(sections, reportIndex), "placeholder"), 34, 452, 870, 56, 13, muted())
    textArea(saved(slot("report", reportIndex)), 32, 523, 890, 255, 1, slot("report", reportIndex), "report", 0)
    actionAt("Export Markdown…", 32, 798, 185, "export", 0, 1)
    actionAt("Review investigation →", 671, 798, 250, "stage", 4, 0)
    labelAt("Evidence reference shelf", 34, 861, 870, 26, 17, ink())
    let e = 0
    while e < 6 { actionAt(recordId(e) + "  " + str(evidenceAt(e), "title"), 32 + (e % 2) * 448, 905 + (e / 2) * 43, 436, "reference", e, 0) e += 1 }
    emit 1
}
func reportChecklist() {
    let b = sbNew()
    b = sbAppend(b, "Evidence reviewed: " + reviewedCount() + "/6\nObservations classified: " + assessedCount() + "/6\nTimeline records: " + len(saved("timeline")) + "/6\nDecisions checked with rationale: " + decisionCount() + "/3\nReport sections written: " + reportCount() + "/6\nDistinct evidence IDs cited: " + citationCount() + " (need at least 2)\nUnrecognized evidence IDs: " + invalidCitations() + " (need 0)")
    emit sbToString(b)
}
func showReview() {
    clearDocument(1740) caseHeader(4)
    labelAt("Review your investigation.", 34, 251, 870, 35, 23, ink())
    labelAt("Structured feedback compares answers with authored guidance. Narrative quality requires self-review.", 34, 296, 870, 43, 13, muted())
    panel(32, 359, 890, 143, highlightColor())
    labelAt("Evidence: " + correctClassifications() + "/6 aligned     ·     Decisions: " + correctDecisions() + "/3 aligned", 54, 382, 846, 28, 18, purple())
    let timeline = "Timeline: review your ordering."
    if saved("timeline") == chronologicalOrder() { timeline = "Timeline: chronological. Earlier does not automatically mean causal." }
    labelAt(timeline, 54, 425, 846, 51, 12, muted())
    textArea(reportChecklist(), 32, 526, 890, 225, 0, "", "", 0)
    let caption = "Complete investigation & reveal debrief"
    if saved("complete") == "yes" { caption = "✓ Completed — debrief unlocked" }
    let complete = actionAt(caption, 32, 770, 451, "complete", 0, 1)
    if readyToComplete() == 0 { doDisable(complete) }
    actionAt("Export report…", 703, 770, 218, "export", 0, 0)
    labelAt("Completion requires the checklist above, not perfect answers. Revise any answer and reassess.", 34, 822, 870, 41, 11, muted())
    labelAt("Analyst self-review", 34, 890, 870, 27, 18, ink())
    textArea("Can each technical claim be traced to a record?\nHave you separated confirmed facts, likelihood, and unresolved gaps?\nDoes each decision explain evidence, preservation, tradeoffs, and validation?\nDoes leadership understand potential versus confirmed business impact?\nAre recovery criteria, owners, and review times explicit?", 32, 933, 890, 170, 0, "", "", 0)
    if saved("complete") == "yes" {
        let text = "CASE DEBRIEF\n\n" + str(currentCase(), "debrief") + "\n\nBUSINESS IMPACT\n" + str(currentCase(), "business") + "\n\nNEXT COLLECTION\n" + str(currentCase(), "next") + "\n\nSAMPLE SYNTHESIS\n" + str(currentCase(), "exemplar") + "\n\nOne defensible synthesis, not the only acceptable answer. Your full report should also name owners, validation, and review times."
        textArea(text, 32, 1130, 890, 482, 0, "", "", 0)
    } else { labelAt("Finish the checklist to unlock the full case debrief and sample synthesis.", 34, 1139, 870, 55, 15, muted()) }
    actionAt("Reset this case…", 32, 1654, 190, "reset", 0, 0)
    emit 1
}
func showPortfolio() {
    clearDocument(1030)
    header("YOUR EVIDENCE PORTFOLIO", "Work you can explain and defend.", "Incident reports stay on this Mac. Export Markdown to keep a portable copy of your work.")
    let original = caseIndex let i = 0
    while i < 3 {
        caseIndex = i let y = 171 + i * 220
        panel(32, y, 890, 199, cardColor())
        labelAt(str(currentCase(), "org"), 53, y + 20, 810, 20, 11, purple())
        labelAt(str(currentCase(), "title"), 53, y + 51, 810, 35, 21, ink())
        let status = "Draft"
        if saved("complete") == "yes" { status = "Submitted for self-review" }
        labelAt(status + "   ·   " + reportCount() + "/6 sections written", 53, y + 98, 800, 23, 12, muted())
        actionAt("Open report", 53, y + 141, 170, "portfolio-case", i, 1)
        actionAt("Export Markdown…", 240, y + 141, 180, "export-case", i, 0)
        i += 1
    }
    caseIndex = original
    labelAt("Planned portfolio additions: risk assessments, network reviews, and security recommendations.", 34, 881, 870, 52, 13, muted())
    emit 1
}
func showSkills() {
    clearDocument(1280)
    header("YOUR LEARNING SIGNALS", "Practice. Reflect. Revisit.", "Structured practice results, not a certification or semantic assessment of your writing.")
    let original = caseIndex let i = 0
    while i < 3 {
        caseIndex = i let y = 176 + i * 232
        panel(32, y, 890, 210, cardColor())
        labelAt(str(currentCase(), "category"), 54, y + 20, 810, 31, 20, ink())
        labelAt("Evidence reasoning: " + correctClassifications() + "/6 aligned  ·  Response decisions: " + correctDecisions() + "/3 aligned", 54, y + 69, 810, 30, 14, purple())
        let feedback = "Start with the evidence, then explain what remains uncertain."
        if assessedCount() > 0 && correctClassifications() < assessedCount() { feedback = "Revisit evidence classifications: read the explanations and identify where your confidence exceeded the records." }
        else { if decisionCount() > 0 && correctDecisions() < decisionCount() { feedback = "Revisit response tradeoffs: preservation, containment scope, and business continuity." } }
        labelAt(feedback, 54, y + 112, 810, 49, 12, muted())
        actionAt("Revisit investigation", 54, y + 165, 220, "case", i, 1)
        i += 1
    }
    caseIndex = original
    labelAt("Next learning modules", 34, 910, 870, 30, 21, ink())
    labelAt("PLANNED · Network defense: diagrams, firewall rules, access reviews.\nPLANNED · Risk & governance: prioritize risks, select controls, justify spending.\nPLANNED · Isolated hands-on labs and secure-code review.", 34, 961, 870, 103, 13, muted())
    labelAt("These modules are roadmap items, not playable challenges in version 1.", 34, 1093, 870, 30, 12, muted())
    emit 1
}
func showGuide() {
    clearDocument(1210)
    header("ANALYST FIELD GUIDE", "Ground every claim in evidence.", "A companion for applying graduate cybersecurity knowledge to practical decisions.")
    textArea("01  NAME YOUR CONFIDENCE\n\nConfirmed fact: a directly supported, bounded observation. Say what the source records, not what you assume it means.\n\nReasonable inference: an explanation supported by observations. Name supporting evidence and plausible alternatives.\n\nUnresolved: a claim the available records cannot establish. Describe missing evidence and how to obtain it.\n\n02  BUILD A TESTABLE STORY\n\nNormalize time zones and distinguish event time from collection time. Correlate session IDs, process IDs, and hashes. Earlier does not necessarily mean causal. Treat missing telemetry as a collection gap, not proof that an event never occurred.\n\n03  EXPLAIN THE RESPONSE TRADEOFF\n\nState the observed risk, why the action helps, evidence to preserve, and business services affected. Define recovery checks, owners, and review times. Translate technical findings into potential versus confirmed financial, operational, and confidentiality impact.\n\n04  KNOW THIS LAB’S LIMITS\n\nAll organizations, people, records, and events are fictional. Sample domains and addresses are inert training text. No security tools, mail, accounts, or endpoints are connected. Response choices are proposals only.\n\nFeedback is authored and rule-based. Evidence classifications and response choices have case-specific explanations. Reports and rationales are saved for self-review, not semantically graded or assessed by AI. No external API, telemetry, login, or cloud service is used.\n\nLocal preferences retain progress after quitting. Export a Markdown report for a portable copy. Data is not shared between the native app and the separate browser prototype.\n\nNo NIST NICE or MITRE ATT&CK skill or technique mappings are claimed in this version. Future mappings require verification against official sources.\n\n05  GRADUATE-LEVEL REFLECTION\n\nWhat alternative hypothesis fits the observations? Which collection could change your decision? What business process must continue? Which control would reduce recurrence, who owns it, and how would you measure whether it worked?", 32, 168, 890, 940, 0, "", "", 0)
    emit 1
}
func render() {
    if screen == "home" { showHome() }
    if screen == "evidence" { showEvidence() }
    if screen == "timeline" { showTimeline() }
    if screen == "decisions" { showDecisions() }
    if screen == "report" { showReport() }
    if screen == "review" { showReview() }
    if screen == "portfolio" { showPortfolio() }
    if screen == "skills" { showSkills() }
    if screen == "guide" { showGuide() }
    emit 1
}
func stageName(n) { if n == 0 { emit "evidence" } if n == 1 { emit "timeline" } if n == 2 { emit "decisions" } if n == 3 { emit "report" } emit "review" }
func exportMarkdown() {
    let b = sbNew()
    let status = "Draft"
    if saved("complete") == "yes" { status = "Submitted for self-review" }
    b = sbAppend(b, "# Krypton CyberLab — " + str(currentCase(), "title") + "\n\nSIMULATED TRAINING REPORT. Fictional records; no real response actions performed.\n\nOrganization: " + str(currentCase(), "org") + "\nStatus: " + status + "\n\n")
    let i = 0
    while i < 6 { b = sbAppend(b, "## " + str(at(sections, i), "label") + "\n\n" + saved(slot("report", i)) + "\n\n") i += 1 }
    b = sbAppend(b, "## Analyst timeline (user order)\n\n")
    let order = saved("timeline") let j = 0
    while j < len(order) { let n = indexOf("abcdef", substring(order, j, j + 1)) let e = evidenceAt(n) b = sbAppend(b, "- [" + recordId(n) + "] " + str(e, "time") + " UTC " + str(e, "date") + " — " + str(e, "title") + "\n") j += 1 }
    b = sbAppend(b, "\n## Evidence reasoning\n\n")
    let n = 0
    while n < 6 { let e = evidenceAt(n) b = sbAppend(b, "### [" + recordId(n) + "] " + str(e, "title") + "\nObservation: " + str(e, "claim") + "\nClassification: " + confidenceName(saved(slot("classification", n))) + "\nNotes: " + saved(slot("note", n)) + "\n\n") n += 1 }
    b = sbAppend(b, "## Proposed response decisions\n\n")
    let d = 0
    while d < 3 {
        let answer = saved(slot("answer", d)) let choice = "Not checked"
        if answer == "0" || answer == "1" || answer == "2" { choice = str(at(obj(decisionAt(d), "options"), toInt(answer)), "label") }
        b = sbAppend(b, "### " + str(decisionAt(d), "title") + "\nChoice: " + choice + "\nRationale: " + saved(slot("reason", d)) + "\n\n") d += 1
    }
    b = sbAppend(b, "## Structured practice feedback\n\nEvidence classifications: " + correctClassifications() + "/6 aligned.\nResponse decisions: " + correctDecisions() + "/3 aligned.\nReports and reasoning need human self-review. These checks do not establish writing quality, professional competence, or certification.\n")
    if saved("complete") == "yes" { b = sbAppend(b, "\n## Authored case debrief\n\n" + str(currentCase(), "debrief") + "\n\nBusiness impact: " + str(currentCase(), "business") + "\n\nNext collection: " + str(currentCase(), "next")) }
    emit sbToString(b)
}
func exportReport() {
    flushEditor()
    let path = saveFile("Export simulated incident report", "Krypton-" + str(currentCase(), "id") + "-report.md")
    if path == "" { emit 0 }
    let success = msg_4(nsString(exportMarkdown()), "writeToFile:atomically:encoding:error:", nsString(path), 1, 4, 0)
    if success == 1 { doText(statusLabel, "Report exported to " + path) }
    else { alert("Export failed", "The report could not be written. Your saved progress is still on this Mac. Choose a writable location and try again.") }
    emit success
}
func resetCase() {
    let alert = fresh("NSAlert")
    msg_1(alert, "setMessageText:", nsString("Reset this investigation?"))
    msg_1(alert, "setInformativeText:", nsString("Export first to keep a copy. This removes this case’s notes, assessments, decisions, timeline, and report from this Mac. Other cases stay intact."))
    msg_1(alert, "addButtonWithTitle:", nsString("Cancel")) msg_1(alert, "addButtonWithTitle:", nsString("Reset case"))
    if msg(alert, "runModal") != 1001 { emit 0 }
    editor = 0
    let i = 0
    while i < 6 { store(slot("reviewed", i), "") store(slot("classification", i), "") store(slot("note", i), "") store(slot("report", i), "") i += 1 }
    let d = 0
    while d < 3 { store(slot("choice", d), "") store(slot("answer", d), "") store(slot("reason", d), "") d += 1 }
    store("timeline", "") store("complete", "") render() emit 1
}
func onAction(self, command, sender) {
    flushEditor()
    let action = nsToStr(chocGetAssocKey(sender, "lab.action")) let tag = msg(sender, "tag")
    if action == "settings" { showSettings() emit 0 }
    if action == "settings-done" { msg_1(settingsWindow, "orderOut:", 0) emit 0 }
    if action == "theme" {
        let choice = msg(sender, "indexOfSelectedItem")
        let mode = "system" if choice == 1 { mode = "light" } if choice == 2 { mode = "dark" }
        chooseTheme(mode) emit 0
    }
    if action == "home" { screen = "home" }
    if action == "portfolio" { screen = "portfolio" }
    if action == "skills" { screen = "skills" }
    if action == "guide" { screen = "guide" }
    if action == "case" { editor = 0 caseIndex = tag itemIndex = 0 screen = "evidence" }
    if action == "portfolio-case" { editor = 0 caseIndex = tag reportIndex = 0 screen = "report" }
    if action == "stage" { screen = stageName(tag) }
    if action == "evidence-pick" { itemIndex = msg(sender, "indexOfSelectedItem") }
    if action == "decision-pick" { decisionIndex = msg(sender, "indexOfSelectedItem") }
    if action == "report-pick" { reportIndex = msg(sender, "indexOfSelectedItem") }
    if action == "reviewed" { store(slot("reviewed", itemIndex), "yes") }
    if action == "add" { timelineAdd(tag) }
    if action == "remove" { timelineRemove(tag) }
    if action == "earlier" { timelineMove(tag, 0 - 1) }
    if action == "later" { timelineMove(tag, 1) }
    if action == "sort" { sortTimeline() }
    if action == "classify" { store(slot("classification", itemIndex), confidenceValue(tag)) }
    if action == "reference" { itemIndex = tag screen = "evidence" }
    if action == "response-pick" {
        let choice = msg(sender, "indexOfSelectedItem") - 1
        let value = "" if choice >= 0 { value = "" + choice }
        store(slot("choice", decisionIndex), value) store(slot("answer", decisionIndex), "")
        if feedbackView != 0 { doTextBox(feedbackView, "Choice changed. Explain your reasoning, then check this decision.") }
        emit 0
    }
    if action == "hint" { alert("Optional case hint", str(decisionAt(decisionIndex), "hint")) emit 0 }
    if action == "check-decision" {
        let selected = saved(slot("choice", decisionIndex))
        if selected == "" || clean(saved(slot("reason", decisionIndex))) == "" { alert("Explain your decision", "Choose a response and write your evidence-based rationale before checking it.") emit 0 }
        store(slot("answer", decisionIndex), selected)
    }
    if action == "complete" { if readyToComplete() == 1 { store("complete", "yes") } }
    if action == "export" { exportReport() emit 0 }
    if action == "export-case" { let old = caseIndex editor = 0 caseIndex = tag exportReport() caseIndex = old emit 0 }
    if action == "reset" { resetCase() emit 0 }
    // Clear editor before changing selected evidence/report keys to avoid saving
    // a previous editor value under the newly selected item during rendering.
    editor = 0 render() emit 0
}
// Settings use a separate native window so future preferences do not crowd
// the investigation workspace. Reuse the same window after closing it.
func refreshSettings() {
    let previousDocument = document let previousHeight = docHeight let previousSidebar = buildingSidebar
    document = settingsDocument docHeight = 380 buildingSidebar = 0
    while msg(msg(document, "subviews"), "count") > 0 { msg(at(msg(document, "subviews"), 0), "removeFromSuperview") }
    paint(document, pageColor())
    labelAt("Settings", 28, 23, 544, 38, 26, ink())
    labelAt("Preferences for your Krypton workspace.", 28, 72, 544, 25, 13, muted())
    panel(28, 118, 544, 166, cardColor())
    labelAt("APPEARANCE", 48, 137, 490, 20, 10, purple())
    labelAt("Theme", 48, 177, 175, 28, 17, ink())
    let selected = 0
    if themeChoice() == "light" { selected = 1 } if themeChoice() == "dark" { selected = 2 }
    themePopup = popupAt(nativeStrings("Follow ", "Light", "Dark"), 278, 172, 270, selected, "theme")
    identify(themePopup, "appearance.selector") msg_1(themePopup, "setAccessibilityLabel:", nsString("Appearance"))
    labelAt("Follow macOS automatically matches your system appearance.", 48, 224, 480, 42, 12, muted())
    labelAt("Changes save automatically on this Mac.", 28, 319, 350, 25, 11, muted())
    actionAt("Done", 428, 313, 144, "settings-done", 0, 1)
    document = previousDocument docHeight = previousHeight buildingSidebar = previousSidebar
    emit 1
}
func showSettings() {
    flushEditor()
    if settingsWindow == 0 {
        settingsWindow = window("Krypton CyberLab Settings", 600, 380)
        msg_1(settingsWindow, "setReleasedWhenClosed:", 0)
        msg_1(settingsWindow, "setStyleMask:", 3)
        let klass = cls("KryptonCyberLabDocument")
        settingsDocument = msg_frame(msg(klass, "alloc"), "initWithFrame:", 0, 0, 600, 380)
        msg_1(settingsWindow, "setContentView:", settingsDocument)
        msg(settingsWindow, "center")
    }
    applyTheme()
    doShow(settingsWindow)
    emit 1
}
func onOpenSettings(self, command, sender) { showSettings() emit 0 }
func onQuit(self, command, sender) { flushEditor() doQuit() emit 0 }
func onWindowClose(self, command, notification) { flushEditor() doQuit() emit 0 }
func navButton(title, y, key) {
    let v = fresh("NSButton") msg_frame(v, "setFrame:", 14, 820 - y - 38, 182, 38)
    msg_1(v, "setTitle:", nsString(title)) msg_1(v, "setBezelStyle:", 1)
    msg_1(v, "setBezelColor:", rgb(60, 42, 79)) msg_1(v, "setContentTintColor:", rgb(236, 228, 246))
    msg_1(v, "setAutoresizingMask:", 8)
    doClick(v, key, funcptr(onAction)) chocSetAssocKey(v, "lab.action", nsString(key))
    msg_1(sidebar, "addSubview:", v) emit v
}
func initializeUI() {
    app("Krypton CyberLab")
    win = window("Krypton CyberLab — Simulated Analyst Workspace", 1200, 820)
    applyTheme()
    minSize(win, 1170, 740)
    msg_1(win, "setReleasedWhenClosed:", 0) msg_1(win, "setFrameAutosaveName:", nsString("KryptonCyberLabMain"))
    let content = msg(win, "contentView")
    sidebar = msg_frame(msg(cls("NSView"), "alloc"), "initWithFrame:", 0, 0, 210, 820)
    paint(sidebar, rgb(33, 23, 46)) msg_1(sidebar, "setAutoresizingMask:", 16) msg_1(content, "addSubview:", sidebar)
    document = sidebar docHeight = 820 buildingSidebar = 1
    labelAt("K", 24, 28, 38, 48, 37, green())
    labelAt("KRYPTON", 66, 32, 134, 29, 19, rgb(249, 245, 255))
    labelAt("C Y B E R L A B", 68, 65, 135, 20, 9, rgb(191, 172, 210))
    labelAt("YOUR WORKSPACE", 24, 129, 170, 21, 9, rgb(191, 172, 210))
    navButton("Investigations", 168, "home") navButton("Evidence portfolio", 217, "portfolio") navButton("Skill dashboard", 266, "skills") navButton("Analyst field guide", 315, "guide")
    settingsButton = navButton("Settings", 377, "settings")
    identify(settingsButton, "settings.open")
    labelAt("A safe place to investigate.", 22, 623, 170, 49, 14, green())
    labelAt("Fictional cases.\nReal analytical practice.", 22, 685, 170, 50, 11, rgb(204, 188, 220))
    labelAt("SIMULATION ENVIRONMENT", 22, 766, 175, 19, 8, green())
    buildingSidebar = 0
    scroller = msg_frame(msg(cls("NSScrollView"), "alloc"), "initWithFrame:", 210, 32, 990, 788)
    msg_1(scroller, "setHasVerticalScroller:", 1) msg_1(scroller, "setHasHorizontalScroller:", 1)
    msg_1(scroller, "setAutoresizingMask:", 18) msg_1(scroller, "setDrawsBackground:", 0)
    let documentClass = chocViewClassNew("KryptonCyberLabDocument")
    chocClassAddMethod(documentClass, "isFlipped", funcptr(documentIsFlipped), "q@:")
    chocClassRegister(documentClass)
    document = msg_frame(msg(documentClass, "alloc"), "initWithFrame:", 0, 0, 960, 1200)
    msg_1(scroller, "setDocumentView:", document) msg_1(content, "addSubview:", scroller)
    statusLabel = fresh("NSTextField") msg_frame(statusLabel, "setFrame:", 230, 6, 940, 20)
    msg_1(statusLabel, "setEditable:", 0) msg_1(statusLabel, "setBezeled:", 0) msg_1(statusLabel, "setDrawsBackground:", 0)
    msg_1(statusLabel, "setTextColor:", muted()) msg_1(statusLabel, "setFont:", msg_d1(cls("NSFont"), "systemFontOfSize:", 10))
    msg_1(statusLabel, "setAutoresizingMask:", 2) msg_1(content, "addSubview:", statusLabel)
    doText(statusLabel, "Local learning workspace · Fictional data only · Saved on this Mac")
    let klass = chocClassNew("KryptonCyberLabDelegate")
    chocClassAddMethod(klass, "textDidChange:", funcptr(onTextChange), "v@:@")
    chocClassAddMethod(klass, "windowWillClose:", funcptr(onWindowClose), "v@:@")
    chocClassAddMethod(klass, "observeValueForKeyPath:ofObject:change:context:", funcptr(onSystemTheme), "v@:@@@^v")
    chocClassRegister(klass) delegate = msg(klass, "new") msg_1(win, "setDelegate:", delegate)
    msg_4(sharedApp(), "addObserver:forKeyPath:options:context:", delegate, nsString("effectiveAppearance"), 0, 0)
    applyTheme()
    let bar = menuBar() let application = menu(bar, "Krypton CyberLab")
    menuAction(application, "Settings…", ",", funcptr(onOpenSettings))
    menuSeparator(application)
    menuAction(application, "Quit Krypton CyberLab", "q", funcptr(onQuit))
    let edit = menu(bar, "Edit")
    menuSelector(edit, "Undo", "z", "undo:") menuSelector(edit, "Redo", "Z", "redo:")
    menuSeparator(edit) menuSelector(edit, "Cut", "x", "cut:") menuSelector(edit, "Copy", "c", "copy:") menuSelector(edit, "Paste", "v", "paste:") menuSelector(edit, "Select All", "a", "selectAll:")
    render() msg(win, "center") emit 1
}

// Assertions and native integration checks share production functions.
func expect(name, yes) {
    if !yes { print("FAIL: " + name) exit("1") }
    assertions += 1 print("PASS: " + name) emit 1
}
func findAction(action, tag) {
    let views = msg(document, "subviews") let i = 0
    while i < msg(views, "count") {
        let view = at(views, i)
        if nsToStr(chocGetAssocKey(view, "lab.action")) == action {
            if msg(view, "tag") == tag { emit view }
        }
        i += 1
    }
    emit 0
}
func selfTest() {
    expect("three cases", msg(curriculum, "count") == 3)
    expect("six report sections", msg(sections, "count") == 6)
    let c = 0
    while c < 3 {
        caseIndex = c
        expect("six records per case", msg(obj(currentCase(), "evidence"), "count") == 6)
        expect("three response decisions", msg(obj(currentCase(), "decisions"), "count") == 3)
        expect("blank case cannot complete", readyToComplete() == 0)
        let i = 0
        while i < 6 {
            let e = evidenceAt(i)
            expect("evidence includes record, observation, explanation", len(str(e, "body")) > 30 && len(str(e, "claim")) > 10 && len(str(e, "why")) > 30)
            store(slot("reviewed", i), "yes") store(slot("classification", i), str(e, "expected"))
            store(slot("note", i), "Unicode Ω · quotes \" and newline\nretained")
            timelineAdd(i) timelineAdd(i)
            i += 1
        }
        expect("timeline deduplicates", len(saved("timeline")) == 6)
        expect("six classification answers align", correctClassifications() == 6)
        timelineMove(0, 1) expect("timeline manual move", indexOf(saved("timeline"), "a") == 1)
        sortTimeline() expect("chronology includes prior-day baseline", saved("timeline") == chronologicalOrder())
        timelineRemove(2) expect("timeline removal", len(saved("timeline")) == 5)
        timelineAdd(2) sortTimeline()
        let d = 0
        while d < 3 {
            let options = obj(decisionAt(d), "options") let good = 0 let n = 0
            while n < 3 {
                expect("option explanation authored", len(str(at(options, n), "explanation")) > 40)
                if msg(obj(at(options, n), "correct"), "boolValue") == 1 { good += 1 store(slot("choice", d), "" + n) store(slot("answer", d), "" + n) }
                n += 1
            }
            expect("one defensible authored answer", good == 1)
            store(slot("reason", d), "I cite [" + recordId(0) + "] and explain preservation and business continuity.") d += 1
        }
        expect("three response answers align", correctDecisions() == 3)
        let r = 0
        while r < 6 { store(slot("report", r), "Training report section [" + recordId(0) + "] [" + recordId(1) + "] with facts and open questions.") r += 1 }
        expect("distinct citations", citationCount() == 2)
        expect("full case completes", readyToComplete() == 1)
        store("complete", "yes") expect("completion retained", saved("complete") == "yes")
        store(slot("report", 0), "Changed report [X99]") expect("edits reopen case", saved("complete") == "")
        expect("unknown evidence citation blocks completion", readyToComplete() == 0 && invalidCitations() == 1)
        store(slot("report", 0), "Revised [" + recordId(0) + "]")
        expect("export labeled simulation", contains(exportMarkdown(), "SIMULATED TRAINING REPORT"))
        expect("export includes analyst reasoning", contains(exportMarkdown(), "business continuity"))
        expect("notes preserve Unicode and newline", saved(slot("note", 0)) == "Unicode Ω · quotes \" and newline\nretained")
        c += 1
    }
    let restored = msg_1(msg(cls("NSMutableDictionary"), "alloc"), "initWithContentsOfFile:", stateFile)
    expect("progress file written to disk", restored != 0 && saveFailed == 0)
    preferences = restored
    caseIndex = 0
    expect("report restored from disk", contains(saved("report.0"), "Revised"))
    expect("notes restored from disk", contains(saved("note.0"), "Unicode Ω"))
    initializeUI()
    expect("appearance hidden from sidebar", themePopup == 0)
    let investigationScreen = screen
    msg_1(settingsButton, "performClick:", 0)
    expect("settings opens from native button", settingsWindow != 0 && themePopup != 0)
    expect("settings preserves investigation screen", screen == investigationScreen)
    msg_1(settingsWindow, "orderOut:", 0)
    showSettings()
    expect("settings window can reopen", msg(settingsWindow, "isVisible") == 1)
    msg_1(settingsWindow, "orderOut:", 0)
    // Exercise the real AppKit callback routing, text delegate, and rendering.
    screen = "report" reportIndex = 0 render()
    doTextBox(editor, "Live native editor [A1] [A3]")
    onTextChange(0, 0, 0)
    expect("native text editor persists", saved("report.0") == "Live native editor [A1] [A3]")
    screen = "evidence" itemIndex = 0 render()
    expect("native note restored", contains(textBoxValue(editor), "Unicode Ω"))
    screen = "timeline" render()
    screen = "decisions" render()
    screen = "review" render()
    screen = "portfolio" render()
    screen = "skills" render()
    screen = "guide" render()
    screen = "home" render()
    expect("all native screens render", win != 0)
    expect("document uses top-origin scrolling", msg(document, "isFlipped") == 1)
    msg_1(findAction("case", 0), "performClick:", 0)
    expect("native button opens correct case", screen == "evidence" && caseIndex == 0)
    msg_1(findAction("classify", 0), "performClick:", 0)
    expect("native classification callback", saved("classification.0") == "confirmed")
    msg_1(findAction("stage", 1), "performClick:", 0)
    expect("native timeline navigation callback", screen == "timeline")
    msg_1(findAction("stage", 2), "performClick:", 0)
    expect("native decisions navigation callback", screen == "decisions")
    doTextBox(editor, "\n\t  ") flushEditor()
    expect("whitespace rationale rejected", clean(saved("reason.0")) == "")
    store("complete", "yes")
    let priorReport = nsString(saved("report.0")) msg(priorReport, "retain")
    chooseTheme("dark")
    expect("explicit dark palette", darkTheme == 1)
    expect("dark native appearance", msg(msg(msg(win, "effectiveAppearance"), "name"), "UTF8String") == "NSAppearanceNameDarkAqua")
    expect("theme does not reopen completed investigation", saved("complete") == "yes")
    expect("theme preserves report", saved("report.0") == nsToStr(priorReport))
    let disk = msg_1(msg(cls("NSDictionary"), "alloc"), "initWithContentsOfFile:", stateFile)
    expect("appearance choice persists to disk", str(disk, "ui.appearance") == "dark")
    expect("settings theme selector stays in sync", msg(themePopup, "indexOfSelectedItem") == 2)
    expect("dark title bar is transparent over branded background", msg(win, "titlebarAppearsTransparent") == 1)
    let mode = 0
    while mode < 2 {
        if mode == 0 { chooseTheme("light") expect("explicit light palette", darkTheme == 0) }
        else { chooseTheme("dark") }
        screen = "home" render() screen = "evidence" render() screen = "timeline" render()
        screen = "decisions" render() screen = "report" render() screen = "review" render()
        screen = "portfolio" render() screen = "skills" render() screen = "guide" render()
        expect("all screens render with selected theme", win != 0)
        mode += 1
    }
    chooseTheme("system")
    expect("system theme follows effective  appearance", darkTheme == systemIsDark())
    expect("system mode clears window appearance override", msg(win, "appearance") == 0)
    print("Krypton CyberLab: " + assertions + " checks passed.")
    emit 1
}
just run {
    let pool = newPool()
    let data = msg_2(nsString(curriculumJSON()), "dataUsingEncoding:allowLossyConversion:", 4, 0)
    catalog = msg_3(cls("NSJSONSerialization"), "JSONObjectWithData:options:error:", data, 0, 0)
    if catalog == 0 { printErr("Curriculum could not be loaded.\n") exit("1") }
    curriculum = obj(catalog, "cases") sections = obj(catalog, "reportFields")
    let manager = msg(cls("NSFileManager"), "defaultManager")
    let directory = msg_1(msg(msg(manager, "homeDirectoryForCurrentUser"), "path"), "stringByAppendingPathComponent:", nsString("Library/Application Support/Krypton CyberLab"))
    if arg("0") == "--selftest" {
        testMode = 1
        directory = msg(msg(manager, "temporaryDirectory"), "path")
    }
    if msg_4(manager, "createDirectoryAtPath:withIntermediateDirectories:attributes:error:", directory, 1, 0, 0) == 0 { printErr("Unable to create local progress directory.\n") exit("1") }
    let name = "progress-v1.plist"
    if testMode == 1 { name = "krypton-cyberlab-test-" + msg(msg(cls("NSProcessInfo"), "processInfo"), "processIdentifier") + ".plist" }
    stateFile = msg_1(directory, "stringByAppendingPathComponent:", nsString(name))
    msg(stateFile, "retain")
    preferences = msg_1(msg(cls("NSMutableDictionary"), "alloc"), "initWithContentsOfFile:", stateFile)
    if preferences == 0 { preferences = fresh("NSMutableDictionary") }
    if testMode == 1 {
        selfTest()
        msg_2(manager, "removeItemAtPath:error:", stateFile, 0)
        exit("0")
    }
    initializeUI() doShow(win) doRun()
}
