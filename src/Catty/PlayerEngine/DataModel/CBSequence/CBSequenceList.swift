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

final class CBSequenceList : SequenceType {

    // MARK: - Properties
    weak var rootSequenceList : CBScriptSequenceList?
    lazy var sequenceList = [CBSequence]()
    var count : Int { return sequenceList.count }

    // MARK: - Initializers
    init(rootSequenceList : CBScriptSequenceList?) {
        self.rootSequenceList = rootSequenceList
    }

    // MARK: - Operations
    func append(let sequence : CBSequence) {
        sequenceList.append(sequence)
    }

    // MARK: - Generator
// [Swift2.0] DO NOT REMOVE!!!
//    func generate() -> AnyGenerator<CBSequence> {
//        var i = 0
//        return anyGenerator {
//            return i >= self.sequenceList.count ? .None : self.sequenceList[i++]
//        }
//    }
// [Swift2.0] DO NOT REMOVE!!!
// [Swift1.2] DO NOT REMOVE!!!
    func generate() -> GeneratorOf<CBSequence> {
        var i = 0
        return GeneratorOf<CBSequence> {
            return i >= self.sequenceList.count ? .None : self.sequenceList[i++]
        }
    }
// [Swift1.2] DO NOT REMOVE!!!

}

// MARK: - Custom operators
func +=(left: CBSequenceList, right: CBSequence) {
    left.append(right)
}
