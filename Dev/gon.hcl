bundle_id = "sh.talktalk"

source = [".build/release/talk"]

sign {}

zip {
  output_path = "talk.zip"
}

notarize {
  path = "./talk.zip"
  bundle_id = "sh.talktalk"
}
