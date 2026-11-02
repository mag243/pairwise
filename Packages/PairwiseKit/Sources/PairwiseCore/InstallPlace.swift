/// Where the app runs from, and whether that is a place to stay.
public enum InstallPlace {
    /// Whether to offer to move the app to Applications: only once, and only from elsewhere,
    /// such as a disk image or Downloads. The offer stays away from a move the user declined.
    public static func offersMove(appPath: String, homePath: String, hasOffered: Bool) -> Bool {
        guard !hasOffered else { return false }
        let places = ["/Applications/", homePath + "/Applications/"]
        return !places.contains { appPath.hasPrefix($0) }
    }
}
