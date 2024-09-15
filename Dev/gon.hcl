source = [
  ".build/release/talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/Standard/Int.talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/Standard/Array.talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/Standard/Dictionary.talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/Standard/String.talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/REPL/repl.talk"
]

bundle_id = "sh.talktalk"

sign {

}

zip {
  output_path = "TalkTalk.zip"
}

notarize {
  path = "./TalkTalk.zip"
  bundle_id = "sh.talktalk"
}
