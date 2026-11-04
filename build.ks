#!/usr/bin/env kr
// Build, verify, and test the native app using KryptScript only.
import "k:objc"
import "k:objk_process_macos"

func run(executable, arguments) {
    let result = okRunArgvCaptured(executable, arguments)
    let end = indexOf(result, "\n")
    let status = substring(result, 0, end)
    let output = substring(result, end + 1, len(result))
    if output != "" { print(output) }
    if status != "0" { printErr("Build step failed: " + executable + " (" + status + ")\n") exit("1") }
    emit 1
}
func args1(a) { let args = okProcessArgs() doProcessArg(args, a) emit args }
func args2(a, b) { let args = args1(a) doProcessArg(args, b) emit args }
func args3(a, b, c) { let args = args2(a, b) doProcessArg(args, c) emit args }
func args4(a, b, c, d) { let args = args3(a, b, c) doProcessArg(args, d) emit args }
just run {
    let pool = newPool()
    let root = nsToStr(msg(msg(cls("NSFileManager"), "defaultManager"), "currentDirectoryPath"))
    let bundle = root + "/dist/Krypton CyberLab.app"
    let contents = bundle + "/Contents"
    let executable = contents + "/MacOS/KryptonCyberLab"
    run("/bin/mkdir", args3("-p", contents + "/MacOS", contents + "/Resources"))
    let compiler = nsToStr(msg_1(msg(msg(cls("NSProcessInfo"), "processInfo"), "environment"), "objectForKey:", nsString("KCC")))
    if compiler == "" { compiler = "/usr/local/bin/kcc" }
    print("Compiling native Krypton / Objective-K application…")
    run(compiler, args3(root + "/src/main.ks", "-o", executable))
    let plist = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\"><dict>\n<key>CFBundleName</key><string>Krypton CyberLab</string>\n<key>CFBundleDisplayName</key><string>Krypton CyberLab</string>\n<key>CFBundleExecutable</key><string>KryptonCyberLab</string>\n<key>CFBundleIdentifier</key><string>org.krypton.CyberLab</string>\n<key>CFBundlePackageType</key><string>APPL</string>\n<key>CFBundleShortVersionString</key><string>0.1.0</string>\n<key>CFBundleVersion</key><string>1</string>\n<key>LSMinimumSystemVersion</key><string>14.0</string>\n<key>NSPrincipalClass</key><string>NSApplication</string>\n<key>NSRequiresAquaSystemAppearance</key><false/>\n<key>NSHighResolutionCapable</key><true/>\n<key>LSApplicationCategoryType</key><string>public.app-category.education</string>\n</dict></plist>\n"
    if msg_4(nsString(plist), "writeToFile:atomically:encoding:error:", nsString(contents + "/Info.plist"), 1, 4, 0) == 0 { printErr("Unable to write bundle metadata.\n") exit("1") }
    run("/usr/bin/plutil", args2("-lint", contents + "/Info.plist"))
    run("/usr/bin/codesign", args4("--force", "--sign", "-", bundle))
    run("/usr/bin/codesign", args4("--verify", "--deep", "--strict", bundle))
    if arg("0") == "test" { run(executable, args1("--selftest")) }
    print("Ready: " + bundle)
    if arg("0") == "run" { run("/usr/bin/open", args1(bundle)) }
}
