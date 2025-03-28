//
//  PostHogFeatureFlagsTest.swift
//  PostHogTests
//
//  Created by Manoel Aranda Neto on 30.10.23.
//

import Foundation
import Nimble
@testable import PostHog
import Quick

class PostHogFeatureFlagsTest: QuickSpec {
    let config = PostHogConfig(apiKey: "123", host: "http://localhost:9001")

    func getSut(storage: PostHogStorage? = nil) -> PostHogFeatureFlags {
        let theStorage = storage ?? PostHogStorage(config)
        let api = PostHogApi(config)
        return PostHogFeatureFlags(config, theStorage, api)
    }

    override func spec() {
        var server: MockPostHogServer!

        beforeEach {
            server = MockPostHogServer()
            server.start()
        }
        afterEach {
            server.stop()
        }

        it("returns true for enabled flag - boolean") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            expect(sut.isFeatureEnabled("bool-value")) == true
        }

        it("returns true for enabled flag - string") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            expect(sut.isFeatureEnabled("string-value")) == true
        }

        it("returns false for disabled flag") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            expect(sut.isFeatureEnabled("disabled-flag")) == false
        }

        it("returns feature flag value") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            expect(sut.getFeatureFlag("string-value") as? String) == "test"
        }

        it("returns feature flag payload") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            expect(sut.getFeatureFlagPayload("number-value") as? Int) == 2
        }

        it("returns feature flag payload as dict") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            expect(sut.getFeatureFlagPayload("payload-json") as? [String: String]) == ["foo": "bar"]
        }

        it("merge flags if computed errors") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            server.errorsWhileComputingFlags = true

            let group2 = DispatchGroup()
            group2.enter()

            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group2.leave()
            })

            group2.wait()

            expect(sut.isFeatureEnabled("new-flag")) == true
            expect(sut.isFeatureEnabled("bool-value")) == true
        }

        it("clears feature flags when quota limited") {
            let sut = self.getSut()
            let group = DispatchGroup()
            group.enter()

            // First load some feature flags normally
            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group.leave()
            })

            group.wait()

            // Verify flags are loaded
            expect(sut.isFeatureEnabled("bool-value")) == true
            expect(sut.getFeatureFlag("string-value") as? String) == "test"

            // Now set the server to return quota limited response
            server.quotaLimitFeatureFlags = true

            let group2 = DispatchGroup()
            group2.enter()

            // Load flags again, this time with quota limiting
            sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                group2.leave()
            })

            group2.wait()

            // Verify flags are cleared
            expect(sut.isFeatureEnabled("bool-value")) == false
            expect(sut.getFeatureFlag("string-value")).to(beNil())
        }

        #if os(iOS)
            it("returns isSessionReplayFlagActive true if there is a value") {
                let storage = PostHogStorage(self.config)

                let recording: [String: Any] = ["test": 1]
                storage.setDictionary(forKey: .sessionReplay, contents: recording)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == true

                storage.reset()
            }

            it("returns isSessionReplayFlagActive false if there is no value") {
                let sut = self.getSut()

                expect(sut.isSessionReplayFlagActive()) == false
            }

            it("returns isSessionReplayFlagActive false if feature flag disabled") {
                let storage = PostHogStorage(self.config)

                let recording: [String: Any] = ["test": 1]
                storage.setDictionary(forKey: .sessionReplay, contents: recording)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == true

                let group = DispatchGroup()
                group.enter()

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) == nil
                expect(sut.isSessionReplayFlagActive()) == false

                storage.reset()
            }

            it("returns isSessionReplayFlagActive true if feature flag active") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == true

                storage.reset()
            }

            it("returns isSessionReplayFlagActive true if bool linked flag is enabled") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true
                server.returnReplayWithVariant = true

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == true

                storage.reset()
            }

            it("returns isSessionReplayFlagActive false if bool linked flag is disabled") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true
                server.returnReplayWithVariant = true
                server.replayVariantValue = false

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == false

                storage.reset()
            }

            it("returns isSessionReplayFlagActive true if multi variant linked flag is a match") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true
                server.returnReplayWithVariant = true
                server.returnReplayWithMultiVariant = true
                server.replayVariantName = "recording-platform"
                server.replayVariantValue = ["flag": "recording-platform-check", "variant": "web"]

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == true

                storage.reset()
            }

            it("returns isSessionReplayFlagActive false if multi variant linked flag is not a match") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true
                server.returnReplayWithVariant = true
                server.returnReplayWithMultiVariant = true
                server.replayVariantName = "recording-platform"
                server.replayVariantValue = ["flag": "recording-platform-check", "variant": "mobile"]

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == false

                storage.reset()
            }

            it("returns isSessionReplayFlagActive false if bool linked flag is missing") {
                let storage = PostHogStorage(self.config)

                let sut = self.getSut(storage: storage)

                expect(sut.isSessionReplayFlagActive()) == false

                let group = DispatchGroup()
                group.enter()

                server.returnReplay = true
                server.returnReplayWithVariant = true
                server.replayVariantName = "some-missing-flag"
                server.flagsSkipReplayVariantName = true

                sut.loadFeatureFlags(distinctId: "distinctId", anonymousId: "anonymousId", groups: ["group": "value"], callback: {
                    group.leave()
                })

                group.wait()

                expect(storage.getDictionary(forKey: .sessionReplay)) != nil
                expect(self.config.snapshotEndpoint) == "/newS/"
                expect(sut.isSessionReplayFlagActive()) == false

                storage.reset()
            }
        #endif
    }
}
