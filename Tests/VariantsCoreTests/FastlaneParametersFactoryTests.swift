//
//  Variants
//
//  Copyright (c) Backbase B.V. - https://www.backbase.com
//  Created by Arthur Alves
//

import XCTest
import PathKit
@testable import VariantsCore

let parameters = [
    CustomProperty(name: "sample", value: "sample-value", destination: .project),
    CustomProperty(name: "sample-2", value: "sample-2-value", destination: .fastlane),
    CustomProperty(name: "sample-3", value: "sample-3-value", destination: .project),
    CustomProperty(name: "sample-4", value: "sample-4-value", destination: .fastlane),
    CustomProperty(name: "sample-5", value: "sample-5-value", destination: .fastlane),
    CustomProperty(name: "sample-env", value: "{{ envVars.API_TOKEN }}", destination: .fastlane)
]

let correctOutput =
    """
    # Generated by Variants
    VARIANTS_PARAMS = {
        sample-2: \"sample-2-value\",
        sample-4: \"sample-4-value\",
        sample-5: \"sample-5-value\",
        sample-env: ENV[\"API_TOKEN\"],
    }.freeze
    """

class FastlaneParametersFactoryTests: XCTestCase {
    func testRender_correctData() {
        guard
            let templateFilePath = Bundle(for: type(of: self))
                .path(forResource: "Resources/variants_params_template", ofType: "rb"),
            let templateFileContent = try? String(contentsOfFile: templateFilePath,
                                                  encoding: .utf8)
        else { return }
        
        // Assset we are able to write the template's content to a temporary
        // template in `private/tmp/`, to be used as `Path` from this test target.
        // Without this Path, `FastlaneParametersFactory` can't be tested as it
        // depends on `Stencil.FileSystemLoader` to load the template.
        let temporaryTemplatePath = Path("variants_params_template.rb")
        XCTAssertNoThrow(try temporaryTemplatePath.write(templateFileContent))
        
        let factory = FastlaneParametersFactory(templatePath: Path("./"))
        
        XCTAssertNoThrow(try factory.render(parameters: parameters))
        XCTAssertNotNil(try factory.render(parameters: parameters))
        
        do {
            if let renderedData = try factory.render(parameters: parameters) {
                XCTAssertEqual(String(data: renderedData, encoding: .utf8), correctOutput)
            }
        } catch {
            XCTFail("'Try' should not throw - "+error.localizedDescription)
        }
    }
    
    func testFileWrite_correctOutput() {
        let basePath = Path("./")
        do {
            let fastlaneParametersPath = try Path("fastlane").safeJoin(path: Path("parameters/"))
            if !fastlaneParametersPath.exists {
                XCTAssertNoThrow(try fastlaneParametersPath.mkpath())
            }
            
            let factory = FastlaneParametersFactory(templatePath: basePath)
            XCTAssertNoThrow(try factory.write(Data(correctOutput.utf8), using: fastlaneParametersPath))
            
            let fastlaneParametersFile = Path(fastlaneParametersPath.string+"/variants_params.rb")
            XCTAssertTrue(fastlaneParametersFile.exists)
            XCTAssertEqual(try fastlaneParametersFile.read(), correctOutput)
            
        } catch {
            XCTFail("'Try' should not throw - "+error.localizedDescription)
        }
    }
}
