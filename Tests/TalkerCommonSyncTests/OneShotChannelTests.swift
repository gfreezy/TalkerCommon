import Foundation
import Testing

@testable import TalkerCommonSync

@Test("OneShotChannel.wait throws CancellationError when the awaiting task is cancelled before finish")
func testOneShotChannelCancelBeforeFinish() async throws {
    let channel = OneShotChannel(Int.self)

    let waiter = Task<Int, Error> {
        try await channel.wait()
    }

    // Give the waiter time to suspend on wait()
    try await Task.sleep(nanoseconds: 50_000_000)
    waiter.cancel()

    do {
        _ = try await waiter.value
        Issue.record("expected CancellationError but task returned")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("expected CancellationError, got \(error)")
    }
}

@Test("OneShotChannel.wait returns the value when finish wins the race against cancel")
func testOneShotChannelFinishWinsRaceWithCancel() async throws {
    let channel = OneShotChannel(Int.self)

    let waiter = Task<Int, Error> {
        try await channel.wait()
    }

    try await Task.sleep(nanoseconds: 50_000_000)
    channel.finish(42)
    let value = try await waiter.value
    #expect(value == 42)
}

@Test("OneShotChannel.wait throws immediately if the task is already cancelled")
func testOneShotChannelCancelBeforeWait() async throws {
    let channel = OneShotChannel(Int.self)

    let waiter = Task<Int, Error> {
        // Cancel ourselves before waiting.
        withUnsafeCurrentTask { $0?.cancel() }
        return try await channel.wait()
    }

    do {
        _ = try await waiter.value
        Issue.record("expected CancellationError but task returned")
    } catch is CancellationError {
        // Expected.
    } catch {
        Issue.record("expected CancellationError, got \(error)")
    }
}

@Test("OneShotChannel resumes all concurrent waiters with the value")
func testOneShotChannelMultipleWaiters() async throws {
    let channel = OneShotChannel(Int.self)

    async let a = channel.wait()
    async let b = channel.wait()
    async let c = channel.wait()

    try await Task.sleep(nanoseconds: 50_000_000)
    channel.finish(7)

    let values = try await (a, b, c)
    #expect(values.0 == 7)
    #expect(values.1 == 7)
    #expect(values.2 == 7)
}

@Test("OneShotChannel.wait returns the cached value for callers arriving after finish")
func testOneShotChannelLateWaiter() async throws {
    let channel = OneShotChannel(Int.self)
    channel.finish(99)
    let v = try await channel.wait()
    #expect(v == 99)
}

@Test("OneShotChannel.wait rethrows the cached error for callers arriving after finish(throwing:)")
func testOneShotChannelLateWaiterError() async throws {
    struct Boom: Error, Equatable {}
    let channel = OneShotChannel(Int.self)
    channel.finish(throwing: Boom())
    do {
        _ = try await channel.wait()
        Issue.record("expected throw")
    } catch is Boom {
        // Expected.
    } catch {
        Issue.record("expected Boom, got \(error)")
    }
}
