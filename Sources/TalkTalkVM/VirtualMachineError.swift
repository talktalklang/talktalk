//
//  VirtualMachineError.swift
//  TalkTalk
//
//  Created by Pat Nakajima on 9/3/24.
//

import TalkTalkBytecode

public enum VirtualMachineError: Error {
	case stackImbalance(String)
	case mainNotFound(String)
	case valueMissing(String)
	case unknownOpcode(Byte)
	case typeError(String)
}
