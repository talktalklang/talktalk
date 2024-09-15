source = [
  "./talk"
]

bundle_id = "sh.talktalk"

sign {}

notarize {
  path = "./talk"
  bundle_id = "sh.talktalk"
}
