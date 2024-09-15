source = [
  "./Release/talk",
  "./Release/Library"
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
