import Foundation
import Testing
@testable import DeepworkCore

struct AudioTests {
    private func renderSeconds(_ mode: AudioMode, seconds: Float = 4, sampleRate: Float = 48_000) -> ([Float], [Float]) {
        let params = AudioParameters(mode: mode, gain: 1, rampSeconds: 0.01)
        let renderer = FocusRenderer(params: params, sampleRate: sampleRate)
        let n = Int(seconds * sampleRate)
        var left = [Float](repeating: 0, count: n)
        var right = [Float](repeating: 0, count: n)
        left.withUnsafeMutableBufferPointer { l in
            right.withUnsafeMutableBufferPointer { r in
                var offset = 0
                while offset < n {
                    let block = min(512, n - offset)
                    renderer.render(frameCount: block, left: l.baseAddress! + offset, right: r.baseAddress! + offset)
                    offset += block
                }
            }
        }
        return (left, right)
    }

    @Test(arguments: AudioMode.allCases)
    func generatorsStayBoundedAndFinite(mode: AudioMode) {
        let (l, r) = renderSeconds(mode)
        for v in l { #expect(v.isFinite); #expect(abs(v) <= 1.0) }
        for v in r { #expect(v.isFinite); #expect(abs(v) <= 1.0) }
        let rms = sqrt(l.reduce(0) { $0 + $1 * $1 } / Float(l.count))
        #expect(rms > 0.01, "modo \(mode) está em silêncio")
    }

    @Test func pinkAndBrownHaveLessHighFrequencyEnergyThanWhite() {
        func highLowRatio(_ x: [Float]) -> Float {
            // Diferença de amostras adjacentes aproxima um passa-altas; soma aproxima um passa-baixas.
            var hi: Float = 0, lo: Float = 0
            for i in 1..<x.count {
                let d = x[i] - x[i - 1]
                let s = x[i] + x[i - 1]
                hi += d * d
                lo += s * s
            }
            return hi / max(lo, 1e-9)
        }
        let white = highLowRatio(renderSeconds(.white).0)
        let pink = highLowRatio(renderSeconds(.pink).0)
        let brown = highLowRatio(renderSeconds(.brown).0)
        #expect(pink < white)
        #expect(brown < pink)
    }

    @Test func binauralChannelsDifferByBeatFrequency() {
        let params = AudioParameters(mode: .binauralGamma, gain: 1, rampSeconds: 0.001, beatHz: 40, carrierHz: 200)
        let sr: Float = 48_000
        let renderer = FocusRenderer(params: params, sampleRate: sr)
        let n = Int(sr)
        var l = [Float](repeating: 0, count: n)
        var r = [Float](repeating: 0, count: n)
        l.withUnsafeMutableBufferPointer { lp in
            r.withUnsafeMutableBufferPointer { rp in
                renderer.render(frameCount: n, left: lp.baseAddress!, right: rp.baseAddress!)
            }
        }
        func zeroCrossings(_ x: [Float]) -> Int {
            var c = 0
            for i in 1..<x.count where (x[i - 1] < 0) != (x[i] < 0) { c += 1 }
            return c
        }
        // Cruzamentos por zero em 1 s ≈ 2 × frequência.
        let fl = Float(zeroCrossings(l)) / 2
        let fr = Float(zeroCrossings(r)) / 2
        #expect(abs(fl - 200) <= 2)
        #expect(abs(fr - 240) <= 2)
    }

    @Test func gainRampsToSilenceWithoutJumps() {
        let params = AudioParameters(mode: .brown, gain: 1, rampSeconds: 0.001)
        let sr: Float = 48_000
        let renderer = FocusRenderer(params: params, sampleRate: sr)
        var l = [Float](repeating: 0, count: 4800)
        var r = [Float](repeating: 0, count: 4800)
        l.withUnsafeMutableBufferPointer { lp in r.withUnsafeMutableBufferPointer { rp in
            renderer.render(frameCount: 4800, left: lp.baseAddress!, right: rp.baseAddress!)
        } }
        params.targetGain = 0
        params.rampSeconds = 0.05
        var tail = [Float](repeating: 0, count: 4800)
        var tailR = [Float](repeating: 0, count: 4800)
        tail.withUnsafeMutableBufferPointer { lp in tailR.withUnsafeMutableBufferPointer { rp in
            renderer.render(frameCount: 4800, left: lp.baseAddress!, right: rp.baseAddress!)
        } }
        #expect(abs(tail[4799]) < 1e-5)
        #expect(renderer.isSilent)
    }

    @Test func bellIsNormalizedAndFinite() {
        let bell = BellSynth.renderBell(sampleRate: 48_000, volume: 1)
        #expect(bell.count == 144_000)
        let peak = bell.map { abs($0) }.max() ?? 0
        #expect(abs(peak - 0.7) < 0.001)
        #expect(bell.allSatisfy { $0.isFinite })
        #expect(abs(bell[0]) < 0.01)
        let quiet = BellSynth.renderBell(sampleRate: 48_000, volume: 0.5)
        #expect(abs((quiet.map { abs($0) }.max() ?? 0) - 0.35) < 0.001)
    }

    @Test func blipIsShort() {
        let blip = BellSynth.renderBlip()
        #expect(blip.count == 2880)
        #expect((blip.map { abs($0) }.max() ?? 0) <= 0.3001)
    }
}
