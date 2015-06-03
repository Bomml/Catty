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

class CBScriptContextAbstract : SKNode {

    // MARK: - Properties
    final var script:Script {
        if let startScriptCtxt = self as? CBStartScriptContext {
            return startScriptCtxt.startScript
        } else if let whenScriptCtxt = self as? CBWhenScriptContext {
            return whenScriptCtxt.whenScript
        } else if let broadcastScriptCtxt = self as? CBBroadcastScriptContext {
            return broadcastScriptCtxt.broadcastScript
        } else {
            fatalError("No or unknown subclass of abstract CBScriptContextAbstract class!!!")
        }
    }
    final var isLocked = false
    final private var _stateStorage: CBScriptState
    final var state: CBScriptState {
        get { return _stateStorage }
        // if script is RunningBlocking (BroadcastScript called by BroadcastWait) then do not change state!
        set { _stateStorage = (_stateStorage != .RunningBlocking || newValue != .RunningMature) ? newValue : _stateStorage }
    }
    final var count: Int { return _instructionList.count }

    final private var _reverseInstructionPointer : Int = 0
    final private lazy var _instructionList = [CBExecClosure]()
    final private var _scriptSequenceList: CBScriptSequenceList?

    // MARK: - Initializers
    convenience init(scriptSequenceList: CBScriptSequenceList) {
        self.init(state: .Runnable, scriptSequenceList: scriptSequenceList, instructionList: [])
    }

    init(state: CBScriptState, scriptSequenceList: CBScriptSequenceList, instructionList: [CBExecClosure]) {
        _stateStorage = state
        self._scriptSequenceList = scriptSequenceList
        super.init()
        for instruction in instructionList {
            self.appendInstruction(instruction)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This initializer must NOT be called")
    }

    // MARK: - Operations
    final func appendInstruction(instruction: CBExecClosure) {
        _instructionList.append(instruction)
        ++_reverseInstructionPointer
    }

    final func nextInstruction() -> CBExecClosure? {
        if state == .Dead { return nil } // must be an old deprecated enqueued dispatch closure
        assert((state == .Running) || (state == .RunningMature) || (state == .RunningBlocking))
        if (_reverseInstructionPointer == 0) || (_instructionList.count == 0) {
            return nil
        }

        // after first instruction executed => set state to RunningMature
        if state == .Running {
            state = .RunningMature
        }
        return _instructionList[--_reverseInstructionPointer]
    }

    final func jump(#numberOfInstructions: Int) {
        if state == .Dead { return } // must be an old deprecated enqueued dispatch closure
        if numberOfInstructions == 0 { return }
        assert((state == .Running) || (state == .RunningMature) || (state == .RunningBlocking))
        let newInstructionPointerPosition = _reverseInstructionPointer - numberOfInstructions
        if newInstructionPointerPosition < 0 || newInstructionPointerPosition > _instructionList.count {
            return
        }
        _reverseInstructionPointer = newInstructionPointerPosition
    }

    final func reset() {
        _reverseInstructionPointer = _instructionList.count
    }

    final func removeReferences() {
        self._instructionList.removeAll(keepCapacity: false)
        self._scriptSequenceList?.sequenceList.rootSequenceList = nil
        if self._scriptSequenceList != nil {
            for sequence in self._scriptSequenceList!.sequenceList {
                sequence.rootSequenceList = nil
            }
        }
        self._scriptSequenceList = nil
    }
}

// MARK: - Custom operators
func +=(inout left: CBScriptContextAbstract, right: CBExecClosure) {
    left.appendInstruction(right)
}
