source = [
  ".build/release/talk",
  ".build/release/TalkTalk_TalkTalkCore.bundle/Standard/*.talk"
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
