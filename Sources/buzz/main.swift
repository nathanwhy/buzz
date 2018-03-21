import buzzCore

let tool = Buzz()

do {
    try tool.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
