source = [
  "./Release/talk",
  "./Release/TalkTalk_TalkTalkCore.bundle"
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
