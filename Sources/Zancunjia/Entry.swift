import AppKit

@main
@MainActor
enum Entry {
    static func main() {
        let app = NSApplication.shared
        app.delegate = AppDelegate.shared
        app.run()
    }
}
