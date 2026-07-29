import Foundation
import Testing
@testable import Toruto

struct FilterParametersTests {
    @Test
    func 空のJSONはニュートラル値になる() throws {
        let decoded = try JSONDecoder().decode(FilterParameters.self, from: Data("{}".utf8))
        #expect(decoded == FilterParameters())
    }

    @Test
    func 指定した項目だけ上書きされる() throws {
        let json = #"{"saturation": 1.25, "grainIntensity": 0.5}"#
        let decoded = try JSONDecoder().decode(FilterParameters.self, from: Data(json.utf8))

        #expect(decoded.saturation == 1.25)
        #expect(decoded.grainIntensity == 0.5)
        #expect(decoded.contrast == 1)
        #expect(decoded.temperature == 6500)
    }
}
