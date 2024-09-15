bundle_id = "sh.talktalk"

sign {}

notarize {
  path = "./talk.zip"
  bundle_id = "sh.talktalk"
  staple = true
}
