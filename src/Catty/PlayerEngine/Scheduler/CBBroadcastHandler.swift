/**
 *  Copyright (C) 2010-2015 The Catrobat Team
 *  (http://developer.catrobat.org/credits)
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 *
 *  An additional term exception under section 7 of the GNU Affero
 *  General Public License, version 3, is available at
 *  (http://developer.catrobat.org/license_additional_term)
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see http://www.gnu.org/licenses/.
 */

final class CBBroadcastHandler : CBBroadcastHandlerProtocol {

    // MARK: - Constants
    // specifies max depth limit for self broadcasts running on the same function stack
    let selfBroadcastRecursionMaxDepthLimit = 30

    // MARK: - Properties
    var logger: CBLogger
    weak var scheduler: CBSchedulerProtocol?
    private lazy var _broadcastWaitingContextsQueue = [CBScriptContext:[CBBroadcastScriptContext]]()
    private lazy var _registeredBroadcastContexts = [String:[CBBroadcastScriptContext]]()
    private lazy var _selfBroadcastCounters = [String:Int]()

    // MARK: - Initializers
    init(logger: CBLogger, scheduler: CBSchedulerProtocol?) {
        self.logger = logger
        self.scheduler = scheduler
    }

    convenience init(logger: CBLogger) {
        self.init(logger: logger, scheduler: nil)
    }

    // MARK: - Operations
    func setup() {}

    func tearDown() {
        _broadcastWaitingContextsQueue.removeAll(keepCapacity: false)
        _registeredBroadcastContexts.removeAll(keepCapacity: false)
        _selfBroadcastCounters.removeAll(keepCapacity: false)
    }

    func subscribeBroadcastContext(context: CBBroadcastScriptContext) {
        let message = context.broadcastMessage
        if var registeredContexts = _registeredBroadcastContexts[message] {
            assert(registeredContexts.contains(context) == false, "FATAL: BroadcastScriptContext already registered!")
            registeredContexts += context
            _registeredBroadcastContexts[message] = registeredContexts

        } else {
            _registeredBroadcastContexts[message] = [context]
        }

        let object = context.script.object
        logger.info("Subscribed new CBBroadcastScriptContext of object \(object!.name) for message \(message)")
    }

    func unsubscribeBroadcastContext(context: CBBroadcastScriptContext) {
        let message = context.broadcastMessage
        if var registeredContexts = _registeredBroadcastContexts[message] {
            var index = 0
            for registeredContext in registeredContexts {
                if registeredContext === context {
                    registeredContexts.removeAtIndex(index)
                    let object = context.script.object
                    logger.info("Unsubscribed CBBroadcastScriptContext of object \(object!.name) for message \(message)")
                    return
                }
                ++index
            }
        }
        fatalError("FATAL: Given BroadcastScript is NOT registered!")
    }

    // MARK: - Broadcast Handling
    func performBroadcastWithMessage(message: String, senderContext: CBScriptContext,
        broadcastType: CBBroadcastType)
    {
        logger.info("Performing \(broadcastType.typeName()) with message '\(message)'")
        let enqueuedWaitingScripts = _broadcastWaitingContextsQueue[senderContext]
        assert(enqueuedWaitingScripts == nil || enqueuedWaitingScripts?.count == 0)

        var isSelfBroadcast = false
        let registeredContexts = _registeredBroadcastContexts[message]
        if registeredContexts == nil || registeredContexts?.count == 0 {
            logger.info("No listeners for message '\(message)' found")
            scheduler?.runNextInstructionOfContext(senderContext)
            return
        }

        // collect all broadcast recipients
        var recipientContexts = [CBBroadcastScriptContext]()
        for registeredContext in registeredContexts! {
            // case broadcastScript == senderScript => restart script
            if registeredContext === senderContext {
                // end of script reached!! Script will be aborted due to self-calling broadcast
                isSelfBroadcast = true
                // stop own script (sender script!)
                scheduler?.stopContext(registeredContext, continueWaitingBroadcastSenders: true)
                continue
            }

            // case broadcastScript != senderScript (=> other broadcastscript)
            if scheduler?.isContextScheduled(registeredContext) == true {
                // case broadcastScript is running => stop it
                scheduler?.stopContext(registeredContext, continueWaitingBroadcastSenders: true)
            }
            recipientContexts += registeredContext // collect other (!) broadcastScript
        }

        if !isSelfBroadcast && broadcastType == .BroadcastWait {
            // do not wait for broadcast script if self broadcast == senderScript
            // => do not execute further actions of senderScript!
            senderContext.state = .Waiting
            _broadcastWaitingContextsQueue[senderContext] = recipientContexts
        }

        // finally schedule all other (!) (collected) listening broadcast scripts
        for recipientContext in recipientContexts {
            scheduler?.scheduleContext(recipientContext, withInitialState: .Runnable)
        }

        if isSelfBroadcast {
            // launch self (!) listening broadcast script
            _performSelfBroadcastForContext(senderContext as! CBBroadcastScriptContext)
        } else if broadcastType == .Broadcast {
            scheduler?.runNextInstructionOfContext(senderContext)
        }
    }

    private func _performSelfBroadcastForContext(context: CBBroadcastScriptContext) {
        let message = context.broadcastMessage
        var counter = 0
        if let counterNumber = _selfBroadcastCounters[message] {
            counter = counterNumber
        }
        if ++counter % selfBroadcastRecursionMaxDepthLimit == 0 { // XXX: DIRTY PERFORMANCE HACK!!
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                // restart this self-listening BroadcastScript
                self?.scheduler?.startContext(context, withInitialState: .Runnable)
            })
        } else {
            scheduler?.startContext(context, withInitialState: .Runnable)
        }
        _selfBroadcastCounters[message] = counter
        logger.debug("BROADCASTSCRIPT HAS BEEN RESTARTED DUE TO SELF-BROADCAST!!")
    }

    func continueContextsWaitingForTerminationOfBroadcastContext(context: CBBroadcastScriptContext) {
        var waitingContextsToBeContinued = [CBScriptContext]()
        for (waitingContext, var runningBroadcastContexts) in _broadcastWaitingContextsQueue {
            assert(waitingContext != context)
            runningBroadcastContexts.removeObject(context)
            if runningBroadcastContexts.isEmpty {
                waitingContextsToBeContinued += waitingContext
            }
            _broadcastWaitingContextsQueue[waitingContext] = runningBroadcastContexts
            assert(_broadcastWaitingContextsQueue[waitingContext]!.count == runningBroadcastContexts.count)
        }
        for waitingContext in waitingContextsToBeContinued {
            // finally remove waitingContext from dictionary
            _broadcastWaitingContextsQueue.removeValueForKey(waitingContext)
            // schedule next instruction!
            assert(waitingContext.state == .Waiting) // just to ensure
            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                assert(waitingContext.state == .Waiting) // just to ensure
                waitingContext.state = .Runnable // running again!
                self?.scheduler?.runNextInstructionOfContext(waitingContext)
            })
        }
    }

    func removeWaitingContextAndTerminateAllCalledBroadcastContexts(context: CBScriptContext) {
        if let broadcastContexts = _broadcastWaitingContextsQueue[context] {
//            for broadcastContext in broadcastContexts {
//                scheduler?.stopContext(broadcastContext, continueWaitingBroadcastSenders: false)
//            }
            _broadcastWaitingContextsQueue.removeValueForKey(context)
        }
    }
}
