import PairwiseCore
import Testing

@Suite struct InstallPlaceTests {
    private static let home = "/Users/someone"

    @Test(arguments: [
        "/Volumes/Pairwise/Pairwise.app",
        "/Users/someone/Downloads/Pairwise.app",
        "/Users/someone/Desktop/Pairwise.app",
        "/private/var/folders/ab/T/AppTranslocation/1234/d/Pairwise.app",
        "/ApplicationsOld/Pairwise.app",
    ])
    func offersAMoveFromElsewhere(path: String) {
        #expect(InstallPlace.offersMove(appPath: path, homePath: Self.home, hasOffered: false))
    }

    @Test(arguments: [
        "/Applications/Pairwise.app",
        "/Applications/Tools/Pairwise.app",
        "/Users/someone/Applications/Pairwise.app",
    ])
    func staysInApplications(path: String) {
        #expect(!InstallPlace.offersMove(appPath: path, homePath: Self.home, hasOffered: false))
    }

    @Test func offersOnlyOnce() {
        #expect(
            !InstallPlace.offersMove(
                appPath: "/Users/someone/Downloads/Pairwise.app", homePath: Self.home,
                hasOffered: true))
    }
}
