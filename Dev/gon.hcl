source = ["./Release/talk"]
bundle_id = "sh.talktalk"

sign {

}

zip {
  output_path = "talk.zip"
}

notarize {
  path = "./talk.zip"
  bundle_id = "sh.talktalk"
}
