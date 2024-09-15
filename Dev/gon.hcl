bundle_id = "sh.talktalk"

source {
  path = ".build/release/talk"
}

sign {}

zip {
  output_path = "talk.zip"
}

notarize {
  path = "./talk.zip"
  bundle_id = "sh.talktalk"
  staple = true
}
